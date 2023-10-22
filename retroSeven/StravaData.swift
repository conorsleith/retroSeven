//
//  StravaData.swift
//  retroSeven
//
//  Created by Conor Sleith on 10/21/23.
//

import Foundation
import Combine

struct Athlete: Decodable {
    let id: Int
    let resourceState: Int
    
    enum CodingKeys: String, CodingKey {
        case id
        case resourceState = "resource_state"
    }
}

struct Map: Decodable {
    let id: String
    let resourceState: Int
    let summaryPlotline: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case resourceState = "resource_state"
        case summaryPlotline = "summary_plotline"
    }
}

struct StravaActivity: Decodable {
    let achievementCount: Int
//    let athlete: Athlete
    let athleteCount: Int
    let averageCadence: Double
    let averageHeartrate: Double
    let averageSpeed: Double
    let averageTemp: Int
    let commentCount: Int
    let commute: Bool
    let displayHideHeartrateOption: Bool
    let distance: Double
    let elapsedTime: Int
    let elevHigh: Double
    let elevLow: Double
    let endLatlng: [Double]
    let externalId: String
    let flagged: Bool
    let fromAcceptedTag: Bool
    let gearId: String
    let hasHeartrate: Bool
    let hasKudoed: Bool
    let heartrateOptOut: Bool
    let id: Int
    let kudosCount: Int
    let locationCity: String?
    let locationCountry: String?
    let locationState: String?
    let manual: Bool
//    let map: Map
    let maxHeartrate: Double
    let maxSpeed: Double
    let movingTime: Int
    let name: String
    let photoCount: Int
    let prCount: Int
    let isPrivate: Bool
    let resourceState: Int
    let sportType: String
    let startDate: String
    let startDateLocal: String
    let startLatlng: [Double]
    let sufferScore: Double
    let timezone: String
    let totalElevationGain: Double
    let totalPhotoCount: Int
    let isTrainer: Bool
    let type: String
    let uploadId: Int
    let uploadIdStr: String
    let utcOffset: Double
    let visibility: String
    let workoutType: Int
    
    enum CodingKeys: String, CodingKey {
        case achievementCount = "achievement_count"
//        case athlete
        case athleteCount = "athlete_count"
        case averageCadence = "average_cadence"
        case averageHeartrate = "average_heartrate"
        case averageSpeed = "average_speed"
        case averageTemp = "average_temp"
        case commentCount = "comment_count"
        case commute
        case displayHideHeartrateOption = "display_hide_heartrate_option"
        case distance
        case elapsedTime = "elapsed_time"
        case elevHigh = "elev_high"
        case elevLow = "elev_low"
        case endLatlng = "end_latlng"
        case externalId = "external_id"
        case flagged
        case fromAcceptedTag = "from_accepted_tag"
        case gearId = "gear_id"
        case hasHeartrate = "has_heartrate"
        case hasKudoed = "has_kudoed"
        case heartrateOptOut = "heartrate_opt_out"
        case id
        case kudosCount = "kudos_count"
        case locationCity = "location_city"
        case locationCountry = "location_country"
        case locationState = "location_state"
        case manual
//        case map
        case maxHeartrate = "max_heartrate"
        case maxSpeed = "max_speed"
        case movingTime = "moving_time"
        case name
        case photoCount = "photo_count"
        case prCount = "pr_count"
        case isPrivate = "private"
        case resourceState = "resource_state"
        case sportType = "sport_type"
        case startDate = "start_date"
        case startDateLocal = "start_date_local"
        case startLatlng = "start_latlng"
        case sufferScore = "suffer_score"
        case timezone
        case totalElevationGain = "total_elevation_gain"
        case totalPhotoCount = "total_photo_count"
        case isTrainer = "trainer"
        case type
        case uploadId = "upload_id"
        case uploadIdStr = "upload_id_str"
        case utcOffset = "utc_offset"
        case visibility
        case workoutType = "workout_type"
    }
}

class StravaDataViewModel: ObservableObject {
//    private var authViewModel: AuthViewModel
    @Published var activities: [StravaActivity] = []
    @Published var isLoading: Bool = false
    @Published var error: Error?
    private var cancellables: Set<AnyCancellable> = []
    private var storedData: Data = Data()

    
    func fetchStravaActivities() {
        // Set isLoading to true to show a loading indicator in your view.
        print("Loading strava data...")
        isLoading = true
        var accessToken: String
        if let tokenResponse = AuthViewModel.retrieveTokenFromKeychain(service: "com.retroseven.stravaToken") {
            accessToken = tokenResponse
        } else {
            print("Couldn't get access token")
            return
        }
        let apiUrl = "https://www.strava.com/api/v3/athlete/activities"
        
        // Create the URL request.
        guard let baseURL = URL(string: apiUrl) else {
            isLoading = false
            error = URLError(URLError.badURL)
            return
        }
        var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: true)
        let today = Date().timeIntervalSince1970
        let parameters: [URLQueryItem] = [
            URLQueryItem(name: "before", value: String(format: "%.0f", today)),
            URLQueryItem(name: "after", value: String(format: "%.0f", today - 604800)),
            URLQueryItem(name: "page", value: "1"),
            URLQueryItem(name: "per_dpage", value: "28")
        ]
        components?.queryItems = parameters
        
        if let url = components?.url {
            var request = URLRequest(url: url)
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
            
            // DEBUG
            print("URL: \(request.url?.absoluteString ?? "N/A")")
            print("HTTP Method: \(request.httpMethod ?? "N/A")")
            print("Headers: \(request.allHTTPHeaderFields ?? [:])")

            if let bodyData = request.httpBody, let bodyString = String(data: bodyData, encoding: .utf8) {
                print("HTTP Body: \(bodyString)")
            }
            // /DEBUG
            
            URLSession.shared.dataTaskPublisher(for: request)
                .map(\.data)
                .tryMap { data in
                        // Decode the data into a JSON object (dictionary)
                        do {
                            let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
                            var singleData: Data = Data()
                            if let jsonArray = jsonObject as? [[String: Any]] {
                                // You can now inspect the JSON dictionary
                                do {
                                    let _singleData = try JSONSerialization.data(withJSONObject: jsonArray[0], options: [])
                                    singleData = _singleData
                                    // Now 'data' contains the JSON representation of the dictionary
                                } catch {
                                    print("Error converting dictionary to data: \(error)")
                                }
                                do {
                                    let decodedObject = try JSONDecoder().decode(StravaActivity.self, from: singleData)
                                    print("we did it!")
                                } catch {
                                    print("Error decoding data into object: \(error)")
                                }
                                return data
                            } else {
                                throw NSError(domain: "YourAppDomain", code: 1, userInfo: ["message": "Failed to cast JSON as [String: Any]"])
                            }
                        } catch {
                            throw error
                        }
                    }
                .sink(receiveCompletion: { result in
                    switch result {
                    case .finished:
                        break
                    case .failure(let error):
                        self.isLoading = false
                        self.error = error
                    }
                }, receiveValue: { data in
                    // Store the data for inspection
                    self.storedData = data

                    // You can also inspect the data here if needed
                    // print(String(data: data, encoding: .utf8))

                    // Continue decoding and updating your model as needed
                    do {
                        let activities = try JSONDecoder().decode([StravaActivity].self, from: data)
                        self.activities = activities
                        print(self.activities.count)
                    } catch {
                        // Handle decoding errors
                        self.isLoading = false
                        self.error = error
                    }
                })
                .store(in: &cancellables)
        }
    }
}
