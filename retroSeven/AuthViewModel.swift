//
//  AuthViewModel.swift
//  retroSeven
//
//  Created by Conor Sleith on 10/21/23.
//

import SwiftUI

class AuthViewModel: ObservableObject {
    @Published var isAuthenticated: Bool = false
    @Published var oauthToken = ""
    @StateObject private var authViewModel: AuthViewModel = AuthViewModel()

    // Add methods to handle authentication (e.g., login, logout).
    // You can also store the access token and other relevant data here.
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
}



