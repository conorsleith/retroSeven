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

    // Add methods to handle authentication (e.g., login, logout).
    // You can also store the access token and other relevant data here.
    func saveRefreshTokenToKeychain(refreshToken: String, service: String) -> Bool {
        if let data = refreshToken.data(using: .utf8) {
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: service,
                kSecValueData as String: data,
                kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
            ]
            let status = SecItemAdd(query as CFDictionary, nil)

            return status == errSecSuccess
        }
        return false
    }

    func retrieveRefreshTokenFromKeychain(service: String) -> String? {
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



