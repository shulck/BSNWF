import Foundation
import FirebaseFirestore

// Import DocumentPermissions from DocumentModels
// Note: DocumentPermissions is defined in DocumentModels.swift

struct UserModel: Identifiable, Codable, Equatable {
    let id: String
    let email: String
    var name: String
    var phone: String
    let groupId: String?
    var role: UserRole
    var isOnline: Bool?
    var lastSeen: Date?
    var avatarURL: String?
    
    // MARK: - Document Management Fields (Added for Google Drive integration)
    var documentPermissions: DocumentPermissions?
    var googleDriveEmail: String?
    var hasGoogleDriveAccess: Bool?
    
    // MARK: - Fan System Properties (NEW)
    let userType: UserType
    let fanGroupId: String?        // For fans - ID of the group they follow
    let fanProfile: FanProfile?    // Fan-specific data

    enum UserRole: String, Codable, CaseIterable, Identifiable {
        case admin = "Admin"
        case manager = "Manager"
        case musician = "Musician"
        case member = "Member"
        
        var id: String { rawValue }
        
        // MARK: - Permission System Extensions
        
        var description: String {
            switch self {
            case .admin:
                return "Full access to all features and settings"
            case .manager:
                return "Management and coordination responsibilities"
            case .musician:
                return "Band member with musical performance role"
            case .member:
                return "Basic band member with limited access"
            }
        }
        
        var icon: String {
            switch self {
            case .admin: return "crown.fill"
            case .manager: return "person.badge.key.fill"
            case .musician: return "music.note"
            case .member: return "person.fill"
            }
        }
        
        var color: String {
            switch self {
            case .admin: return "red"
            case .manager: return "orange"
            case .musician: return "blue"
            case .member: return "gray"
            }
        }
        
        // Hierarchy level for comparison
        var hierarchyLevel: Int {
            switch self {
            case .admin: return 4
            case .manager: return 3
            case .musician: return 2
            case .member: return 1
            }
        }
        
        // Check if this role can manage another role
        func canManage(_ otherRole: UserRole) -> Bool {
            return self.hierarchyLevel > otherRole.hierarchyLevel
        }
    }
    
    // MARK: - Initializer (Updated)
    init(
        id: String,
        email: String,
        name: String,
        phone: String,
        groupId: String? = nil,
        role: UserRole = .member,
        isOnline: Bool? = nil,
        lastSeen: Date? = nil,
        avatarURL: String? = nil,
        documentPermissions: DocumentPermissions? = nil,
        googleDriveEmail: String? = nil,
        hasGoogleDriveAccess: Bool? = nil,
        userType: UserType = .bandMember,
        fanGroupId: String? = nil,
        fanProfile: FanProfile? = nil
    ) {
        self.id = id
        self.email = email
        self.name = name
        self.phone = phone
        self.groupId = groupId
        self.role = role
        self.isOnline = isOnline
        self.lastSeen = lastSeen
        self.avatarURL = avatarURL
        self.documentPermissions = documentPermissions
        self.googleDriveEmail = googleDriveEmail
        self.hasGoogleDriveAccess = hasGoogleDriveAccess
        self.userType = userType
        self.fanGroupId = fanGroupId
        self.fanProfile = fanProfile
    }

    static func == (lhs: UserModel, rhs: UserModel) -> Bool {
        return lhs.id == rhs.id &&
               lhs.email == rhs.email &&
               lhs.name == rhs.name &&
               lhs.phone == rhs.phone &&
               lhs.groupId == rhs.groupId &&
               lhs.role == rhs.role &&
               lhs.isOnline == rhs.isOnline &&
               lhs.lastSeen == rhs.lastSeen &&
               lhs.avatarURL == rhs.avatarURL &&
               lhs.googleDriveEmail == rhs.googleDriveEmail &&
               lhs.hasGoogleDriveAccess == rhs.hasGoogleDriveAccess &&
               lhs.userType == rhs.userType &&
               lhs.fanGroupId == rhs.fanGroupId
    }
}

extension UserModel {
    static var mock: UserModel {
        UserModel(
            id: "user1",
            email: "test@example.com",
            name: "Test User",
            phone: "1234567890",
            groupId: "group1",
            role: .musician,
            isOnline: true,
            lastSeen: Date()
        )
    }
    
    // MARK: - Document Permissions Helper Methods
    
    var effectiveDocumentPermissions: DocumentPermissions {
        // If custom permissions are set, use them
        if let customPermissions = documentPermissions {
            return customPermissions
        }
        
        // Otherwise, use role-based permissions
        switch role {
        case .admin:
            return DocumentPermissions.adminPermissions
        case .manager:
            return DocumentPermissions.managerPermissions
        case .musician, .member:
            return DocumentPermissions.memberPermissions
        }
    }
    
    var canManageDocuments: Bool {
        return effectiveDocumentPermissions.canEdit && effectiveDocumentPermissions.canUpload
    }
    
    var canCreateFolders: Bool {
        return effectiveDocumentPermissions.canCreateFolders
    }
    
    var isDocumentAdmin: Bool {
        return role == .admin || effectiveDocumentPermissions.canDelete
    }
    
    // MARK: - Permission System Helper Methods
    
    // Computed properties for role checking
    var isAdmin: Bool {
        return role == .admin
    }
    
    var isManager: Bool {
        return role == .manager
    }
    
    var isMusician: Bool {
        return role == .musician
    }
    
    var isMember: Bool {
        return role == .member
    }
    
    var canManageOthers: Bool {
        return role == .admin || role == .manager
    }
    
    var hasGroupAccess: Bool {
        return groupId != nil
    }
    
    // MARK: - Fan System Helper Methods (NEW)
    
    // Fan-specific computed properties
    var isFan: Bool {
        return userType == .fan
    }
    
    var isBandMember: Bool {
        return userType == .bandMember
    }
    
    var displayName: String {
        if isFan, let fanProfile = fanProfile {
            return fanProfile.nickname
        }
        return name
    }
    
    var fanLevel: FanLevel? {
        return fanProfile?.level
    }
    
    var canModerate: Bool {
        if isBandMember {
            return role == .admin || role == .manager
        } else if isFan {
            return fanProfile?.isModerator ?? false
        }
        return false
    }
    
    // User initials for UI
    var initials: String {
        let components = name.components(separatedBy: " ")
        let firstInitial = components.first?.first?.uppercased() ?? ""
        let lastInitial = components.count > 1 ? components.last?.first?.uppercased() ?? "" : ""
        return firstInitial + lastInitial
    }
    
    // Helper methods for permission checking
    func hasRole(_ requiredRole: UserRole) -> Bool {
        return role == requiredRole
    }
    
    func hasRoleOrHigher(_ minimumRole: UserRole) -> Bool {
        return role.hierarchyLevel >= minimumRole.hierarchyLevel
    }
    
    func canEdit(user: UserModel) -> Bool {
        // Users can edit themselves
        if self.id == user.id {
            return true
        }
        
        // Admins can edit anyone except other admins
        if self.isAdmin {
            return !user.isAdmin || self.id == user.id
        }
        
        // Managers can edit musicians and members
        if self.isManager {
            return user.isMusician || user.isMember
        }
        
        return false
    }
    
    func canDelete(user: UserModel) -> Bool {
        // Users cannot delete themselves
        if self.id == user.id {
            return false
        }
        
        // Only admins can delete users
        if self.isAdmin {
            return !user.isAdmin // Admins cannot delete other admins
        }
        
        return false
    }
    
    /// Get permissions summary for this user role
    func getPermissionsSummary() -> [String: Any] {
        var summary: [String: Any] = [:]
        summary["role"] = role.rawValue
        summary["hierarchyLevel"] = role.hierarchyLevel
        summary["canManageOthers"] = canManageOthers
        
        // Module access based on role
        var moduleAccess: [String: [String: Bool]] = [:]
        
        switch role {
        case .admin:
            // Admin has full access to everything
            for module in ModuleType.allCases {
                moduleAccess[module.rawValue] = [
                    "read": true,
                    "write": true,
                    "delete": true
                ]
            }
            
        case .manager:
            // Manager extended access
            let managerModules: [ModuleType: (Bool, Bool, Bool)] = [
                .merchandise: (true, true, true),
                .documents: (true, true, true),
                .calendar: (true, true, true),
                .setlists: (true, true, true),
                .tasks: (true, true, true)
            ]
            
            for (module, permissions) in managerModules {
                moduleAccess[module.rawValue] = [
                    "read": permissions.0,
                    "write": permissions.1,
                    "delete": permissions.2
                ]
            }
            
        case .musician:
            // Musician basic access
            let musicianModules: [ModuleType: (Bool, Bool, Bool)] = [
                .documents: (true, true, false),
                .calendar: (true, true, false),
                .chats: (true, true, false),
                .setlists: (true, false, false), // Only read
                .tasks: (true, true, false)
            ]
            
            for (module, permissions) in musicianModules {
                moduleAccess[module.rawValue] = [
                    "read": permissions.0,
                    "write": permissions.1,
                    "delete": permissions.2
                ]
            }
            
        case .member:
            // Member minimal access
            let memberModules: [ModuleType: (Bool, Bool, Bool)] = [
                .calendar: (true, true, false),
                .chats: (true, true, false)
            ]
            
            for (module, permissions) in memberModules {
                moduleAccess[module.rawValue] = [
                    "read": permissions.0,
                    "write": permissions.1,
                    "delete": permissions.2
                ]
            }
        }
        
        summary["moduleAccess"] = moduleAccess
        return summary
    }
    
    // MARK: - Firebase Conversion Helpers (NEW)
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "id": id,
            "email": email,
            "name": name,
            "phone": phone,
            "role": role.rawValue,
            "userType": userType.rawValue
        ]
        
        // Handle optional fields
        dict["groupId"] = groupId ?? NSNull()
        dict["isOnline"] = isOnline ?? NSNull()
        dict["lastSeen"] = lastSeen != nil ? Timestamp(date: lastSeen!) : NSNull()
        dict["avatarURL"] = avatarURL ?? NSNull()
        dict["documentPermissions"] = documentPermissions ?? NSNull()
        dict["googleDriveEmail"] = googleDriveEmail ?? NSNull()
        dict["hasGoogleDriveAccess"] = hasGoogleDriveAccess ?? NSNull()
        dict["fanGroupId"] = fanGroupId ?? NSNull()
        
        // Handle fan profile
        if let fanProfile = fanProfile {
            dict["fanProfile"] = [
                "nickname": fanProfile.nickname,
                "joinDate": Timestamp(date: fanProfile.joinDate),
                "location": fanProfile.location,
                "favoriteSong": fanProfile.favoriteSong,
                "level": fanProfile.level.rawValue,
                "achievements": fanProfile.achievements,
                "isModerator": fanProfile.isModerator,
                "stats": [
                    "totalMessages": fanProfile.stats.totalMessages,
                    "joinDate": Timestamp(date: fanProfile.stats.joinDate),
                    "lastActive": Timestamp(date: fanProfile.stats.lastActive),
                    "merchandisePurchased": fanProfile.stats.merchandisePurchased,
                    "concertsAttended": fanProfile.stats.concertsAttended,
                    "achievementsUnlocked": fanProfile.stats.achievementsUnlocked
                ],
                "notificationSettings": [
                    "newConcerts": fanProfile.notificationSettings.newConcerts,
                    "officialNews": fanProfile.notificationSettings.officialNews,
                    "chatMessages": fanProfile.notificationSettings.chatMessages,
                    "newMerch": fanProfile.notificationSettings.newMerch,
                    "achievements": fanProfile.notificationSettings.achievements,
                    "moderatorActions": fanProfile.notificationSettings.moderatorActions
                ]
            ]
        } else {
            dict["fanProfile"] = NSNull()
        }
        
        return dict
    }
    
    static func fromDictionary(_ dict: [String: Any], id: String) -> UserModel? {
        guard let email = dict["email"] as? String,
              let name = dict["name"] as? String,
              let phone = dict["phone"] as? String,
              let roleString = dict["role"] as? String,
              let role = UserRole(rawValue: roleString) else {
            return nil
        }
        
        let userTypeString = dict["userType"] as? String ?? "BandMember"
        let userType = UserType(rawValue: userTypeString) ?? .bandMember
        
        let groupId = dict["groupId"] as? String
        let isOnline = dict["isOnline"] as? Bool
        let lastSeen = (dict["lastSeen"] as? Timestamp)?.dateValue()
        let avatarURL = dict["avatarURL"] as? String
        let documentPermissions = dict["documentPermissions"] as? DocumentPermissions
        let googleDriveEmail = dict["googleDriveEmail"] as? String
        let hasGoogleDriveAccess = dict["hasGoogleDriveAccess"] as? Bool
        let fanGroupId = dict["fanGroupId"] as? String
        
        var fanProfile: FanProfile?
        if let fanProfileDict = dict["fanProfile"] as? [String: Any] {
            fanProfile = FanProfile.fromDictionary(fanProfileDict)
        }
        
        return UserModel(
            id: id,
            email: email,
            name: name,
            phone: phone,
            groupId: groupId,
            role: role,
            isOnline: isOnline,
            lastSeen: lastSeen,
            avatarURL: avatarURL,
            documentPermissions: documentPermissions,
            googleDriveEmail: googleDriveEmail,
            hasGoogleDriveAccess: hasGoogleDriveAccess,
            userType: userType,
            fanGroupId: fanGroupId,
            fanProfile: fanProfile
        )
    }
}

// MARK: - FanProfile Firebase Conversion (NEW)
extension FanProfile {
    static func fromDictionary(_ dict: [String: Any]) -> FanProfile? {
        guard let nickname = dict["nickname"] as? String,
              let joinDateTimestamp = dict["joinDate"] as? Timestamp,
              let location = dict["location"] as? String,
              let favoriteSong = dict["favoriteSong"] as? String,
              let levelString = dict["level"] as? String,
              let level = FanLevel(rawValue: levelString),
              let achievements = dict["achievements"] as? [String],
              let isModerator = dict["isModerator"] as? Bool else {
            return nil
        }
        
        let joinDate = joinDateTimestamp.dateValue()
        
        var stats = FanStats()
        if let statsDict = dict["stats"] as? [String: Any] {
            stats = FanStats(
                totalMessages: statsDict["totalMessages"] as? Int ?? 0,
                joinDate: (statsDict["joinDate"] as? Timestamp)?.dateValue() ?? joinDate,
                lastActive: (statsDict["lastActive"] as? Timestamp)?.dateValue() ?? Date(),
                merchandisePurchased: statsDict["merchandisePurchased"] as? Int ?? 0,
                concertsAttended: statsDict["concertsAttended"] as? Int ?? 0,
                achievementsUnlocked: statsDict["achievementsUnlocked"] as? Int ?? 0
            )
        }
        
        var notificationSettings = FanNotificationSettings()
        if let settingsDict = dict["notificationSettings"] as? [String: Any] {
            notificationSettings = FanNotificationSettings(
                newConcerts: settingsDict["newConcerts"] as? Bool ?? true,
                officialNews: settingsDict["officialNews"] as? Bool ?? true,
                chatMessages: settingsDict["chatMessages"] as? Bool ?? true,
                newMerch: settingsDict["newMerch"] as? Bool ?? false,
                achievements: settingsDict["achievements"] as? Bool ?? true,
                moderatorActions: settingsDict["moderatorActions"] as? Bool ?? true
            )
        }
        
        return FanProfile(
            nickname: nickname,
            joinDate: joinDate,
            location: location,
            favoriteSong: favoriteSong,
            level: level,
            achievements: achievements,
            isModerator: isModerator,
            stats: stats,
            notificationSettings: notificationSettings
        )
    }
}
