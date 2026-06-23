//
//  ProfileView.swift
//  Soundtrack
//
//  Created by Brian Barragan-Cid on 6/22/26.
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var auth: SpotifyAuthManager
    @State private var profile: SpotifyProfile?
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("Loading profile…")
                } else if let profile {
                    profileContent(profile)
                } else if let error = errorMessage {
                    ContentUnavailableView(error, systemImage: "exclamationmark.triangle")
                }
            }
            .navigationTitle("Profile")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Log out", role: .destructive) {
                        auth.logout()
                    }
                }
            }
        }
        .task { await loadProfile() }
    }
    
    @ViewBuilder
    private func profileContent(_ profile: SpotifyProfile) -> some View {
        VStack(spacing: 20) {
            // Profile image
            AsyncImage(url: URL(string: profile.imageURL ?? "")) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                Circle().fill(.secondary.opacity(0.2))
                    .overlay(Image(systemName: "person.fill").foregroundStyle(.secondary))
            }
            .frame(width: 100, height: 100)
            .clipShape(Circle())
            
            VStack(spacing: 4) {
                Text(profile.displayName ?? profile.id)
                    .font(.title2.weight(.semibold))
                Text("\(profile.followers) followers")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            // Week 2: this is where "Import your listening history" CTA will go
            Spacer()
        }
        .padding(.top, 32)
    }
    
    private func loadProfile() async {
        isLoading = true
        do {
            let token = try await auth.validAccessToken()
            profile = try await SpotifyAPIClient.shared.fetchProfile(token: token)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}

#Preview {
    ProfileView().environmentObject(SpotifyAuthManager())
}
