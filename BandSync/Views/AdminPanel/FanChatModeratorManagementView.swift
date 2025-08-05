import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct FanChatModeratorManagementView: View {
    @StateObject private var fanChatService = FanChatService.shared
    @StateObject private var appState = AppState.shared
    
    @State private var searchText = ""
    @State private var showingAddModerator = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isLoading = false
    
    @State private var fanUsers: [UserModel] = []
    @State private var globalModerators: Set<String> = []
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if !isCurrentUserAdmin {
                    // Access denied view
                    VStack(spacing: 20) {
                        Image(systemName: "lock.circle.fill")
                            .font(.system(size: 64))
                            .foregroundColor(.red)
                        
                        Text(NSLocalizedString("Access Denied", comment: ""))
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text(NSLocalizedString("Only main app admins can manage fan chat moderators", comment: ""))
                            .font(.body)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                    }
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    // Admin interface
                    mainContent
                }
            }
            .navigationTitle(NSLocalizedString("Fan Chat Moderators", comment: ""))
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                if isCurrentUserAdmin {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(NSLocalizedString("Add Moderator", comment: "")) {
                            showingAddModerator = true
                        }
                    }
                }
            }
            .sheet(isPresented: $showingAddModerator) {
                AddModeratorView(
                    availableFans: fanUsers.filter { !globalModerators.contains($0.id) }
                ) { userId in
                    addGlobalModerator(userId: userId)
                }
            }
            .alert(alertMessage, isPresented: $showingAlert) {
                Button("OK") { }
            }
            .onAppear {
                if isCurrentUserAdmin {
                    loadData()
                }
            }
        }
    }
    
    private var isCurrentUserAdmin: Bool {
        appState.user?.role == .admin
    }
    
    private var mainContent: some View {
        VStack(spacing: 0) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField(NSLocalizedString("Search fans...", comment: ""), text: $searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            .padding()
            
            if isLoading {
                Spacer()
                VStack {
                    ProgressView(NSLocalizedString("Loading fans...", comment: ""))
                    Text(NSLocalizedString("Searching for fans in Firebase...", comment: ""))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 8)
                }
                Spacer()
            } else if fanUsers.isEmpty {
                Spacer()
                VStack(spacing: 16) {
                    Image(systemName: "person.2.slash")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    
                    Text(NSLocalizedString("No Fans Found", comment: ""))
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text(NSLocalizedString("No registered fans found for this group.\nFans need to register with userType 'fan' and fanGroupId matching your group.", comment: ""))
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                    
                    Button(NSLocalizedString("Refresh", comment: "")) {
                        loadData()
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
                Spacer()
            } else {
                // Fan users list
                List {
                    Section(String(format: NSLocalizedString("Fan Users (%d found)", comment: ""), fanUsers.count)) {
                        ForEach(filteredFanUsers, id: \.id) { user in
                            FanUserRow(
                                user: user,
                                isGlobalModerator: globalModerators.contains(user.id),
                                onToggleModerator: { userId in
                                    toggleGlobalModerator(userId: userId)
                                }
                            )
                        }
                    }
                    
                    if !fanChatService.fanChats.isEmpty {
                        Section(NSLocalizedString("Chat-Specific Moderators", comment: "")) {
                            ForEach(fanChatService.fanChats, id: \.id) { chat in
                                if let chatId = chat.id {
                                    ChatModeratorsRow(
                                        chat: chat,
                                        fanUsers: fanUsers,
                                        onAddModerator: { userId in
                                            addChatModerator(userId: userId, chatId: chatId)
                                        },
                                        onRemoveModerator: { userId in
                                            removeChatModerator(userId: userId, chatId: chatId)
                                        }
                                    )
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    private var filteredFanUsers: [UserModel] {
        if searchText.isEmpty {
            return fanUsers
        } else {
            return fanUsers.filter { user in
                user.name.localizedCaseInsensitiveContains(searchText) ||
                user.email.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    // MARK: - Actions
    
    private func loadData() {
        isLoading = true
        
        // Load fan users
        loadFanUsers()
        
        // Load global moderators
        loadGlobalModerators()
        
        // Убираем искусственную задержку - данные загружаются асинхронно
    }
    
    private func loadFanUsers() {
        guard let currentUser = appState.user,
              let groupId = currentUser.groupId else {
            print("❌ Cannot load fans: no group ID")
            print("Current user: \(String(describing: appState.user))")
            isLoading = false
            return
        }
        
        print("🔍 Loading fans for group: \(groupId)")
        
        // Load real fans from Firestore
        let db = Firestore.firestore()
        
        // Попробуем несколько вариантов запроса
        db.collection("users")
            .whereField("userType", isEqualTo: "Fan")
            .whereField("fanGroupId", isEqualTo: groupId)
            .getDocuments { [self] snapshot, error in
                DispatchQueue.main.async {
                    if let error = error {
                        print("❌ Error loading fan users: \(error)")
                        alertMessage = "Failed to load fans: \(error.localizedDescription)"
                        showingAlert = true
                        isLoading = false
                        return
                    }
                    
                    guard let documents = snapshot?.documents else {
                        print("⚠️ No documents returned from query")
                        fanUsers = []
                        isLoading = false
                        return
                    }
                    
                    print("📄 Found \(documents.count) documents")
                    
                    // Отладим первый документ
                    if let firstDoc = documents.first {
                        print("🔍 First document data: \(firstDoc.data())")
                    }
                    
                    fanUsers = documents.compactMap { document in
                        let data = document.data()
                        
                        print("📋 Processing document \(document.documentID)")
                        
                        guard let email = data["email"] as? String,
                              let name = data["name"] as? String else {
                            print("⚠️ Missing required fields for document \(document.documentID)")
                            return nil
                        }
                        
                        print("✅ Creating user: \(name) (\(email))")
                        
                        return UserModel(
                            id: document.documentID,
                            email: email,
                            name: name,
                            phone: data["phone"] as? String ?? "",
                            groupId: nil,
                            role: .member,
                            isOnline: data["isOnline"] as? Bool,
                            lastSeen: (data["lastSeen"] as? Timestamp)?.dateValue(),
                            avatarURL: data["avatarURL"] as? String,
                            userType: .fan,
                            fanGroupId: groupId,
                            fanProfile: parseFanProfile(from: data["fanProfile"] as? [String: Any])
                        )
                    }
                    
                    print("✅ Successfully loaded \(fanUsers.count) fan users")
                    isLoading = false
                }
            }
        
        // Также попробуем запрос без фильтра userType для отладки
        db.collection("users")
            .whereField("fanGroupId", isEqualTo: groupId)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("❌ Debug query error: \(error)")
                } else if let documents = snapshot?.documents {
                    print("🔍 Debug: Found \(documents.count) users with fanGroupId = \(groupId)")
                    for doc in documents {
                        let data = doc.data()
                        print("  - User: \(data["name"] ?? "unknown"), userType: \(data["userType"] ?? "unknown")")
                    }
                }
            }
    }
    
    private func parseFanProfile(from data: [String: Any]?) -> FanProfile? {
        guard let data = data,
              let nickname = data["nickname"] as? String,
              let joinDate = (data["joinDate"] as? Timestamp)?.dateValue(),
              let location = data["location"] as? String,
              let favoriteSong = data["favoriteSong"] as? String else {
            return nil
        }
        
        let levelString = data["level"] as? String ?? "newbie"
        let level = FanLevel(rawValue: levelString) ?? .newbie
        
        let achievements = data["achievements"] as? [String] ?? []
        let isModerator = data["isModerator"] as? Bool ?? false
        
        let stats = parseFanStats(from: data["stats"] as? [String: Any]) ?? FanStats()
        let notificationSettings = parseFanNotifications(from: data["notificationSettings"] as? [String: Any]) ?? FanNotificationSettings()
        
        return FanProfile(
            nickname: nickname,
            joinDate: joinDate,
            location: location,
            favoriteSong: favoriteSong,
            level: level,
            achievements: achievements,
            isModerator: isModerator,
            stats: stats,
            notificationSettings: notificationSettings
        )
    }
    
    private func parseFanStats(from data: [String: Any]?) -> FanStats? {
        guard let data = data else { return nil }
        
        let totalMessages = data["totalMessages"] as? Int ?? 0
        let joinDate = (data["joinDate"] as? Timestamp)?.dateValue() ?? Date()
        let lastActive = (data["lastActive"] as? Timestamp)?.dateValue() ?? Date()
        let merchandisePurchased = data["merchandisePurchased"] as? Int ?? 0
        let concertsAttended = data["concertsAttended"] as? Int ?? 0
        let achievementsUnlocked = data["achievementsUnlocked"] as? Int ?? 0
        
        return FanStats(
            totalMessages: totalMessages,
            joinDate: joinDate,
            lastActive: lastActive,
            merchandisePurchased: merchandisePurchased,
            concertsAttended: concertsAttended,
            achievementsUnlocked: achievementsUnlocked
        )
    }
    
    private func parseFanNotifications(from data: [String: Any]?) -> FanNotificationSettings? {
        guard let data = data else { return nil }
        
        return FanNotificationSettings(
            newConcerts: data["newConcerts"] as? Bool ?? true,
            officialNews: data["officialNews"] as? Bool ?? true,
            chatMessages: data["chatMessages"] as? Bool ?? true,
            newMerch: data["newMerch"] as? Bool ?? false,
            achievements: data["achievements"] as? Bool ?? true,
            moderatorActions: data["moderatorActions"] as? Bool ?? true
        )
    }
    
    private func loadGlobalModerators() {
        guard let currentUser = appState.user,
              let groupId = currentUser.groupId else { return }
        
        // Load global moderators from Firestore
        let db = Firestore.firestore()
        
        db.collection("groups")
            .document(groupId)
            .collection("fanChatModerators")
            .getDocuments { [self] snapshot, error in
                DispatchQueue.main.async {
                    if let error = error {
                        print("Error loading global moderators: \(error)")
                        return
                    }
                    
                    let moderatorIds = snapshot?.documents.compactMap { document in
                        document.documentID
                    } ?? []
                    
                    globalModerators = Set(moderatorIds)
                    print("Loaded \(globalModerators.count) global moderators")
                }
            }
    }
    
    private func addGlobalModerator(userId: String) {
        fanChatService.addFanChatModerator(userId: userId, chatId: nil) { success, message in
            DispatchQueue.main.async {
                if success {
                    globalModerators.insert(userId)
                    alertMessage = message ?? "Moderator added successfully"
                } else {
                    alertMessage = message ?? "Failed to add moderator"
                }
                showingAlert = true
            }
        }
    }
    
    private func toggleGlobalModerator(userId: String) {
        if globalModerators.contains(userId) {
            removeGlobalModerator(userId: userId)
        } else {
            addGlobalModerator(userId: userId)
        }
    }
    
    private func removeGlobalModerator(userId: String) {
        fanChatService.removeFanChatModerator(userId: userId, chatId: nil) { success, message in
            DispatchQueue.main.async {
                if success {
                    globalModerators.remove(userId)
                    alertMessage = message ?? "Moderator removed successfully"
                } else {
                    alertMessage = message ?? "Failed to remove moderator"
                }
                showingAlert = true
            }
        }
    }
    
    private func addChatModerator(userId: String, chatId: String) {
        fanChatService.addFanChatModerator(userId: userId, chatId: chatId) { success, message in
            DispatchQueue.main.async {
                alertMessage = message ?? (success ? "Moderator added successfully" : "Failed to add moderator")
                showingAlert = true
            }
        }
    }
    
    private func removeChatModerator(userId: String, chatId: String) {
        fanChatService.removeFanChatModerator(userId: userId, chatId: chatId) { success, message in
            DispatchQueue.main.async {
                alertMessage = message ?? (success ? "Moderator removed successfully" : "Failed to remove moderator")
                showingAlert = true
            }
        }
    }
    
    
}

// MARK: - Fan User Row

struct FanUserRow: View {
    let user: UserModel
    let isGlobalModerator: Bool
    let onToggleModerator: (String) -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(user.name)
                    .font(.headline)
                
                Text(user.email)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                if isGlobalModerator {
                    Text(NSLocalizedString("Global Moderator", comment: ""))
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.green.opacity(0.2))
                        .foregroundColor(.green)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
                
                Button(isGlobalModerator ? NSLocalizedString("Remove", comment: "") : NSLocalizedString("Make Moderator", comment: "")) {
                    onToggleModerator(user.id)
                }
                .font(.caption)
                .foregroundColor(isGlobalModerator ? .red : .blue)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Chat Moderators Row

struct ChatModeratorsRow: View {
    let chat: FanChat
    let fanUsers: [UserModel]
    let onAddModerator: (String) -> Void
    let onRemoveModerator: (String) -> Void
    
    @State private var showingModeratorPicker = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(chat.displayName)
                    .font(.headline)
                
                Spacer()
                
                Button(NSLocalizedString("Manage", comment: "")) {
                    showingModeratorPicker = true
                }
                .font(.caption)
            }
            
            if !chat.moderatorIds.isEmpty {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 120))], spacing: 8) {
                    ForEach(chat.moderatorIds, id: \.self) { moderatorId in
                        if let user = fanUsers.first(where: { $0.id == moderatorId }) {
                            HStack(spacing: 4) {
                                Text(user.name)
                                    .font(.caption)
                                    .lineLimit(1)
                                
                                Button {
                                    onRemoveModerator(moderatorId)
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.caption)
                                        .foregroundColor(.red)
                                }
                            }
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                        }
                    }
                }
            } else {
                Text(NSLocalizedString("No chat-specific moderators", comment: ""))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .sheet(isPresented: $showingModeratorPicker) {
            ModeratorPickerView(
                availableUsers: fanUsers.filter { !chat.moderatorIds.contains($0.id) },
                onAddModerator: onAddModerator
            )
        }
    }
}

// MARK: - Add Moderator View

struct AddModeratorView: View {
    let availableFans: [UserModel]
    let onAddModerator: (String) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    
    var body: some View {
        NavigationView {
            VStack {
                TextField(NSLocalizedString("Search fans...", comment: ""), text: $searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                
                List(filteredUsers, id: \.id) { user in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(user.name)
                                .font(.headline)
                            Text(user.email)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Button(NSLocalizedString("Add", comment: "")) {
                            onAddModerator(user.id)
                            dismiss()
                        }
                    }
                }
            }
            .navigationTitle(NSLocalizedString("Add Moderator", comment: ""))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(NSLocalizedString("Cancel", comment: "")) {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var filteredUsers: [UserModel] {
        if searchText.isEmpty {
            return availableFans
        } else {
            return availableFans.filter { user in
                user.name.localizedCaseInsensitiveContains(searchText) ||
                user.email.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
}

// MARK: - Moderator Picker View

struct ModeratorPickerView: View {
    let availableUsers: [UserModel]
    let onAddModerator: (String) -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List(availableUsers, id: \.id) { user in
                Button {
                    onAddModerator(user.id)
                    dismiss()
                } label: {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(user.name)
                                .font(.headline)
                                .foregroundColor(.primary)
                            Text(user.email)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.blue)
                    }
                }
            }
            .navigationTitle(NSLocalizedString("Add Chat Moderator", comment: ""))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(NSLocalizedString("Cancel", comment: "")) {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    FanChatModeratorManagementView()
}
