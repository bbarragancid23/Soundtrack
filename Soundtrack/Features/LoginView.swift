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
        VStack(spacing: 102) {
            Spacer()
            
            VStack(spacing: 8) {
                HStack(spacing: 10) {
                    Text("Sound")
                    //.font(.system(size: 100))
                        .font(.custom("AmericanTypewriter", size: 100))
                        .lineLimit(1)
                        .minimumScaleFactor(0.01)
                        .frame(maxWidth: .infinity)
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .stroke(
                            LinearGradient(
                                colors: [.purple, .blue],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            lineWidth: 5
                        )
                        .frame(width: 60)
                    Text("Track")
                    //.font(.system(size: 100))
                        .font(.custom("AmericanTypewriter", size: 100))
                        .kerning(2)
                        .lineLimit(1)
                        .minimumScaleFactor(0.01)
                        .frame(maxWidth: .infinity)
                }
                .padding(EdgeInsets(top: 0, leading: 10, bottom: 5, trailing: 10))

                Text("The Soundtrack for your \nlife")
                    .font(.title2)
                    .foregroundStyle(.secondary)
                    //.padding(.top, 20 )
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
                .frame(height: 25)
            
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
                .clipShape(RoundedRectangle(cornerRadius: 32))
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
        .background(
            DotGridView()
                .ignoresSafeArea(.all)
        )
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
