//
//  FanModels.swift
//  BandSync
//
//  Created by Claude on 27.07.2025.
//

import Foundation

// MARK: - User Type Extension
enum UserType: String, Codable, CaseIterable {
    case bandMember = "BandMember"
    case fan = "Fan"
    
    var localizedName: String {
        switch self {
        case .bandMember:
            return "Band Member"
        case .fan:
            return "Fan"
        }
    }
}

// MARK: - Fan Level System
enum FanLevel: String, Codable, CaseIterable, Identifiable {
    case newbie = "Newbie"
    case regular = "Regular"
    case vip = "VIP"
    
    var id: String { rawValue }
    
    var localizedName: String {
        switch self {
        case .newbie:
            return "New fan"
        case .regular:
            return "Regular"
        case .vip:
            return "VIP"
        }
    }
    
    var color: String {
        switch self {
        case .newbie:
            return "#10B981" // Green
        case .regular:
            return "#3B82F6" // Blue
        case .vip:
            return "#F59E0B" // Gold
        }
    }
    
    var iconName: String {
        switch self {
        case .newbie:
            return "star.fill"
        case .regular:
            return "star.leadinghalf.filled"
        case .vip:
            return "crown.fill"
        }
    }
    
    var requiredConcerts: Int {
        switch self {
        case .newbie:
            return 0
        case .regular:
            return 10
        case .vip:
            return 25
        }
    }
}

// MARK: - Fan Statistics
struct FanStats: Codable, Equatable {
    let totalMessages: Int
    let joinDate: Date
    let lastActive: Date
    let merchandisePurchased: Int
    let concertsAttended: Int
    let achievementsUnlocked: Int
    
    init(
        totalMessages: Int = 0,
        joinDate: Date = Date(),
        lastActive: Date = Date(),
        merchandisePurchased: Int = 0,
        concertsAttended: Int = 0,
        achievementsUnlocked: Int = 0
    ) {
        self.totalMessages = totalMessages
        self.joinDate = joinDate
        self.lastActive = lastActive
        self.merchandisePurchased = merchandisePurchased
        self.concertsAttended = concertsAttended
        self.achievementsUnlocked = achievementsUnlocked
    }
}

// MARK: - Fan Profile
struct FanProfile: Codable, Equatable {
    let nickname: String
    let joinDate: Date
    let location: String
    let favoriteSong: String
    let level: FanLevel
    let achievements: [String] // Achievement IDs
    let isModerator: Bool
    let stats: FanStats
    let notificationSettings: FanNotificationSettings
    
    init(
        nickname: String,
        joinDate: Date = Date(),
        location: String,
        favoriteSong: String,
        level: FanLevel = .newbie,
        achievements: [String] = [],
        isModerator: Bool = false,
        stats: FanStats = FanStats(),
        notificationSettings: FanNotificationSettings = FanNotificationSettings()
    ) {
        self.nickname = nickname
        self.joinDate = joinDate
        self.location = location
        self.favoriteSong = favoriteSong
        self.level = level
        self.achievements = achievements
        self.isModerator = isModerator
        self.stats = stats
        self.notificationSettings = notificationSettings
    }
    
    var daysSinceJoining: Int {
        Calendar.current.dateComponents([.day], from: joinDate, to: Date()).day ?? 0
    }
    
    var isActive: Bool {
        let daysSinceLastActive = Calendar.current.dateComponents([.day], from: stats.lastActive, to: Date()).day ?? 0
        return daysSinceLastActive <= 7
    }
}

// MARK: - Fan Notification Settings
struct FanNotificationSettings: Codable, Equatable {
    var newConcerts: Bool
    var officialNews: Bool
    var chatMessages: Bool
    var newMerch: Bool
    var achievements: Bool
    var moderatorActions: Bool
    
    init(
        newConcerts: Bool = true,
        officialNews: Bool = true,
        chatMessages: Bool = true,
        newMerch: Bool = false,
        achievements: Bool = true,
        moderatorActions: Bool = true
    ) {
        self.newConcerts = newConcerts
        self.officialNews = officialNews
        self.chatMessages = chatMessages
        self.newMerch = newMerch
        self.achievements = achievements
        self.moderatorActions = moderatorActions
    }
}

// MARK: - Fan Invite Code
struct FanInviteCode: Identifiable, Codable {
    let id: String
    let groupId: String
    let code: String
    let createdBy: String
    let createdAt: Date
    let isActive: Bool
    let maxUses: Int?
    let currentUses: Int
    let groupName: String
    
    init(
        id: String = UUID().uuidString,
        groupId: String,
        code: String,
        createdBy: String,
        createdAt: Date = Date(),
        isActive: Bool = true,
        maxUses: Int? = nil,
        currentUses: Int = 0,
        groupName: String
    ) {
        self.id = id
        self.groupId = groupId
        self.code = code
        self.createdBy = createdBy
        self.createdAt = createdAt
        self.isActive = isActive
        self.maxUses = maxUses
        self.currentUses = currentUses
        self.groupName = groupName
    }
    
    var canBeUsed: Bool {
        guard isActive else { return false }
        if let maxUses = maxUses {
            return currentUses < maxUses
        }
        return true
    }
    
    var formattedCode: String {
        code.uppercased()
    }
}

// MARK: - Achievement System
struct Achievement: Identifiable, Codable {
    let id: String
    let title: String
    let description: String
    let iconName: String
    let requirements: AchievementRequirements
    let category: AchievementCategory
    let points: Int
    
    init(
        id: String,
        title: String,
        description: String,
        iconName: String,
        requirements: AchievementRequirements,
        category: AchievementCategory,
        points: Int = 10
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.iconName = iconName
        self.requirements = requirements
        self.category = category
        self.points = points
    }
}

enum AchievementCategory: String, Codable, CaseIterable {
    case concerts = "Concerts"
    case social = "Social"
    case loyalty = "Loyalty"
    case merchandise = "Merchandise"
    case special = "Special"
    
    var localizedName: String {
        switch self {
        case .concerts:
            return "Concerts"
        case .social:
            return "Social"
        case .loyalty:
            return "Loyalty"
        case .merchandise:
            return "Merchandise"
        case .special:
            return "Special"
        }
    }
}

struct AchievementRequirements: Codable {
    let concertsAttended: Int?
    let daysSinceJoining: Int?
    let messagesCount: Int?
    let merchPurchases: Int?
    let isAmongFirst: Int?
    let customCondition: String?
    
    init(
        concertsAttended: Int? = nil,
        daysSinceJoining: Int? = nil,
        messagesCount: Int? = nil,
        merchPurchases: Int? = nil,
        isAmongFirst: Int? = nil,
        customCondition: String? = nil
    ) {
        self.concertsAttended = concertsAttended
        self.daysSinceJoining = daysSinceJoining
        self.messagesCount = messagesCount
        self.merchPurchases = merchPurchases
        self.isAmongFirst = isAmongFirst
        self.customCondition = customCondition
    }
}

// MARK: - Default Achievements
extension Achievement {
    static let defaults: [Achievement] = [
        Achievement(
            id: "year_member",
            title: "Loyal Fan",
            description: "One year in the fan club",
            iconName: "calendar",
            requirements: AchievementRequirements(daysSinceJoining: 365),
            category: .loyalty,
            points: 50
        ),
        Achievement(
            id: "regular_attender",
            title: "Regular Attender",
            description: "Attended 5+ concerts",
            iconName: "star.circle",
            requirements: AchievementRequirements(concertsAttended: 5),
            category: .concerts,
            points: 30
        ),
        Achievement(
            id: "superfan",
            title: "Superfan",
            description: "Attended 10+ concerts",
            iconName: "crown",
            requirements: AchievementRequirements(concertsAttended: 10),
            category: .concerts,
            points: 100
        ),
        Achievement(
            id: "first_merch",
            title: "First Purchase",
            description: "Bought your first merchandise",
            iconName: "tshirt",
            requirements: AchievementRequirements(merchPurchases: 1),
            category: .merchandise,
            points: 15
        ),
        Achievement(
            id: "active_chatter",
            title: "Active Chatter",
            description: "Sent 100+ messages in chat",
            iconName: "bubble.left.and.bubble.right",
            requirements: AchievementRequirements(messagesCount: 100),
            category: .social,
            points: 25
        )
    ]
}
