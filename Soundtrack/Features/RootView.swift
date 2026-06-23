//
//  RootView.swift
//  Soundtrack
//
//  Created by Brian Barragan-Cid on 6/22/26.
//

import SwiftUI

struct RootView: View {
    @EnvironmentObject var auth: SpotifyAuthManager
    
    var body: some View {
        if auth.isAuthenticated {
            ProfileView()
        } else {
            LoginView()
        }
    }
}
