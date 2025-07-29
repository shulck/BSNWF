import SwiftUI
import FirebaseAuth
import FirebaseDatabase

struct ChatsListViewWrapper: View {
    @State private var navigationPath = NavigationPath()
    @State private var isNavigating = false
    @EnvironmentObject private var navigationManager: NavigationManager
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            ChatsListView()
                .navigationDestination(for: NavigationManager.ChatNavigationData.self) { chatData in
                    if let chat = ChatService.shared.chats.first(where: { $0.id == chatData.chatId }) {
                        ChatDetailView(chat: chat)
                            .onAppear {
                                ChatService.shared.startListeningToMessages(for: chatData.chatId)
                            }
                    } else {
                        Text("Loading chat...".localized)
                            .onAppear {
                                ChatService.shared.startListeningToChats()
                            }
                    }
                }
        }
                .onAppear {
                    // ИСПРАВЛЕНИЕ: Отложенная инициализация сервисов
                    DispatchQueue.main.async {
                        _ = ChatService.shared // Ленивая инициализация
                    }
                }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ResetTab3"))) { _ in
            navigationPath = NavigationPath()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("NavigateToChat"))) { notification in
            handleNavigateToChat(notification)
        }
        .onReceive(navigationManager.$chatToOpen) { chatData in
            if let chatData = chatData, !isNavigating {
                isNavigating = true
                
                ChatService.shared.startListeningToChats()
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.navigationPath.append(chatData)
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        self.isNavigating = false
                    }
                }
            }
        }
    }
    
    private func handleNavigateToChat(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let chatId = userInfo["chatId"] as? String else {
            return
        }
        
        let messageId = userInfo["messageId"] as? String ?? ""
        let shouldHighlight = userInfo["shouldHighlight"] as? Bool ?? false
        
        ChatService.shared.startListeningToChats()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.navigateToChat(chatId: chatId, messageId: messageId, shouldHighlight: shouldHighlight)
        }
    }
    
    private func navigateToChat(chatId: String, messageId: String, shouldHighlight: Bool) {
        let chatData = NavigationManager.ChatNavigationData(
            chatId: chatId,
            messageId: messageId.isEmpty ? nil : messageId,
            shouldHighlight: shouldHighlight
        )
        navigationManager.chatToOpen = chatData
    }
}

struct ChatsListView: View {
    @StateObject private var chatService = ChatService.shared
    @StateObject private var userService = UserService.shared
    @StateObject private var groupService = GroupService.shared
    @StateObject private var permissionService = PermissionService.shared
    @StateObject private var badgeManager = UnifiedBadgeManager.shared
    @State private var showingNewChatSheet = false
    @State private var searchText = ""
    @State private var showingContactSelector = false
    @State private var showingGroupChatCreation = false
    @State private var showingBandWideCreation = false
    @State private var hasAppeared = false
    @State private var showingNewChatView = false
    @State private var hasInitialized = false
    @State private var chatToDelete: Chat?
    @State private var showingDeleteConfirmation = false
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""
    
    private let currentUserId = Auth.auth().currentUser?.uid ?? ""
    
    var filteredChats: [Chat] {
        if searchText.isEmpty {
            return chatService.chats.sorted { (chat1, chat2) in
                let time1 = chat1.lastMessage?.timestamp ?? Date.distantPast
                let time2 = chat2.lastMessage?.timestamp ?? Date.distantPast
                return time1 > time2
            }
        } else {
            return chatService.chats.filter { chat in
                if let chatName = chat.name, chatName.localizedCaseInsensitiveContains(searchText) {
                    return true
                }
                for participantId in chat.participants {
                    if let user = userService.users.first(where: { $0.id == participantId }),
                       user.name.localizedCaseInsensitiveContains(searchText) {
                        return true
                    }
                }
                return false
            }.sorted { (chat1, chat2) in
                let time1 = chat1.lastMessage?.timestamp ?? Date.distantPast
                let time2 = chat2.lastMessage?.timestamp ?? Date.distantPast
                return time1 > time2
            }
        }
    }
    
    var body: some View {
        VStack {
            if chatService.isLoading {
                LoadingView()
            } else if filteredChats.isEmpty {
                EmptyChatsView()
            } else {
                List {
                    ForEach(filteredChats, id: \.id) { chat in
                        NavigationLink(destination: ChatDetailView(chat: chat)) {
                            ChatRowView(chat: chat)
                        }
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            if chat.canUserDelete(currentUserId) {
                                Button("Delete".localized, role: .destructive) {
                                    chatToDelete = chat
                                    showingDeleteConfirmation = true
                                }
                            }
                        }
                    }
                }
                .listStyle(PlainListStyle())
                .searchable(text: $searchText, prompt: "Search chats...".localized)
            }
        }
        .navigationTitle("Chats".localized)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showingNewChatView = true
                }) {
                    Image(systemName: "square.and.pencil")
                        .foregroundColor(.blue)
                }
                .accessibilityLabel("New chat".localized)
                .accessibilityHint("Double tap to start a new chat".localized)
            }
        }
        .sheet(isPresented: $showingNewChatView) {
            NewChatView()
        }
        .onAppear {
            guard !hasInitialized else { return }
            hasInitialized = true
            
            chatService.startListeningToChats()
            userService.fetchUsers()
            
            // Load group data for avatars
            if let groupId = userService.currentUser?.groupId {
                groupService.fetchGroup(by: groupId)
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                badgeManager.forceRefreshBadgeCounts()
            }
        }
        .onDisappear {
            
        }
        .alert("Delete Chat?".localized, isPresented: $showingDeleteConfirmation) {
            Button("Cancel".localized, role: .cancel) {
                chatToDelete = nil
            }
            Button("Delete".localized, role: .destructive) {
                if let chat = chatToDelete {
                    deleteChat(chat)
                }
                chatToDelete = nil
            }
        } message: {
            if let chat = chatToDelete {
                Text(String(format: "Delete Chat With Name Confirmation".localized, chat.displayName))
            }
        }
        .alert("Error".localized, isPresented: $showingErrorAlert) {
            Button("OK".localized, role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func deleteChat(_ chat: Chat) {
        guard let chatId = chat.id else { return }
        
        chatService.deleteChat(chatId) { result in
            switch result {
            case .success:
                DispatchQueue.main.async {
                    badgeManager.forceRefreshBadgeCounts()
                }
            case .failure(let error):
                self.errorMessage = "Failed to delete chat: \(error.localizedDescription)"
                self.showingErrorAlert = true
            }
        }
    }
}

struct ChatRowView: View {
    let chat: Chat
    @StateObject private var chatService = ChatService.shared
    @StateObject private var userService = UserService.shared
    @StateObject private var badgeManager = UnifiedBadgeManager.shared
    @State private var lastMessage: Message?
    @State private var unreadCount: Int = 0
    @State private var hasLoadedMessage = false
    @State private var isLoadingMessage = false
    @State private var isCalculatingUnread = false
    
    private var currentUserId: String {
        Auth.auth().currentUser?.uid ?? ""
    }
    
    private var chatDisplayName: String {
        switch chat.type {
        case .direct:
            let otherUserId = chat.participants.first { $0 != currentUserId } ?? ""
            if let otherUser = userService.users.first(where: { $0.id == otherUserId }) {
                return otherUser.name
            }
            return String(format: "User %@".localized, String(otherUserId.prefix(8)))
        case .group:
            return chat.name ?? "Group Chat".localized
        case .bandWide:
            return chat.name ?? "Band Announcement".localized
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            ChatAvatarView(chat: chat, size: 50)
                .frame(width: 50, height: 50)
                .background(Color.clear)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline) {
                    Text(chatDisplayName)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    if let lastMessage = lastMessage {
                        Text(formatMessageTime(lastMessage.timestamp))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                HStack(alignment: .top) {
                    if let lastMessage = lastMessage {
                        Text(formatLastMessage(lastMessage))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    } else {
                        Text("No messages yet".localized)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .italic()
                    }
                    
                    Spacer()
                    
                    if unreadCount > 0 {
                        Text("\(unreadCount)")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.red)
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint("Double tap to open chat".localized)
        .accessibilityValue(unreadCount > 0 ? "\(unreadCount) unread messages".localized : "")
        .onAppear {
            loadLastMessageIfNeeded()
            calculateUnreadCount()
        }
        .onReceive(chatService.$currentMessages) { _ in
            refreshLastMessage()
        }
        .onReceive(badgeManager.$unreadChatsCount.throttle(for: .seconds(1), scheduler: DispatchQueue.main, latest: true)) { _ in
            let lastReadKey = "lastReadTime_\(chat.id ?? "")"
            let lastReadTime = UserDefaults.standard.object(forKey: lastReadKey) as? Date ?? Date().addingTimeInterval(-7 * 24 * 60 * 60)
            
            if Date().timeIntervalSince(lastReadTime) < 5 {
                self.unreadCount = 0
            } else {
                calculateUnreadCount()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .chatMarkedAsRead)) { notification in
            if let chatId = notification.object as? String, chatId == chat.id {
                DispatchQueue.main.async {
                    self.unreadCount = 0
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .messagesUpdated)) { notification in
            if let chatId = notification.object as? String, chatId == chat.id {
                calculateUnreadCount()
            }
        }
    }
    
    private var accessibilityLabel: String {
        let time = lastMessage != nil ? formatMessageTime(lastMessage!.timestamp) : ""
        let lastMsg = lastMessage != nil ? formatLastMessage(lastMessage!) : "No messages yet".localized
        return String(format: "Chat with %@. Last message: %@. %@".localized, chatDisplayName, lastMsg, time)
    }
    
    private func loadLastMessageIfNeeded() {
        guard let chatId = chat.id, !chatId.isEmpty else { return }
        guard !hasLoadedMessage && !isLoadingMessage else { return }
        
        hasLoadedMessage = true
        isLoadingMessage = true
        
        loadLastMessage()
    }
    
    private func refreshLastMessage() {
        guard hasLoadedMessage && !isLoadingMessage else { return }
        
        isLoadingMessage = true
        loadLastMessage()
    }
    
    private func loadLastMessage() {
        guard let chatId = chat.id else {
            isLoadingMessage = false
            return
        }
        
        chatService.getLastMessage(for: chatId) { message in
            DispatchQueue.main.async {
                self.lastMessage = message
                self.isLoadingMessage = false
            }
        }
    }
    
    private func calculateUnreadCount() {
        guard let chatId = chat.id, !isCalculatingUnread else {
            if chat.id == nil {
                self.unreadCount = 0
            }
            return
        }
        
        isCalculatingUnread = true
        
        let lastReadKey = "lastReadTime_\(chatId)"
        let lastReadTime = UserDefaults.standard.object(forKey: lastReadKey) as? Date ?? Date().addingTimeInterval(-7 * 24 * 60 * 60)
        
        let db = Database.database().reference()
        
        db.child("messages").child(chatId)
            .queryOrdered(byChild: "timestamp")
            .queryStarting(atValue: lastReadTime.timeIntervalSince1970 * 1000)
            .observeSingleEvent(of: .value) { snapshot in
                defer { DispatchQueue.main.async { self.isCalculatingUnread = false } }
                
                var chatUnreadCount = 0
                
                for child in snapshot.children {
                    guard let childSnapshot = child as? DataSnapshot,
                          let messageData = childSnapshot.value as? [String: Any] else { continue }
                    
                    let senderId = messageData["senderID"] as? String ?? messageData["senderId"] as? String
                    
                    guard let actualSenderId = senderId,
                          actualSenderId != self.currentUserId,
                          let isDeleted = messageData["isDeleted"] as? Bool,
                          !isDeleted else { continue }
                    
                    if let timestamp = messageData["timestamp"] as? TimeInterval {
                        let messageDate = Date(timeIntervalSince1970: timestamp / 1000)
                        if messageDate > lastReadTime {
                            chatUnreadCount += 1
                        }
                    }
                }
                
                DispatchQueue.main.async {
                    self.unreadCount = chatUnreadCount
                }
            }
    }
    
    private func formatLastMessage(_ message: Message) -> String {
        let isCurrentUser = message.senderID == currentUserId
        let senderName = isCurrentUser ? "You".localized : getSenderName(message.senderID)
        let prefix = chat.type == .direct ? (isCurrentUser ? "You: ".localized : "") : "\(senderName): "
        
        if !message.content.isEmpty {
            return prefix + message.content
        } else if message.imageURL != nil {
            return prefix + "📷 Photo".localized
        } else {
            return prefix + "Message".localized
        }
    }
    
    private func getSenderName(_ senderId: String) -> String {
        if let user = userService.users.first(where: { $0.id == senderId }) {
            return user.name
        }
        return "User \(senderId.prefix(8))"
    }
    
    private func formatMessageTime(_ timestamp: Date) -> String {
        let formatter = DateFormatter()
        let calendar = Calendar.current
        
        if calendar.isDate(timestamp, inSameDayAs: Date()) {
            formatter.timeStyle = .short
            return formatter.string(from: timestamp)
        } else if calendar.isDate(timestamp, inSameDayAs: Date().addingTimeInterval(-86400)) {
            return "Yesterday".localized
        } else {
            formatter.dateStyle = .short
            return formatter.string(from: timestamp)
        }
    }
}

struct ChatAvatarView: View {
    let chat: Chat
    let size: CGFloat
    @StateObject private var userService = UserService.shared
    @StateObject private var groupService = GroupService.shared
    
    var body: some View {
        ZStack {
            if chat.type == .direct {
                if let otherParticipant = getOtherParticipant() {
                    AvatarView(user: otherParticipant, size: size)
                } else {
                    defaultChatAvatar
                }
            } else {
                groupChatAvatar
            }
        }
        .frame(width: size, height: size)
        .background(Color.clear)
    }
    
    private var defaultChatAvatar: some View {
        ZStack {
            Circle()
                .fill(LinearGradient(
                    gradient: Gradient(colors: [Color.blue.opacity(0.6), Color.purple.opacity(0.6)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .frame(width: size, height: size)
            
            Image(systemName: "person.fill")
                .foregroundColor(.white)
                .font(.system(size: size * 0.4))
        }
    }
    
    private var groupChatAvatar: some View {
        ZStack {
            if chat.type == .bandWide {
                // Show group logo for band-wide chats
                if let group = groupService.group {
                    GroupAvatarView(group: group, size: size)
                } else {
                    // Fallback to default band icon
                    Circle()
                        .fill(LinearGradient(
                            gradient: Gradient(colors: [Color.orange.opacity(0.6), Color.red.opacity(0.6)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: size, height: size)
                    
                    Image(systemName: "music.note.house.fill")
                        .foregroundColor(.white)
                        .font(.system(size: size * 0.4))
                }
            } else {
                // Regular group chat
                Circle()
                    .fill(LinearGradient(
                        gradient: Gradient(colors: [Color.purple.opacity(0.6), Color.blue.opacity(0.6)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: size, height: size)
                
                Image(systemName: "person.3.fill")
                    .foregroundColor(.white)
                    .font(.system(size: size * 0.4))
            }
        }
    }
    
    private func getOtherParticipant() -> UserModel? {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return nil }
        let otherParticipantId = chat.participants.first { $0 != currentUserId }
        return userService.users.first { $0.id == otherParticipantId }
    }
}

struct EmptyChatsView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "message")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("No Chats".localized)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Text("Create a new chat to start communicating with band members".localized)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .padding()
    }
}

struct LoadingView: View {
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("Loading chats...".localized)
                .font(.body)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}

#Preview {
    NavigationView {
        ChatsListView()
    }
}
