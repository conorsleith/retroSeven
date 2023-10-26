//
//  retroSevenWatchApp.swift
//  retroSevenWatch Watch App
//
//  Created by Conor Sleith on 10/26/23.
//

import SwiftUI

@main
struct retroSevenWatch_Watch_AppApp: App {
    @Environment(\.scenePhase) private var phase
    @ObservedObject var authViewModel = AuthViewModel()
    @StateObject private var stravaData = StravaDataViewModel()

    var body: some Scene {
        WindowGroup {
            if (AuthViewModel.isAuthorized()) {
                MainScreen()
                    .environmentObject(authViewModel)
                    .environmentObject(stravaData)
                    .onReceive(stravaData.$needsRefresh) { needsRefresh in
                        if (needsRefresh){
                            authViewModel.refresh { success in
                                if (success) {
                                    stravaData.needsRefresh = false
                                }
                            }
                        }
                    }
                    .onReceive(authViewModel.$refreshTrigger) { triggerState in
                        if (triggerState){
                            Task {
                                await stravaData.fetchStravaActivities()
                                authViewModel.refreshTrigger = false
                            }
                        }
                    }
            } else {
                AuthenticationView()
            }
        }
//        .onChange(of: phase) { newPhase in
//            switch newPhase {
//            case .background: scheduleAppRefresh()
//            default: break
//            }
//        }
//        .backgroundTask(.appRefresh("myapprefresh")) {
//            await stravaData.fetchStravaActivities()
//        }
    }
}

//func scheduleAppRefresh() {
//    let request = BGAppRefreshTaskRequest(identifier: "myapprefresh")
//    try? BGTaskScheduler.shared.submit(request)
//}
