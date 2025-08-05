import SwiftUI
import FirebaseAuth

struct MessageBubbleView: View {
    let message: Message
    let chat: Chat
    let onReply: ((Message) -> Void)?
    @StateObject private var chatService = ChatService.shared
    @StateObject private var userService = UserService.shared
    @State private var showingImageViewer = false
    @State private var showingActionSheet = false
    @State private var showingEditAlert = false
    @State private var editText = ""
    @State private var showingShareSheet = false
    @State private var showingIntegrationSheet = false
    @State private var showingDeleteConfirmation = false
    
    private var isCurrentUser: Bool {
        message.senderID == Auth.auth().currentUser?.uid
    }
    
    private var senderName: String {
        if isCurrentUser {
            return NSLocalizedString("you", comment: "You (current user indicator)")
        }
        if let user = userService.users.first(where: { $0.id == message.senderID }) {
            return user.name
        }
        return message.senderName.isEmpty ? NSLocalizedString("unknown", comment: "Unknown user") : message.senderName
    }
    
    private var accessibilityLabel: String {
        let sender = isCurrentUser ? NSLocalizedString("you", comment: "You (current user indicator)") : senderName
        let time = DateFormatter.localizedString(from: message.timestamp, dateStyle: .none, timeStyle: .short)
        
        switch message.type {
        case .text:
            return String.localizedStringWithFormat(NSLocalizedString("userSaidMessageAtTime", comment: "User said message at time"), sender, message.content, time)
        case .image:
            return String.localizedStringWithFormat(NSLocalizedString("userSentImageAtTime", comment: "User sent an image at time"), sender, time)
        case .reply:
            return String.localizedStringWithFormat(NSLocalizedString("userRepliedMessageAtTime", comment: "User replied message at time"), sender, message.content, time)
        default:
            return String.localizedStringWithFormat(NSLocalizedString("userSentMessageAtTime", comment: "User sent a message at time"), sender, time)
        }
    }
    
    private var accessibilityHint: String {
        let deleteHint = NSLocalizedString("doubleTapToDeleteLongPressForOptions", comment: "Double tap to delete, long press for options")
        let optionsHint = NSLocalizedString("longPressForOptions", comment: "Long press for options")
        
        return isCurrentUser ? deleteHint : optionsHint
    }
    
    var body: some View {
        VStack(alignment: isCurrentUser ? .trailing : .leading, spacing: 4) {
            senderNameView
            replyPreviewView
            messageContentHStack
        }
        .onAppear {
            // Ensure user data is loaded for this message
            if !isCurrentUser && userService.users.first(where: { $0.id == message.senderID }) == nil {
                userService.fetchUsers()
            }
        }
        .sheet(isPresented: $showingImageViewer) {
            if let imageURL = message.imageURL {
                ImageViewerSheet(imageUrl: imageURL)
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            ChatShareView(message: message, sourceChat: chat)
                .onAppear {
                    print("📤 ShareSheet is about to be presented")
                }
        }
        .sheet(isPresented: $showingIntegrationSheet) {
            ChatIntegrationView(message: message, chat: chat)
                .onAppear {
                    print("📋 IntegrationSheet is about to be presented")
                }
        }
        .alert(NSLocalizedString("Delete Message", comment: "Alert title for deleting a message"), isPresented: $showingDeleteConfirmation) {
            Button(NSLocalizedString("cancel", comment: "Cancel button"), role: .cancel) { }
            Button(NSLocalizedString("delete", comment: "Delete button"), role: .destructive) {
                deleteMessage()
            }
        } message: {
            Text(NSLocalizedString("Delete Message Confirmation", comment: "Confirmation message for deleting a message"))
        }
        .alert(NSLocalizedString("Edit Message", comment: "Alert title for editing a message"), isPresented: $showingEditAlert) {
            TextField(NSLocalizedString("Message", comment: "Placeholder for message input field"), text: $editText)
            Button(NSLocalizedString("Cancel", comment: "Cancel button in edit message alert"), role: .cancel) { }
            Button(NSLocalizedString("Save", comment: "Save button in edit message alert")) {
                editMessage()
            }
        }
        .actionSheet(isPresented: $showingActionSheet) {
            ActionSheet(
                title: Text(NSLocalizedString("Message Actions", comment: "Action sheet title for message actions")),
                buttons: createActionSheetButtons()
            )
        }
    }
    
    @ViewBuilder
    private var senderNameView: some View {
        if !isCurrentUser && (chat.type == .group || chat.type == .bandWide) {
            Text(senderName)
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal, 16)
        }
    }
    
    @ViewBuilder
    private var replyPreviewView: some View {
        if message.replyToMessageId != nil {
            ReplyPreviewView(
                replyToContent: message.replyToContent ?? NSLocalizedString("message", comment: "Message fallback"),
                replyToSenderName: message.replyToSenderName ?? NSLocalizedString("unknown", comment: "Unknown user")
            )
            .padding(.horizontal, isCurrentUser ? 16 : 0)
        }
    }
    
    private var messageContentHStack: some View {
        HStack(alignment: .bottom, spacing: 8) {
            // Avatar section - only for messages from other users
            if !isCurrentUser && (chat.type == .group || chat.type == .bandWide) {
                if let sender = userService.users.first(where: { $0.id == message.senderID }) {
                    AvatarView(user: sender, size: 32)
                } else {
                    // Fallback avatar while user data is loading
                    AvatarView(avatarURL: nil, name: message.senderName.isEmpty ? NSLocalizedString("user", comment: "User fallback") : message.senderName, size: 32)
                }
            }
            
            // Message bubble with spacers
            VStack {
                HStack {
                    if isCurrentUser {
                        Spacer(minLength: 80)
                    }
                    
                    messageBubble
                    
                    if !isCurrentUser {
                        Spacer(minLength: 80)
                    }
                }
            }
        }
        .onAppear {
            // Load users if not already loaded
            if userService.users.isEmpty {
                loadUsersIfNeeded()
            }
        }
    }
    
    private var messageBubble: some View {
        VStack(alignment: isCurrentUser ? .trailing : .leading, spacing: 0) {
            // Основное содержимое сообщения
            VStack(alignment: .leading, spacing: 8) {
                MessageContentView(message: message, showingImageViewer: $showingImageViewer)
                MessageFooterView(message: message, isCurrentUser: isCurrentUser)
            }
            .padding(12)
            .background(bubbleBackground)
            .foregroundColor(bubbleTextColor)
            
            // ✅ НОВОЕ: Реакции НАД сообщением как в WhatsApp
            if !message.reactions.isEmpty {
                WhatsAppStyleReactionsView(message: message, isCurrentUser: isCurrentUser)
                    .padding(.top, -8) // Небольшое наложение
                    .padding(.horizontal, 8)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(accessibilityHint)
        .accessibilityAddTraits(isCurrentUser ? [.isButton] : [])
        // ✅ ИСПРАВЛЕНО: Компактное контекстное меню
        .contextMenu {
            CompactMessageContextMenu(
                message: message,
                isCurrentUser: isCurrentUser,
                onReply: { onReply?(message) },
                onEdit: {
                    editText = message.content
                    showingEditAlert = true
                },
                onDelete: { showingDeleteConfirmation = true },
                onCopy: { copyMessageText() },
                onReact: { emoji in addReaction(emoji) },
                onShare: { 
                    print("🔄 Share button pressed")
                    showingShareSheet = true
                    print("📤 showingShareSheet set to: \(showingShareSheet)")
                },
                onIntegrate: { 
                    print("🔄 Create Task button pressed")
                    showingIntegrationSheet = true
                    print("📋 showingIntegrationSheet set to: \(showingIntegrationSheet)")
                }
            )
        }
        .onTapGesture(count: 2) {
            if isCurrentUser {
                showingDeleteConfirmation = true
            }
        }
    }
    
    // ✅ ИСПРАВЛЕНО: Новый дизайн с лучшей видимостью статусов
    private var bubbleBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(bubbleBackgroundColor)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(bubbleBorderColor, lineWidth: isCurrentUser ? 1 : 0)
            )
    }
    
    // ✅ НОВОЕ: Более контрастные цвета
    private var bubbleBackgroundColor: Color {
        if isCurrentUser {
            // Светло-серый вместо синего для лучшей читаемости
            return Color(.systemGray6)
        } else {
            return Color(.systemGray5).opacity(0.8)
        }
    }
    
    private var bubbleBorderColor: Color {
        if isCurrentUser {
            // Тонкая синяя рамка для обозначения твоих сообщений
            return Color.blue.opacity(0.6)
        } else {
            return Color.clear
        }
    }
    
    private var bubbleTextColor: Color {
        // Всегда темный текст для лучшей читаемости
        return Color.primary
    }
    
    private func createActionSheetButtons() -> [ActionSheet.Button] {
        var buttons: [ActionSheet.Button] = []
        
        // ✅ ИСПРАВЛЕНО: Только самые важные действия
        buttons.append(.default(Text(NSLocalizedString("Reply", comment: "Reply button in message actions"))) {
            onReply?(message)
        })
        
        if !message.content.isEmpty {
            buttons.append(.default(Text(NSLocalizedString("Copy", comment: "Copy button in message actions"))) {
                copyMessageText()
            })
        }
        
        // Быстрые реакции
        buttons.append(.default(Text("👍")) { addReaction("👍") })
        buttons.append(.default(Text("❤️")) { addReaction("❤️") })
        buttons.append(.default(Text("😂")) { addReaction("😂") })
        
        // Дополнительные действия
        buttons.append(.default(Text(NSLocalizedString("Share", comment: "Share button in message actions"))) {
            print("🔄 ActionSheet Share button pressed")
            showingShareSheet = true
            print("📤 ActionSheet showingShareSheet set to: \(showingShareSheet)")
        })
        
        buttons.append(.default(Text(NSLocalizedString("Create Task", comment: "Create task button in message actions"))) {
            print("🔄 ActionSheet Create Task button pressed")
            showingIntegrationSheet = true
            print("📋 ActionSheet showingIntegrationSheet set to: \(showingIntegrationSheet)")
        })
        
        // Только для своих сообщений
        if isCurrentUser {
            if !message.content.isEmpty {
                buttons.append(.default(Text(NSLocalizedString("Edit", comment: "Edit button in message actions"))) {
                    editText = message.content
                    showingEditAlert = true
                })
            }
            
            buttons.append(.destructive(Text(NSLocalizedString("Delete", comment: "Delete button in message actions"))) {
                showingDeleteConfirmation = true
            })
        }
        
        buttons.append(.cancel())
        return buttons
    }
    
    private func copyMessageText() {
        UIPasteboard.general.string = message.content
    }
    
    private func editMessage() {
        guard !editText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              let messageId = message.id else { return }
        
        chatService.editMessage(messageId, newContent: editText.trimmingCharacters(in: .whitespacesAndNewlines)) { result in
            
        }
    }
    
    private func deleteMessage() {
        guard let messageId = message.id else { return }
        
        chatService.deleteMessage(messageId) { result in
            // Handle result silently
        }
    }
    
    private func addReaction(_ emoji: String) {
        guard let currentUserId = Auth.auth().currentUser?.uid,
              let messageId = message.id else { return }
        
        chatService.addReaction(to: messageId, emoji: emoji, userId: currentUserId) { result in
            
        }
    }
}

struct MessageContentView: View {
    let message: Message
    @Binding var showingImageViewer: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let imageURL = message.imageURL, !imageURL.isEmpty && imageURL != "placeholder_image_url" {
                AsyncImage(url: URL(string: imageURL)) { phase in
                    switch phase {
                    case .empty:
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 200, height: 150)
                            .overlay {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                            }
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(maxWidth: 250, maxHeight: 300)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .onTapGesture {
                                showingImageViewer = true
                            }
                    case .failure(_):
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.red.opacity(0.3))
                            .frame(width: 200, height: 150)
                            .overlay {
                                VStack {
                                    Image(systemName: "exclamationmark.triangle")
                                        .foregroundColor(.red)
                                    Text(NSLocalizedString("Failed to load", comment: "Error message when content fails to load"))
                                        .font(.caption)
                                        .foregroundColor(.red)
                                }
                            }
                    @unknown default:
                        EmptyView()
                    }
                }
            }
            
            if !message.content.isEmpty {
                Text(message.content)
                    .font(.body)
                    .textSelection(.enabled)
            }
            
            if message.isEdited {
                Text(NSLocalizedString("edited", comment: "Label indicating message was edited"))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .italic()
            }
        }
    }
}

// ✅ ИСПРАВЛЕНО: Улучшенная видимость статусов сообщений
struct MessageFooterView: View {
    let message: Message
    let isCurrentUser: Bool
    
    var body: some View {
        HStack(spacing: 6) {
            Text(formatTime(message.timestamp))
                .font(.caption2)
                .foregroundColor(.secondary)
            
            if isCurrentUser {
                // ✅ ИСПРАВЛЕНО: Контрастные иконки статусов
                HStack(spacing: 2) {
                    if !message.readBy.isEmpty {
                        // Прочитано - синяя двойная галочка
                        Image(systemName: "checkmark")
                            .font(.caption2)
                            .foregroundColor(.blue)
                        Image(systemName: "checkmark")
                            .font(.caption2)
                            .foregroundColor(.blue)
                            .offset(x: -3)
                    } else {
                        // Доставлено - серая одинарная галочка
                        Image(systemName: "checkmark")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// ✅ НОВОЕ: Реакции в стиле WhatsApp
struct WhatsAppStyleReactionsView: View {
    let message: Message
    let isCurrentUser: Bool
    @StateObject private var chatService = ChatService.shared
    
    var body: some View {
        HStack(spacing: 6) {
            if isCurrentUser {
                Spacer()
            }
            
            HStack(spacing: 4) {
                ForEach(Array(message.reactions.keys.sorted()), id: \.self) { emoji in
                    if let userIds = message.reactions[emoji], !userIds.isEmpty {
                        ReactionBubble(
                            emoji: emoji,
                            count: userIds.count,
                            isUserReacted: userIds.contains(Auth.auth().currentUser?.uid ?? ""),
                            onTap: {
                                toggleReaction(emoji)
                            }
                        )
                    }
                }
            }
            
            if !isCurrentUser {
                Spacer()
            }
        }
    }
    
    private func toggleReaction(_ emoji: String) {
        guard let currentUserId = Auth.auth().currentUser?.uid,
              let messageId = message.id else { return }
        
        chatService.addReaction(to: messageId, emoji: emoji, userId: currentUserId) { _ in }
    }
}

// ✅ НОВОЕ: Отдельная капсула для каждой реакции
struct ReactionBubble: View {
    let emoji: String
    let count: Int
    let isUserReacted: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 4) {
                Text(emoji)
                    .font(.caption)
                
                if count > 1 {
                    Text("\(count)")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(isUserReacted ? .white : .secondary)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(isUserReacted ? Color.blue : Color(.systemGray5))
                    .overlay(
                        Capsule()
                            .stroke(Color(.systemGray4), lineWidth: 0.5)
                    )
            )
            .foregroundColor(isUserReacted ? .white : .primary)
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isUserReacted ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isUserReacted)
    }
}

struct ReplyPreviewView: View {
    let replyToContent: String
    let replyToSenderName: String
    
    var body: some View {
        HStack(spacing: 8) {
            Rectangle()
                .fill(Color.blue)
                .frame(width: 3)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(replyToSenderName)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)
                
                Text(replyToContent.isEmpty ? NSLocalizedString("photo", comment: "Photo message type") : replyToContent)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.1))
        )
    }
}

// ✅ НОВОЕ: Компактное контекстное меню
struct CompactMessageContextMenu: View {
    let message: Message
    let isCurrentUser: Bool
    let onReply: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onCopy: () -> Void
    let onReact: (String) -> Void
    let onShare: () -> Void
    let onIntegrate: () -> Void
    
    var body: some View {
        Group {
            // Основные действия
            Button(NSLocalizedString("reply", comment: "Reply button"), action: onReply)
            
            if !message.content.isEmpty {
                Button(NSLocalizedString("copy", comment: "Copy button"), action: onCopy)
            }
            
            // Только самые популярные реакции
            Button("👍") { onReact("👍") }
            Button("❤️") { onReact("❤️") }
            Button("😂") { onReact("😂") }
            
            // Действия владельца сообщения
            if isCurrentUser {
                Divider()
                
                if !message.content.isEmpty {
                    Button(NSLocalizedString("edit", comment: "Edit button"), action: onEdit)
                }
                
                Button(NSLocalizedString("delete", comment: "Delete button"), role: .destructive, action: onDelete)
            }
        }
    }
}

struct MessageContextMenu: View {
    let message: Message
    let chat: Chat
    let isCurrentUser: Bool
    let onReply: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onCopy: () -> Void
    let onReact: (String) -> Void
    let onShare: () -> Void
    let onIntegrate: () -> Void
    
    var body: some View {
        Group {
            Button(NSLocalizedString("reply", comment: "Reply button"), action: onReply)
            
            if !message.content.isEmpty {
                Button(NSLocalizedString("copy", comment: "Copy button"), action: onCopy)
            }
            
            Button("👍") { onReact("👍") }
            Button("❤️") { onReact("❤️") }
            Button("😂") { onReact("😂") }
            Button("😮") { onReact("😮") }
            Button("😢") { onReact("😢") }
            Button("😡") { onReact("😡") }
            
            Divider()
            
            Button(NSLocalizedString("share", comment: "Share button"), action: onShare)
            Button(NSLocalizedString("createTask", comment: "Create task button"), action: onIntegrate)
            
            if isCurrentUser && !message.content.isEmpty {
                Button(NSLocalizedString("edit", comment: "Edit button"), action: onEdit)
            }
            
            if isCurrentUser {
                Button(NSLocalizedString("delete", comment: "Delete button"), role: .destructive, action: onDelete)
            }
        }
    }
}

struct ImageViewerSheet: View {
    let imageUrl: String
    @Environment(\.dismiss) private var dismiss
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                AsyncImage(url: URL(string: imageUrl)) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.5)
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .scaleEffect(scale)
                            .gesture(
                                MagnificationGesture()
                                    .onChanged { value in
                                        scale = lastScale * value
                                    }
                                    .onEnded { value in
                                        lastScale = scale
                                        if scale < 1.0 {
                                            withAnimation(.spring()) {
                                                scale = 1.0
                                                lastScale = 1.0
                                            }
                                        } else if scale > 5.0 {
                                            withAnimation(.spring()) {
                                                scale = 5.0
                                                lastScale = 5.0
                                            }
                                        }
                                    }
                            )
                            .onTapGesture(count: 2) {
                                withAnimation(.spring()) {
                                    if scale > 1.0 {
                                        scale = 1.0
                                        lastScale = 1.0
                                    } else {
                                        scale = 2.0
                                        lastScale = 2.0
                                    }
                                }
                            }
                    case .failure(_):
                        VStack {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 50))
                                .foregroundColor(.white)
                            Text(NSLocalizedString("Failed to load image", comment: "Error message when image fails to load"))
                                .foregroundColor(.white)
                                .font(.headline)
                        }
                    @unknown default:
                        EmptyView()
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(NSLocalizedString("Close", comment: "Close button")) {
                        dismiss()
                    }
                    .foregroundColor(.white)
                    .fontWeight(.semibold)
                }
            }
            .preferredColorScheme(.dark)
        }
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let uiImage = info[.originalImage] as? UIImage {
                parent.selectedImage = uiImage
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

// MARK: - Helper Methods

extension MessageBubbleView {
    private func loadUsersIfNeeded() {
        guard let currentUser = userService.currentUser,
              let groupId = currentUser.groupId else { return }
        
        userService.fetchUsers(for: groupId) { _ in
            // Users loaded, view will refresh automatically
        }
    }
}

#Preview {
    let sampleMessage = Message(
        id: "sample",
        chatId: "chat1",
        content: NSLocalizedString("sampleMessageContent", comment: "Sample message content for preview"),
        senderID: "user1",
        senderName: NSLocalizedString("sampleUser1", comment: "Sample user 1 name"),
        timestamp: Date(),
        type: .text,
        reactions: ["👍": ["user2"], "❤️": ["user3", "user4"]]
    )
    
    let sampleChat = Chat(
        type: .direct,
        participants: ["user1", "user2"],
        createdBy: "user1",
        createdAt: Date(),
        updatedAt: Date(),
        name: NSLocalizedString("testChat", comment: "Test chat name")
    )
    
    VStack(spacing: 20) {
        MessageBubbleView(message: sampleMessage, chat: sampleChat, onReply: nil)
        
        // Пример чужого сообщения
        MessageBubbleView(message: Message(
            id: "sample2",
            chatId: "chat1",
            content: NSLocalizedString("sampleMessageFromOtherUser", comment: "Sample message from another user"),
            senderID: "user2",
            senderName: NSLocalizedString("otherUser", comment: "Other user name"),
            timestamp: Date(),
            type: .text
        ), chat: sampleChat, onReply: nil)
    }
    .padding()
}
