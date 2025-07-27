import Foundation

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
               lhs.hasGoogleDriveAccess == rhs.hasGoogleDriveAccess
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
}
