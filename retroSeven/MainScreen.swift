//
//  MainScreen.swift
//  retroSeven
//
//  Created by Conor Sleith on 10/21/23.
//
import SwiftUI

struct MainScreen: View {
    @State private var leftNumber = 123
    @State private var rightNumber = 456
    @StateObject private var stravaData = StravaDataViewModel()
    

    var body: some View {
        VStack {
            Button("Fetch Strava Data") {
                stravaData.fetchStravaActivities()
            }
            HStack {
                Text("\(leftNumber)")
                    .foregroundColor(Color(red: 0.98, green: 0.32, blue: 0.01)) // Strava orange color
                Text("(\(rightNumber))")
                    .foregroundColor(Color.gray) // Grey color
            }
            .font(.largeTitle)
            .padding()
        }
    }
}

struct MainScreen_Previews: PreviewProvider {
    static var previews: some View {
        MainScreen()
    }
}
