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
    @Published var activities: [StravaActivity] = []
    @Published var isLoading: Bool = false
    @Published var error: Error?

    private var cancellables: Set<AnyCancellable> = []
    
    func fetchStravaActivities() {
        // Set isLoading to true to show a loading indicator in your view.
        print("Loading strava data...")
        isLoading = true
        
        // Replace with your API endpoint for fetching Strava activities.
        let apiUrl = "https://www.strava.com/api/v3/activities"
        
        // Replace with your actual access token.
        let accessToken = "b070f3da52cfb93221b6c6769b0b15280228a406"
        
        // Create the URL request.
        guard let url = URL(string: apiUrl) else {
            isLoading = false
            error = URLError(URLError.badURL)
            return
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        // Use Combine to fetch and decode data from the API.
        URLSession.shared.dataTaskPublisher(for: request)
            .map(\.data)
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
    }
}
