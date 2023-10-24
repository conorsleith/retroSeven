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
                stravaData.fetchStravaActivities(authViewModel: authViewModel)
            }
            HStack {
                Text("\(stravaData.currentMileage)")
                    .foregroundColor(Color(red: 0.98, green: 0.32, blue: 0.01)) // Strava orange color
                Text("(\(stravaData.expiringMileage))")
                    .foregroundColor(Color.gray) // Grey color
            }
            .font(.largeTitle)
            .padding()
        }
        .onAppear {
            stravaData.fetchStravaActivities(authViewModel: authViewModel)
            Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { timer in
                stravaData.fetchStravaActivities(authViewModel: authViewModel)
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
            stravaData.fetchStravaActivities(authViewModel: authViewModel)
        }
    }
}


struct MainScreen_Previews: PreviewProvider {
    static var previews: some View {
        MainScreen()
    }
}
