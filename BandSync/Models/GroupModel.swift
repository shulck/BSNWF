//
//  GroupModel.swift
//  BandSync
//
//  Created by Oleksandr Kuziakin on 31.03.2025.
//

import Foundation
import FirebaseFirestore

struct GroupModel: Identifiable, Codable, Equatable {
    @DocumentID var id: String?
    var name: String
    var code: String
    var members: [String]
    var pendingMembers: [String]
    var logoURL: String?
    var description: String?
    var paypalAddress: String? // For fan gift donations
    
    // ✅ ДОБАВЛЕНО: Новые поля из Firebase
    var establishedDate: String?
    var genre: String?
    var location: String?
    var socialMediaLinks: SocialMediaLinks?
    var admins: [String]?
    var membersCount: String?
    var createdAt: Date?
    var createdBy: String?
    
    // Implementation of Equatable for object comparison
    static func == (lhs: GroupModel, rhs: GroupModel) -> Bool {
        return lhs.id == rhs.id &&
               lhs.name == rhs.name &&
               lhs.code == rhs.code &&
               lhs.members == rhs.members &&
               lhs.pendingMembers == rhs.pendingMembers &&
               lhs.logoURL == rhs.logoURL &&
               lhs.description == rhs.description &&
               lhs.paypalAddress == rhs.paypalAddress &&
               lhs.establishedDate == rhs.establishedDate &&
               lhs.genre == rhs.genre &&
               lhs.location == rhs.location &&
               lhs.socialMediaLinks == rhs.socialMediaLinks
    }
}

// ✅ ДОБАВЛЕНО: Модель для социальных сетей
struct SocialMediaLinks: Codable, Equatable {
    var website: String?
    var facebook: String?
    var instagram: String?
    var youtube: String?
    var spotify: String?
    var appleMusic: String?
    var twitter: String?
    var tiktok: String?
    var soundcloud: String?
    var bandcamp: String?
    var patreon: String?
    var discord: String?
    var linkedin: String?
    var pinterest: String?
    var snapchat: String?
    var telegram: String?
    var whatsapp: String?
    var reddit: String?
    
    init(
        website: String? = nil,
        facebook: String? = nil,
        instagram: String? = nil,
        youtube: String? = nil,
        spotify: String? = nil,
        appleMusic: String? = nil,
        twitter: String? = nil,
        tiktok: String? = nil,
        soundcloud: String? = nil,
        bandcamp: String? = nil,
        patreon: String? = nil,
        discord: String? = nil,
        linkedin: String? = nil,
        pinterest: String? = nil,
        snapchat: String? = nil,
        telegram: String? = nil,
        whatsapp: String? = nil,
        reddit: String? = nil
    ) {
        self.website = website
        self.facebook = facebook
        self.instagram = instagram
        self.youtube = youtube
        self.spotify = spotify
        self.appleMusic = appleMusic
        self.twitter = twitter
        self.tiktok = tiktok
        self.soundcloud = soundcloud
        self.bandcamp = bandcamp
        self.patreon = patreon
        self.discord = discord
        self.linkedin = linkedin
        self.pinterest = pinterest
        self.snapchat = snapchat
        self.telegram = telegram
        self.whatsapp = whatsapp
        self.reddit = reddit
    }
    
    var isEmpty: Bool {
        return website?.isEmpty != false &&
               facebook?.isEmpty != false &&
               instagram?.isEmpty != false &&
               youtube?.isEmpty != false &&
               spotify?.isEmpty != false &&
               appleMusic?.isEmpty != false &&
               twitter?.isEmpty != false &&
               tiktok?.isEmpty != false &&
               soundcloud?.isEmpty != false &&
               bandcamp?.isEmpty != false &&
               patreon?.isEmpty != false &&
               discord?.isEmpty != false &&
               linkedin?.isEmpty != false &&
               pinterest?.isEmpty != false &&
               snapchat?.isEmpty != false &&
               telegram?.isEmpty != false &&
               whatsapp?.isEmpty != false &&
               reddit?.isEmpty != false
    }
}
