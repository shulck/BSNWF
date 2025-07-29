import SwiftUI
import FirebaseAuth
import PhotosUI
import Combine

class ImageManager: ObservableObject {
    @Published var selectedImage: UIImage?
}

// ViewModel для лучшего управления состоянием
class ChatDetailViewModel: ObservableObject {
    @Published var messages: [Message] = []
    @Published var isLoading = false
    @Published var showingImagePicker = false
    @Published var replyingTo: Message?
    @Published var editingMessage: Message?
    @Published var showingMessageOptions = false
    @Published var selectedMessage: Message?
    @Published var isLoadingOlderMessages = false
    @Published var isSendingImage = false
    @Published var showingError = false
    @Published var errorMessage = ""
    @Published var showingDeleteChatConfirmation = false
    
    private var cancellables = Set<AnyCancellable>()
    private var typingTimer: Timer?
    
    let chat: Chat
    let chatService = ChatService.shared
    let userService = UserService.shared
    
    init(chat: Chat) {
        self.chat = chat
    }
    
    deinit {
        cleanup()
    }
    
    private func cleanup() {
        typingTimer?.invalidate()
        chatService.stopListeningToMessages()
        stopTyping()
        cancellables.removeAll()
    }
    
    // MARK: - Message Management
    
    func loadMessages() {
        guard let chatId = chat.id else { return }
        
        // Clear previous messages
        messages.removeAll()
        
        chatService.startListeningToMessages(for: chatId)
        
        chatService.$currentMessages
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newMessages in
                // Only update if this is for our chat
                if self?.chatService.currentChatId == chatId {
                    self?.messages = newMessages
                }
            }
            .store(in: &cancellables)
    }
    
    func loadOlderMessages() {
        guard let firstMessage = messages.first,
              let chatId = chat.id,
              !isLoadingOlderMessages else { return }
        
        isLoadingOlderMessages = true
        
        chatService.loadOlderMessages(for: chatId, before: firstMessage) { [weak self] olderMessages in
            DispatchQueue.main.async {
                self?.isLoadingOlderMessages = false
                
                if !olderMessages.isEmpty {
                    self?.messages.insert(contentsOf: olderMessages, at: 0)
                }
            }
        }
    }
    
    func sendMessage(messageText: String) {
        guard !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              let chatId = chat.id else { return }
        
        let currentUserId = Auth.auth().currentUser?.uid ?? ""
        let message = Message(
            chatId: chatId,
            content: messageText,
            senderID: currentUserId,
            senderName: getCurrentUserName(),
            timestamp: Date(),
            type: .text,
            replyToMessageId: replyingTo?.id,
            replyToContent: replyingTo?.content,
            replyToSenderName: replyingTo?.senderName
        )
        
        chatService.sendMessage(message) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    self?.replyingTo = nil
                case .failure(let error):
                    self?.showError("Failed to send message: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func sendImageMessage(_ image: UIImage) {
        guard let chatId = chat.id else { return }
        
        isSendingImage = true
        let currentUserId = Auth.auth().currentUser?.uid ?? ""
        let message = Message(
            chatId: chatId,
            content: "",
            senderID: currentUserId,
            senderName: getCurrentUserName(),
            timestamp: Date(),
            type: .image,
            replyToMessageId: replyingTo?.id,
            replyToContent: replyingTo?.content,
            replyToSenderName: replyingTo?.senderName
        )
        
        chatService.sendImageMessage(message, image: image) { [weak self] result in
            DispatchQueue.main.async {
                self?.isSendingImage = false
                
                switch result {
                case .success:
                    self?.replyingTo = nil
                case .failure(let error):
                    self?.showError("Failed to send image: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func deleteMessage(_ message: Message) {
        guard let messageId = message.id else { return }
        
        chatService.deleteMessage(messageId) { result in
            switch result {
            case .success:
                break
            case .failure(let error):
                print("Error deleting message: \(error)")
            }
        }
    }
    
    // ИСПРАВЛЕНИЕ: Улучшенный метод markMessagesAsRead
    func markMessagesAsRead() {
        guard let chatId = chat.id else { return }
        
        let currentUserId = Auth.auth().currentUser?.uid ?? ""
        let unreadMessages = messages.filter { !$0.readBy.keys.contains(currentUserId) }
        
        // ИСПРАВЛЕНИЕ: Всегда помечаем чат как прочитанный, даже если нет непрочитанных сообщений
        UnifiedBadgeManager.shared.markChatAsRead(chatId)
        
        // Если есть непрочитанные сообщения, помечаем их в Firebase
        if !unreadMessages.isEmpty {
            DispatchQueue.global(qos: .utility).async {
                for message in unreadMessages {
                    if let messageId = message.id {
                        self.chatService.markMessageAsRead(messageId, userId: currentUserId) { _ in
                            // Silent completion
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Typing Management
    
    func handleTypingChange(_ newValue: String) {
        guard let chatId = chat.id else { return }
        
        let trimmedValue = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if !trimmedValue.isEmpty {
            chatService.startTyping(in: chatId)
            
            typingTimer?.invalidate()
            typingTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { [weak self] _ in
                self?.stopTyping()
            }
        } else {
            stopTyping()
        }
    }
    
    func stopTyping() {
        guard let chatId = chat.id else { return }
        
        typingTimer?.invalidate()
        typingTimer = nil
        chatService.stopTyping(in: chatId)
    }
    
    // MARK: - Helper Methods
    
    private func getCurrentUserName() -> String {
        let currentUserId = Auth.auth().currentUser?.uid ?? ""
        if let user = userService.users.first(where: { $0.id == currentUserId }) {
            return user.name
        }
        return userService.currentUser?.name ?? "Unknown".localized
    }
    
    func showError(_ message: String) {
        errorMessage = message
        showingError = true
    }
    
    private func extractMentions(from text: String) -> [String] {
        let pattern = "@([A-Za-z0-9_]+)"
        let regex = try? NSRegularExpression(pattern: pattern, options: [])
        let range = NSRange(location: 0, length: text.count)
        let matches = regex?.matches(in: text, options: [], range: range) ?? []
        
        return matches.compactMap { match in
            if let range = Range(match.range(at: 1), in: text) {
                return String(text[range])
            }
            return nil
        }
    }
}

struct ChatDetailView: View {
    let chat: Chat
    @StateObject private var viewModel: ChatDetailViewModel
    @StateObject private var imageManager = ImageManager()
    @StateObject private var groupService = GroupService.shared
    @State private var messageText = ""
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isTextFieldFocused: Bool
    
    // Sheet management for actions from confirmationDialog
    @State private var showingShareSheet = false
    @State private var showingIntegrationSheet = false
    
    init(chat: Chat) {
        self.chat = chat
        self._viewModel = StateObject(wrappedValue: ChatDetailViewModel(chat: chat))
    }
    
    private var currentUserId: String {
        Auth.auth().currentUser?.uid ?? ""
    }
    
    private var navigationTitle: String {
        switch chat.type {
        case .direct:
            let otherUserId = chat.participants.first { $0 != currentUserId } ?? ""
            
            if let otherUser = viewModel.userService.users.first(where: { $0.id == otherUserId }) {
                return otherUser.name
            }
            
            return "User \(otherUserId.prefix(8))"
            
        case .group:
            return chat.name ?? "Group Chat".localized
            
        case .bandWide:
            return chat.name ?? "Band Announcement".localized
        }
    }
    
    private var navigationTitleView: some View {
        VStack {
            Text(navigationTitle)
                .font(.headline)
                .fontWeight(.semibold)
            
            if !viewModel.chatService.typingUsers.isEmpty {
                Text("\(viewModel.chatService.typingUsers.first ?? "") is typing...".localized)
                    .font(.caption)
                    .foregroundColor(.green)
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 8) {
                        if viewModel.messages.count >= 20 {
                            Button {
                                viewModel.loadOlderMessages()
                            } label: {
                                HStack {
                                    if viewModel.isLoadingOlderMessages {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                    }
                                    
                                    Text(viewModel.isLoadingOlderMessages ? "Loading...".localized : "Load older messages".localized)
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                }
                                .padding(.vertical, 8)
                            }
                            .disabled(viewModel.isLoadingOlderMessages)
                        }
                        
                        ForEach(viewModel.messages, id: \.id) { message in
                            MessageBubbleView(
                                message: message,
                                chat: chat,
                                onReply: { replyMessage in
                                    viewModel.replyingTo = replyMessage
                                }
                            )
                            .onTapGesture {
                                viewModel.selectedMessage = message
                                viewModel.showingMessageOptions = true
                            }
                            .id(message.id)
                        }
                        
                        if !viewModel.chatService.typingUsers.isEmpty {
                            TypingIndicatorView(typingUsers: viewModel.chatService.typingUsers)
                        }
                        
                        if viewModel.isSendingImage {
                            HStack {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("Sending image...".localized)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    isTextFieldFocused = false
                }
                .onAppear {
                    if let lastMessage = viewModel.messages.last, let messageId = lastMessage.id {
                        withAnimation(.easeOut(duration: 0.3)) {
                            proxy.scrollTo(messageId, anchor: .bottom)
                        }
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        if let lastMessage = viewModel.messages.last, let messageId = lastMessage.id {
                            withAnimation(.easeOut(duration: 0.3)) {
                                proxy.scrollTo(messageId, anchor: .bottom)
                            }
                        }
                    }
                }
                .onChange(of: viewModel.messages.count) {
                    if let lastMessage = viewModel.messages.last, let messageId = lastMessage.id {
                        withAnimation(.easeOut(duration: 0.3)) {
                            proxy.scrollTo(messageId, anchor: .bottom)
                        }
                    }
                }
            }
            
            if let replyingTo = viewModel.replyingTo {
                ReplyBannerView(
                    message: replyingTo,
                    onCancel: { viewModel.replyingTo = nil }
                )
            }
            
            if viewModel.editingMessage != nil {
                EditBannerView(
                    onCancel: {
                        viewModel.editingMessage = nil
                        messageText = ""
                    }
                )
            }
            
            MessageInputView(
                text: $messageText,
                isEditing: viewModel.editingMessage != nil,
                isSendingImage: viewModel.isSendingImage,
                onSend: {
                    viewModel.sendMessage(messageText: messageText)
                    messageText = ""
                },
                onImagePick: {
                    viewModel.showingImagePicker = true
                },
                onCancel: {
                    viewModel.editingMessage = nil
                    viewModel.replyingTo = nil
                    messageText = ""
                }
            )
            .focused($isTextFieldFocused)
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                navigationTitleView
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    if chat.canUserDelete(currentUserId) {
                        Button(role: .destructive, action: { viewModel.showingDeleteChatConfirmation = true }) {
                            Label("Delete Chat".localized, systemImage: "trash")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $viewModel.showingImagePicker) {
            ImagePickerView(selectedImage: $imageManager.selectedImage)
                .interactiveDismissDisabled(false)
        }
        .sheet(isPresented: $showingShareSheet) {
            if let selectedMessage = viewModel.selectedMessage {
                ChatShareView(message: selectedMessage, sourceChat: chat)
                    .onAppear {
                        print("📤 ChatDetailView ShareSheet opened")
                    }
            }
        }
        .sheet(isPresented: $showingIntegrationSheet) {
            if let selectedMessage = viewModel.selectedMessage {
                ChatIntegrationView(message: selectedMessage, chat: chat)
                    .onAppear {
                        print("📋 ChatDetailView IntegrationSheet opened")
                    }
            }
        }
        .confirmationDialog("Message Actions".localized, isPresented: $viewModel.showingMessageOptions, presenting: viewModel.selectedMessage) { message in
            Button("Reply".localized) {
                viewModel.replyingTo = message
                isTextFieldFocused = true
            }
            
            if message.senderID == currentUserId {
                Button("Edit".localized) {
                    viewModel.editingMessage = message
                    messageText = message.content
                    isTextFieldFocused = true
                }
                
                Button("Delete".localized, role: .destructive) {
                    viewModel.deleteMessage(message)
                }
            }
            
            Button("Copy".localized) {
                UIPasteboard.general.string = message.content
            }
            
            Button("Share".localized) {
                print("🔄 ChatDetailView Share button pressed")
                showingShareSheet = true
            }
            
            Button("Create Task".localized) {
                print("🔄 ChatDetailView Create Task button pressed")
                showingIntegrationSheet = true
            }
            
            Button("Cancel".localized, role: .cancel) { }
        }
        .alert("Error".localized, isPresented: $viewModel.showingError) {
            Button("OK".localized) {
                viewModel.showingError = false
                viewModel.errorMessage = ""
            }
        } message: {
            Text(viewModel.errorMessage)
        }
        .alert("Delete Chat".localized, isPresented: $viewModel.showingDeleteChatConfirmation) {
            Button("Delete".localized, role: .destructive) {
                deleteChatAndDismiss()
            }
            Button("Cancel".localized, role: .cancel) { }
        } message: {
            Text("Delete Chat Confirmation".localized)
        }
        .onAppear {
            setupView()
        }
        .onDisappear {
            cleanupView()
        }
        .onChange(of: messageText) { _, newValue in
            viewModel.handleTypingChange(newValue)
        }
        .onChange(of: imageManager.selectedImage) { _, image in
            if let image = image {
                viewModel.sendImageMessage(image)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    imageManager.selectedImage = nil
                }
            }
        }
    }
    
    // ИСПРАВЛЕНИЕ: Улучшенный setupView
    private func setupView() {
        // Prevent multiple setups for the same chat
        guard viewModel.messages.isEmpty else { return }
        
        print("ChatDetailView: Setting up view for chat \(chat.id ?? "unknown")")
        
        // Load messages for this specific chat
        viewModel.loadMessages()
        
        // Fetch users to display names and avatars
        viewModel.userService.fetchUsers()
        
        // Load group data for band-wide chats
        if chat.type == .bandWide, let groupId = viewModel.userService.currentUser?.groupId {
            groupService.fetchGroup(by: groupId)
        }
        
        // ИСПРАВЛЕНИЕ: Помечаем сообщения как прочитанные с задержкой
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            viewModel.markMessagesAsRead()
        }
    }
    
    // ИСПРАВЛЕНИЕ: Улучшенный cleanupView
    private func cleanupView() {
        viewModel.chatService.stopListeningToMessages()
        viewModel.stopTyping()
        
        // ИСПРАВЛЕНИЕ: Окончательно помечаем как прочитанные при выходе
        viewModel.markMessagesAsRead()
        
        // ИСПРАВЛЕНИЕ: Принудительно обновляем бейджи
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            UnifiedBadgeManager.shared.forceRefreshBadgeCounts()
        }
    }
    
    private func deleteChatAndDismiss() {
        guard let chatId = chat.id else { return }
        
        viewModel.chatService.deleteChat(chatId) { result in
            switch result {
            case .success:
                DispatchQueue.main.async {
                    UnifiedBadgeManager.shared.refreshBadgeCounts()
                    dismiss()
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    viewModel.showError("Failed to delete chat: \(error.localizedDescription)")
                }
            }
        }
    }
}

struct ReplyBannerView: View {
    let message: Message
    let onCancel: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Reply to message".localized)
                    .font(.caption)
                    .foregroundColor(.blue)
                
                Text(message.content.isEmpty ? "📷 Photo" : message.content)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            Button(action: onCancel) {
                Image(systemName: "xmark")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
    }
}

struct EditBannerView: View {
    let onCancel: () -> Void
    
    var body: some View {
        HStack {
            Text("Edit message".localized)
                .font(.caption)
                .foregroundColor(.orange)
            
            Spacer()
            
            Button(action: onCancel) {
                Image(systemName: "xmark")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
    }
}

struct MessageInputView: View {
    @Binding var text: String
    let isEditing: Bool
    let isSendingImage: Bool
    let onSend: () -> Void
    let onImagePick: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            if !isEditing {
                Button(action: onImagePick) {
                    Image(systemName: "camera")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
                .disabled(isSendingImage)
                .accessibilityLabel("Add photo")
            }
            
            HStack {
                TextField(isEditing ? "Edit message...".localized : "Type a message...".localized, text: $text, axis: .vertical)
                    .textFieldStyle(PlainTextFieldStyle())
                    .lineLimit(1...5)
                
                if isEditing {
                    Button("Cancel".localized, action: onCancel)
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(.systemGray6))
            .cornerRadius(20)
            
            if canSend {
                Button(action: onSend) {
                    Image(systemName: isEditing ? "checkmark" : "arrow.up.circle.fill")
                        .font(.title2)
                        .foregroundColor(canSend ? .blue : .gray)
                }
                .disabled(!canSend || isSendingImage)
                .accessibilityLabel(isEditing ? "Save changes" : "Send message")
            }
        }
        .padding()
        .background(Color(.systemBackground))
    }
    
    private var canSend: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

#Preview {
    NavigationView {
        ChatDetailView(chat: Chat(
            type: .group,
            participants: ["user1", "user2"],
            createdBy: "user1",
            createdAt: Date(),
            updatedAt: Date(),
            name: "Test Chat",
            adminIds: ["user1"]
        ))
    }
}
