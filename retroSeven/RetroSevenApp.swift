//
//  retroSevenApp.swift
//  retroSeven
//
//  Created by Conor Sleith on 10/21/23.
//

import SwiftUI
import OAuthSwift

@main
struct RetroSeven: App {
    @StateObject private var authViewModel = AuthViewModel()

    var body: some Scene {
        WindowGroup {
            if authViewModel.isAuthenticated {
                MainScreen()
            } else {
                AuthenticationView()
                    .onOpenURL(perform: handleURL)
                    .environmentObject(authViewModel)
            }
        }
    }
    func handleURL(_ url: URL) {
        if url.host == "retroseven.com" {
            return OAuthSwift.handle(url: url)
        }
    }
}
