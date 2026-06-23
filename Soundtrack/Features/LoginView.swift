//
//  LoginView.swift
//  Soundtrack
//
//  Created by Brian Barragan-Cid on 6/22/26.
//

import SwiftUI
 
// MARK: - LoginView
 
struct LoginView: View {
    @EnvironmentObject var auth: SpotifyAuthManager
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            VStack(spacing: 8) {
                Text("Soundtrack")
                    .font(.largeTitle.weight(.semibold))
                Text("A visual timeline of your life through music.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
            
            Button {
                Task { await auth.login() }
            } label: {
                HStack(spacing: 10) {
                    if auth.isLoading {
                        ProgressView().tint(.black)
                    } else {
                        Image(systemName: "music.note")
                    }
                    Text(auth.isLoading ? "Connecting…" : "Continue with Spotify")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color(hex: "#1DB954")) // Spotify green
                .foregroundStyle(.black)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(auth.isLoading)
            .padding(.horizontal, 24)
            
            if let error = auth.error {
                Text(error.localizedDescription)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
            
            Spacer().frame(height: 16)
        }
    }
}


#Preview {
    LoginView().environmentObject(SpotifyAuthManager())
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8)  & 0xFF) / 255
        let b = Double(int         & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}
