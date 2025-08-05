import Foundation
import FirebaseAuth

// MARK: - FAN CHAT MODELS (SEPARATE FROM MAIN CHAT SYSTEM)

struct FanChat: Identifiable, Codable, Hashable {
    var id: String?
    let type: FanChatType
    var participants: [String] // Fan user IDs
    var participantNames: [String: String] // Map of userId -> displayName
    var participantAvatars: [String: String] // Map of userId -> avatarURL
    let createdBy: String // Fan user ID
    let createdAt: Date
    var updatedAt: Date
    var name: String?
    var description: String?
    var lastMessage: FanLastMessage?
    var isDeleted: Bool = false
    var groupId: String // Band group ID
    var moderatorIds: [String] = [] // Fan user IDs who can moderate
    var isActive: Bool = true // Can be disabled by admin/moderator
    var chatRulesAccepted: [String: Date] = [:] // Fan ID -> acceptance date
    
    init(id: String? = nil,
         type: FanChatType,
         participants: [String],
         participantNames: [String: String] = [:],
         participantAvatars: [String: String] = [:],
         createdBy: String,
         createdAt: Date,
         updatedAt: Date,
         name: String? = nil,
         description: String? = nil,
         lastMessage: FanLastMessage? = nil,
         isDeleted: Bool = false,
         groupId: String,
         moderatorIds: [String] = [],
         isActive: Bool = true,
         chatRulesAccepted: [String: Date] = [:]) {
        
        self.id = id
        self.type = type
        self.participants = participants
        self.participantNames = participantNames
        self.participantAvatars = participantAvatars
        self.createdBy = createdBy
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.name = name
        self.description = description
        self.lastMessage = lastMessage
        self.isDeleted = isDeleted
        self.groupId = groupId
        self.moderatorIds = moderatorIds
        self.isActive = isActive
        self.chatRulesAccepted = chatRulesAccepted
    }
    
    enum FanChatType: String, Codable, CaseIterable {
        case general = "general"        // Общий чат всех фанатов
        case privateChat = "private"    // Приватный чат между фанатами
        case themed = "themed"          // Тематический чат (создается модератором)
        case announcement = "announcement" // Массовые уведомления (только чтение для фанатов)
        case mixed = "mixed"           // Совместный чат админов + фанатов
    }
    
    struct FanLastMessage: Codable, Hashable {
        let id: String
        var content: String
        let senderID: String
        let senderName: String
        let timestamp: Date
        let type: FanMessageType
        
        enum FanMessageType: String, Codable, CaseIterable {
            case text = "text"
            case system = "system"
            case announcement = "announcement"
        }
    }
    
    var isPrivateChat: Bool {
        return type == .privateChat
    }
    
    var isGroupChat: Bool {
        return type == .general || type == .themed || type == .mixed
    }
    
    var isReadOnlyForFans: Bool {
        return type == .announcement
    }
    
    var displayName: String {
        switch type {
        case .general:
            return "Fan Community"
        case .privateChat:
            guard let currentUserId = Auth.auth().currentUser?.uid,
                  let otherUserId = participants.first(where: { $0 != currentUserId }) else {
                return "Private Chat"
            }
            // Use real name from participantNames if available (nickname for fans)
            if let otherUserName = participantNames[otherUserId], !otherUserName.isEmpty {
                return otherUserName
            }
            // If no stored name, show a more user-friendly fallback
            return "Private Chat"
        case .themed:
            return name ?? "Themed Chat"
        case .announcement:
            return "Band Announcements"
        case .mixed:
            return name ?? "Band & Fans Chat"
        }
    }
    
    var otherUserAvatarURL: String? {
        guard type == .privateChat,
              let currentUserId = Auth.auth().currentUser?.uid,
              let otherUserId = participants.first(where: { $0 != currentUserId }) else {
            return nil
        }
        return participantAvatars[otherUserId]
    }
    
    func getOtherParticipantId(currentUserId: String) -> String? {
        return participants.first { $0 != currentUserId }
    }
    
    func canUserModerate(_ userId: String) -> Bool {
        return moderatorIds.contains(userId) || createdBy == userId
    }
    
    func canUserDelete(_ userId: String) -> Bool {
        switch type {
        case .privateChat:
            return participants.contains(userId)
        case .general:
            return false // Cannot delete general chat
        case .themed, .mixed:
            return moderatorIds.contains(userId) || createdBy == userId
        case .announcement:
            return false // Cannot delete announcement chat
        }
    }
    
    func hasUserAcceptedRules(_ userId: String) -> Bool {
        return chatRulesAccepted[userId] != nil
    }
    
    mutating func acceptRules(for userId: String) {
        chatRulesAccepted[userId] = Date()
    }
}

// MARK: - FAN MESSAGE MODEL

struct FanMessage: Identifiable, Codable {
    var id: String?
    let chatId: String
    let senderID: String
    let senderName: String
    let senderNickname: String? // Fan nickname
    var content: String
    var originalContent: String? // Store original content for edited messages
    let timestamp: Date
    let type: MessageType
    var isDeleted: Bool
    var editedAt: Date?
    var reportedBy: [String] // User IDs who reported this message
    var isModerated: Bool // Hidden by moderator
    var moderatedBy: String?
    var moderatedAt: Date?
    var moderationReason: String?
    
    enum MessageType: String, Codable {
        case text = "text"
        case system = "system"
        case announcement = "announcement"
        case warning = "warning" // Moderation warning
    }
    
    init(id: String? = nil,
         chatId: String,
         senderID: String,
         senderName: String,
         senderNickname: String? = nil,
         content: String,
         originalContent: String? = nil,
         timestamp: Date = Date(),
         type: MessageType = .text,
         isDeleted: Bool = false,
         editedAt: Date? = nil,
         reportedBy: [String] = [],
         isModerated: Bool = false,
         moderatedBy: String? = nil,
         moderatedAt: Date? = nil,
         moderationReason: String? = nil) {
        
        self.id = id
        self.chatId = chatId
        self.senderID = senderID
        self.senderName = senderName
        self.senderNickname = senderNickname
        self.content = content
        self.originalContent = originalContent
        self.timestamp = timestamp
        self.type = type
        self.isDeleted = isDeleted
        self.editedAt = editedAt
        self.reportedBy = reportedBy
        self.isModerated = isModerated
        self.moderatedBy = moderatedBy
        self.moderatedAt = moderatedAt
        self.moderationReason = moderationReason
    }
    
    var displayName: String {
        return senderNickname ?? senderName
    }
    
    var isVisible: Bool {
        return !isDeleted && !isModerated
    }
    
    var isReported: Bool {
        return !reportedBy.isEmpty
    }
    
    var isEdited: Bool {
        return editedAt != nil
    }
    
    func canBeEditedBy(_ userId: String) -> Bool {
        return senderID == userId && !isDeleted && !isModerated
    }
    
    func canUserReport(_ userId: String) -> Bool {
        return senderID != userId && !reportedBy.contains(userId) && type == .text
    }
    
    mutating func report(by userId: String) {
        if !reportedBy.contains(userId) && senderID != userId {
            reportedBy.append(userId)
        }
    }
    
    mutating func moderate(by moderatorId: String, reason: String) {
        isModerated = true
        moderatedBy = moderatorId
        moderatedAt = Date()
        moderationReason = reason
    }
}

// MARK: - FAN CHAT RULES MODEL

struct FanChatRules: Codable {
    let groupId: String
    var rules: [ChatRule]
    let createdAt: Date
    var updatedAt: Date
    let version: Int
    
    struct ChatRule: Codable, Identifiable {
        var id = UUID()
        let title: String
        let description: String
        let icon: String
        let severity: RuleSeverity
        
        enum RuleSeverity: String, Codable {
            case info = "info"
            case warning = "warning"
            case serious = "serious"
        }
    }
    
    static func defaultRules(for groupId: String) -> FanChatRules {
        return FanChatRules(
            groupId: groupId,
            rules: [
                ChatRule(
                    title: "Be Respectful",
                    description: "Treat all fans and band members with respect. No harassment, bullying, or offensive language.",
                    icon: "heart.fill",
                    severity: .serious
                ),
                ChatRule(
                    title: "Stay On Topic",
                    description: "Keep discussions related to the band and music. Off-topic conversations should be moved to private chats.",
                    icon: "target",
                    severity: .info
                ),
                ChatRule(
                    title: "No Spam or Flooding",
                    description: "Don't send repetitive messages or flood the chat. Give others a chance to participate.",
                    icon: "exclamationmark.triangle.fill",
                    severity: .warning
                ),
                ChatRule(
                    title: "Text Only",
                    description: "Fan chats support text messages only. No images, links, or other media are allowed.",
                    icon: "text.bubble.fill",
                    severity: .info
                ),
                ChatRule(
                    title: "Report Issues",
                    description: "If you see inappropriate behavior, use the report function. Don't engage in arguments.",
                    icon: "flag.fill",
                    severity: .info
                )
            ],
            createdAt: Date(),
            updatedAt: Date(),
            version: 1
        )
    }
}

// MARK: - FAN CHAT REPORT MODEL

struct FanChatReport: Identifiable, Codable {
    var id: String?
    let chatId: String
    let messageId: String
    let reportedUserId: String
    let reporterUserId: String
    let reason: ReportReason
    let description: String?
    let timestamp: Date
    var status: ReportStatus = .pending
    var reviewedBy: String?
    var reviewedAt: Date?
    var action: ModerationAction?
    
    enum ReportReason: String, Codable, CaseIterable {
        case spam = "spam"
        case harassment = "harassment"
        case offensive = "offensive"
        case inappropriate = "inappropriate"
        case other = "other"
        
        var displayName: String {
            switch self {
            case .spam: return "Spam or Flooding"
            case .harassment: return "Harassment or Bullying"
            case .offensive: return "Offensive Language"
            case .inappropriate: return "Inappropriate Content"
            case .other: return "Other"
            }
        }
        
        var icon: String {
            switch self {
            case .spam: return "exclamationmark.triangle"
            case .harassment: return "person.2.slash"
            case .offensive: return "speaker.slash"
            case .inappropriate: return "eye.slash"
            case .other: return "questionmark.circle"
            }
        }
    }
    
    enum ReportStatus: String, Codable {
        case pending = "pending"
        case reviewed = "reviewed"
        case resolved = "resolved"
        case dismissed = "dismissed"
    }
    
    enum ModerationAction: String, Codable {
        case warning = "warning"
        case messageHidden = "messageHidden"
        case temporaryBan = "temporaryBan"
        case permanentBan = "permanentBan"
        case noAction = "noAction"
        
        var displayName: String {
            switch self {
            case .warning: return "Warning Issued"
            case .messageHidden: return "Message Hidden"
            case .temporaryBan: return "Temporary Ban"
            case .permanentBan: return "Permanent Ban"
            case .noAction: return "No Action Required"
            }
        }
    }
}

// MARK: - FAN CHAT MODERATION LOG MODEL

struct ModerationLog: Identifiable, Codable {
    var id: String?
    let action: String
    let moderatorId: String
    let moderatorName: String
    let targetUserId: String
    let targetUserName: String
    let chatId: String
    let messageId: String?
    let reason: String
    let timestamp: Date
    
    enum ModerationAction: String, CaseIterable {
        case deleteMessage = "delete_message"
        case hideMessage = "hide_message" 
        case showMessage = "show_message"
        case warnUser = "warn_user"
        case banUser = "ban_user"
        case tempBanUser = "temp_ban_user"
        case unbanUser = "unban_user"
        case muteUser = "mute_user"
        case unmuteUser = "unmute_user"
        case historyCleared = "history_cleared"
        
        var displayName: String {
            switch self {
            case .deleteMessage: return "Delete Message"
            case .hideMessage: return "Hide Message"
            case .showMessage: return "Show Message"
            case .warnUser: return "Warn User"
            case .banUser: return "Ban User"
            case .tempBanUser: return "Temporary Ban"
            case .unbanUser: return "Unban User"
            case .muteUser: return "Mute User"
            case .unmuteUser: return "Unmute User"
            case .historyCleared: return "History Cleared"
            }
        }
        
        var icon: String {
            switch self {
            case .deleteMessage: return "trash"
            case .hideMessage: return "eye.slash"
            case .showMessage: return "eye"
            case .warnUser: return "exclamationmark.triangle"
            case .banUser, .tempBanUser: return "person.crop.circle.badge.xmark"
            case .unbanUser: return "person.crop.circle.badge.checkmark"
            case .muteUser: return "speaker.slash"
            case .unmuteUser: return "speaker"
            case .historyCleared: return "clock.arrow.circlepath"
            }
        }
        
        var color: String {
            switch self {
            case .deleteMessage, .banUser: return "red"
            case .hideMessage, .tempBanUser, .muteUser, .historyCleared: return "orange"
            case .warnUser: return "yellow"
            case .showMessage, .unbanUser, .unmuteUser: return "green"
            }
        }
    }
}
