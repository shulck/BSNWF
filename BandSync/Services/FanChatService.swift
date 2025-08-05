import Foundation
import FirebaseDatabase
import FirebaseAuth
import FirebaseFirestore
import UIKit

// MARK: - FAN CHAT SERVICE (SEPARATE FROM MAIN CHAT SYSTEM)

final class FanChatService: ObservableObject {
    static let shared = FanChatService()
    
    private let db = Database.database().reference()
    private let firestore = Firestore.firestore()
    private var chatsListener: DatabaseHandle?
    private var messagesListeners: [String: DatabaseHandle] = [:]
    
    @Published var fanChats: [FanChat] = []
    @Published var currentMessages: [FanMessage] = []
    @Published var isLoading = false
    @Published var typingUsers: [String] = []
    @Published var chatRules: FanChatRules?
    @Published var hasAcceptedRules = false
    
    private(set) var currentChatId: String?
    private var typingListener: DatabaseHandle?
    private var lastTypingUpdate: Date = Date.distantPast
    private let typingRateLimit: TimeInterval = 2.0
    
    private var messageCache: [String: [FanMessage]] = [:]
    private var unreadCountCache: [String: (count: Int, timestamp: Date)] = [:]
    private let cacheExpiry: TimeInterval = 30
    
    // Moderation
    @Published var pendingReports: [FanChatReport] = []
    @Published var bannedUsers: Set<String> = []
    @Published var userWarnings: [String: Int] = [:] // userId -> warning count
    
    private init() {}
    
    // MARK: - Chat Rules Management
    
    func loadChatRules(for groupId: String) {
        firestore.collection("groups").document(groupId).collection("fanChatRules")
            .document("rules")
            .getDocument { [weak self] snapshot, error in
                DispatchQueue.main.async {
                    if let error = error {
                        print("Error loading chat rules: \(error)")
                        // Use default rules if none exist
                        self?.chatRules = FanChatRules.defaultRules(for: groupId)
                        return
                    }
                    
                    if let data = snapshot?.data(),
                       let rulesData = try? JSONSerialization.data(withJSONObject: data),
                       let rules = try? JSONDecoder().decode(FanChatRules.self, from: rulesData) {
                        self?.chatRules = rules
                    } else {
                        // Create default rules
                        self?.chatRules = FanChatRules.defaultRules(for: groupId)
                        self?.saveChatRules(FanChatRules.defaultRules(for: groupId))
                    }
                    
                    // Check if current user has accepted rules
                    self?.checkRulesAcceptance(for: groupId)
                }
            }
    }
    
    private func saveChatRules(_ rules: FanChatRules) {
        guard let rulesData = try? JSONEncoder().encode(rules),
              let rulesDict = try? JSONSerialization.jsonObject(with: rulesData) as? [String: Any] else {
            return
        }
        
        firestore.collection("groups").document(rules.groupId).collection("fanChatRules")
            .document("rules")
            .setData(rulesDict)
    }
    
    private func checkRulesAcceptance(for groupId: String) {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        firestore.collection("groups").document(groupId).collection("fanChatRules")
            .document("acceptances")
            .getDocument { [weak self] snapshot, error in
                DispatchQueue.main.async {
                    if let data = snapshot?.data(),
                       let acceptanceDate = data[currentUserId] as? Timestamp {
                        self?.hasAcceptedRules = true
                    } else {
                        self?.hasAcceptedRules = false
                    }
                }
            }
    }
    
    func acceptChatRules(for groupId: String) {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        firestore.collection("groups").document(groupId).collection("fanChatRules")
            .document("acceptances")
            .setData([currentUserId: Timestamp()], merge: true) { [weak self] error in
                DispatchQueue.main.async {
                    if error == nil {
                        self?.hasAcceptedRules = true
                    }
                }
            }
    }
    
    // MARK: - Chat Management
    
    func startListeningToFanChats(for groupId: String) {
        guard let currentUserId = Auth.auth().currentUser?.uid else { 
            print("❌ Cannot start listening to fan chats: no current user")
            return 
        }
        
        print("🎧 Starting to listen for fan chats in group: \(groupId) for user: \(currentUserId)")
        
        stopListeningToFanChats()
        isLoading = true
        isListening = true
        
        // Use single event listener that refreshes less frequently to avoid loops
        loadFanChatsWithDebounce(for: groupId, currentUserId: currentUserId)
    }
    
    private var lastLoadTime: Date = Date.distantPast
    private let loadDebounceInterval: TimeInterval = 5.0 // Minimum 5 seconds between loads
    private var isListening = false // Flag to control periodic updates
    
    private func loadFanChatsWithDebounce(for groupId: String, currentUserId: String) {
        let now = Date()
        
        // Only load if enough time has passed since last load
        if now.timeIntervalSince(lastLoadTime) < loadDebounceInterval {
            print("🔄 Skipping fan chats load - too soon since last load")
            return
        }
        
        lastLoadTime = now
        
        db.child("fanChats").child(groupId)
            .queryOrdered(byChild: "updatedAt")
            .observeSingleEvent(of: .value) { [weak self] snapshot in
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.processFanChatsSnapshot(snapshot, currentUserId: currentUserId, groupId: groupId)
                }
            }
        
        // Set up a timer to refresh periodically only if still listening
        if isListening {
            DispatchQueue.main.asyncAfter(deadline: .now() + 30) { [weak self] in
                guard let self = self, self.isListening else { return }
                self.loadFanChatsWithDebounce(for: groupId, currentUserId: currentUserId)
            }
        }
    }
    
    private func processFanChatsSnapshot(_ snapshot: DataSnapshot, currentUserId: String, groupId: String) {
        var chats: [FanChat] = []
        
        for child in snapshot.children {
            guard let childSnapshot = child as? DataSnapshot,
                  let chatData = childSnapshot.value as? [String: Any],
                  let chatId = childSnapshot.key as String? else {
                continue
            }
            
            // Parse chat data
            if let chat = self.parseFanChatData(chatData, id: chatId) {
                // Include chat if:
                // 1. For private chats: user is participant
                // 2. For themed/general/mixed chats: user is in the same group (accessible to all fans)
                let shouldInclude = chat.isActive && !chat.isDeleted && (
                    chat.participants.contains(currentUserId) || // User is direct participant
                    (chat.type != FanChat.FanChatType.privateChat && chat.groupId == groupId) // Public chat in user's group
                )
                
                if shouldInclude {
                    chats.append(chat)
                }
            }
        }
        
        self.fanChats = chats.sorted { chat1, chat2 in
            let time1 = chat1.lastMessage?.timestamp ?? Date.distantPast
            let time2 = chat2.lastMessage?.timestamp ?? Date.distantPast
            return time1 > time2
        }
    }
    
    func stopListeningToFanChats() {
        isListening = false
        if let listener = chatsListener {
            db.removeObserver(withHandle: listener)
            chatsListener = nil
        }
    }
    
    private func parseFanChatData(_ data: [String: Any], id: String) -> FanChat? {
        guard let typeString = data["type"] as? String,
              let type = FanChat.FanChatType(rawValue: typeString),
              let createdBy = data["createdBy"] as? String,
              let createdAtTimestamp = data["createdAt"] as? TimeInterval,
              let updatedAtTimestamp = data["updatedAt"] as? TimeInterval,
              let groupId = data["groupId"] as? String else {
            print("❌ Missing required fields for chat \(id)")
            return nil
        }
        
        // Participants can be empty for some chat types (like themed chats)
        let participants = data["participants"] as? [String] ?? []
        let participantNames = data["participantNames"] as? [String: String] ?? [:]
        let participantAvatars = data["participantAvatars"] as? [String: String] ?? [:]
        let createdAt = Date(timeIntervalSince1970: createdAtTimestamp / 1000)
        let updatedAt = Date(timeIntervalSince1970: updatedAtTimestamp / 1000)
        
        var lastMessage: FanChat.FanLastMessage?
        if let lastMsgData = data["lastMessage"] as? [String: Any] {
            lastMessage = parseLastMessage(lastMsgData)
        }
        
        return FanChat(
            id: id,
            type: type,
            participants: participants,
            participantNames: participantNames,
            participantAvatars: participantAvatars,
            createdBy: createdBy,
            createdAt: createdAt,
            updatedAt: updatedAt,
            name: data["name"] as? String,
            description: data["description"] as? String,
            lastMessage: lastMessage,
            isDeleted: data["isDeleted"] as? Bool ?? false,
            groupId: groupId,
            moderatorIds: data["moderatorIds"] as? [String] ?? [],
            isActive: data["isActive"] as? Bool ?? true,
            chatRulesAccepted: data["chatRulesAccepted"] as? [String: Date] ?? [:]
        )
    }
    
    private func parseLastMessage(_ data: [String: Any]) -> FanChat.FanLastMessage? {
        guard let id = data["id"] as? String,
              let content = data["content"] as? String,
              let senderID = data["senderID"] as? String,
              let senderName = data["senderName"] as? String,
              let timestampValue = data["timestamp"] as? TimeInterval,
              let typeString = data["type"] as? String,
              let type = FanChat.FanLastMessage.FanMessageType(rawValue: typeString) else {
            return nil
        }
        
        let timestamp = Date(timeIntervalSince1970: timestampValue / 1000)
        return FanChat.FanLastMessage(id: id, content: content, senderID: senderID, senderName: senderName, timestamp: timestamp, type: type)
    }
    
    // MARK: - Message Management
    
    func startListeningToMessages(for chatId: String) {
        print("🎧 Starting to listen for messages in chat: \(chatId)")
        print("🔄 Previous currentChatId: \(currentChatId ?? "none"), switching to: \(chatId)")
        currentChatId = chatId
        
        // Clear current messages when switching chats
        DispatchQueue.main.async {
            self.currentMessages = []
            print("🧹 Cleared currentMessages for new chat")
        }
        
        // Stop previous listener
        if let listener = messagesListeners[chatId] {
            db.removeObserver(withHandle: listener)
            print("🔇 Stopped previous listener for chat: \(chatId)")
        }
        
        // Check cache first
        if let cachedMessages = messageCache[chatId] {
            print("📦 Using cached messages: \(cachedMessages.count) messages")
            DispatchQueue.main.async {
                self.currentMessages = cachedMessages
                print("📋 Set currentMessages from cache: \(cachedMessages.count) messages")
            }
        } else {
            print("🆕 No cached messages, starting fresh")
        }
        
        print("📡 Setting up Firebase listener for path: fanMessages/\(chatId)")
        
        messagesListeners[chatId] = db.child("fanMessages").child(chatId)
            .queryOrdered(byChild: "timestamp")
            .queryLimited(toLast: 100)
            .observe(.value) { [weak self] snapshot in
                guard let self = self else { return }
                
                print("📥 Received message data from Firebase. Children count: \(snapshot.childrenCount)")
                
                var messages: [FanMessage] = []
                
                for child in snapshot.children {
                    guard let childSnapshot = child as? DataSnapshot,
                          let messageData = childSnapshot.value as? [String: Any],
                          let messageId = childSnapshot.key as String? else {
                        continue
                    }
                    
                    print("📄 Processing message \(messageId): \(messageData)")
                    
                    if let message = self.parseFanMessageData(messageData, id: messageId) {
                        // Only show visible messages (not deleted or moderated)
                        if message.isVisible {
                            messages.append(message)
                        }
                    }
                }
                
                print("✅ Parsed \(messages.count) visible messages")
                
                DispatchQueue.main.async {
                    self.currentMessages = messages.sorted { $0.timestamp < $1.timestamp }
                    self.messageCache[chatId] = self.currentMessages
                    print("🔄 Updated currentMessages with \(self.currentMessages.count) messages")
                }
            }
        }
    
    private func parseFanMessageData(_ data: [String: Any], id: String) -> FanMessage? {
        guard let chatId = data["chatId"] as? String,
              let senderID = data["senderID"] as? String,
              let senderName = data["senderName"] as? String,
              let content = data["content"] as? String,
              let timestampValue = data["timestamp"] as? TimeInterval,
              let typeString = data["type"] as? String,
              let type = FanMessage.MessageType(rawValue: typeString) else {
            return nil
        }
        
        let timestamp = Date(timeIntervalSince1970: timestampValue / 1000)
        
        return FanMessage(
            id: id,
            chatId: chatId,
            senderID: senderID,
            senderName: senderName,
            senderNickname: data["senderNickname"] as? String,
            content: content,
            originalContent: data["originalContent"] as? String,
            timestamp: timestamp,
            type: type,
            isDeleted: data["isDeleted"] as? Bool ?? false,
            editedAt: (data["editedAt"] as? TimeInterval).map { Date(timeIntervalSince1970: $0 / 1000) },
            reportedBy: data["reportedBy"] as? [String] ?? [],
            isModerated: data["isModerated"] as? Bool ?? false,
            moderatedBy: data["moderatedBy"] as? String,
            moderatedAt: (data["moderatedAt"] as? TimeInterval).map { Date(timeIntervalSince1970: $0 / 1000) },
            moderationReason: data["moderationReason"] as? String
        )
    }
    
    // MARK: - Send Message
    
    func sendMessage(_ content: String, to chatId: String, type: FanMessage.MessageType = .text) {
        guard let currentUser = AppState.shared.user else {
            print("❌ Cannot send message: no current user")
            return
        }
        
        guard !bannedUsers.contains(currentUser.id) else {
            print("❌ Cannot send message: user is banned")
            return
        }
        
        print("📨 Sending message from \(currentUser.name) to chat \(chatId)")
        
        // Content validation - only text allowed
        let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedContent.isEmpty && trimmedContent.count <= 500 else {
            print("❌ Message validation failed: empty or too long")
            return
        }
        
        // Spam check
        if isSpamming(userId: currentUser.id) {
            print("❌ Message blocked: spam detected")
            return
        }
        
        let messageId = db.child("fanMessages").child(chatId).childByAutoId().key ?? UUID().uuidString
        
        // Use fan profile nickname if available, otherwise use display name
        let senderNickname = currentUser.fanProfile?.nickname ?? currentUser.name
        
        let message = FanMessage(
            id: messageId,
            chatId: chatId,
            senderID: currentUser.id,
            senderName: currentUser.name,
            senderNickname: senderNickname,
            content: trimmedContent,
            type: type
        )
        
        print("💬 Message data prepared: \(message)")
        
        let messageData: [String: Any] = [
            "chatId": message.chatId,
            "senderID": message.senderID,
            "senderName": message.senderName,
            "senderNickname": message.senderNickname ?? "",
            "content": message.content,
            "originalContent": message.originalContent as Any,
            "timestamp": message.timestamp.timeIntervalSince1970 * 1000,
            "type": message.type.rawValue,
            "isDeleted": message.isDeleted,
            "editedAt": message.editedAt != nil ? message.editedAt!.timeIntervalSince1970 * 1000 : NSNull(),
            "reportedBy": message.reportedBy,
            "isModerated": message.isModerated,
            "moderatedBy": message.moderatedBy ?? NSNull(),
            "moderatedAt": message.moderatedAt != nil ? message.moderatedAt!.timeIntervalSince1970 * 1000 : NSNull(),
            "moderationReason": message.moderationReason as Any
        ]
        
        print("💾 Saving message to path: fanMessages/\(chatId)/\(messageId)")
        print("📄 Message data: \(messageData)")
        
        // Save message
        db.child("fanMessages").child(chatId).child(messageId).setValue(messageData) { [weak self] error, ref in
            if let error = error {
                print("❌ Error saving message: \(error.localizedDescription)")
            } else {
                print("✅ Message saved successfully to: \(ref.url)")
                
                // Update participant names in chat if not already present
                self?.updateParticipantNames(for: chatId, userId: currentUser.id, userName: senderNickname)
            }
        }
        
        // Update chat's last message
        updateLastMessage(for: chatId, message: message)
    }
    
    private func updateParticipantNames(for chatId: String, userId: String, userName: String) {
        guard let chat = fanChats.first(where: { $0.id == chatId }),
              chat.participantNames[userId] == nil else { 
            return // Already has name for this user
        }
        
        let groupId = chat.groupId
        let participantNamesRef = db.child("fanChats").child(groupId).child(chatId).child("participantNames")
        
        participantNamesRef.child(userId).setValue(userName) { error, _ in
            if let error = error {
                print("❌ Error updating participant names: \(error)")
            } else {
                print("✅ Updated participant name for \(userId): \(userName)")
                
                // Update local data
                if let index = self.fanChats.firstIndex(where: { $0.id == chatId }) {
                    self.fanChats[index].participantNames[userId] = userName
                }
            }
        }
    }
    
    private func updateLastMessage(for chatId: String, message: FanMessage) {
        guard let groupId = fanChats.first(where: { $0.id == chatId })?.groupId else { return }
        
        let lastMessageData: [String: Any] = [
            "id": message.id ?? "",
            "content": message.content,
            "senderID": message.senderID,
            "senderName": message.displayName,
            "timestamp": message.timestamp.timeIntervalSince1970 * 1000,
            "type": message.type.rawValue
        ]
        
        db.child("fanChats").child(groupId).child(chatId).child("lastMessage").setValue(lastMessageData)
        db.child("fanChats").child(groupId).child(chatId).child("updatedAt").setValue(Date().timeIntervalSince1970 * 1000)
    }
    
    // MARK: - Spam Protection
    
    private var lastMessageTimes: [String: [Date]] = [:]
    
    private func isSpamming(userId: String) -> Bool {
        let now = Date()
        let timeWindow: TimeInterval = 60 // 1 minute
        let maxMessages = 10 // Max 10 messages per minute
        
        if lastMessageTimes[userId] == nil {
            lastMessageTimes[userId] = []
        }
        
        // Remove old timestamps
        lastMessageTimes[userId] = lastMessageTimes[userId]?.filter { now.timeIntervalSince($0) < timeWindow } ?? []
        
        // Check if limit exceeded
        if (lastMessageTimes[userId]?.count ?? 0) >= maxMessages {
            return true
        }
        
        // Add current timestamp
        lastMessageTimes[userId]?.append(now)
        return false
    }
    
    // MARK: - Moderation
    
    func reportMessage(_ messageId: String, in chatId: String, reason: FanChatReport.ReportReason, description: String?) {
        guard let currentUserId = Auth.auth().currentUser?.uid,
              let message = currentMessages.first(where: { $0.id == messageId }),
              message.canUserReport(currentUserId) else {
            return
        }
        
        let reportId = UUID().uuidString
        let report = FanChatReport(
            id: reportId,
            chatId: chatId,
            messageId: messageId,
            reportedUserId: message.senderID,
            reporterUserId: currentUserId,
            reason: reason,
            description: description,
            timestamp: Date()
        )
        
        // Save report to Firebase
        if let reportData = try? JSONEncoder().encode(report),
           let reportDict = try? JSONSerialization.jsonObject(with: reportData) as? [String: Any] {
            
            firestore.collection("fanChatReports").document(reportId).setData(reportDict)
            
            // Update message to mark as reported
            db.child("fanMessages").child(chatId).child(messageId).child("reportedBy").setValue(message.reportedBy + [currentUserId])
        }
    }
    
    func banUser(_ userId: String, temporarily: Bool = false, duration: TimeInterval = 24 * 60 * 60) {
        bannedUsers.insert(userId)
        
        // TODO: Implement ban expiration for temporary bans
        // For now, all bans are permanent until manually removed
    }
    
    func unbanUser(_ userId: String) {
        bannedUsers.remove(userId)
    }
    
    func warnUser(_ userId: String) {
        userWarnings[userId] = (userWarnings[userId] ?? 0) + 1
        
        // Auto-ban after 3 warnings
        if (userWarnings[userId] ?? 0) >= 3 {
            banUser(userId, temporarily: true)
        }
    }
    
    // MARK: - Chat Creation
    
    func createGeneralChat(for groupId: String) {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        let chatId = "general_\(groupId)"
        let now = Date()
        
        let chat = FanChat(
            id: chatId,
            type: .general,
            participants: [], // Will be populated with all fans
            createdBy: currentUserId,
            createdAt: now,
            updatedAt: now,
            name: "Fan Community",
            description: "General chat for all fans",
            groupId: groupId,
            isActive: true
        )
        
        saveFanChat(chat)
    }
    
    func createPrivateChat(with fanUserId: String, groupId: String) {
        guard let currentUserId = Auth.auth().currentUser?.uid,
              currentUserId != fanUserId else { 
            print("❌ Invalid user IDs for private chat creation")
            return 
        }
        
        guard let currentUser = AppState.shared.user else {
            print("❌ No current user for chat creation")
            return
        }
        
        print("🔍 Creating private chat between \(currentUserId) and \(fanUserId)")
        
        let chatId = [currentUserId, fanUserId].sorted().joined(separator: "_")
        print("💬 Generated chat ID: \(chatId)")
        
        let existingChat = fanChats.first { $0.type == .privateChat && $0.participants.sorted() == [currentUserId, fanUserId].sorted() }
        
        if existingChat != nil {
            print("⚠️ Private chat already exists")
            return // Chat already exists
        }
        
        // Get the fan user's name from Firebase
        Firestore.firestore().collection("users").document(fanUserId).getDocument { [weak self] document, error in
            guard let self = self else { return }
            
            var otherUserName = "Fan"
            var otherUserAvatar = ""
            if let document = document, document.exists,
               let userData = document.data() {
                // Try to get displayName (nickname for fans, name for others)
                if let userType = userData["userType"] as? String, userType == "Fan",
                   let fanProfileData = userData["fanProfile"] as? [String: Any],
                   let nickname = fanProfileData["nickname"] as? String {
                    otherUserName = nickname
                    print("👤 Found fan nickname: \(nickname)")
                } else if let name = userData["name"] as? String {
                    otherUserName = name
                    print("👤 Found user name: \(name)")
                } else {
                    print("⚠️ Could not find name for fan, using default")
                }
                
                // Get avatar URL
                if let avatarURL = userData["avatarURL"] as? String {
                    otherUserAvatar = avatarURL
                    print("🖼️ Found fan avatar: \(avatarURL)")
                }
            } else {
                print("⚠️ Could not find fan document, using default")
            }
            
            // Create participant names and avatars maps
            let participantNames: [String: String] = [
                currentUserId: currentUser.displayName,
                fanUserId: otherUserName
            ]
            
            let participantAvatars: [String: String] = [
                currentUserId: currentUser.avatarURL ?? "",
                fanUserId: otherUserAvatar
            ]
            
            print("👥 Participant names: \(participantNames)")
            print("🖼️ Participant avatars: \(participantAvatars)")
            
            let now = Date()
            let chat = FanChat(
                id: chatId,
                type: .privateChat,
                participants: [currentUserId, fanUserId],
                participantNames: participantNames,
                participantAvatars: participantAvatars,
                createdBy: currentUserId,
                createdAt: now,
                updatedAt: now,
                groupId: groupId,
                isActive: true
                )
        
            print("💾 Saving private chat to Firebase...")
            self.saveFanChat(chat)
        }
    }
    
    func createThemedChat(name: String, description: String?, groupId: String) {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        // Verify user can create themed chats
        canUserCreateThemedChats(userId: currentUserId) { [weak self] canCreate in
            guard canCreate else {
                print("User does not have permission to create themed chats")
                return
            }
            
            let chatId = "themed_\(UUID().uuidString)"
            let now = Date()
            
            let chat = FanChat(
                id: chatId,
                type: .themed,
                participants: [], // Will be populated as users join
                createdBy: currentUserId,
                createdAt: now,
                updatedAt: now,
                name: name,
                description: description,
                groupId: groupId,
                moderatorIds: [currentUserId], // Creator is automatically a moderator
                isActive: true
            )
            
            self?.saveFanChat(chat)
            
            // Log admin action
            self?.logAdminAction(
                action: "create_themed_chat", 
                targetUserId: currentUserId, 
                chatId: chatId, 
                details: "Created themed chat: \(name)"
            )
        }
    }
    
    // MARK: - Chat Deletion
    
    func deleteFanChat(_ chat: FanChat) {
        guard let currentUserId = Auth.auth().currentUser?.uid,
              let chatId = chat.id else { return }
        
        // Check if user can delete this chat
        let canDelete = chat.createdBy == currentUserId || isMainAppAdmin()
        
        guard canDelete else {
            print("❌ User \(currentUserId) cannot delete chat \(chatId) - not creator or admin")
            return
        }
        
        print("🗑️ Deleting fan chat: \(chatId)")
        
        // Mark chat as deleted instead of actually removing it (for audit purposes)
        var updatedChat = chat
        updatedChat.isDeleted = true
        updatedChat.updatedAt = Date()
        
        // Save updated chat
        saveFanChat(updatedChat)
        
        // Remove from local array
        fanChats.removeAll { $0.id == chatId }
        
        print("✅ Chat \(chatId) marked as deleted and removed from local array")
    }
    
    // MARK: - NEW: Fan Announcement Methods
    
    func sendAnnouncementToFans(title: String, message: String, isImportant: Bool, groupId: String) {
        guard let currentUser = AppState.shared.user else { return }
        
        // Get or create announcement chat
        let announcementChatId = "announcements_\(groupId)"
        
        // Check if announcement chat exists, create if not
        if !fanChats.contains(where: { $0.id == announcementChatId }) {
            createAnnouncementChat(for: groupId)
        }
        
        // Send announcement message
        let messageId = db.child("fanMessages").child(announcementChatId).childByAutoId().key ?? UUID().uuidString
        
        let announcementMessage = FanMessage(
            id: messageId,
            chatId: announcementChatId,
            senderID: currentUser.id,
            senderName: currentUser.name,
            senderNickname: "Band",
            content: message,
            type: .announcement
        )
        
        let messageData: [String: Any] = [
            "chatId": announcementMessage.chatId,
            "senderID": announcementMessage.senderID,
            "senderName": announcementMessage.senderName,
            "senderNickname": announcementMessage.senderNickname ?? "",
            "content": announcementMessage.content,
            "timestamp": announcementMessage.timestamp.timeIntervalSince1970 * 1000,
            "type": announcementMessage.type.rawValue,
            "isDeleted": announcementMessage.isDeleted,
            "isImportant": isImportant
        ]
        
        // Save message
        db.child("fanMessages").child(announcementChatId).child(messageId).setValue(messageData)
        
        // Update chat's last message
        updateLastMessage(for: announcementChatId, message: announcementMessage)
        
        // TODO: Send push notification if important
        if isImportant {
            // Implement push notification logic
        }
    }
    
    private func createAnnouncementChat(for groupId: String) {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        let chatId = "announcements_\(groupId)"
        let now = Date()
        
        let chat = FanChat(
            id: chatId,
            type: .announcement,
            participants: [], // All fans will be auto-added
            createdBy: currentUserId,
            createdAt: now,
            updatedAt: now,
            name: "Band Announcements",
            description: "Official announcements from the band",
            groupId: groupId,
            isActive: true
        )
        
        saveFanChat(chat)
    }
    
    // MARK: - NEW: Mixed Chat Methods
    
    func createMixedChat(name: String, description: String?, participants: [String], groupId: String) {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        let chatId = "mixed_\(UUID().uuidString)"
        let now = Date()
        
        let chat = FanChat(
            id: chatId,
            type: .mixed,
            participants: participants,
            createdBy: currentUserId,
            createdAt: now,
            updatedAt: now,
            name: name,
            description: description,
            groupId: groupId,
            moderatorIds: [currentUserId], // Creator is moderator
            isActive: true
        )
        
        saveFanChat(chat)
    }
    
    func toggleMixedChatStatus(chatId: String, isActive: Bool) {
        guard let chat = fanChats.first(where: { $0.id == chatId }),
              chat.type == .mixed else { return }
        
        db.child("fanChats").child(chat.groupId).child(chatId).child("isActive").setValue(isActive)
    }
    
    private func saveFanChat(_ chat: FanChat) {
        guard let chatId = chat.id else { 
            print("❌ Cannot save chat: no chat ID")
            return 
        }
        
        print("💾 Saving fan chat to path: fanChats/\(chat.groupId)/\(chatId)")
        
        let chatData: [String: Any] = [
            "type": chat.type.rawValue,
            "participants": chat.participants,
            "participantNames": chat.participantNames,
            "participantAvatars": chat.participantAvatars,
            "createdBy": chat.createdBy,
            "createdAt": chat.createdAt.timeIntervalSince1970 * 1000,
            "updatedAt": chat.updatedAt.timeIntervalSince1970 * 1000,
            "name": chat.name ?? "",
            "description": chat.description ?? "",
            "isDeleted": chat.isDeleted,
            "groupId": chat.groupId,
            "moderatorIds": chat.moderatorIds,
            "isActive": chat.isActive,
            "chatRulesAccepted": chat.chatRulesAccepted
        ]
        
        print("📄 Chat data: \(chatData)")
        
        db.child("fanChats").child(chat.groupId).child(chatId).setValue(chatData) { error, ref in
            if let error = error {
                print("❌ Error saving fan chat: \(error.localizedDescription)")
            } else {
                print("✅ Fan chat saved successfully to: \(ref.url)")
            }
        }
    }
    
    // MARK: - Cleanup
    
    deinit {
        stopListeningToFanChats()
        for (_, handle) in messagesListeners {
            db.removeObserver(withHandle: handle)
        }
    }
    
    // MARK: - Moderator Functions
    
    /// Check if user is moderator of specific chat or global moderator
    func isUserModerator(userId: String, chatId: String) -> Bool {
        // Check if user is main app admin
        if isMainAppAdmin() {
            return true
        }
        
        // Check if user is moderator of this specific chat
        if let chat = fanChats.first(where: { $0.id == chatId }) {
            if chat.moderatorIds.contains(userId) || chat.createdBy == userId {
                return true
            }
        }
        
        // TODO: Check if user is global fan chat moderator (async check needed)
        return false
    }
    
    /// Delete message (moderator action)
    func moderatorDeleteMessage(_ messageId: String, in chatId: String, reason: String) async {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        // Check if user has moderation rights
        guard isUserModerator(userId: currentUserId, chatId: chatId) else {
            print("❌ User \(currentUserId) cannot delete message - not a moderator")
            return
        }
        
        print("🗑️ Moderator deleting message \(messageId) in chat \(chatId)")
        
        let messageRef = db.child("fanMessages").child(chatId).child(messageId)
        
        // First get the message to identify the sender
        await withCheckedContinuation { continuation in
            messageRef.observeSingleEvent(of: .value) { [weak self] snapshot in
                guard let self = self,
                      let messageData = snapshot.value as? [String: Any],
                      let senderID = messageData["senderID"] as? String else {
                    print("❌ Could not fetch message data for moderation")
                    continuation.resume()
                    return
                }
                
                // Mark message as moderated instead of deleting
                let moderationData: [String: Any] = [
                    "isModerated": true,
                    "moderatedBy": currentUserId,
                    "moderatedAt": Date().timeIntervalSince1970 * 1000,
                    "moderationReason": reason,
                    "updatedAt": Date().timeIntervalSince1970 * 1000
                ]
                
                messageRef.updateChildValues(moderationData) { error, _ in
                    if let error = error {
                        print("❌ Error moderating message: \(error)")
                    } else {
                        print("✅ Message \(messageId) moderated successfully")
                        
                        // Log moderation action with correct sender ID
                        self.logModerationAction(
                            action: "delete_message",
                            targetUserId: senderID,
                            chatId: chatId,
                            messageId: messageId,
                            reason: reason
                        )
                    }
                    continuation.resume()
                }
            }
        }
    }
    
    /// Hide/Show message (moderator action)
    func moderatorToggleMessageVisibility(_ messageId: String, in chatId: String, hide: Bool, reason: String?) {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        guard isUserModerator(userId: currentUserId, chatId: chatId) else {
            print("❌ User \(currentUserId) cannot moderate message - not a moderator")
            return
        }
        
        let messageRef = db.child("fanMessages").child(chatId).child(messageId)
        
        // First get the message to identify the sender
        messageRef.observeSingleEvent(of: .value) { [weak self] snapshot in
            guard let self = self,
                  let messageData = snapshot.value as? [String: Any],
                  let senderID = messageData["senderID"] as? String else {
                print("❌ Could not fetch message data for moderation")
                return
            }
            
            let moderationData: [String: Any] = [
                "isModerated": hide,
                "moderatedBy": hide ? currentUserId : NSNull(),
                "moderatedAt": hide ? Date().timeIntervalSince1970 * 1000 : NSNull(),
                "moderationReason": reason ?? NSNull(),
                "updatedAt": Date().timeIntervalSince1970 * 1000
            ]
            
            messageRef.updateChildValues(moderationData) { error, _ in
                if let error = error {
                    print("❌ Error moderating message: \(error)")
                } else {
                    print("✅ Message \(messageId) \(hide ? "hidden" : "shown") successfully")
                    
                    self.logModerationAction(
                        action: hide ? "hide_message" : "show_message",
                        targetUserId: senderID,
                        chatId: chatId,
                        messageId: messageId,
                        reason: reason ?? "No reason provided"
                    )
                }
            }
        }
    }
    
    /// Warn user (moderator action)
    func moderatorWarnUser(_ userId: String, in chatId: String, reason: String) async {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        guard isUserModerator(userId: currentUserId, chatId: chatId) else {
            print("❌ User \(currentUserId) cannot warn user - not a moderator")
            return
        }
        
        // Increment warning count
        userWarnings[userId] = (userWarnings[userId] ?? 0) + 1
        let warningCount = userWarnings[userId] ?? 1
        
        // Send warning message to chat
        let warningMessage = "⚠️ User has been warned by moderator. Reason: \(reason) (Warning \(warningCount)/3)"
        
        sendMessage(warningMessage, to: chatId, type: .system)
        
        // Auto-ban after 3 warnings
        if warningCount >= 3 {
            await moderatorBanUserFromChat(userId, from: chatId, reason: "Exceeded maximum warnings (3)", temporarily: true, duration: 24 * 60 * 60)
        }
        
        // Log warning
        logModerationAction(
            action: "warn_user",
            targetUserId: userId,
            chatId: chatId,
            messageId: nil,
            reason: reason
        )
        
        print("⚠️ User \(userId) warned in chat \(chatId). Warning count: \(warningCount)")
    }
    
    /// Ban user from specific chat (moderator action)
    func moderatorBanUserFromChat(_ userId: String, from chatId: String, reason: String, temporarily: Bool = false, duration: TimeInterval = 24 * 60 * 60) async {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        guard isUserModerator(userId: currentUserId, chatId: chatId) else {
            print("❌ User \(currentUserId) cannot ban user - not a moderator")
            return
        }
        
        // Add to banned users
        await MainActor.run {
            bannedUsers.insert(userId)
        }
        
        // Remove user from chat participants
        if let chatIndex = fanChats.firstIndex(where: { $0.id == chatId }) {
            await MainActor.run {
                fanChats[chatIndex].participants.removeAll { $0 == userId }
            }
            
            // Update Firebase
            let chatRef = db.child("fanChats").child(fanChats[chatIndex].groupId).child(chatId)
            await withCheckedContinuation { continuation in
                chatRef.child("participants").setValue(fanChats[chatIndex].participants) { _, _ in
                    continuation.resume()
                }
            }
        }
        
        // Send ban notification to chat
        let banMessage = temporarily ? 
            "🚫 User has been temporarily banned from this chat for \(Int(duration/3600)) hours. Reason: \(reason)" :
            "🚫 User has been permanently banned from this chat. Reason: \(reason)"
        
        sendMessage(banMessage, to: chatId, type: .system)
        
        // Log ban action
        logModerationAction(
            action: temporarily ? "temp_ban_user" : "ban_user",
            targetUserId: userId,
            chatId: chatId,
            messageId: nil,
            reason: reason
        )
        
        // Handle temporary ban expiration
        if temporarily {
            Task {
                try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
                await moderatorUnbanUserFromChat(userId, from: chatId, reason: "Temporary ban expired")
            }
        }
        
        print("🚫 User \(userId) banned from chat \(chatId) for reason: \(reason)")
    }
    
    /// Unban user from specific chat (moderator action)
    func moderatorUnbanUserFromChat(_ userId: String, from chatId: String, reason: String) async {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        guard isUserModerator(userId: currentUserId, chatId: chatId) else {
            print("❌ User \(currentUserId) cannot unban user - not a moderator")
            return
        }
        
        // Remove from banned users
        await MainActor.run {
            bannedUsers.remove(userId)
            // Reset warning count
            userWarnings[userId] = 0
        }
        
        // Send unban notification
        let unbanMessage = "✅ User has been unbanned from this chat. Reason: \(reason)"
        sendMessage(unbanMessage, to: chatId, type: .system)
        
        // Log unban action
        logModerationAction(
            action: "unban_user",
            targetUserId: userId,
            chatId: chatId,
            messageId: nil,
            reason: reason
        )
        
        print("✅ User \(userId) unbanned from chat \(chatId)")
    }
    
    /// Mute user in specific chat (moderator action)
    func moderatorMuteUser(_ userId: String, in chatId: String, duration: TimeInterval, reason: String) async {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        guard isUserModerator(userId: currentUserId, chatId: chatId) else {
            print("❌ User \(currentUserId) cannot mute user - not a moderator")
            return
        }
        
        // Add to banned users temporarily for mute functionality
        await MainActor.run {
            bannedUsers.insert(userId)
        }
        
        let muteMessage = "🔇 User has been muted for \(Int(duration/60)) minutes. Reason: \(reason)"
        sendMessage(muteMessage, to: chatId, type: .system)
        
        // Auto-unmute after duration
        Task {
            try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
            await MainActor.run {
                self.bannedUsers.remove(userId)
            }
            let unmuteMessage = "🔊 User has been automatically unmuted."
            self.sendMessage(unmuteMessage, to: chatId, type: .system)
        }
        
        logModerationAction(
            action: "mute_user",
            targetUserId: userId,
            chatId: chatId,
            messageId: nil,
            reason: reason
        )
        
        print("🔇 User \(userId) muted in chat \(chatId) for \(duration) seconds")
    }
    
    /// Get moderation history for a chat
    func getModerationHistory(for chatId: String) async -> [ModerationLog] {
        print("🔍 Fetching moderation history for chat: \(chatId)")
        return await withCheckedContinuation { continuation in
            firestore.collection("fanChatModerationLogs")
                .whereField("chatId", isEqualTo: chatId)
                .limit(to: 50)
                .getDocuments { snapshot, error in
                    if let error = error {
                        print("❌ Error fetching moderation history: \(error)")
                        continuation.resume(returning: [])
                        return
                    }
                    
                    print("📊 Found \(snapshot?.documents.count ?? 0) moderation log documents")
                    var logs: [ModerationLog] = []
                    
                    for document in snapshot?.documents ?? [] {
                        print("🔍 Processing document: \(document.documentID)")
                        print("📄 Document data: \(document.data())")
                        
                        do {
                            let log = try document.data(as: ModerationLog.self)
                            logs.append(log)
                            print("✅ Successfully parsed moderation log: \(log.action)")
                        } catch {
                            print("❌ Error parsing moderation log: \(error)")
                        }
                    }
                    
                    print("✅ Successfully parsed \(logs.count) moderation logs")
                    continuation.resume(returning: logs)
                }
        }
    }
    
    /// Clear moderation history for a specific chat
    func clearModerationHistory(for chatId: String) async -> Bool {
        print("🧹 Clearing moderation history for chat: \(chatId)")
        
        guard let currentUser = AppState.shared.user else {
            print("❌ Cannot clear moderation history - no current user")
            return false
        }
        
        return await withCheckedContinuation { continuation in
            // First get all documents to delete
            firestore.collection("fanChatModerationLogs")
                .whereField("chatId", isEqualTo: chatId)
                .getDocuments { [weak self] snapshot, error in
                    guard let self = self else {
                        continuation.resume(returning: false)
                        return
                    }
                    
                    if let error = error {
                        print("❌ Error fetching moderation logs to clear: \(error)")
                        continuation.resume(returning: false)
                        return
                    }
                    
                    guard let documents = snapshot?.documents, !documents.isEmpty else {
                        print("ℹ️ No moderation logs found to clear for chat: \(chatId)")
                        continuation.resume(returning: true)
                        return
                    }
                    
                    print("🗑️ Found \(documents.count) moderation logs to delete")
                    
                    // Create batch delete operation
                    let batch = self.firestore.batch()
                    
                    for document in documents {
                        batch.deleteDocument(document.reference)
                    }
                    
                    // Execute batch delete
                    batch.commit { error in
                        if let error = error {
                            print("❌ Error clearing moderation history: \(error)")
                            continuation.resume(returning: false)
                        } else {
                            print("✅ Successfully cleared \(documents.count) moderation logs for chat: \(chatId)")
                            
                            // Log the clear action itself
                            self.logModerationAction(
                                action: "history_cleared",
                                targetUserId: "",
                                chatId: chatId,
                                messageId: nil,
                                reason: "Moderation history cleared by moderator"
                            )
                            
                            continuation.resume(returning: true)
                        }
                    }
                }
        }
    }
    
    /// Log moderation actions
    private func logModerationAction(action: String, targetUserId: String, chatId: String, messageId: String?, reason: String) {
        guard let currentUser = AppState.shared.user else { 
            print("❌ Cannot log moderation action - no current user")
            return 
        }
        
        print("📝 Logging moderation action: \(action) for user \(targetUserId) in chat \(chatId)")
        
        // Get target user name
        var targetUserName = "Unknown User"
        if let chat = fanChats.first(where: { $0.id == chatId }) {
            targetUserName = chat.participantNames[targetUserId] ?? "Unknown User"
        }
        
        // If still unknown, try to get from current messages
        if targetUserName == "Unknown User", let message = currentMessages.first(where: { $0.senderID == targetUserId }) {
            targetUserName = message.displayName
        }
        
        let logData: [String: Any] = [
            "action": action,
            "moderatorId": currentUser.id,
            "moderatorName": currentUser.name,
            "targetUserId": targetUserId,
            "targetUserName": targetUserName,
            "chatId": chatId,
            "messageId": messageId ?? "",
            "reason": reason,
            "timestamp": FieldValue.serverTimestamp()
        ]
        
        print("📄 Log data to be saved: \(logData)")
        
        firestore.collection("fanChatModerationLogs").addDocument(data: logData) { error in
            if let error = error {
                print("❌ Error logging moderation action: \(error)")
            } else {
                print("✅ Moderation action logged successfully: \(action)")
            }
        }
    }

    // MARK: - Admin & Moderation Methods
    
    /// Toggle chat active status
    func toggleChatStatus(chatId: String, isActive: Bool) {
        let db = Database.database().reference()
        db.child("fanChats").child(chatId).child("isActive").setValue(isActive) { error, _ in
            if let error = error {
                print("Error toggling chat status: \(error)")
            } else {
                // Update local data
                if let index = self.fanChats.firstIndex(where: { $0.id == chatId }) {
                    self.fanChats[index].isActive = isActive
                }
            }
        }
    }
    
    /// Delete a specific message (admin action)
    func deleteMessage(messageId: String) {
        // Implementation depends on which chat the message belongs to
        // For now, we'll handle it in the moderation view directly
    }
    
    // MARK: - Message Editing
    
    func editMessage(_ messageId: String, in chatId: String, newContent: String) {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        print("✏️ Editing message \(messageId) in chat \(chatId)")
        
        let db = Database.database().reference()
        let messageRef = db.child("fanMessages").child(chatId).child(messageId)
        
        // First, get the current message to verify user can edit it
        messageRef.observeSingleEvent(of: .value) { [weak self] snapshot in
            guard let messageData = snapshot.value as? [String: Any],
                  let senderID = messageData["senderID"] as? String else {
                print("❌ Could not fetch message data for editing")
                return
            }
            
            // Check if user can edit this message
            guard senderID == currentUserId else {
                print("❌ User \(currentUserId) cannot edit message \(messageId) - not sender")
                return
            }
            
            // Store original content if this is the first edit
            var updatedData: [String: Any] = [:]
            
            if messageData["originalContent"] == nil,
               let currentContent = messageData["content"] as? String {
                updatedData["originalContent"] = currentContent
            }
            
            // Update message content and edit timestamp
            updatedData["content"] = newContent
            updatedData["editedAt"] = Date().timeIntervalSince1970 * 1000
            updatedData["updatedAt"] = Date().timeIntervalSince1970 * 1000
            
            // Save the changes
            messageRef.updateChildValues(updatedData) { error, _ in
                if let error = error {
                    print("❌ Error editing message: \(error)")
                } else {
                    print("✅ Message \(messageId) edited successfully")
                    
                    // Update last message if this was the most recent message
                    self?.updateLastMessageIfNeeded(chatId: chatId, messageId: messageId, newContent: newContent)
                }
            }
        }
    }
    
    private func updateLastMessageIfNeeded(chatId: String, messageId: String, newContent: String) {
        // Find the chat and check if this message was the last message
        if let chat = fanChats.first(where: { $0.id == chatId }),
           let lastMessage = chat.lastMessage,
           lastMessage.id == messageId {
            
            // Update the last message content in the chat
            var updatedLastMessage = lastMessage
            updatedLastMessage.content = newContent
            
            let db = Database.database().reference()
            let chatRef = db.child("fanChats").child(chat.groupId).child(chatId)
            
            let lastMessageData: [String: Any] = [
                "id": updatedLastMessage.id,
                "content": updatedLastMessage.content,
                "senderID": updatedLastMessage.senderID,
                "senderName": updatedLastMessage.senderName,
                "timestamp": updatedLastMessage.timestamp.timeIntervalSince1970 * 1000,
                "type": updatedLastMessage.type.rawValue
            ]
            
            chatRef.child("lastMessage").setValue(lastMessageData)
        }
    }
    
    /// Block user from all fan chats
    func blockUserFromFanChats(userId: String, reason: String) {
        let db = Firestore.firestore()
        let blockData: [String: Any] = [
            "userId": userId,
            "reason": reason,
            "blockedAt": Timestamp(),
            "blockedBy": Auth.auth().currentUser?.uid ?? "",
            "type": "fan_chat_block"
        ]
        
        db.collection("blockedUsers").addDocument(data: blockData) { error in
            if let error = error {
                print("Error blocking user: \(error)")
            } else {
                // Remove user from all fan chats
                self.removeUserFromAllFanChats(userId: userId)
            }
        }
    }
    
    /// Remove user from all fan chats
    private func removeUserFromAllFanChats(userId: String) {
        let db = Database.database().reference()
        
        for chat in fanChats {
            if let chatId = chat.id {
                db.child("fanChats").child(chatId).child("participants").child(userId).removeValue()
            }
        }
        
        // Update local data
        for i in 0..<fanChats.count {
            fanChats[i].participants.removeAll { $0 == userId }
        }
    }
    
    /// Add new chat rule
    func addRule(rule: FanChatRules.ChatRule) {
        guard let user = AppState.shared.user,
              let groupId = user.fanGroupId ?? user.groupId else { return }
        
        let db = Firestore.firestore()
        let ruleRef = db.collection("fanChatRules").document(groupId)
        
        ruleRef.getDocument { document, error in
            if let document = document, document.exists {
                // Update existing rules
                do {
                    let ruleData = try JSONEncoder().encode(rule)
                    let ruleDict = try JSONSerialization.jsonObject(with: ruleData) as? [String: Any]
                    
                    ruleRef.updateData([
                        "rules": FieldValue.arrayUnion([ruleDict]),
                        "updatedAt": Timestamp()
                    ])
                } catch {
                    print("Error encoding rule: \(error)")
                }
            } else {
                // Create new rules document
                let newRules = FanChatRules(
                    groupId: groupId,
                    rules: [rule],
                    createdAt: Date(),
                    updatedAt: Date(),
                    version: 1
                )
                
                do {
                    try ruleRef.setData(from: newRules)
                } catch {
                    print("Error creating rules: \(error)")
                }
            }
        }
        
        // Update local rules
        if chatRules == nil {
            chatRules = FanChatRules(
                groupId: groupId,
                rules: [rule],
                createdAt: Date(),
                updatedAt: Date(),
                version: 1
            )
        } else {
            chatRules?.rules.append(rule)
            chatRules?.updatedAt = Date()
        }
    }
    
    /// Remove chat rule
    func removeRule(rule: FanChatRules.ChatRule) {
        guard let user = AppState.shared.user,
              let groupId = user.fanGroupId ?? user.groupId else { return }
        
        let db = Firestore.firestore()
        
        do {
            let ruleData = try JSONEncoder().encode(rule)
            let ruleDict = try JSONSerialization.jsonObject(with: ruleData) as? [String: Any]
            
            db.collection("fanChatRules").document(groupId).updateData([
                "rules": FieldValue.arrayRemove([ruleDict]),
                "updatedAt": Timestamp()
            ])
        } catch {
            print("Error encoding rule for removal: \(error)")
        }
        
        // Update local rules
        chatRules?.rules.removeAll { $0.id == rule.id }
        chatRules?.updatedAt = Date()
    }
    
    /// Get moderation statistics
    func getModerationStats() -> [String: Int] {
        return [
            "totalChats": fanChats.count,
            "activeChats": fanChats.filter { $0.isActive }.count,
            "totalParticipants": fanChats.reduce(0) { $0 + $1.participants.count },
            "reportedMessages": 0 // Will be implemented with real data
        ]
    }
    
    // MARK: - Moderator Management (ADMIN ONLY)
    
    /// Check if current user is main app admin (can manage fan chat moderators)
    func isMainAppAdmin() -> Bool {
        guard let user = AppState.shared.user else { return false }
        return user.role == .admin
    }
    
    /// Add moderator to fan chat system (ADMIN ONLY)
    func addFanChatModerator(userId: String, chatId: String?, completion: @escaping (Bool, String?) -> Void) {
        guard isMainAppAdmin() else {
            completion(false, "Only main app admins can assign fan chat moderators")
            return
        }
        
        if let chatId = chatId {
            // Add moderator to specific chat
            addModeratorToSpecificChat(userId: userId, chatId: chatId, completion: completion)
        } else {
            // Add as global fan chat moderator
            addGlobalFanChatModerator(userId: userId, completion: completion)
        }
    }
    
    /// Remove moderator from fan chat system (ADMIN ONLY)
    func removeFanChatModerator(userId: String, chatId: String?, completion: @escaping (Bool, String?) -> Void) {
        guard isMainAppAdmin() else {
            completion(false, "Only main app admins can remove fan chat moderators")
            return
        }
        
        if let chatId = chatId {
            // Remove moderator from specific chat
            removeModeratorFromSpecificChat(userId: userId, chatId: chatId, completion: completion)
        } else {
            // Remove as global fan chat moderator
            removeGlobalFanChatModerator(userId: userId, completion: completion)
        }
    }
    
    /// Add moderator to specific chat
    private func addModeratorToSpecificChat(userId: String, chatId: String, completion: @escaping (Bool, String?) -> Void) {
        let db = Database.database().reference()
        
        // First check if chat exists and get current moderators
        db.child("fanChats").child(chatId).observeSingleEvent(of: .value) { snapshot, _ in
            guard var chatData = snapshot.value as? [String: Any] else {
                completion(false, "Chat not found")
                return
            }
            
            var moderatorIds = chatData["moderatorIds"] as? [String] ?? []
            
            if !moderatorIds.contains(userId) {
                moderatorIds.append(userId)
                chatData["moderatorIds"] = moderatorIds
                chatData["updatedAt"] = ServerValue.timestamp()
                
                // Update chat data
                db.child("fanChats").child(chatId).updateChildValues(chatData) { error, _ in
                    if let error = error {
                        completion(false, "Failed to add moderator: \(error.localizedDescription)")
                    } else {
                        // Update local data
                        if let index = self.fanChats.firstIndex(where: { $0.id == chatId }) {
                            self.fanChats[index].moderatorIds = moderatorIds
                        }
                        
                        // Log admin action
                        self.logAdminAction(action: "add_moderator", targetUserId: userId, chatId: chatId, details: "Added user as chat moderator")
                        
                        completion(true, "Moderator added successfully")
                    }
                }
            } else {
                completion(false, "User is already a moderator of this chat")
            }
        }
    }
    
    /// Remove moderator from specific chat
    private func removeModeratorFromSpecificChat(userId: String, chatId: String, completion: @escaping (Bool, String?) -> Void) {
        let db = Database.database().reference()
        
        // First check if chat exists and get current moderators
        db.child("fanChats").child(chatId).observeSingleEvent(of: .value) { snapshot, _ in
            guard var chatData = snapshot.value as? [String: Any] else {
                completion(false, "Chat not found")
                return
            }
            
            var moderatorIds = chatData["moderatorIds"] as? [String] ?? []
            
            if let index = moderatorIds.firstIndex(of: userId) {
                moderatorIds.remove(at: index)
                chatData["moderatorIds"] = moderatorIds
                chatData["updatedAt"] = ServerValue.timestamp()
                
                // Update chat data
                db.child("fanChats").child(chatId).updateChildValues(chatData) { error, _ in
                    if let error = error {
                        completion(false, "Failed to remove moderator: \(error.localizedDescription)")
                    } else {
                        // Update local data
                        if let index = self.fanChats.firstIndex(where: { $0.id == chatId }) {
                            self.fanChats[index].moderatorIds = moderatorIds
                        }
                        
                        // Log admin action
                        self.logAdminAction(action: "remove_moderator", targetUserId: userId, chatId: chatId, details: "Removed user as chat moderator")
                        
                        completion(true, "Moderator removed successfully")
                    }
                }
            } else {
                completion(false, "User is not a moderator of this chat")
            }
        }
    }
    
    /// Add global fan chat moderator (can moderate all chats and create themed chats)
    private func addGlobalFanChatModerator(userId: String, completion: @escaping (Bool, String?) -> Void) {
        guard let currentUser = AppState.shared.user,
              let groupId = currentUser.groupId else {
            completion(false, "Cannot determine group ID")
            return
        }
        
        let db = Firestore.firestore()
        
        // Store global moderator in Firestore
        let moderatorData: [String: Any] = [
            "userId": userId,
            "groupId": groupId,
            "assignedBy": currentUser.id,
            "assignedAt": Timestamp(),
            "permissions": [
                "canCreateThemedChats": true,
                "canModerateAllChats": true,
                "canManageRules": true
            ]
        ]
        
        db.collection("groups").document(groupId).collection("fanChatModerators")
            .document(userId).setData(moderatorData) { error in
                if let error = error {
                    completion(false, "Failed to add global moderator: \(error.localizedDescription)")
                } else {
                    // Log admin action
                    self.logAdminAction(action: "add_global_moderator", targetUserId: userId, chatId: nil as String?, details: "Added user as global fan chat moderator")
                    
                    completion(true, "Global fan chat moderator added successfully")
                }
            }
    }
    
    /// Remove global fan chat moderator
    private func removeGlobalFanChatModerator(userId: String, completion: @escaping (Bool, String?) -> Void) {
        guard let currentUser = AppState.shared.user,
              let groupId = currentUser.groupId else {
            completion(false, "Cannot determine group ID")
            return
        }
        
        let db = Firestore.firestore()
        
        // Remove global moderator from Firestore
        db.collection("groups").document(groupId).collection("fanChatModerators")
            .document(userId).delete { error in
                if let error = error {
                    completion(false, "Failed to remove global moderator: \(error.localizedDescription)")
                } else {
                    // Log admin action
                    self.logAdminAction(action: "remove_global_moderator", targetUserId: userId, chatId: nil as String?, details: "Removed user as global fan chat moderator")
                    
                    completion(true, "Global fan chat moderator removed successfully")
                }
            }
    }
    
    /// Check if user is global fan chat moderator
    func isGlobalFanChatModerator(userId: String, completion: @escaping (Bool) -> Void) {
        guard let currentUser = AppState.shared.user else {
            print("❌ No current user for moderator check")
            completion(false)
            return
        }
        
        // For fan users, use fanGroupId; for regular users, use groupId
        let groupId = currentUser.fanGroupId ?? currentUser.groupId
        
        guard let groupId = groupId else {
            print("❌ No group ID (neither groupId nor fanGroupId) for moderator check")
            completion(false)
            return
        }
        
        print("🔍 Checking global moderator status for user \(userId) in group \(groupId)")
        
        let db = Firestore.firestore()
        
        db.collection("groups").document(groupId).collection("fanChatModerators")
            .document(userId).getDocument { snapshot, error in
                if let error = error {
                    print("❌ Error checking global moderator status: \(error)")
                    completion(false)
                } else {
                    let exists = snapshot?.exists == true
                    print("✅ Global moderator document exists: \(exists)")
                    if let data = snapshot?.data() {
                        print("📄 Moderator document data: \(data)")
                    }
                    completion(exists)
                }
            }
    }
    
    /// Check if user can create themed chats
    func canUserCreateThemedChats(userId: String, completion: @escaping (Bool) -> Void) {
        print("🔍 Checking themed chat permissions for user: \(userId)")
        
        // Only main app admins and global fan chat moderators can create themed chats
        if isMainAppAdmin() {
            print("✅ User is main app admin - can create themed chats")
            completion(true)
            return
        }
        
        print("🔍 Checking if user is global fan chat moderator...")
        isGlobalFanChatModerator(userId: userId) { isModerator in
            print("✅ Global moderator check result: \(isModerator)")
            completion(isModerator)
        }
    }
    
    /// Log admin actions for audit trail
    private func logAdminAction(action: String, targetUserId: String, chatId: String?, details: String) {
        guard let currentUser = AppState.shared.user else { return }
        
        let db = Firestore.firestore()
        let logData: [String: Any] = [
            "action": action,
            "adminId": currentUser.id,
            "adminName": currentUser.name,
            "targetUserId": targetUserId,
            "chatId": chatId ?? "",
            "details": details,
            "timestamp": Timestamp()
        ]
        
        db.collection("fanChatAdminLogs").addDocument(data: logData) { error in
            if let error = error {
                print("Error logging admin action: \(error)")
            }
        }
    }
}
