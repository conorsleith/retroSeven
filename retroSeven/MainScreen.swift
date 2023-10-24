//
//  MainScreen.swift
//  retroSeven
//
//  Created by Conor Sleith on 10/21/23.
//
import SwiftUI
import Swift

struct MainScreen: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var stravaData: StravaDataViewModel

    var body: some View {
        VStack {
            Button("Refresh Strava Data") {
                stravaData.fetchStravaActivities()
            }
            HStack {
                Text("\(stravaData.currentMileage > 0 ? "\(stravaData.currentMileage)" : "")")
                    .foregroundColor(Color(red: 0.98, green: 0.32, blue: 0.01)) // Strava orange color
                Text("\(stravaData.expiringMileage > 0 ? "\(stravaData.expiringMileage)" : "")")
                    .foregroundColor(Color.gray) // Grey color
            }
            .font(.largeTitle)
            .padding()
        }
        .onAppear {
            stravaData.fetchStravaActivities()
            Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { timer in
                stravaData.fetchStravaActivities()
            }
        }
        .onReceive(stravaData.$currentMileage) { newCurrentMileage in
            // Handle changes to the first derived number
            print("First Number changed to: \(newCurrentMileage)")
        }
        .onReceive(stravaData.$expiringMileage) { newExpiringMileage in
            // Handle changes to the second derived number
            print("Second Number changed to: \(newExpiringMileage)")
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            stravaData.fetchStravaActivities()
        }
    }
}


struct MainScreen_Previews: PreviewProvider {
    static var previews: some View {
        MainScreen()
    }
}
