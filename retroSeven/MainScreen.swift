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
    @State var currentMileage: Int = 0
    @State var expiringMileage: Int = 0

    var body: some View {
        VStack {
            Button("Refresh Strava Data") {
                Task {
                    await stravaData.fetchStravaActivities()
                }
            }
            HStack {
                Text("\(currentMileage > 0 ? "\(currentMileage)" : "")")
                    .foregroundColor(Color(red: 0.98, green: 0.32, blue: 0.01)) // Strava orange color
                Text("\(expiringMileage > 0 ? "\(expiringMileage)" : "")")
                    .foregroundColor(Color.gray) // Grey color
            }
            .font(.largeTitle)
            .padding()
        }
        .onAppear {
            Task {
                await stravaData.fetchStravaActivities()
            }
            Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { timer in
                Task {
                    await stravaData.fetchStravaActivities()
                }
            }
        }
        .onReceive(stravaData.$currentMileage) { newCurrentMileage in
            // Handle changes to the first derived number
            print("First Number changed to: \(newCurrentMileage)")
            currentMileage = newCurrentMileage
        }
        .onReceive(stravaData.$expiringMileage) { newExpiringMileage in
            // Handle changes to the second derived number
            print("Second Number changed to: \(newExpiringMileage)")
            expiringMileage = newExpiringMileage
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in Task {
            await stravaData.fetchStravaActivities()
            }
        }
    }
}


struct MainScreen_Previews: PreviewProvider {
    static var previews: some View {
        MainScreen()
    }
}
