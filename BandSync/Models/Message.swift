import Foundation

struct Message: Identifiable, Codable {
    var id: String?
    let chatId: String
    let content: String
    let senderID: String
    let senderName: String
    let timestamp: Date
    let type: MessageType
    
    var isEdited: Bool = false
    var editedAt: Date?
    var isDeleted: Bool = false
    var deletedAt: Date?
    
    var replyToMessageId: String?
    var replyToContent: String?
    var replyToSenderName: String?
    
    var imageURL: String?
    var imageWidth: Double?
    var imageHeight: Double?
    
    var linkPreview: LinkPreview?
    
    var reactions: [String: [String]] = [:]
    
    var readBy: [String: Date] = [:]
    var deliveredTo: [String: Date] = [:]
    
    var mentions: [String] = []
    
    init(id: String? = nil,
         chatId: String,
         content: String,
         senderID: String,
         senderName: String,
         timestamp: Date,
         type: MessageType,
         isEdited: Bool = false,
         editedAt: Date? = nil,
         isDeleted: Bool = false,
         deletedAt: Date? = nil,
         replyToMessageId: String? = nil,
         replyToContent: String? = nil,
         replyToSenderName: String? = nil,
         imageURL: String? = nil,
         imageWidth: Double? = nil,
         imageHeight: Double? = nil,
         linkPreview: LinkPreview? = nil,
         reactions: [String: [String]] = [:],
         readBy: [String: Date] = [:],
         deliveredTo: [String: Date] = [:],
         mentions: [String] = []) {
        
        self.id = id
        self.chatId = chatId
        self.content = content
        self.senderID = senderID
        self.senderName = senderName
        self.timestamp = timestamp
        self.type = type
        self.isEdited = isEdited
        self.editedAt = editedAt
        self.isDeleted = isDeleted
        self.deletedAt = deletedAt
        self.replyToMessageId = replyToMessageId
        self.replyToContent = replyToContent
        self.replyToSenderName = replyToSenderName
        self.imageURL = imageURL
        self.imageWidth = imageWidth
        self.imageHeight = imageHeight
        self.linkPreview = linkPreview
        self.reactions = reactions
        self.readBy = readBy
        self.deliveredTo = deliveredTo
        self.mentions = mentions
    }
    
    enum MessageType: String, Codable, CaseIterable {
        case text = "text"
        case image = "image"
        case system = "system"
        case reply = "reply"
    }
    
    struct LinkPreview: Codable {
        let url: String
        let title: String?
        let description: String?
        let imageURL: String?
        let domain: String?
    }
    
    var isSystemMessage: Bool {
        return type == .system
    }
    
    var isImageMessage: Bool {
        return type == .image
    }
    
    var isReplyMessage: Bool {
        return replyToMessageId != nil
    }
    
    var hasReactions: Bool {
        return !reactions.isEmpty
    }
    
    var hasLinkPreview: Bool {
        return linkPreview != nil
    }
    
    var hasMentions: Bool {
        return !mentions.isEmpty
    }
    
    var isRead: Bool {
        return !readBy.isEmpty
    }
    
    func isReadBy(_ userId: String) -> Bool {
        return readBy.keys.contains(userId)
    }
    
    func isDeliveredTo(_ userId: String) -> Bool {
        return deliveredTo.keys.contains(userId)
    }
    
    func getDeliveryStatus(for userId: String) -> DeliveryStatus {
        if isReadBy(userId) {
            return .read
        } else if isDeliveredTo(userId) {
            return .delivered
        } else {
            return .sent
        }
    }
    
    enum DeliveryStatus {
        case sent
        case delivered
        case read
        
        var icon: String {
            switch self {
            case .sent: return "checkmark"
            case .delivered: return "checkmark.circle"
            case .read: return "checkmark.circle.fill"
            }
        }
    }
    
    func getReactionCount(for emoji: String) -> Int {
        return reactions[emoji]?.count ?? 0
    }
    
    func hasUserReacted(_ userId: String, with emoji: String) -> Bool {
        return reactions[emoji]?.contains(userId) ?? false
    }
    
    var extractedURLs: [URL] {
        let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        let matches = detector?.matches(in: content, options: [], range: NSRange(location: 0, length: content.utf16.count)) ?? []
        return matches.compactMap { match in
            guard let range = Range(match.range, in: content) else { return nil }
            return URL(string: String(content[range]))
        }
    }
    
    var containsLinks: Bool {
        return !extractedURLs.isEmpty
    }
}

struct TypingStatus: Codable, Identifiable {
    let id: String
    let userId: String
    let userName: String
    let timestamp: Date
    let chatId: String
    
    var isValid: Bool {
        Date().timeIntervalSince(timestamp) < 5.0
    }
}
