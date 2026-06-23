//
//  SpotifyTokenStore.swift
//  Soundtrack
//
//  Created by Brian Barragan-Cid on 6/22/26.
//

import Foundation
import KeychainSwift

// MARK: - SpotifyTokenStore
//
// Wraps KeychainSwift to persist tokens across app launches.
// Never store tokens in UserDefaults — Keychain only.

final class SpotifyTokenStore {
    
    private let keychain = KeychainSwift(keyPrefix: "soundtrack_")
    
    private enum Keys {
        static let accessToken  = "access_token"
        static let refreshToken = "refresh_token"
        static let expiresAt    = "expires_at"
    }
    
    func save(_ tokens: SpotifyTokens) {
        keychain.set(tokens.accessToken,  forKey: Keys.accessToken)
        keychain.set(tokens.refreshToken, forKey: Keys.refreshToken)
        keychain.set(
            String(tokens.expiresAt.timeIntervalSince1970),
            forKey: Keys.expiresAt
        )
    }
    
    func load() -> SpotifyTokens? {
        guard
            let access  = keychain.get(Keys.accessToken),
            let refresh = keychain.get(Keys.refreshToken),
            let expiresStr = keychain.get(Keys.expiresAt),
            let expiresInterval = TimeInterval(expiresStr)
        else { return nil }
        
        return SpotifyTokens(
            accessToken:  access,
            refreshToken: refresh,
            expiresAt:    Date(timeIntervalSince1970: expiresInterval)
        )
    }
    
    func clear() {
        keychain.delete(Keys.accessToken)
        keychain.delete(Keys.refreshToken)
        keychain.delete(Keys.expiresAt)
    }
}
