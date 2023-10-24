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

    var body: some View {
        VStack {
            if !isAuthenticating {
                Button("Connect to Strava") {
                    self.isAuthenticating = true
                    self.authViewModel.authorize()
                }
            } else {
                Text("Authenticating...")
            }
        }
    }
}
