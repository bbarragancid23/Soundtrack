//
//  SpotifyAPIClient.swift
//  Soundtrack
//
//  Created by Brian Barragan-Cid on 6/22/26.
//

import SwiftUI

final class SpotifyAPIClient {
    static let shared = SpotifyAPIClient()
    private let base = URL(string: "https://api.spotify.com/v1")!
    
    func fetchProfile(token: String) async throws -> SpotifyProfile {
        var request = URLRequest(url: base.appendingPathComponent("me"))
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode(SpotifyProfile.self, from: data)
    }
}
