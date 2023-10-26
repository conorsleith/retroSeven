//
//  retroSevenApp.swift
//  retroSeven
//
//  Created by Conor Sleith on 10/21/23.
//

import SwiftUI
import OAuthSwift
import BackgroundTasks
    
func scheduleAppRefresh() {
    let request = BGAppRefreshTaskRequest(identifier: "myapprefresh")
    try? BGTaskScheduler.shared.submit(request)
}

@main
struct RetroSeven: App {
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
                            authViewModel.refresh()
                            stravaData.needsRefresh = false
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
                    .onOpenURL(perform: handleURL)
                    .environmentObject(authViewModel)
            }
        }
        .onChange(of: phase) { newPhase in
            switch newPhase {
            case .background: scheduleAppRefresh()
            default: break
            }
        }
        .backgroundTask(.appRefresh("myapprefresh")) {
            await stravaData.fetchStravaActivities()
        }
    }
    func handleURL(_ url: URL) {
        if url.host == "retroseven.com" {
            return OAuthSwift.handle(url: url)
        }
    }
}
