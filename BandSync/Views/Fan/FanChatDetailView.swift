import SwiftUI
import UIKit
import FirebaseAuth

// MARK: - FAN CHAT DETAIL VIEW

struct FanChatDetailView: View {
    let chat: FanChat
    @StateObject private var fanChatService = FanChatService.shared
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var messageText = ""
    @State private var showingReportSheet = false
    @State private var selectedMessage: FanMessage?
    @State private var showingChatInfo = false
    @State private var showingDeleteConfirmation = false
    @State private var showingModerationPanel = false
    @State private var showingModerationHistory = false
    @State private var selectedMessageForModeration: FanMessage?
    @FocusState private var isMessageFieldFocused: Bool
    
    private let currentUserId = Auth.auth().currentUser?.uid ?? ""
    
    private var canDeleteChat: Bool {
        return chat.createdBy == currentUserId || fanChatService.isMainAppAdmin()
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Messages List
            messagesListView
            
            // Message Input
            if !chat.isReadOnlyForFans || canUserSendMessages {
                messageInputView
            } else {
                readOnlyNoticeView
            }
        }
        .navigationTitle(chat.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(false)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack {
                    if isModerator {
                        Button {
                            showingModerationHistory = true
                        } label: {
                            Image(systemName: "shield")
                                .foregroundColor(.orange)
                        }
                    }
                    
                    if canDeleteChat {
                        Button {
                            showingDeleteConfirmation = true
                        } label: {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                    }
                    
                    Button {
                        showingChatInfo = true
                    } label: {
                        Image(systemName: "info.circle")
                            .foregroundColor(.blue)
                    }
                }
            }
        }
        .sheet(isPresented: $showingChatInfo) {
            FanChatInfoView(chat: chat)
        }
        .sheet(isPresented: $showingReportSheet) {
            if let message = selectedMessage {
                FanMessageReportView(message: message, chat: chat)
            }
        }
        .sheet(isPresented: $showingModerationPanel) {
            if let message = selectedMessageForModeration {
                ModerationPanelView(message: message, chat: chat, onAction: { action, reason in
                    handleModerationAction(action, for: message, reason: reason)
                    showingModerationPanel = false
                })
            }
        }
        .sheet(isPresented: $showingModerationHistory) {
            ModerationHistoryView(chat: chat)
        }
        .alert(NSLocalizedString("Delete Chat", comment: "Alert title for deleting a chat"), isPresented: $showingDeleteConfirmation) {
            Button(NSLocalizedString("Cancel", comment: "Cancel button in delete chat alert"), role: .cancel) { }
            Button(NSLocalizedString("Delete", comment: "Delete button in delete chat alert"), role: .destructive) {
                fanChatService.deleteFanChat(chat)
                dismiss()
            }
        } message: {
            Text(NSLocalizedString("Are you sure you want to delete this chat? This action cannot be undone.", comment: "Confirmation message for deleting chat"))
        }
        .onAppear {
            let chatId = chat.id ?? ""
            print("🔍 FanChatDetailView onAppear for chat: \(chatId)")
            print("📊 Current messages count: \(fanChatService.currentMessages.count)")
            print("📋 Current messages: \(fanChatService.currentMessages.map { $0.content })")
            fanChatService.startListeningToMessages(for: chatId)
        }
        .onTapGesture {
            isMessageFieldFocused = false
        }
    }
    
    // MARK: - Messages List View
    
    private var messagesListView: some View {
        ScrollViewReader { proxy in
            List {
                ForEach(fanChatService.currentMessages, id: \.id) { message in
                    FanMessageBubbleView(
                        message: message,
                        isCurrentUser: message.senderID == currentUserId,
                        isModerator: isModerator,
                        onReport: {
                            selectedMessage = message
                            showingReportSheet = true
                        },
                        onModerate: {
                            selectedMessageForModeration = message
                            showingModerationPanel = true
                        }
                    )
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                }
            }
            .listStyle(PlainListStyle())
            .onChange(of: fanChatService.currentMessages.count) { _ in
                scrollToBottom(proxy: proxy)
            }
            .onAppear {
                scrollToBottom(proxy: proxy)
            }
        }
    }
    
    // MARK: - Message Input View
    
    private var messageInputView: some View {
        VStack(spacing: 0) {
            Divider()
            
            HStack(spacing: 12) {
                // Message Text Field
                HStack(spacing: 8) {
                    TextField(NSLocalizedString("Type a message...", comment: "Placeholder text for message input field"), text: $messageText, axis: .vertical)
                        .textFieldStyle(PlainTextFieldStyle())
                        .focused($isMessageFieldFocused)
                        .lineLimit(1...4)
                        .onSubmit {
                            sendMessage()
                        }
                    
                    if !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Button(action: clearMessage) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.secondary.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 20))
                
                // Send Button
                Button(action: sendMessage) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                        .foregroundColor(canSendMessage ? .blue : .secondary)
                }
                .disabled(!canSendMessage)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                Rectangle()
                    .fill(colorScheme == .dark ? Color.black : Color.white)
                    .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: -1)
            )
        }
    }
    
    // MARK: - Read Only Notice View
    
    private var readOnlyNoticeView: some View {
        VStack(spacing: 8) {
            Divider()
            
            HStack(spacing: 12) {
                Image(systemName: "lock.fill")
                    .foregroundColor(.orange)
                
                Text(NSLocalizedString("This is a read-only chat. Only administrators can send messages.", comment: "Notice shown when chat is read-only"))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color.orange.opacity(0.05))
        }
    }
    
    // MARK: - Helper Properties
    
    private var canUserSendMessages: Bool {
        guard let user = appState.user else { return false }
        
        // Band members can always send messages
        if user.userType != .fan {
            return true
        }
        
        // Check if user is banned
        if fanChatService.bannedUsers.contains(user.id) {
            return false
        }
        
        // Check chat type permissions
        switch chat.type {
        case .announcement:
            return false // Only admins can send to announcement chats
        case .general, .privateChat, .themed, .mixed:
            return true
        }
    }
    
    private var isModerator: Bool {
        guard let user = appState.user else { return false }
        return chat.moderatorIds.contains(user.id) || fanChatService.isMainAppAdmin()
    }
    
    private var canSendMessage: Bool {
        let trimmed = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty && trimmed.count <= 500 && canUserSendMessages
    }
    
    // MARK: - Helper Methods
    
    private func sendMessage() {
        guard canSendMessage else { return }
        
        let trimmed = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        fanChatService.sendMessage(trimmed, to: chat.id ?? "")
        messageText = ""
        isMessageFieldFocused = false
    }
    
    private func clearMessage() {
        messageText = ""
    }
    
    private func scrollToBottom(proxy: ScrollViewProxy) {
        if let lastMessage = fanChatService.currentMessages.last {
            withAnimation(.easeOut(duration: 0.3)) {
                proxy.scrollTo(lastMessage.id, anchor: .bottom)
            }
        }
    }
    
    private func handleModerationAction(_ action: ModerationLog.ModerationAction, for message: FanMessage, reason: String) {
        Task {
            switch action {
            case .deleteMessage:
                await fanChatService.moderatorDeleteMessage(message.id ?? "", in: chat.id ?? "", reason: reason)
            case .warnUser:
                await fanChatService.moderatorWarnUser(message.senderID, in: chat.id ?? "", reason: reason)
            case .banUser:
                await fanChatService.moderatorBanUserFromChat(message.senderID, from: chat.id ?? "", reason: reason)
            case .tempBanUser:
                await fanChatService.moderatorBanUserFromChat(message.senderID, from: chat.id ?? "", reason: reason, temporarily: true, duration: 24 * 60 * 60) // 24 hours
            case .muteUser:
                await fanChatService.moderatorMuteUser(message.senderID, in: chat.id ?? "", duration: 60 * 60, reason: reason) // 1 hour
            default:
                break
            }
        }
    }
}

// MARK: - FAN MESSAGE BUBBLE VIEW

struct FanMessageBubbleView: View {
    let message: FanMessage
    let isCurrentUser: Bool
    let isModerator: Bool
    let onReport: () -> Void
    let onModerate: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var fanChatService = FanChatService.shared
    @State private var showingContextMenu = false
    @State private var isEditing = false
    @State private var editText = ""
    
    private var canEdit: Bool {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return false }
        return message.canBeEditedBy(currentUserId)
    }
    
    var body: some View {
        HStack {
            if isCurrentUser {
                Spacer(minLength: 60)
            }
            
            VStack(alignment: isCurrentUser ? .trailing : .leading, spacing: 4) {
                // Message Content
                HStack {
                    if !isCurrentUser {
                        // Sender Avatar (for group chats)
                        if message.type != .system {
                            VStack {
                                ZStack {
                                    Circle()
                                        .fill(Color.blue.opacity(0.15))
                                        .frame(width: 32, height: 32)
                                    
                                    Text(String(message.displayName.prefix(1)).uppercased())
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundColor(.blue)
                                }
                                Spacer()
                            }
                        }
                    }
                    
                    VStack(alignment: isCurrentUser ? .trailing : .leading, spacing: 6) {
                        // Sender Name (for group chats)
                        if !isCurrentUser && message.type != .system {
                            Text(message.displayName)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                        }
                        
                        // Message Bubble
                        messageBubble
                        
                        // Timestamp
                        Text(formatTime(message.timestamp))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .contextMenu {
                    if canEdit {
                        Button {
                            editText = message.content
                            isEditing = true
                        } label: {
                            Label(NSLocalizedString("Edit", comment: "Context menu option to edit message"), systemImage: "pencil")
                        }
                    }
                    
                    if isModerator && !isCurrentUser {
                        Button {
                            onModerate()
                        } label: {
                            Label(NSLocalizedString("Moderate", comment: "Context menu option to moderate message"), systemImage: "shield")
                        }
                        .foregroundColor(.orange)
                    }
                    
                    if !isCurrentUser && message.type == .text {
                        Button {
                            onReport()
                        } label: {
                            Label(NSLocalizedString("Report Message", comment: "Context menu option to report message"), systemImage: "flag")
                        }
                    }
                    
                    Button {
                        UIPasteboard.general.string = message.content
                    } label: {
                        Label(NSLocalizedString("Copy", comment: "Context menu option to copy message"), systemImage: "doc.on.doc")
                    }
                }
            }
            
            if !isCurrentUser {
                Spacer(minLength: 60)
            }
        }
        .padding(.vertical, 2)
    }
    
    private var messageBubble: some View {
        Group {
            switch message.type {
            case .text:
                textMessageBubble
            case .system:
                systemMessageBubble
            case .announcement:
                announcementMessageBubble
            case .warning:
                warningMessageBubble
            }
        }
    }
    
    private var textMessageBubble: some View {
        VStack(alignment: isCurrentUser ? .trailing : .leading, spacing: 4) {
            if isEditing {
                // Edit mode
                VStack(spacing: 8) {
                    TextField(NSLocalizedString("Edit message", comment: "Placeholder for editing message"), text: $editText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    HStack {
                        Button(NSLocalizedString("Cancel", comment: "Cancel button for editing message")) {
                            isEditing = false
                            editText = message.content
                        }
                        .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Button(NSLocalizedString("Save", comment: "Save button for editing message")) {
                            let trimmed = editText.trimmingCharacters(in: .whitespacesAndNewlines)
                            if !trimmed.isEmpty && trimmed != message.content {
                                fanChatService.editMessage(message.id ?? "", in: message.chatId, newContent: trimmed)
                            }
                            isEditing = false
                        }
                        .disabled(editText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        .foregroundColor(.blue)
                    }
                    .font(.caption)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color(UIColor.systemGray6))
                )
            } else {
                // Display mode
                VStack(alignment: isCurrentUser ? .trailing : .leading, spacing: 2) {
                    Text(message.content)
                        .font(.body)
                        .foregroundColor(isCurrentUser ? .white : .primary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(isCurrentUser ? Color.blue : (colorScheme == .dark ? Color(UIColor.secondarySystemGroupedBackground) : Color(UIColor.systemGray5)))
                        )
                    
                    // Show edited indicator
                    if message.isEdited {
                        Text(NSLocalizedString("edited", comment: "Label indicating message was edited"))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .italic()
                    }
                }
            }
        }
    }
    
    private var systemMessageBubble: some View {
        Text(message.content)
            .font(.caption)
            .foregroundColor(.secondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(Color.secondary.opacity(0.1))
            )
    }
    
    private var announcementMessageBubble: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "megaphone.fill")
                    .font(.caption)
                    .foregroundColor(.orange)
                
                Text(NSLocalizedString("Announcement", comment: "Label for announcement messages"))
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.orange)
            }
            
            Text(message.content)
                .font(.body)
                .foregroundColor(.primary)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.orange.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    private var warningMessageBubble: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundColor(.red)
                
                Text(NSLocalizedString("Warning", comment: "Label for warning messages"))
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.red)
            }
            
            Text(message.content)
                .font(.body)
                .foregroundColor(.primary)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.red.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.red.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - FAN CHAT INFO VIEW

struct FanChatInfoView: View {
    let chat: FanChat
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        NavigationView {
            List {
                // Chat Details Section
                Section {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(Color.blue.opacity(0.15))
                                    .frame(width: 60, height: 60)
                                
                                Image(systemName: chatIcon)
                                    .font(.title2)
                                    .foregroundColor(.blue)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(chat.displayName)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                
                                Text(chat.type.rawValue.capitalized)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(Color.blue.opacity(0.1))
                                    .clipShape(Capsule())
                            }
                            
                            Spacer()
                        }
                        
                        if let description = chat.description, !description.isEmpty {
                            Text(description)
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                // Chat Rules Section
                Section(NSLocalizedString("Chat Rules", comment: "Section title for chat rules")) {
                    NavigationLink(NSLocalizedString("View Community Rules", comment: "Link to view community rules")) {
                        FanChatRulesDisplayView()
                    }
                }
                
                // Participants Section (for group chats)
                if chat.isGroupChat {
                    Section(NSLocalizedString("Participants", comment: "Section title for chat participants")) {
                        HStack {
                            Image(systemName: "person.2.fill")
                                .foregroundColor(.blue)
                            
                            Text(String(format: NSLocalizedString("%d members", comment: "Number of chat members"), chat.participants.count))
                                .font(.body)
                            
                            Spacer()
                        }
                    }
                }
                
                // Chat Settings Section
                Section(NSLocalizedString("Settings", comment: "Section title for chat settings")) {
                    if chat.type == .privateChat {
                        Button(NSLocalizedString("Leave Chat", comment: "Button to leave a chat")) {
                            // TODO: Implement leave chat
                        }
                        .foregroundColor(.red)
                    }
                    
                    Button(NSLocalizedString("Report Chat", comment: "Button to report a chat")) {
                        // TODO: Implement report chat
                    }
                    .foregroundColor(.orange)
                }
            }
            .navigationTitle(NSLocalizedString("Chat Info", comment: "Navigation title for chat info screen"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(NSLocalizedString("Done", comment: "Button to dismiss chat info screen")) {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var chatIcon: String {
        switch chat.type {
        case .general: return "person.3.fill"
        case .privateChat: return "person.2.fill"
        case .themed: return "tag.fill"
        case .announcement: return "megaphone.fill"
        case .mixed: return "person.2.badge.gearshape.fill"
        }
    }
}

// MARK: - FAN CHAT RULES DISPLAY VIEW

struct FanChatRulesDisplayView: View {
    @StateObject private var fanChatService = FanChatService.shared
    
    var body: some View {
        List {
            if let rules = fanChatService.chatRules {
                ForEach(rules.rules) { rule in
                    FanChatRuleCard(rule: rule)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                }
            }
        }
        .listStyle(PlainListStyle())
        .navigationTitle(NSLocalizedString("Community Rules", comment: "Navigation title for community rules screen"))
        .navigationBarTitleDisplayMode(.large)
    }
}

// MARK: - MODERATION PANEL VIEW

struct ModerationPanelView: View {
    let message: FanMessage
    let chat: FanChat
    let onAction: (ModerationLog.ModerationAction, String) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var selectedAction: ModerationLog.ModerationAction = .warnUser
    @State private var reason = ""
    @State private var showingConfirmation = false
    @State private var isReasonFocused = false
    
    private let moderationActions: [ModerationLog.ModerationAction] = [
        .deleteMessage, 
        .warnUser, 
        .tempBanUser, 
        .banUser, 
        .muteUser
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header with warning icon
                    VStack(spacing: 12) {
                        Image(systemName: "shield.lefthalf.filled.badge.checkmark")
                            .font(.system(size: 48))
                            .foregroundStyle(.orange, .blue)
                        
                        Text(NSLocalizedString("Moderation Panel", comment: "Title for moderation panel"))
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text(NSLocalizedString("Review the message and select an appropriate action", comment: "Instructions for moderation panel"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 20)
                    
                    // Message Card with enhanced design
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Image(systemName: "message.fill")
                                .font(.caption)
                                .foregroundColor(.orange)
                            
                            Text(NSLocalizedString("Reported Message", comment: "Header for reported message section"))
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.orange)
                            
                            Spacer()
                            
                            Text(formatMessageTime(message.timestamp))
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        
                        // User info and message
                        HStack(alignment: .top, spacing: 12) {
                            // Avatar with border - improved avatar loading
                            Group {
                                if let avatarURL = chat.participantAvatars[message.senderID], 
                                   !avatarURL.isEmpty,
                                   let url = URL(string: avatarURL) {
                                    AsyncImage(url: url) { image in
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                    } placeholder: {
                                        ProgressView()
                                            .scaleEffect(0.5)
                                    }
                                } else {
                                    // Default avatar with user initials
                                    ZStack {
                                        Circle()
                                            .fill(LinearGradient(
                                                colors: [.orange.opacity(0.8), .red.opacity(0.6)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ))
                                        
                                        Text(String(message.displayName.prefix(1)).uppercased())
                                            .font(.headline)
                                            .fontWeight(.bold)
                                            .foregroundColor(.white)
                                    }
                                }
                            }
                            .frame(width: 40, height: 40)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(.orange.opacity(0.4), lineWidth: 2)
                            )
                            .shadow(color: .orange.opacity(0.3), radius: 4, x: 0, y: 2)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text(message.displayName)
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.primary)
                                    
                                    if message.editedAt != nil {
                                        Text("(edited)")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                            .italic()
                                    }
                                }
                                
                                Text(message.content)
                                    .font(.body)
                                    .foregroundColor(.primary)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 20)
                                            .fill(Color(.systemGray6))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 20)
                                                    .stroke(.orange.opacity(0.2), lineWidth: 1)
                                            )
                                    )
                            }
                            
                            Spacer()
                        }
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.systemBackground))
                            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(.orange.opacity(0.2), lineWidth: 1)
                    )
                    
                    // Action Selection with modern cards
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Image(systemName: "gearshape.2.fill")
                                .font(.caption)
                                .foregroundColor(.blue)
                            
                            Text(NSLocalizedString("Select Moderation Action", comment: "Header for moderation action selection"))
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                        
                        // More adaptive grid for better display
                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: 8),
                            GridItem(.flexible(), spacing: 8)
                        ], spacing: 16) {
                            ForEach(moderationActions, id: \.self) { action in
                                ModerationActionCard(
                                    action: action,
                                    isSelected: selectedAction == action,
                                    onTap: {
                                        selectedAction = action
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 4)
                    }
                    
                    // Reason Input with enhanced design
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "doc.text.fill")
                                .font(.caption)
                                .foregroundColor(.green)
                            
                            Text("Reason")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            Text("(Required)")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                        
                        ZStack(alignment: .topLeading) {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(isReasonFocused ? Color(.systemBackground) : Color(.systemGray6))
                                .frame(minHeight: 80)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(
                                            isReasonFocused ? .blue.opacity(0.8) :
                                            reason.isEmpty ? .gray.opacity(0.3) : .green.opacity(0.6), 
                                            lineWidth: isReasonFocused ? 2 : 1
                                        )
                                )
                                .animation(.easeInOut(duration: 0.2), value: isReasonFocused)
                            
                            if reason.isEmpty && !isReasonFocused {
                                Text("Provide a clear reason for this moderation action...")
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 16)
                                    .padding(.top, 12)
                                    .allowsHitTesting(false)
                            }
                            
                            TextEditor(text: $reason)
                                .font(.body)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color.clear)
                                .scrollContentBackground(.hidden)
                                .onTapGesture {
                                    isReasonFocused = true
                                }
                                .onChange(of: reason) { _ in
                                    if !reason.isEmpty && !isReasonFocused {
                                        isReasonFocused = true
                                    }
                                }
                        }
                        
                        // Character count and validation
                        HStack {
                            if !reason.isEmpty {
                                HStack(spacing: 4) {
                                    Image(systemName: reason.count >= 10 ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                                        .font(.caption)
                                        .foregroundColor(reason.count >= 10 ? .green : .orange)
                                    
                                    Text(reason.count >= 10 ? "Good reason provided" : "Reason too short")
                                        .font(.caption)
                                        .foregroundColor(reason.count >= 10 ? .green : .orange)
                                }
                            }
                            
                            Spacer()
                            
                            Text("\(reason.count)/500")
                                .font(.caption)
                                .foregroundColor(reason.count > 450 ? .red : .secondary)
                        }
                    }
                    
                    // Action description
                    if !selectedAction.displayName.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: selectedAction.icon)
                                    .font(.caption)
                                    .foregroundColor(Color(selectedAction.color))
                                
                                Text("Action Details")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                            
                            Text(getActionDescription(selectedAction))
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color(.systemGray6).opacity(0.5))
                                .cornerRadius(8)
                        }
                    }
                    
                    Spacer(minLength: 20)
                    
                    // Action Buttons - Simplified and Clear
                    VStack(spacing: 16) {
                        Button {
                            showingConfirmation = true
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: selectedAction.icon)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                
                                Text("Apply \(selectedAction.displayName)")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                
                                Spacer()
                                
                                if !reason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.title2)
                                        .foregroundColor(.white)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                            .background(
                                reason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty 
                                    ? Color.gray
                                    : Color.red
                            )
                            .foregroundColor(.white)
                            .cornerRadius(12)
                            .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                        }
                        .disabled(reason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        
                        Button("Cancel") {
                            dismiss()
                        }
                        .font(.title3)
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color(.systemGray4))
                        .foregroundColor(.primary)
                        .cornerRadius(12)
                        
                        // Simple status text
                        if reason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            Text("Please provide a reason to proceed")
                                .font(.caption)
                                .foregroundColor(.orange)
                                .padding(.top, 8)
                        } else {
                            Text("Ready to apply moderation action")
                                .font(.caption)
                                .foregroundColor(.green)
                                .padding(.top, 8)
                        }
                    }
                }
                .padding(20)
            }
            .navigationTitle("")
            .navigationBarHidden(true)
            .background(Color(.systemGroupedBackground))
        }
        .alert("Confirm Action", isPresented: $showingConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Confirm", role: .destructive) {
                onAction(selectedAction, reason)
                dismiss()
            }
        } message: {
            Text("Are you sure you want to \(selectedAction.displayName.lowercased()) for:\n\"\(reason)\"")
        }
    }
    
    private func formatMessageTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
    
    private func getActionDescription(_ action: ModerationLog.ModerationAction) -> String {
        switch action {
        case .deleteMessage:
            return "This will hide the message from all users and mark it as moderated."
        case .warnUser:
            return "This will send a warning to the user. After 3 warnings, they will be temporarily banned."
        case .tempBanUser:
            return "This will temporarily ban the user from this chat for 24 hours."
        case .banUser:
            return "This will permanently ban the user from this chat."
        case .muteUser:
            return "This will prevent the user from sending messages for a specified duration."
        default:
            return "This action will be applied to the user or message."
        }
    }
}

// MARK: - Moderation Action Card

struct ModerationActionCard: View {
    let action: ModerationLog.ModerationAction
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                // Header with severity indicator
                HStack {
                    Circle()
                        .fill(severityColor)
                        .frame(width: 8, height: 8)
                    
                    Text(severityLevel)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(Color(action.color))
                    }
                }
                
                // Main action area
                VStack(spacing: 8) {
                    // Icon with background
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(isSelected ? Color(action.color) : Color(action.color).opacity(0.1))
                            .frame(width: 44, height: 44)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color(action.color).opacity(isSelected ? 0.8 : 0.3), lineWidth: 1)
                            )
                        
                        Image(systemName: action.icon)
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(isSelected ? .white : Color(action.color))
                    }
                    
                    // Action title
                    Text(action.displayName)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.center)
                        .foregroundColor(isSelected ? Color(action.color) : .primary)
                        .lineLimit(2)
                    
                    // Quick description
                    Text(quickDescription)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .opacity(isSelected ? 1.0 : 0.7)
                }
                
                Spacer()
                
                // Bottom indicator
                Rectangle()
                    .fill(isSelected ? Color(action.color) : Color.clear)
                    .frame(height: 3)
                    .cornerRadius(1.5)
            }
            .frame(height: 120)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 8)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        isSelected 
                            ? Color(action.color).opacity(0.05)
                            : Color(.systemBackground)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                isSelected ? Color(action.color).opacity(0.4) : Color(.systemGray5),
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
            )
            .scaleEffect(isSelected ? 1.02 : 1.0)
            .shadow(
                color: isSelected ? Color(action.color).opacity(0.15) : .black.opacity(0.03),
                radius: isSelected ? 12 : 6,
                x: 0,
                y: isSelected ? 6 : 3
            )
        }
        .buttonStyle(PlainButtonStyle())
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isSelected)
    }
    
    private var severityLevel: String {
        switch action {
        case .warnUser:
            return "LOW"
        case .deleteMessage, .muteUser:
            return "MEDIUM"
        case .tempBanUser:
            return "HIGH"
        case .banUser:
            return "SEVERE"
        default:
            return "INFO"
        }
    }
    
    private var severityColor: Color {
        switch action {
        case .warnUser:
            return Color.yellow
        case .deleteMessage, .muteUser:
            return Color.orange
        case .tempBanUser:
            return Color.red.opacity(0.7)
        case .banUser:
            return Color.red
        default:
            return Color.blue
        }
    }
    
    private var quickDescription: String {
        switch action {
        case .deleteMessage:
            return "Hide message from chat"
        case .warnUser:
            return "Send warning notice"
        case .tempBanUser:
            return "24 hour timeout"
        case .banUser:
            return "Permanent removal"
        case .muteUser:
            return "Silence for period"
        default:
            return "Apply action"
        }
    }
}
