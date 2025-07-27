import Foundation
import FirebaseDatabase
import FirebaseAuth
import FirebaseFirestore
import UIKit

final class ChatService: ObservableObject {
    static let shared = ChatService()
    
    private let db = Database.database().reference()
    private let firestore = Firestore.firestore()
    private var chatsListener: DatabaseHandle?
    private var messagesListeners: [String: DatabaseHandle] = [:]
    
    @Published var chats: [Chat] = []
    @Published var currentMessages: [Message] = []
    @Published var isLoading = false
    @Published var typingUsers: [String] = []
    
    private(set) var currentChatId: String?
    private var typingListener: DatabaseHandle?
    private var lastTypingUpdate: Date = Date.distantPast
    private let typingRateLimit: TimeInterval = 2.0
    
    private var messageCache: [String: [Message]] = [:]
    private var unreadCountCache: [String: (count: Int, timestamp: Date)] = [:]
    private let cacheExpiry: TimeInterval = 30
    
    private init() {}
    
    func startListeningToChats() {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            return
        }
        
        stopListeningToChats()
        isLoading = true
        
        chatsListener = db.child("chats")
            .queryOrdered(byChild: "updatedAt")
            .observe(.value) { [weak self] snapshot in
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    self.isLoading = false
                    
                    var chats: [Chat] = []
                    
                    for child in snapshot.children {
                        guard let childSnapshot = child as? DataSnapshot,
                              let chatData = childSnapshot.value as? [String: Any],
                              let participants = chatData["participants"] as? [String],
                              participants.contains(currentUserId) else {
                            continue
                        }
                        
                        let isDeleted = chatData["isDeleted"] as? Bool ?? false
                        if !isDeleted,
                           let chat = self.parseChat(from: chatData, id: childSnapshot.key) {
                            chats.append(chat)
                        }
                    }
                    
                    self.chats = chats.sorted { $0.updatedAt > $1.updatedAt }
                }
            }
    }
    
    func stopListeningToChats() {
        if let listener = chatsListener {
            db.child("chats").removeObserver(withHandle: listener)
            chatsListener = nil
        }
        isLoading = false
    }
    
    func startListeningToMessages(for chatId: String) {
        if let listener = messagesListeners[chatId] {
            db.child("messages").child(chatId).removeObserver(withHandle: listener)
        }
        
        currentChatId = chatId
        startListeningToTyping(for: chatId)
        
        messagesListeners[chatId] = db.child("messages").child(chatId)
            .queryOrdered(byChild: "timestamp")
            .queryLimited(toLast: 50)
            .observe(.value) { [weak self] snapshot in
                DispatchQueue.main.async {
                    var messages: [Message] = []
                    
                    for child in snapshot.children {
                        guard let childSnapshot = child as? DataSnapshot,
                              let messageData = childSnapshot.value as? [String: Any] else {
                            continue
                        }
                        
                        let isDeleted = messageData["isDeleted"] as? Bool ?? false
                        if !isDeleted {
                            if let message = self?.parseMessage(from: messageData, id: childSnapshot.key) {
                                messages.append(message)
                            }
                        }
                    }
                    
                    let sortedMessages = messages.sorted { $0.timestamp < $1.timestamp }
                    self?.currentMessages = sortedMessages
                    self?.messageCache[chatId] = sortedMessages
                }
            }
    }
    
    func stopListeningToMessages() {
        for (chatId, handle) in messagesListeners {
            db.child("messages").child(chatId).removeObserver(withHandle: handle)
        }
        messagesListeners.removeAll()
        
        DispatchQueue.main.async {
            self.currentMessages.removeAll()
        }
        
        stopListeningToTyping()
    }
    
    private func parseChat(from data: [String: Any], id: String) -> Chat? {
        guard
            let typeString = data["type"] as? String,
            let type = Chat.ChatType(rawValue: typeString),
            let participants = data["participants"] as? [String],
            let createdBy = data["createdBy"] as? String,
            let createdAtTimestamp = data["createdAt"] as? TimeInterval,
            let updatedAtTimestamp = data["updatedAt"] as? TimeInterval
        else {
            return nil
        }
        
        let createdAt = Date(timeIntervalSince1970: createdAtTimestamp / 1000)
        let updatedAt = Date(timeIntervalSince1970: updatedAtTimestamp / 1000)
        
        var lastMessage: Chat.LastMessage?
        if let lastMessageData = data["lastMessage"] as? [String: Any] {
            lastMessage = parseLastMessage(from: lastMessageData)
        }
        
        return Chat(
            id: id,
            type: type,
            participants: participants,
            createdBy: createdBy,
            createdAt: createdAt,
            updatedAt: updatedAt,
            name: data["name"] as? String,
            description: data["description"] as? String,
            imageURL: data["imageURL"] as? String,
            lastMessage: lastMessage,
            isDeleted: data["isDeleted"] as? Bool ?? false,
            bandId: data["bandId"] as? String,
            adminIds: data["adminIds"] as? [String] ?? []
        )
    }
    
    private func parseLastMessage(from data: [String: Any]) -> Chat.LastMessage? {
        guard
            let id = data["id"] as? String,
            let content = data["content"] as? String,
            let senderID = data["senderID"] as? String,
            let senderName = data["senderName"] as? String,
            let timestampValue = data["timestamp"] as? TimeInterval,
            let typeString = data["type"] as? String,
            let type = Chat.LastMessage.MessageType(rawValue: typeString)
        else { return nil }
        
        let timestamp = Date(timeIntervalSince1970: timestampValue / 1000)
        
        return Chat.LastMessage(
            id: id,
            content: content,
            senderID: senderID,
            senderName: senderName,
            timestamp: timestamp,
            type: type
        )
    }
    
    private func parseMessage(from data: [String: Any], id: String) -> Message? {
        guard
            let chatId = data["chatId"] as? String,
            let senderID = data["senderID"] as? String,
            let senderName = data["senderName"] as? String,
            let timestampValue = data["timestamp"] as? TimeInterval,
            let typeString = data["type"] as? String,
            let type = Message.MessageType(rawValue: typeString)
        else {
            return nil
        }
        
        let content = data["content"] as? String ?? ""
        let timestamp = Date(timeIntervalSince1970: timestampValue / 1000)
        
        return Message(
            id: id,
            chatId: chatId,
            content: content,
            senderID: senderID,
            senderName: senderName,
            timestamp: timestamp,
            type: type,
            isEdited: data["isEdited"] as? Bool ?? false,
            editedAt: {
                if let editedAtValue = data["editedAt"] as? TimeInterval {
                    return Date(timeIntervalSince1970: editedAtValue / 1000)
                }
                return nil
            }(),
            isDeleted: data["isDeleted"] as? Bool ?? false,
            deletedAt: {
                if let deletedAtValue = data["deletedAt"] as? TimeInterval {
                    return Date(timeIntervalSince1970: deletedAtValue / 1000)
                }
                return nil
            }(),
            replyToMessageId: data["replyToMessageId"] as? String,
            replyToContent: data["replyToContent"] as? String,
            replyToSenderName: data["replyToSenderName"] as? String,
            imageURL: data["imageURL"] as? String,
            imageWidth: data["imageWidth"] as? Double,
            imageHeight: data["imageHeight"] as? Double,
            linkPreview: parseMessageLinkPreview(from: data["linkPreview"]),
            reactions: data["reactions"] as? [String: [String]] ?? [:],
            readBy: parseReadBy(from: data["readBy"]),
            deliveredTo: parseDeliveredTo(from: data["deliveredTo"]),
            mentions: data["mentions"] as? [String] ?? []
        )
    }
    
    private func parseMessageLinkPreview(from data: Any?) -> Message.LinkPreview? {
        guard let previewData = data as? [String: Any],
              let url = previewData["url"] as? String,
              let title = previewData["title"] as? String else { return nil }
        
        let domain = previewData["domain"] as? String ?? URL(string: url)?.host ?? ""
        
        return Message.LinkPreview(
            url: url,
            title: title,
            description: previewData["description"] as? String,
            imageURL: previewData["imageURL"] as? String,
            domain: domain
        )
    }
    
    private func parseReadBy(from data: Any?) -> [String: Date] {
        guard let readByData = data as? [String: TimeInterval] else { return [:] }
        
        var readBy: [String: Date] = [:]
        for (userId, timestamp) in readByData {
            readBy[userId] = Date(timeIntervalSince1970: timestamp / 1000)
        }
        return readBy
    }
    
    private func parseDeliveredTo(from data: Any?) -> [String: Date] {
        guard let deliveredData = data as? [String: TimeInterval] else { return [:] }
        
        var deliveredTo: [String: Date] = [:]
        for (userId, timestamp) in deliveredData {
            deliveredTo[userId] = Date(timeIntervalSince1970: timestamp / 1000)
        }
        return deliveredTo
    }
    
    func loadOlderMessages(for chatId: String, before lastMessage: Message, completion: @escaping ([Message]) -> Void) {
        let endTimestamp = lastMessage.timestamp.timeIntervalSince1970 * 1000
        
        db.child("messages").child(chatId)
            .queryOrdered(byChild: "timestamp")
            .queryEnding(atValue: endTimestamp - 1)
            .queryLimited(toLast: 50)
            .observeSingleEvent(of: .value) { [weak self] snapshot in
                var messages: [Message] = []
                
                for child in snapshot.children {
                    guard let childSnapshot = child as? DataSnapshot,
                          let messageData = childSnapshot.value as? [String: Any] else { continue }
                    
                    let isDeleted = messageData["isDeleted"] as? Bool ?? false
                    if !isDeleted {
                        if let message = self?.parseMessage(from: messageData, id: childSnapshot.key) {
                            messages.append(message)
                        }
                    }
                }
                
                let sortedMessages = messages.sorted { $0.timestamp < $1.timestamp }
                completion(sortedMessages)
            }
    }
    
    func sendMessage(_ message: Message, completion: @escaping (Result<Void, Error>) -> Void) {
        let messageRef = db.child("messages").child(message.chatId).childByAutoId()
        let messageId = messageRef.key ?? UUID().uuidString
        
        var messageWithId = message
        messageWithId.id = messageId
        
        let messageData: [String: Any] = [
            "chatId": messageWithId.chatId,
            "content": messageWithId.content,
            "senderID": messageWithId.senderID,
            "senderName": messageWithId.senderName,
            "timestamp": messageWithId.timestamp.timeIntervalSince1970 * 1000,
            "type": messageWithId.type.rawValue,
            "isEdited": messageWithId.isEdited,
            "isDeleted": messageWithId.isDeleted,
            "replyToMessageId": messageWithId.replyToMessageId ?? NSNull(),
            "replyToContent": messageWithId.replyToContent ?? NSNull(),
            "replyToSenderName": messageWithId.replyToSenderName ?? NSNull(),
            "imageURL": messageWithId.imageURL ?? NSNull(),
            "imageWidth": messageWithId.imageWidth ?? NSNull(),
            "imageHeight": messageWithId.imageHeight ?? NSNull(),
            "reactions": messageWithId.reactions,
            "mentions": messageWithId.mentions
        ]
        
        messageRef.setValue(messageData) { [weak self] error, _ in
            if let error = error {
                completion(.failure(error))
            } else {
                self?.updateChatLastMessage(chatId: message.chatId, message: messageWithId)
                
                if let chat = self?.chats.first(where: { $0.id == message.chatId }) {
                    self?.sendChatNotification(for: messageWithId, in: chat)
                }
                
                completion(.success(()))
            }
        }
    }
    
    func sendImageMessage(_ message: Message, image: UIImage, completion: @escaping (Result<Void, Error>) -> Void) {
        let messageId = UUID().uuidString
        
        FirebaseStorageService.shared.uploadChatImage(image, chatId: message.chatId, messageId: messageId) { [weak self] imageURL in
            guard let imageURL = imageURL else {
                DispatchQueue.main.async {
                    completion(.failure(ChatError.imageCompressionFailed))
                }
                return
            }
            
            let imageMessage = Message(
                id: messageId,
                chatId: message.chatId,
                content: message.content,
                senderID: message.senderID,
                senderName: message.senderName,
                timestamp: message.timestamp,
                type: .image,
                isEdited: false,
                editedAt: nil,
                isDeleted: false,
                deletedAt: nil,
                replyToMessageId: message.replyToMessageId,
                replyToContent: message.replyToContent,
                replyToSenderName: message.replyToSenderName,
                imageURL: imageURL,
                imageWidth: nil,
                imageHeight: nil,
                linkPreview: nil,
                reactions: [:],
                readBy: [:],
                deliveredTo: [:],
                mentions: message.mentions
            )
            
            self?.sendMessage(imageMessage) { result in
                DispatchQueue.main.async {
                    completion(result)
                }
            }
        }
    }
    
    private func sendChatNotification(for message: Message, in chat: Chat) {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        guard message.senderID != currentUserId else { return }
        
        let messageText = message.type == .image ? "📷 Photo" : message.content
        let isMention = messageText.contains("@")
        
        if isMention {
            NotificationManager.shared.sendMentionNotification(
                from: message.senderName,
                message: messageText,
                chatId: chat.id ?? "",
                messageId: message.id ?? ""
            ) { success, error in
            }
        } else {
            NotificationManager.shared.sendChatNotification(
                from: message.senderName,
                message: messageText,
                chatId: chat.id ?? "",
                messageId: message.id ?? ""
            ) { success, error in
            }
        }
        
        let recipients = chat.participants.filter { $0 != message.senderID }
        
        for _ in recipients {
        }
    }
    
    func editMessage(_ messageId: String, newContent: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let message = currentMessages.first(where: { $0.id == messageId }) else {
            completion(.failure(ChatError.messageNotFound))
            return
        }
        
        let updates: [String: Any] = [
            "content": newContent,
            "isEdited": true,
            "editedAt": Date().timeIntervalSince1970 * 1000
        ]
        
        db.child("messages").child(message.chatId).child(messageId).updateChildValues(updates) { error, _ in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
    
    func deleteMessage(_ messageId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let message = currentMessages.first(where: { $0.id == messageId }) else {
            completion(.failure(ChatError.messageNotFound))
            return
        }
        
        guard let currentUserId = Auth.auth().currentUser?.uid,
              message.senderID == currentUserId else {
            completion(.failure(ChatError.noPermission))
            return
        }
        
        let updates: [String: Any] = [
            "isDeleted": true,
            "deletedAt": Date().timeIntervalSince1970 * 1000,
            "content": "Message deleted"
        ]
        
        db.child("messages").child(message.chatId).child(messageId).updateChildValues(updates) { error, _ in
            if let error = error {
                completion(.failure(error))
            } else {
                if let imageURL = message.imageURL, !imageURL.isEmpty {
                    FirebaseStorageService.shared.deleteChatImage(url: imageURL) { _ in
                    }
                }
                completion(.success(()))
            }
        }
    }
    
    func addReaction(to messageId: String, emoji: String, userId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let message = currentMessages.first(where: { $0.id == messageId }) else {
            completion(.failure(ChatError.messageNotFound))
            return
        }
        
        db.child("messages").child(message.chatId).child(messageId).child("reactions").child(emoji).observeSingleEvent(of: .value) { snapshot in
            var currentUsers = snapshot.value as? [String] ?? []
            
            if let index = currentUsers.firstIndex(of: userId) {
                currentUsers.remove(at: index)
            } else {
                currentUsers.append(userId)
            }
            
            if currentUsers.isEmpty {
                self.db.child("messages").child(message.chatId).child(messageId).child("reactions").child(emoji).removeValue { error, _ in
                    completion(error != nil ? .failure(error!) : .success(()))
                }
            } else {
                self.db.child("messages").child(message.chatId).child(messageId).child("reactions").child(emoji).setValue(currentUsers) { error, _ in
                    completion(error != nil ? .failure(error!) : .success(()))
                }
            }
        }
    }
    
    func markMessageAsRead(_ messageId: String, userId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let message = currentMessages.first(where: { $0.id == messageId }) else {
            completion(.failure(ChatError.messageNotFound))
            return
        }
        
        let readTimestamp = Date().timeIntervalSince1970 * 1000
        
        db.child("messages").child(message.chatId).child(messageId).child("readBy").child(userId).setValue(readTimestamp) { error, _ in
            if let error = error {
                completion(.failure(error))
            } else {
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: .chatMarkedAsRead, object: message.chatId)
                }
                completion(.success(()))
            }
        }
    }
    
    func getLastMessage(for chatId: String, completion: @escaping (Message?) -> Void) {
        if let cachedMessages = messageCache[chatId], let lastMessage = cachedMessages.last {
            completion(lastMessage)
            return
        }
        
        db.child("messages").child(chatId)
            .queryOrdered(byChild: "timestamp")
            .queryLimited(toLast: 1)
            .observeSingleEvent(of: .value) { [weak self] snapshot in
                
                guard snapshot.exists() else {
                    completion(nil)
                    return
                }
                
                for child in snapshot.children {
                    guard let childSnapshot = child as? DataSnapshot,
                          let messageData = childSnapshot.value as? [String: Any] else {
                        continue
                    }
                    
                    let isDeleted = messageData["isDeleted"] as? Bool ?? false
                    if !isDeleted {
                        if let message = self?.parseMessage(from: messageData, id: childSnapshot.key) {
                            completion(message)
                            return
                        }
                    }
                }
                
                completion(nil)
            }
    }
    
    func getUnreadMessageCount(for chatId: String, userId: String, completion: @escaping (Int) -> Void) {
        let cacheKey = "\(chatId)_\(userId)"
        
        if let cached = unreadCountCache[cacheKey],
           Date().timeIntervalSince(cached.timestamp) < cacheExpiry {
            completion(cached.count)
            return
        }
        
        let lastReadKey = "lastReadTime_\(chatId)_\(userId)"
        let lastReadTime = UserDefaults.standard.object(forKey: lastReadKey) as? Date ?? Date().addingTimeInterval(-7 * 24 * 60 * 60)
        
        db.child("messages").child(chatId)
            .queryOrdered(byChild: "timestamp")
            .queryStarting(atValue: lastReadTime.timeIntervalSince1970 * 1000)
            .observeSingleEvent(of: .value) { [weak self] snapshot in
                var unreadCount = 0
                
                for child in snapshot.children {
                    guard let childSnapshot = child as? DataSnapshot,
                          let messageData = childSnapshot.value as? [String: Any] else { continue }
                    
                    let isDeleted = messageData["isDeleted"] as? Bool ?? false
                    if !isDeleted {
                        if let senderID = messageData["senderID"] as? String, senderID != userId {
                            if let readByData = messageData["readBy"] as? [String: Any],
                               readByData[userId] == nil {
                                unreadCount += 1
                            } else if messageData["readBy"] == nil {
                                unreadCount += 1
                            }
                        }
                    }
                }
                
                self?.unreadCountCache[cacheKey] = (count: unreadCount, timestamp: Date())
                
                completion(unreadCount)
            }
    }
    
    func startTyping(in chatId: String) {
        guard let currentUserId = Auth.auth().currentUser?.uid,
              let userName = UserService.shared.currentUser?.name else { return }
        
        let now = Date()
        guard now.timeIntervalSince(lastTypingUpdate) >= typingRateLimit else { return }
        lastTypingUpdate = now
        
        currentChatId = chatId
        
        let typingData: [String: Any] = [
            "userId": currentUserId,
            "userName": userName,
            "timestamp": now.timeIntervalSince1970 * 1000,
            "chatId": chatId
        ]
        
        db.child("chats").child(chatId).child("typing").child(currentUserId).setValue(typingData)
    }
    
    func stopTyping(in chatId: String) {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        db.child("chats").child(chatId).child("typing").child(currentUserId).removeValue()
    }
    
    private func startListeningToTyping(for chatId: String) {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        if let listener = typingListener {
            db.child("chats").child(chatId).child("typing").removeObserver(withHandle: listener)
        }
        
        typingListener = db.child("chats").child(chatId).child("typing")
            .observe(.value) { [weak self] snapshot in
                var activeTypingUsers: [String] = []
                
                for child in snapshot.children {
                    guard let childSnapshot = child as? DataSnapshot,
                          let data = childSnapshot.value as? [String: Any] else { continue }
                    
                    if let userId = data["userId"] as? String,
                       let userName = data["userName"] as? String,
                       let timestampValue = data["timestamp"] as? TimeInterval,
                       userId != currentUserId {
                        
                        let timestamp = Date(timeIntervalSince1970: timestampValue / 1000)
                        
                        if Date().timeIntervalSince(timestamp) < 5.0 {
                            activeTypingUsers.append(userName)
                        } else {
                            childSnapshot.ref.removeValue()
                        }
                    }
                }
                
                DispatchQueue.main.async {
                    self?.typingUsers = activeTypingUsers
                }
            }
    }
    
    private func stopListeningToTyping() {
        if let listener = typingListener, let chatId = currentChatId {
            db.child("chats").child(chatId).child("typing").removeObserver(withHandle: listener)
        }
        typingListener = nil
        currentChatId = nil
        
        DispatchQueue.main.async {
            self.typingUsers.removeAll()
        }
    }
    
    private func updateChatLastMessage(chatId: String, message: Message) {
        let lastMessageData: [String: Any] = [
            "id": message.id ?? "",
            "content": message.content,
            "senderID": message.senderID,
            "senderName": message.senderName,
            "timestamp": message.timestamp.timeIntervalSince1970 * 1000,
            "type": message.type.rawValue
        ]
        
        let chatUpdates: [String: Any] = [
            "lastMessage": lastMessageData,
            "updatedAt": Date().timeIntervalSince1970 * 1000
        ]
        
        db.child("chats").child(chatId).updateChildValues(chatUpdates)
    }
    
    func clearMessageCache() {
        messageCache.removeAll()
        unreadCountCache.removeAll()
    }
    
    func clearCacheForChat(_ chatId: String) {
        messageCache.removeValue(forKey: chatId)
        
        let keysToRemove = unreadCountCache.keys.filter { $0.hasPrefix(chatId) }
        for key in keysToRemove {
            unreadCountCache.removeValue(forKey: key)
        }
    }
}

enum ChatError: Error, LocalizedError {
    case notAuthenticated
    case chatNotFound
    case messageNotFound
    case noPermission
    case imageCompressionFailed
    case imageProcessingFailed
    case downloadURLFailed
    case invalidParticipants
    case networkError
    case dataCorrupted
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "User not authenticated"
        case .chatNotFound:
            return "Chat not found"
        case .messageNotFound:
            return "Message not found"
        case .noPermission:
            return "No permission to perform this action"
        case .imageCompressionFailed:
            return "Failed to compress image"
        case .imageProcessingFailed:
            return "Failed to process image"
        case .downloadURLFailed:
            return "Failed to get download URL"
        case .invalidParticipants:
            return "Invalid participants"
        case .networkError:
            return "Network connection error"
        case .dataCorrupted:
            return "Data corrupted or invalid"
        }
    }
}

extension ChatService {
    func createChat(_ chat: Chat, completion: @escaping (Result<Void, Error>) -> Void) {
        guard Auth.auth().currentUser?.uid != nil else {
            completion(.failure(ChatError.notAuthenticated))
            return
        }
        
        if chat.type == .bandWide {
            guard let currentUser = UserService.shared.currentUser,
                  currentUser.role == .admin || currentUser.role == .manager else {
                completion(.failure(ChatError.noPermission))
                return
            }
        }
        
        let chatRef = db.child("chats").childByAutoId()
        let chatId = chatRef.key ?? UUID().uuidString
        
        var chatWithId = chat
        chatWithId.id = chatId
        
        let chatData: [String: Any] = [
            "type": chatWithId.type.rawValue,
            "participants": chatWithId.participants,
            "createdBy": chatWithId.createdBy,
            "createdAt": chatWithId.createdAt.timeIntervalSince1970 * 1000,
            "updatedAt": chatWithId.updatedAt.timeIntervalSince1970 * 1000,
            "name": chatWithId.name ?? NSNull(),
            "description": chatWithId.description ?? NSNull(),
            "imageURL": chatWithId.imageURL ?? NSNull(),
            "isDeleted": chatWithId.isDeleted,
            "bandId": chatWithId.bandId ?? NSNull(),
            "adminIds": chatWithId.adminIds
        ]
        
        chatRef.setValue(chatData) { error, _ in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
    
    func deleteChat(_ chatId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            completion(.failure(ChatError.notAuthenticated))
            return
        }
        
        db.child("chats").child(chatId).observeSingleEvent(of: .value) { [weak self] snapshot in
            guard let chatData = snapshot.value as? [String: Any],
                  let chat = self?.parseChat(from: chatData, id: chatId) else {
                completion(.failure(ChatError.chatNotFound))
                return
            }
            
            guard chat.canUserDelete(currentUserId) else {
                completion(.failure(ChatError.noPermission))
                return
            }
            
            // Step 1: Delete all chat images from Firebase Storage
            self?.deleteChatImages(chatId: chatId) { [weak self] in
                // Step 2: Delete chat and messages from Realtime Database
                self?.db.child("chats").child(chatId).removeValue { error, _ in
                    if let error = error {
                        completion(.failure(error))
                    } else {
                        self?.db.child("messages").child(chatId).removeValue { error, _ in
                            self?.clearCacheForChat(chatId)
                            completion(.success(()))
                        }
                    }
                }
            }
        }
    }
    
    // Helper function to delete all images from a chat
    private func deleteChatImages(chatId: String, completion: @escaping () -> Void) {
        print("🗑️ Collecting images for chat deletion: \(chatId)")
        
        // Get all messages to find images
        db.child("messages").child(chatId).observeSingleEvent(of: .value) { snapshot in
            var imageUrls: [String] = []
            
            if let messagesData = snapshot.value as? [String: Any] {
                for (_, messageData) in messagesData {
                    if let messageDict = messageData as? [String: Any],
                       let imageURL = messageDict["imageURL"] as? String,
                       !imageURL.isEmpty,
                       FirebaseStorageService.isFirebaseStorageURL(imageURL) {
                        imageUrls.append(imageURL)
                    }
                }
            }
            
            guard !imageUrls.isEmpty else {
                print("🗑️ No images to delete for chat: \(chatId)")
                completion()
                return
            }
            
            print("🗑️ Deleting \(imageUrls.count) images from Firebase Storage for chat: \(chatId)")
            
            // Delete all images
            FirebaseStorageService.shared.deleteChatImages(urls: imageUrls) { successCount, failureCount in
                print("🗑️ Chat image deletion complete: \(successCount) deleted, \(failureCount) failed")
                completion()
            }
        }
    }
    
    func searchMessages(in chatId: String, query: String, completion: @escaping ([Message]) -> Void) {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            completion([])
            return
        }
        
        db.child("messages").child(chatId)
            .observeSingleEvent(of: .value) { [weak self] snapshot in
                var foundMessages: [Message] = []
                let searchQuery = query.lowercased()
                
                for child in snapshot.children {
                    guard let childSnapshot = child as? DataSnapshot,
                          let messageData = childSnapshot.value as? [String: Any] else { continue }
                    
                    let isDeleted = messageData["isDeleted"] as? Bool ?? false
                    if !isDeleted {
                        if let message = self?.parseMessage(from: messageData, id: childSnapshot.key) {
                            if message.content.lowercased().contains(searchQuery) {
                                foundMessages.append(message)
                            }
                        }
                    }
                }
                
                foundMessages.sort { $0.timestamp > $1.timestamp }
                completion(foundMessages)
            }
    }
}
