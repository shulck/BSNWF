//
//  ChatShareView.swift
//  BandSync
//
//  Created by Oleksandr Kuziakin on 26.06.2025.
//

import SwiftUI
import FirebaseAuth

struct ChatShareView: View {
    let message: Message
    let sourceChat: Chat
    @Environment(\.dismiss) private var dismiss
    @StateObject private var chatService = ChatService.shared
    
    @State private var selectedChats: Set<String> = []
    @State private var shareMessage = ""
    @State private var isSharing = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    private var currentUserId: String {
        Auth.auth().currentUser?.uid ?? ""
    }
    
    private var availableChats: [Chat] {
        chatService.chats.filter { chat in
            chat.id != sourceChat.id && // Don't show source chat
            chat.participants.contains(currentUserId) // Only chats where we are participants
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                if availableChats.isEmpty {
                    // No available chats
                    VStack(spacing: 16) {
                        Image(systemName: "bubble.left.and.bubble.right")
                            .font(.system(size: 48))
                            .foregroundColor(.gray)
                        
                        Text("No available chats".localized)
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Text("Create other chats to share messages".localized)
                            .font(.caption)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    VStack(spacing: 0) {
                        // Message preview
                        MessagePreviewSection()
                        
                        // Additional message
                        AdditionalMessageSection()
                        
                        // Chat list
                        ChatSelectionSection()
                    }
                }
            }
            .navigationTitle("Share".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel".localized) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Share".localized) {
                        shareToSelectedChats()
                    }
                    .disabled(selectedChats.isEmpty || isSharing)
                }
            }
            .alert("Error".localized, isPresented: $showingError) {
                Button("OK".localized) { }
            } message: {
                Text(errorMessage)
            }
            .onAppear {
                // Load users for displaying chat names
                UserService.shared.fetchUsers()
            }
        }
    }
    
    @ViewBuilder
    private func MessagePreviewSection() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Message to send:".localized)
                .font(.caption)
                .foregroundColor(.secondary)
            
            VStack(alignment: .leading, spacing: 8) {
                // Source information
                HStack {
                    Text("From chat:".localized)
                        .font(.caption)
                        .foregroundColor(.blue)
                    
                    Text(sourceChat.displayName)
                        .font(.caption)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Text(formatDate(message.timestamp))
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
                
                // Message content
                if !message.content.isEmpty {
                    Text(message.content)
                        .font(.body)
                        .padding(8)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                }
                
                if let imageURL = message.imageURL {
                    AsyncImage(url: URL(string: imageURL)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxHeight: 100)
                            .cornerRadius(8)
                    } placeholder: {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 100)
                            .cornerRadius(8)
                            .overlay {
                                ProgressView()
                            }
                    }
                }
            }
            .padding()
            .background(Color.gray.opacity(0.05))
            .cornerRadius(12)
        }
        .padding(.horizontal)
    }
    
    @ViewBuilder
    private func AdditionalMessageSection() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Additional message (optional):".localized)
                .font(.caption)
                .foregroundColor(.secondary)
            
            TextField("Add comment...".localized, text: $shareMessage, axis: .vertical)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .lineLimit(1...3)
        }
        .padding(.horizontal)
    }
    
    @ViewBuilder
    private func ChatSelectionSection() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Select chats:".localized)
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            List(availableChats, id: \.id) { chat in
                ChatSelectionRow(
                    chat: chat,
                    isSelected: selectedChats.contains(chat.id ?? ""),
                    onToggle: { toggleChatSelection(chat.id ?? "") }
                )
            }
            .listStyle(PlainListStyle())
        }
    }
    
    private func toggleChatSelection(_ chatId: String) {
        if selectedChats.contains(chatId) {
            selectedChats.remove(chatId)
        } else {
            selectedChats.insert(chatId)
        }
    }
    
    private func shareToSelectedChats() {
        guard !selectedChats.isEmpty else { return }
        
        isSharing = true
        
        let group = DispatchGroup()
        var hasError = false
        
        for chatId in selectedChats {
            group.enter()
            
            let forwardedMessage = createForwardedMessage(for: chatId)
            
            chatService.sendMessage(forwardedMessage) { result in
                switch result {
                case .success:
                    break
                case .failure:
                    hasError = true
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            self.isSharing = false
            
            if hasError {
                self.errorMessage = "Failed to send message to some chats".localized
                self.showingError = true
            } else {
                self.dismiss()
            }
        }
    }
    
    private func createForwardedMessage(for chatId: String) -> Message {
        var content = ""
        
        // Add additional message if exists
        if !shareMessage.isEmpty {
            content += shareMessage + "\n\n"
        }
        
        // Add forwarding information
        content += String(format: "Forwarded from chat".localized, sourceChat.displayName)
        
        if !message.content.isEmpty {
            content += "\n\(message.content)"
        }
        
        return Message(
            chatId: chatId,
            content: content,
            senderID: currentUserId,
            senderName: UserService.shared.currentUser?.name ?? "Unknown",
            timestamp: Date(),
            type: message.imageURL != nil ? .image : .text,
            imageURL: message.imageURL // Copy image if exists
        )
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct ChatSelectionRow: View {
    let chat: Chat
    let isSelected: Bool
    let onToggle: () -> Void
    @StateObject private var userService = UserService.shared
    
    private var chatDisplayName: String {
        if chat.type == .direct {
            // For private chats get the other participant's name
            let currentUserId = Auth.auth().currentUser?.uid ?? ""
            let otherUserId = chat.participants.first { $0 != currentUserId } ?? ""
            
            // Try to get user name from UserService
            if let otherUser = userService.users.first(where: { $0.id == otherUserId }) {
                return otherUser.name
            }
            
            // Fallback to showing partial ID if user not found
            return "User \(otherUserId.prefix(8))"
        } else {
            return chat.displayName
        }
    }
    
    private var chatIcon: String {
        switch chat.type {
        case .direct:
            return "person.fill"
        case .group:
            return "person.3.fill"
        case .bandWide:
            return "megaphone.fill"
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Chat icon or avatar
            if chat.type == .direct {
                // Show avatar for private chats
                let currentUserId = Auth.auth().currentUser?.uid ?? ""
                let otherUserId = chat.participants.first { $0 != currentUserId } ?? ""
                
                if let otherUser = userService.users.first(where: { $0.id == otherUserId }) {
                    AvatarView(user: otherUser, size: 32)
                } else {
                    // Fallback avatar while loading
                    AvatarView(avatarURL: nil, name: chatDisplayName, size: 32)
                }
            } else {
                // Show icon for group chats
                Image(systemName: chatIcon)
                    .font(.title2)
                    .foregroundColor(chat.type == .bandWide ? .orange : .blue)
                    .frame(width: 32, height: 32)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(chatDisplayName)
                    .font(.body)
                    .fontWeight(.medium)
                
                if chat.type == .direct {
                    Text("Private chat".localized)
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    Text("\(chat.participants.count) \("participants".localized)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Checkbox
            Button(action: onToggle) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(isSelected ? .blue : .gray)
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            onToggle()
        }
    }
}

#Preview {
    let sampleMessage = Message(
        id: "msg1",
        chatId: "chat1",
        content: "This is an important message that needs to be shared with other team members.",
        senderID: "user1",
        senderName: "User 1",
        timestamp: Date(),
        type: .text
    )
    
    let sampleChat = Chat(
        id: "chat1",
        type: .group,
        participants: ["user1", "user2", "user3"],
        createdBy: "user1",
        createdAt: Date(),
        updatedAt: Date(),
        name: "Work Chat"
    )
    
    ChatShareView(message: sampleMessage, sourceChat: sampleChat)
}
