//
//  SoundtrackApp.swift
//  Soundtrack
//
//  Created by Brian Barragan-Cid on 6/22/26.
//

import SwiftUI

@main
struct SoundtrackApp: App {
    @StateObject private var auth = SpotifyAuthManager()
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(auth)
        }
    }
}
