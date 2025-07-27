import Foundation
import FirebaseAuth

struct Chat: Identifiable, Codable {
    var id: String?
    let type: ChatType
    let participants: [String]
    let createdBy: String
    let createdAt: Date
    var updatedAt: Date
    var name: String?
    var description: String?
    var imageURL: String?
    var lastMessage: LastMessage?
    var isDeleted: Bool = false
    var bandId: String?
    var adminIds: [String] = []
    
    private static var deletePermissionCache: [String: Bool] = [:]
    private static var lastCacheCleanup: Date = Date()
    
    init(id: String? = nil,
         type: ChatType,
         participants: [String],
         createdBy: String,
         createdAt: Date,
         updatedAt: Date,
         name: String? = nil,
         description: String? = nil,
         imageURL: String? = nil,
         lastMessage: LastMessage? = nil,
         isDeleted: Bool = false,
         bandId: String? = nil,
         adminIds: [String] = []) {
        
        self.id = id
        self.type = type
        self.participants = participants
        self.createdBy = createdBy
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.name = name
        self.description = description
        self.imageURL = imageURL
        self.lastMessage = lastMessage
        self.isDeleted = isDeleted
        self.bandId = bandId
        self.adminIds = adminIds
    }
    
    enum ChatType: String, Codable, CaseIterable {
        case direct = "direct"
        case group = "group"
        case bandWide = "bandWide"
    }
    
    struct LastMessage: Codable {
        let id: String
        let content: String
        let senderID: String
        let senderName: String
        let timestamp: Date
        let type: MessageType
        
        enum MessageType: String, Codable {
            case text, image, system
        }
    }
    
    var isPrivateChat: Bool {
        return type == .direct
    }
    
    var isGroupChat: Bool {
        return type == .group || type == .bandWide
    }
    
    var displayName: String {
        switch type {
        case .direct:
            guard let currentUserId = Auth.auth().currentUser?.uid,
                  let otherUserId = participants.first(where: { $0 != currentUserId }) else {
                return "Private Chat"
            }
            
            if let otherUser = UserService.shared.users.first(where: { $0.id == otherUserId }) {
                return otherUser.name
            }
            
            return "User \(otherUserId.prefix(8))"
            
        case .group:
            return name ?? "Group Chat"
            
        case .bandWide:
            return name ?? "Band Announcement"
        }
    }
    
    func getOtherParticipantId(currentUserId: String) -> String? {
        guard isPrivateChat else { return nil }
        return participants.first { $0 != currentUserId }
    }
    
    func isUserAdmin(_ userId: String) -> Bool {
        return createdBy == userId || adminIds.contains(userId)
    }
    
    func canUserDelete(_ userId: String) -> Bool {
        guard let chatId = id else {
            return calculateDeletePermission(for: userId)
        }
        
        let cacheKey = "\(chatId)_\(userId)"
        
        Self.cleanupCacheIfNeeded()
        
        if let cachedResult = Self.deletePermissionCache[cacheKey] {
            return cachedResult
        }
        
        let result = calculateDeletePermission(for: userId)
        
        Self.deletePermissionCache[cacheKey] = result
        return result
    }
    
    private func calculateDeletePermission(for userId: String) -> Bool {
        if createdBy == userId {
            return true
        }
        
        if adminIds.contains(userId) {
            return true
        }
        
        if type == .bandWide {
            if let currentUser = UserService.shared.currentUser,
               currentUser.id == userId {
                let canDelete = currentUser.role == .admin || currentUser.role == .manager
                return canDelete
            }
        }
        
        if type == .direct && participants.contains(userId) {
            return true
        }
        
        return false
    }
    
    private static func cleanupCacheIfNeeded() {
        let now = Date()
        if now.timeIntervalSince(lastCacheCleanup) > 300 {
            deletePermissionCache.removeAll()
            lastCacheCleanup = now
        }
    }
    
    static func clearPermissionCache() {
        deletePermissionCache.removeAll()
    }
}
