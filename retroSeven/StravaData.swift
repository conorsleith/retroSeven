//
//  StravaData.swift
//  retroSeven
//
//  Created by Conor Sleith on 10/21/23.
//

import Foundation
import Combine

struct StravaActivity: Codable {
    let id: Int
    let name: String
    let type: String
    let startDate: Date
    let distance: Double
    let movingTime: Int
    let averageSpeed: Double
    let maxSpeed: Double

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case type
        case startDate = "start_date"
        case distance
        case movingTime = "moving_time"
        case averageSpeed = "average_speed"
        case maxSpeed = "max_speed"
    }
}

class StravaDataViewModel: ObservableObject {
//    private var authViewModel: AuthViewModel
    @Published var activities: [StravaActivity] = []
    @Published var isLoading: Bool = false
    @Published var error: Error?
    private var cancellables: Set<AnyCancellable> = []

    
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
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        print(json)
                    } else {
                        let json = JSONSerialization.jsonObject(with: data)
                        print(data)
                    }
                    return data
                }
                .decode(type: [StravaActivity].self, decoder: JSONDecoder())
                .receive(on: DispatchQueue.main)
                .sink(receiveCompletion: { result in
                    switch result {
                    case .finished:
                        break
                    case .failure(let error):
                        self.isLoading = false
                        self.error = error
                    }
                }, receiveValue: { activities in
                    self.activities = activities
                    self.isLoading = false
                })
                .store(in: &cancellables)
            print("Okay, did a thing")
            print(self.activities.count)
        }
    }
}
