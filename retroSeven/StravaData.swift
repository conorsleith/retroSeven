//
//  StravaData.swift
//  retroSeven
//
//  Created by Conor Sleith on 10/21/23.
//

import Foundation
import Combine

enum RequestStatus {
    case Success
    case AuthFailure
    case DecodeFailure
    case Starting
}

class StravaDataViewModel: ObservableObject {
    @Published var isLoading: Bool = false
    @Published var error: Error?
    @Published var activities: [StravaActivity] = []
    @Published var currentMileage: Int = 0
    @Published var expiringMileage: Int = 0
    @Published var needsRefresh = false
    private var cancellables: Set<AnyCancellable> = []
    private var requestStatus: RequestStatus?
    private var shouldFakeToken = true

    func retrieveToken() -> String? {
        if let tokenResponse = AuthViewModel.retrieveTokenFromKeychain(service: keyChainTokenService) {
            return tokenResponse
        }
        return nil
    }
    
    func fetchStravaActivities() {
        // Set isLoading to true to show a loading indicator in your view.
        print("Loading strava data...")
        isLoading = true
        
        // get the access token from the keychain
        var accessToken: String = ""
        if let tokenResponse = retrieveToken() {
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
            return
        }
        
        // Build the request URL
        let apiUrl = "https://www.strava.com/api/v3/athlete/activities"
        guard let baseURL = URL(string: apiUrl) else {
            isLoading = false
            error = URLError(URLError.badURL)
            return
        }
        var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: true)
        let before = round(Date().timeIntervalSince1970)
        let after = StravaDataViewModel.epochTimestampForOneWeekAgoMidnight()
        let parameters: [URLQueryItem] = [
            URLQueryItem(name: "before", value: String(format: "%.0f", before)),
            URLQueryItem(name: "after", value: String(format: "%.0f", after)),
            URLQueryItem(name: "page", value: "1"),
            URLQueryItem(name: "per_dpage", value: "28")
        ]
        components?.queryItems = parameters
        
        // Make the API call and process
        if let url = components?.url {
            makeFetchCall(url: url, accessToken: accessToken)
        }
    }

    func makeFetchCall(url: URL, accessToken: String) {
        print("Running makeFetchCall with token: \(accessToken)")
        self.requestStatus = RequestStatus.Starting
        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
//        debugPrintRequest(request: request)
        
        URLSession.shared.dataTaskPublisher(for: request)
            .map(\.data)
//            .print("API Request Debug:")
            .sink(receiveCompletion: { result in
                switch result {
                case .finished:
                    break
                case .failure(let error):
                    self.isLoading = false
                    self.error = error
                    print("Failure!")
                }
            }, receiveValue: { data in
            dataProcess: do {
                    // Let's check and see if it's an auth failure
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        if let message = json["message"] as? String {
                            if message == "Authorization Error" {
                                self.requestStatus = RequestStatus.AuthFailure
                                self.needsRefresh = true
                                break dataProcess
                            }
                        }
                    }
                    let activities = try JSONDecoder().decode([StravaActivity].self, from: data)
                    self.activities = activities
                    let (currentMileage, expiringMileage) = StravaDataViewModel.calculateMiles(activities: activities)
                    DispatchQueue.main.async {
                        self.currentMileage = currentMileage
                        self.expiringMileage = expiringMileage
//                        self.currentMileage += 1
//                        self.expiringMileage += 1
                    }
                    self.requestStatus = RequestStatus.Success
                } catch {
                    // Handle decoding errors
                    self.isLoading = false
                    self.error = error
                    self.requestStatus = RequestStatus.DecodeFailure
                    print("Caught an error")
                    print(error)
                }
            })
            .store(in: &cancellables)
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

    static func isDateInOneWeekInterval(_ date: Date) -> Bool {
        let calendar = Calendar.current
        let currentDate = Date()

        // Calculate the start of today at 12:00 AM
        let startOfToday = calendar.startOfDay(for: currentDate)
        if let endOfToday = calendar.date(byAdding: .day, value: 1, to: startOfToday),
           let startOfOneWeekAgo = calendar.date(byAdding: .day, value: -6, to: startOfToday) {
            // Check if the date falls within the range
            return date >= startOfOneWeekAgo && date < endOfToday
        }
        return false
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
                return !isDateInOneWeekInterval(getDateFromTimestamp(timestampString: activity.startDateLocal))
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
