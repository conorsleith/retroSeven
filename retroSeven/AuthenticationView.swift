//
//  AuthenticationView.swift
//  retroSeven
//
//  Created by Conor Sleith on 10/21/23.
//

import AuthenticationServices

import OAuthSwift
import SwiftUI
import SafariServices

struct AuthenticationView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var isAuthenticating = false
    
    private var clientID = "67277"
    private var redirectURI = "retroseven://retroseven.com"
    private var clientSectret = "56fed12e582063a4ad5a44370331102080666128"
    private var oauthswift = OAuth2Swift(
        consumerKey: "67277",
        consumerSecret: "56fed12e582063a4ad5a44370331102080666128",
        authorizeUrl: "https://www.strava.com/oauth/authorize",
        accessTokenUrl: "https://www.strava.com/oauth/token",
        responseType: "code"
    )

    var body: some View {
        VStack {
            if !isAuthenticating {
                Button("Connect to Strava") {
                    self.isAuthenticating = true
                    startStravaOAuth()
                }
            } else {
                Text("Authenticating...")
            }
        }
    }

    func startStravaOAuth() {
        self.oauthswift.authorize(
            withCallbackURL: URL(string: self.redirectURI)!,
            scope: "activity:read_all",
            state: "yourState") { result in
            switch result {
            case .success((let credential, _, _)):
                // Store the access token securely for future API requests.
                var success = AuthViewModel.saveTokenToKeychain(token: credential.oauthRefreshToken, service: "com.retroseven.stravaRefreshToken")
                success = AuthViewModel.saveTokenToKeychain(token: credential.oauthToken, service: "com.retroseven.stravaToken")
                self.isAuthenticating = false
                authViewModel.isAuthenticated = true
                // You can now transition to the main screen.
            case .failure(let error):
                print(error.localizedDescription)
                self.isAuthenticating = false
            }
        }
    }
}
