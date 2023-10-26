//
//  AppDelegate.swift
//  retroSeven
//
//  Created by Conor Sleith on 10/21/23.
//

import SwiftUI
import OAuthSwift

class AppDelegate: UIResponder, UIApplicationDelegate {
    @StateObject private var authViewModel = AuthViewModel()

    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        if url.host == "retroseven.com" {
            OAuthSwift.handle(url: url)
        }
        return true
    }
}
