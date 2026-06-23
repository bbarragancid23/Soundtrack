//
//  SpotifyProfile.swift
//  Soundtrack
//
//  Created by Brian Barragan-Cid on 6/22/26.
//

import SwiftUI

struct SpotifyProfile: Decodable {
    let id: String
    let displayName: String?
    let followers: Int
    let imageURL: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case displayName = "display_name"
        case followers   = "followers"
        case images
    }
    
    struct FollowersContainer: Decodable { let total: Int }
    struct ImageItem: Decodable { let url: String }
    
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id          = try c.decode(String.self, forKey: .id)
        displayName = try c.decodeIfPresent(String.self, forKey: .displayName)
        
        let followersContainer = try c.decode(FollowersContainer.self, forKey: .followers)
        followers = followersContainer.total
        
        let images = try c.decodeIfPresent([ImageItem].self, forKey: .images)
        imageURL = images?.first?.url
    }
}
