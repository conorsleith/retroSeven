//
//  StravaData.swift
//  retroSeven
//
//  Created by Conor Sleith on 10/21/23.
//

import Foundation
import Combine

let SECONDS_IN_DAY: Double = 60 * 60 * 24

enum RequestStatus {
    case Success
    case AuthFailure
    case DecodeFailure
    case Starting
}

class StravaDataViewModel: ObservableObject {
    @Published var currentMileage: Int = 0
    @Published var expiringMileage: Int = 0
    @Published var needsRefresh = false
    
    private let queryBeforeSeconds = round(Date().timeIntervalSince1970)
    private let queryAfterSeconds = StravaDataViewModel.epochTimestampForOneWeekAgoMidnight() + SECONDS_IN_DAY

    private var activities: [StravaActivity] = []
    private var cancellables: Set<AnyCancellable> = []
    private var requestStatus: RequestStatus?
    private var shouldFakeToken = false
    
    var isLoading: Bool = false
    var error: Error?

    init () {
        print("Initializing StravaDataViewModel...")
    }

    func fetchStravaActivities() async -> (Int, Int) {
        // Set isLoading to true to show a loading indicator in your view.
        print("Loading strava data...")
        isLoading = true
        
        // get the access token from the keychain
        var accessToken: String = ""
        if let tokenResponse = StravaDataViewModel.retrieveToken() {
            if (self.shouldFakeToken) {
                accessToken = "foo"
                self.shouldFakeToken = false
            } else {
                accessToken = tokenResponse
            }
        } else {
            // we really shouldn't be here because we're supposed to do
            // the first authorization before entering MainScreen
            print("Couldn't authorize")
            return (-1, -1)
        }

        // Make the API call and process
        if let url = buildURL() {
            return await makeFetchCall(url: url, accessToken: accessToken)
        }
        return (-1, -1)
    }

    func makeFetchCall(url: URL, accessToken: String) async -> (Int, Int){
        print("Running makeFetchCall with token: \(accessToken)")
        self.requestStatus = RequestStatus.Starting
        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                                                let message = json["message"] as? String,
                                                message == "Authorization Error" {
                self.requestStatus = RequestStatus.AuthFailure
                DispatchQueue.main.async {
                    self.needsRefresh = true
                }
            } else {
                let activities = try JSONDecoder().decode([StravaActivity].self, from: data)
                self.activities = activities
                let (currentMileage, expiringMileage) = StravaDataViewModel.calculateMiles(activities: activities)
                DispatchQueue.main.async {
                    self.currentMileage = currentMileage
                    self.expiringMileage = expiringMileage
                }
                self.requestStatus = RequestStatus.Success
                return (currentMileage, expiringMileage)
            }
        } catch {
            self.isLoading = false
            self.error = error
            self.requestStatus = RequestStatus.DecodeFailure
            print("Caught an error")
            print(error)
        }
        return (-1, -1)
    }

    func buildURL() -> URL? {
        let apiUrl = "https://www.strava.com/api/v3/athlete/activities"
        guard let baseURL = URL(string: apiUrl) else {
            isLoading = false
            error = URLError(URLError.badURL)
            return nil
        }
        var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: true)
        let parameters: [URLQueryItem] = [
            URLQueryItem(name: "before", value: String(format: "%.0f", self.queryBeforeSeconds)),
            URLQueryItem(name: "after", value: String(format: "%.0f", self.queryAfterSeconds)),
            URLQueryItem(name: "page", value: "1"),
            URLQueryItem(name: "per_dpage", value: "28")
        ]
        components?.queryItems = parameters
        if let url = components?.url {
            return url
        }
        return nil
    }
    
    static func retrieveToken() -> String? {
        if let tokenResponse = AuthViewModel.retrieveTokenFromKeychain(service: keyChainTokenService) {
            return tokenResponse
        }
        return nil
    }
    
    static func epochTimestampForOneWeekAgoMidnight() -> TimeInterval {
        let calendar = Calendar.current
        let currentDate = Date()

        // Calculate the date one week ago from today
        if let oneWeekAgo = calendar.date(byAdding: .weekOfYear, value: -1, to: currentDate) {

            // Create a date representing 12:00 AM on the one-week-ago date
            var components = calendar.dateComponents([.year, .month, .day], from: oneWeekAgo)
            components.hour = 0
            components.minute = 0
            components.second = 0

            if let dateAtMidnight = calendar.date(from: components) {

                // Calculate and return the epoch timestamp
                return round(dateAtMidnight.timeIntervalSince1970)
            }
        }
        return TimeInterval() // Return nil if there was an error
    }
    
    static func todayEndpoints() -> (Date, Date) {
        let calendar = Calendar.current
        let currentDate = Date()
        let startOfToday = calendar.startOfDay(for: currentDate)
        let endOfToday = startOfToday.addingTimeInterval(SECONDS_IN_DAY)
        return (startOfToday, endOfToday)
    }
    
    static func isDateInOneWeekInterval(_ date: Date) -> Bool {
        var startOfToday: Date
        var endOfToday: Date
        (startOfToday, endOfToday) = todayEndpoints()
        let startOfOneWeekAgo = startOfToday.addingTimeInterval(-6*SECONDS_IN_DAY) // 6 days ago
        return date >= startOfOneWeekAgo && date < endOfToday
    }
    
    static func isOnExpiringDay(_ date: Date) -> Bool {
        let (startOfToday, _) = todayEndpoints()
        let startOfDayOneWeekAgo = startOfToday.addingTimeInterval(-6*SECONDS_IN_DAY) // 6 days ago
        let endOfDayOneWeekAgo = startOfDayOneWeekAgo.addingTimeInterval(SECONDS_IN_DAY)
        return date >= startOfDayOneWeekAgo && date < endOfDayOneWeekAgo
    }

    static func calculateMiles(activities: [StravaActivity]) -> (Int, Int) {
        let runningActivities = activities
            .filter { activity in
            return activity.sportType == "Run"
        }
        let currentActivities: [StravaActivity] = runningActivities
            .filter { activity in
                return isDateInOneWeekInterval(getDateFromTimestamp(timestampString: activity.startDateLocal))
            }
        let expiringActivities: [StravaActivity] = runningActivities
            .filter { activity in
                return isOnExpiringDay(getDateFromTimestamp(timestampString: activity.startDateLocal))
            }
        let currentDistance = currentActivities.reduce(0.0) { (result, activity) in
            return result + activity.distance * MilesToMetersFactor
        }
        let expiringDistance = expiringActivities.reduce(0.0) { (result, activity) in
            return result + activity.distance * MilesToMetersFactor
        }
        return (Int(round(currentDistance)), Int(round(expiringDistance)))
    }

    static func getDateFromTimestamp(timestampString: String) -> Date {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        dateFormatter.timeZone = TimeZone.current // Assuming your timestamp is in UTC

        if let date = dateFormatter.date(from: timestampString) {
            return date
        } else {
            print("Failed to parse the timestamp string.")
            return Date()
        }
    }
    
    static func debugPrintRequest(request: URLRequest) {
        print("URL: \(request.url?.absoluteString ?? "N/A")")
        print("HTTP Method: \(request.httpMethod ?? "N/A")")
        print("Headers: \(request.allHTTPHeaderFields ?? [:])")

        if let bodyData = request.httpBody, let bodyString = String(data: bodyData, encoding: .utf8) {
            print("HTTP Body: \(bodyString)")
        }
    }
}
