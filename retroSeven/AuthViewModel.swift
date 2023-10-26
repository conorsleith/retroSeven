//
//  AuthViewModel.swift
//  retroSeven
//
//  Created by Conor Sleith on 10/21/23.
//

import SwiftUI
import OAuthSwift

let keyChainTokenService: String = "com.retroseven.stravaToken"
let keyChainRefreshService: String = "com.retroseven.stravaRefreshToken"

class AuthViewModel: ObservableObject {
    @Published var isAuthenticated: Bool = false
    @Published var refreshTrigger: Bool = false
    private var redirectURI = "retroseven://retroseven.com"
    private var oauthswift = OAuth2Swift(
        consumerKey: "67277",
        consumerSecret: "56fed12e582063a4ad5a44370331102080666128",
        authorizeUrl: "https://www.strava.com/oauth/authorize",
        accessTokenUrl: "https://www.strava.com/oauth/token",
        responseType: "code"
    )

    // Add methods to handle authentication (e.g., login, logout).
    // You can also store the access token and other relevant data here.
    func startStravaOAuth() {
        self.oauthswift.authorize(
            withCallbackURL: URL(string: self.redirectURI)!,
            scope: "activity:read_all",
            state: "yourState") { result in
            switch result {
            case .success((let credential, _, _)):
                // Store the access token securely for future API requests.
                var success = AuthViewModel.saveTokenToKeychain(token: credential.oauthRefreshToken, service: keyChainRefreshService)
                success = AuthViewModel.saveTokenToKeychain(token: credential.oauthToken, service: keyChainTokenService)
            case .failure(let error):
                print(error.localizedDescription)
            }
        }
    }
    
    func refresh() -> String? {
        var accessToken = ""
        if let refreshToken = AuthViewModel.retrieveTokenFromKeychain(service: keyChainRefreshService) {
            self.oauthswift.renewAccessToken(withRefreshToken: refreshToken) { result in
                switch result {
                case .success(let (credential, response, parameters)):
                    // Handle the successful token renewal here
                    // The new access token is available in 'credential.oauthToken'
                    print("Access Token Renewed: \(credential.oauthToken)")
                    accessToken = credential.oauthToken
                    AuthViewModel.saveTokenToKeychain(token: credential.oauthToken, service: keyChainTokenService)
                    AuthViewModel.saveTokenToKeychain(token: credential.oauthRefreshToken, service: keyChainRefreshService)
                    DispatchQueue.main.async {
                        self.refreshTrigger = true
                    }
                case .failure(let error):
                    // Handle the error, e.g., refresh token expiration or network issues
                    print("Token Renewal Error: \(error.localizedDescription)")
                }
            }
        }
        if (accessToken != "") {
            return accessToken
        }
        return nil
    }
    
    func authorize() -> String? {
        var accessToken = ""
        self.oauthswift.authorize(
            withCallbackURL: URL(string: self.redirectURI)!,
            scope: "activity:read_all",
            state: "yourState") { result in
            switch result {
            case .success((let credential, _, _)):
                // Store the access token securely for future API requests.
                var success = AuthViewModel.saveTokenToKeychain(token: credential.oauthRefreshToken, service: keyChainRefreshService)
                success = AuthViewModel.saveTokenToKeychain(token: credential.oauthToken, service: keyChainTokenService)
                accessToken = credential.oauthToken
            case .failure(let error):
                print(error.localizedDescription)
            }
        }
        if (accessToken == "") {
            return nil
        }
        return accessToken
    }

    static func saveTokenToKeychain(token: String, service: String) {
        if let data = token.data(using: .utf8) {
            // Check if a token already exists for the service
            if let existingToken = retrieveTokenFromKeychain(service: service) {
                // Update the existing token
                let updateQuery: [String: Any] = [
                    kSecClass as String: kSecClassGenericPassword,
                    kSecAttrService as String: service,
                ]
                let updateAttributes: [String: Any] = [
                    kSecValueData as String: data
                ]
                let status = SecItemUpdate(updateQuery as CFDictionary, updateAttributes as CFDictionary)
                
                if status == errSecSuccess {
                    print("Token updated in Keychain")
                } else {
                    print("Failed to update token in Keychain")
                }
            } else {
                // Add the token if it doesn't exist
                let addQuery: [String: Any] = [
                    kSecClass as String: kSecClassGenericPassword,
                    kSecAttrService as String: service,
                    kSecValueData as String: data,
                    kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
                ]
                let status = SecItemAdd(addQuery as CFDictionary, nil)
                
                if status == errSecSuccess {
                    print("Token saved to Keychain")
                } else {
                    print("Failed to save token to Keychain")
                }
            }
        }
    }

    static func retrieveTokenFromKeychain(service: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecReturnData as String: kCFBooleanTrue as CFBoolean
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        if status == errSecSuccess, let data = result as? Data {
            return String(data: data, encoding: .utf8)
        }

        return nil
    }
    
    static func isAuthorized() -> Bool {
        if let _ = AuthViewModel.retrieveTokenFromKeychain(service: keyChainTokenService) {
            return true
        }
        return false
    }
}



