import SwiftUI
import Firebase
import FirebaseAuth

struct FanChatModerationView: View {
    let chat: FanChat
    @StateObject private var fanChatService = FanChatService.shared
    @State private var messages: [FanMessage] = []
    @State private var selectedMessage: FanMessage?
    @State private var showDeleteAlert = false
    @State private var showBlockUserAlert = false
    @State private var blockReason = ""
    @State private var isLoading = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Chat Info Header
            chatInfoHeader
            
            Divider()
            
            // Messages List
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(messages, id: \.id) { message in
                        messageRow(message: message)
                    }
                }
                .padding()
            }
        }
        .navigationTitle(NSLocalizedString("Moderate Chat", comment: ""))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadMessages()
        }
        .alert(NSLocalizedString("Delete Message", comment: ""), isPresented: $showDeleteAlert) {
            Button(NSLocalizedString("Delete", comment: ""), role: .destructive) {
                if let message = selectedMessage {
                    deleteMessage(message)
                }
            }
            Button(NSLocalizedString("Cancel", comment: ""), role: .cancel) {}
        } message: {
            Text(NSLocalizedString("This message will be permanently deleted and cannot be recovered.", comment: ""))
        }
        .alert(NSLocalizedString("Block User", comment: ""), isPresented: $showBlockUserAlert) {
            TextField(NSLocalizedString("Reason for blocking", comment: ""), text: $blockReason)
            Button(NSLocalizedString("Block", comment: ""), role: .destructive) {
                if let message = selectedMessage {
                    blockUser(message.senderID, reason: blockReason)
                }
            }
            Button(NSLocalizedString("Cancel", comment: ""), role: .cancel) {}
        } message: {
            Text(NSLocalizedString("User will be blocked from all fan chats.", comment: ""))
        }
    }
    
    // MARK: - Chat Info Header
    private var chatInfoHeader: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: chatIcon(for: chat.type))
                    .foregroundColor(chatColor(for: chat.type))
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(chat.name ?? NSLocalizedString("Unnamed Chat", comment: ""))
                        .font(.headline)
                    
                    Text(String(format: NSLocalizedString("%d participants", comment: ""), chat.participants.count))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Status Indicator
                HStack(spacing: 4) {
                    Circle()
                        .fill(chat.isActive ? Color.green : Color.red)
                        .frame(width: 8, height: 8)
                    
                    Text(chat.isActive ? NSLocalizedString("Active", comment: "") : NSLocalizedString("Inactive", comment: ""))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            if let description = chat.description {
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
            }
        }
        .padding()
        .background(Color(.systemGray6))
    }
    
    // MARK: - Message Row
    private func messageRow(message: FanMessage) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // Message Header
            HStack {
                Text(message.senderName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text(formatDate(message.timestamp))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Message Content
            Text(message.content)
                .font(.body)
                .multilineTextAlignment(.leading)
            
            // Moderation Actions
            HStack(spacing: 12) {
                Button(NSLocalizedString("Delete", comment: "")) {
                    selectedMessage = message
                    showDeleteAlert = true
                }
                .buttonStyle(.bordered)
                .foregroundColor(.red)
                .font(.caption)
                
                Button(NSLocalizedString("Block User", comment: "")) {
                    selectedMessage = message
                    showBlockUserAlert = true
                }
                .buttonStyle(.bordered)
                .foregroundColor(.orange)
                .font(.caption)
                
                Button(NSLocalizedString("View Profile", comment: "")) {
                    // Navigate to user profile
                }
                .buttonStyle(.bordered)
                .font(.caption)
                
                Spacer()
                
                if message.isReported {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                        .font(.caption)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(message.isReported ? Color.orange.opacity(0.1) : Color(.systemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(message.isReported ? Color.orange.opacity(0.3) : Color.clear, lineWidth: 1)
        )
    }
    
    // MARK: - Helper Functions
    private func chatIcon(for type: FanChat.FanChatType) -> String {
        switch type {
        case .general:
            return "bubble.left.and.bubble.right.fill"
        case .privateChat:
            return "lock.fill"
        case .themed:
            return "music.note"
        case .announcement:
            return "megaphone.fill"
        case .mixed:
            return "person.2.fill"
        }
    }
    
    private func chatColor(for type: FanChat.FanChatType) -> Color {
        switch type {
        case .general:
            return .blue
        case .privateChat:
            return .orange
        case .themed:
            return .purple
        case .announcement:
            return .green
        case .mixed:
            return .pink
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    // MARK: - Actions
    private func loadMessages() {
        isLoading = true
        guard let chatId = chat.id else {
            isLoading = false
            return
        }
        
        let db = Database.database().reference()
        db.child("fanChats").child(chatId).child("messages")
            .queryOrdered(byChild: "timestamp")
            .queryLimited(toLast: 100)
            .observeSingleEvent(of: .value) { snapshot in
                DispatchQueue.main.async {
                    isLoading = false
                    var loadedMessages: [FanMessage] = []
                    
                    for child in snapshot.children {
                        if let childSnapshot = child as? DataSnapshot,
                           let messageData = childSnapshot.value as? [String: Any] {
                            
                            if let message = createMessage(from: messageData, id: childSnapshot.key) {
                                loadedMessages.append(message)
                            }
                        }
                    }
                    
                    messages = loadedMessages.reversed() // Show newest first
                }
            }
    }
    
    private func createMessage(from data: [String: Any], id: String) -> FanMessage? {
        guard let content = data["content"] as? String,
              let senderID = data["senderID"] as? String,
              let senderName = data["senderName"] as? String,
              let timestampValue = data["timestamp"] as? TimeInterval else {
            return nil
        }
        
        let reportedBy = data["reportedBy"] as? [String] ?? []
        
        return FanMessage(
            id: id,
            chatId: chat.id ?? "",
            senderID: senderID,
            senderName: senderName,
            content: content,
            timestamp: Date(timeIntervalSince1970: timestampValue / 1000),
            reportedBy: reportedBy
        )
    }
    
    private func deleteMessage(_ message: FanMessage) {
        let db = Database.database().reference()
        guard let chatId = chat.id, let messageId = message.id else { return }
        db.child("fanChats").child(chatId).child("messages").child(messageId).removeValue { error, _ in
            if let error = error {
                print("Error deleting message: \(error)")
            } else {
                // Remove from local array
                messages.removeAll { $0.id == message.id }
                
                // Log moderation action
                logModerationAction(
                    action: "delete_message",
                    targetUserId: message.senderID,
                    details: "Deleted message: \(message.content.prefix(50))"
                )
            }
        }
    }
    
    private func blockUser(_ userId: String, reason: String) {
        let db = Firestore.firestore()
        let blockData: [String: Any] = [
            "userId": userId,
            "reason": reason,
            "blockedAt": Timestamp(),
            "blockedBy": Auth.auth().currentUser?.uid ?? "",
            "chatId": chat.id ?? ""
        ]
        
        db.collection("blockedUsers").addDocument(data: blockData) { error in
            if let error = error {
                print("Error blocking user: \(error)")
            } else {
                // Remove user from chat participants
                removeUserFromChat(userId)
                
                // Log moderation action
                logModerationAction(
                    action: "block_user",
                    targetUserId: userId,
                    details: reason
                )
                
                blockReason = ""
            }
        }
    }
    
    private func removeUserFromChat(_ userId: String) {
        let db = Database.database().reference()
        guard let chatId = chat.id else { return }
        db.child("fanChats").child(chatId).child("participants").child(userId).removeValue()
    }
    
    private func logModerationAction(action: String, targetUserId: String, details: String) {
        let db = Firestore.firestore()
        let logData: [String: Any] = [
            "action": action,
            "moderatorId": Auth.auth().currentUser?.uid ?? "",
            "targetUserId": targetUserId,
            "chatId": chat.id ?? "",
            "details": details,
            "timestamp": Timestamp()
        ]
        
        db.collection("moderationLogs").addDocument(data: logData)
    }
}

#Preview {
    NavigationView {
        FanChatModerationView(chat: FanChat(
            id: "preview",
            type: .general,
            participants: ["user1", "user2"],
            createdBy: "admin",
            createdAt: Date(),
            updatedAt: Date(),
            name: "General Fan Chat",
            description: "Main chat for all fans",
            lastMessage: nil,
            isDeleted: false,
            groupId: "group1",
            moderatorIds: [],
            isActive: true,
            chatRulesAccepted: [:]
        ))
    }
}
