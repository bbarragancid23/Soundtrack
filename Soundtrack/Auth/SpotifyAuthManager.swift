//
//  SpotifyAuthManager.swift
//  Soundtrack
//
//  Created by Brian Barragan-Cid on 6/22/26.
//

import Combine
import Foundation
import AuthenticationServices
import CryptoKit

// MARK: - Token Model

struct SpotifyTokens {
    let accessToken: String
    let refreshToken: String
    let expiresAt: Date
    
    var isExpired: Bool {
        Date() >= expiresAt.addingTimeInterval(-60) // 60s buffer
    }
}

// MARK: - Auth Errors

enum SpotifyAuthError: LocalizedError {
    case invalidCallbackURL
    case missingAuthCode
    case tokenExchangeFailed(String)
    case noTokensStored
    case refreshFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidCallbackURL:    return "Invalid callback URL from Spotify"
        case .missingAuthCode:       return "No authorization code in callback"
        case .tokenExchangeFailed(let msg): return "Token exchange failed: \(msg)"
        case .noTokensStored:        return "No stored tokens — user must log in"
        case .refreshFailed(let msg): return "Token refresh failed: \(msg)"
        }
    }
}

// MARK: - SpotifyAuthManager

@MainActor
final class SpotifyAuthManager: NSObject, ObservableObject {
    
    // MARK: - Config (replace with your actual values)
    private let clientID: String = {
        guard let id = Bundle.main.object(forInfoDictionaryKey: "SpotifyClientID") as? String,
              !id.isEmpty else {
            fatalError("SpotifyClientID missing — did you set up Config.xcconfig?")
        }
        return id
    }()

    private let redirectURI  = "soundtrack://auth/callback"
    private let scopes       = "user-read-private user-read-email"
    
    // Week 7 — add these when you build playlist export:
    // "playlist-modify-public playlist-modify-private"
    
    // MARK: - Published State
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var error: SpotifyAuthError?
    
    // MARK: - Private
    private let tokenStore = SpotifyTokenStore()
    private var codeVerifier: String?
    private var authSession: ASWebAuthenticationSession?
    
    // MARK: - Init
    
    override init() {
        super.init()
        // Restore session on launch if tokens exist and aren't expired
        if let tokens = tokenStore.load(), !tokens.isExpired {
            isAuthenticated = true
        }
    }
    
    // MARK: - Public API
    
    /// Kick off the Spotify login flow
    func login() async {
        isLoading = true
        error = nil
        
        do {
            let (verifier, challenge) = try makePKCEPair()
            self.codeVerifier = verifier
            
            let authURL = buildAuthURL(codeChallenge: challenge)
            let callbackURL = try await openAuthSession(url: authURL)
            let code = try extractCode(from: callbackURL)
            let tokens = try await exchangeCodeForTokens(code: code, verifier: verifier)
            
            tokenStore.save(tokens)
            isAuthenticated = true
        } catch let err as SpotifyAuthError {
            self.error = err
        } catch {
            // ASWebAuthenticationSession cancellation lands here — don't treat as error
        }
        
        isLoading = false
    }
    
    func logout() {
        tokenStore.clear()
        isAuthenticated = false
        error = nil
    }
    
    /// Returns a valid access token, refreshing if needed.
    /// Call this before every API request.
    func validAccessToken() async throws -> String {
        guard var tokens = tokenStore.load() else {
            throw SpotifyAuthError.noTokensStored
        }
        
        if tokens.isExpired {
            tokens = try await refreshTokens(using: tokens.refreshToken)
            tokenStore.save(tokens)
        }
        
        return tokens.accessToken
    }
    
    // MARK: - PKCE
    
    private func makePKCEPair() throws -> (verifier: String, challenge: String) {
        // Verifier: 64 random bytes → base64url
        var bytes = [UInt8](repeating: 0, count: 64)
        let status = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        guard status == errSecSuccess else {
            throw SpotifyAuthError.tokenExchangeFailed("Could not generate random bytes")
        }
        let verifier = Data(bytes).base64URLEncoded
        
        // Challenge: SHA256(verifier) → base64url
        let hash = SHA256.hash(data: Data(verifier.utf8))
        let challenge = Data(hash).base64URLEncoded
        
        return (verifier, challenge)
    }
    
    // MARK: - Auth URL
    
    private func buildAuthURL(codeChallenge: String) -> URL {
        var components = URLComponents(string: "https://accounts.spotify.com/authorize")!
        components.queryItems = [
            .init(name: "client_id",             value: clientID),
            .init(name: "response_type",          value: "code"),
            .init(name: "redirect_uri",           value: redirectURI),
            .init(name: "scope",                  value: scopes),
            .init(name: "code_challenge_method",  value: "S256"),
            .init(name: "code_challenge",         value: codeChallenge),
            .init(name: "show_dialog",            value: "false"),
        ]
        return components.url!
    }
    
    // MARK: - Auth Session
    
    private func openAuthSession(url: URL) async throws -> URL {
        try await withCheckedThrowingContinuation { continuation in
            let session = ASWebAuthenticationSession(
                url: url,
                callbackURLScheme: "soundtrack"
            ) { callbackURL, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let callbackURL else {
                    continuation.resume(throwing: SpotifyAuthError.invalidCallbackURL)
                    return
                }
                continuation.resume(returning: callbackURL)
            }
            session.presentationContextProvider = self
            session.prefersEphemeralWebBrowserSession = false // keeps user logged into Spotify
            self.authSession = session
            session.start()
        }
    }
    
    // MARK: - Code Extraction
    
    private func extractCode(from url: URL) throws -> String {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let code = components.queryItems?.first(where: { $0.name == "code" })?.value
        else {
            throw SpotifyAuthError.missingAuthCode
        }
        return code
    }
    
    // MARK: - Token Exchange
    
    private func exchangeCodeForTokens(code: String, verifier: String) async throws -> SpotifyTokens {
        var request = URLRequest(url: URL(string: "https://accounts.spotify.com/api/token")!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let body: [String: String] = [
            "grant_type":    "authorization_code",
            "code":          code,
            "redirect_uri":  redirectURI,
            "client_id":     clientID,
            "code_verifier": verifier,
        ]
        request.httpBody = body.formEncoded
        
        return try await performTokenRequest(request)
    }
    
    // MARK: - Token Refresh
    
    private func refreshTokens(using refreshToken: String) async throws -> SpotifyTokens {
        var request = URLRequest(url: URL(string: "https://accounts.spotify.com/api/token")!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let body: [String: String] = [
            "grant_type":    "refresh_token",
            "refresh_token": refreshToken,
            "client_id":     clientID,
        ]
        request.httpBody = body.formEncoded
        
        return try await performTokenRequest(request)
    }
    
    private func performTokenRequest(_ request: URLRequest) async throws -> SpotifyTokens {
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            let body = String(data: data, encoding: .utf8) ?? "unknown error"
            throw SpotifyAuthError.tokenExchangeFailed(body)
        }
        
        struct TokenResponse: Decodable {
            let access_token: String
            let refresh_token: String?
            let expires_in: Int
        }
        
        let decoded = try JSONDecoder().decode(TokenResponse.self, from: data)
        
        // Spotify sometimes omits refresh_token on refresh — keep the old one
        let existingRefresh = tokenStore.load()?.refreshToken ?? ""
        
        return SpotifyTokens(
            accessToken:  decoded.access_token,
            refreshToken: decoded.refresh_token ?? existingRefresh,
            expiresAt:    Date().addingTimeInterval(TimeInterval(decoded.expires_in))
        )
    }
}

// MARK: - ASWebAuthenticationPresentationContextProviding

extension SpotifyAuthManager: ASWebAuthenticationPresentationContextProviding {
    nonisolated func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        // Safe because ASWebAuthenticationSession always calls this on the main thread
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first(where: { $0.activationState == .foregroundActive })?
            .keyWindow ?? UIWindow()
    }
}

// MARK: - Helpers

private extension Data {
    /// Base64URL encoding (no padding, URL-safe chars) as required by PKCE spec
    var base64URLEncoded: String {
        base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}

private extension Dictionary where Key == String, Value == String {
    /// Encodes a dict as application/x-www-form-urlencoded body data
    var formEncoded: Data {
        map { key, value in
            let encodedKey   = key.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? key
            let encodedValue = value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? value
            return "\(encodedKey)=\(encodedValue)"
        }
        .joined(separator: "&")
        .data(using: .utf8) ?? Data()
    }
}
