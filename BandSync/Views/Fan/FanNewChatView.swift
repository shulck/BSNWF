import SwiftUI
import FirebaseAuth
import FirebaseFirestore

// MARK: - FAN NEW CHAT VIEW

struct FanNewChatView: View {
    @StateObject private var fanChatService = FanChatService.shared
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var selectedChatType: FanChat.FanChatType = .privateChat
    @State private var searchText = ""
    @State private var selectedFans: Set<String> = []
    @State private var chatName = ""
    @State private var chatDescription = ""
    @State private var isCreating = false
    @State private var canCreateThemedChats = false
    
    // Mock data - replace with actual fan service
    @State private var availableFans: [UserModel] = []
    
    private var filteredFans: [UserModel] {
        if searchText.isEmpty {
            return availableFans
        } else {
            return availableFans.filter { fan in
                fan.displayName.localizedCaseInsensitiveContains(searchText) ||
                (fan.fanProfile?.nickname.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
    }
    
    private var canCreateChat: Bool {
        switch selectedChatType {
        case .privateChat:
            return selectedFans.count == 1
        case .themed:
            return !chatName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        default:
            return false
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Chat Type Selector
                chatTypeSelector
                
                Divider()
                
                // Content based on chat type
                Group {
                    switch selectedChatType {
                    case .privateChat:
                        fanSelectionView
                    case .themed:
                        themedChatCreationView
                    default:
                        unavailableTypeView
                    }
                }
                
                Spacer()
                
                // Create Button
                createChatButton
            }
            .navigationTitle(NSLocalizedString("New Chat", comment: "Title for creating a new fan chat"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(NSLocalizedString("Cancel", comment: "Cancel button to dismiss new chat creation")) {
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadAvailableFans()
                checkThemedChatPermissions()
            }
        }
    }
    
    // MARK: - Chat Type Selector
    
    private var chatTypeSelector: some View {
        VStack(spacing: 16) {
            Text(NSLocalizedString("Select Chat Type", comment: "Header for chat type selection"))
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            HStack(spacing: 12) {
                ChatTypeButton(
                    type: .privateChat,
                    title: NSLocalizedString("Private", comment: "Private chat type option"),
                    subtitle: NSLocalizedString("1-on-1 chat", comment: "Description for private chat"),
                    icon: "person.2.fill",
                    color: .green,
                    isSelected: selectedChatType == .privateChat
                ) {
                    selectedChatType = .privateChat
                    selectedFans.removeAll()
                }
                
                ChatTypeButton(
                    type: .themed,
                    title: NSLocalizedString("Themed", comment: "Themed chat type option"),
                    subtitle: canCreateThemedChats ? NSLocalizedString("Topic-based group", comment: "Description for themed chat when available") : NSLocalizedString("Admin/Moderator only", comment: "Description for themed chat when restricted"),
                    icon: "tag.fill",
                    color: canCreateThemedChats ? .purple : .gray,
                    isSelected: selectedChatType == .themed,
                    isDisabled: !canCreateThemedChats
                ) {
                    if canCreateThemedChats {
                        selectedChatType = .themed
                        selectedFans.removeAll()
                    }
                }
            }
        }
        .padding()
    }
    
    // MARK: - Fan Selection View
    
    private var fanSelectionView: some View {
        VStack(spacing: 16) {
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField(NSLocalizedString("Search fans...", comment: "Placeholder for searching fans in chat creation"), text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
            }
            .padding()
            .background(Color.secondary.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .padding(.horizontal)
            
            // Fan List
            List {
                ForEach(filteredFans, id: \.id) { fan in
                    FanSelectionRow(
                        fan: fan,
                        isSelected: selectedFans.contains(fan.id)
                    ) {
                        if selectedFans.contains(fan.id) {
                            selectedFans.remove(fan.id)
                        } else {
                            selectedFans.removeAll() // Only one fan for private chat
                            selectedFans.insert(fan.id)
                        }
                    }
                }
            }
            .listStyle(PlainListStyle())
        }
    }
    
    // MARK: - Themed Chat Creation View
    
    private var themedChatCreationView: some View {
        VStack(spacing: 20) {
            // Chat Name Input
            VStack(alignment: .leading, spacing: 8) {
                Text(NSLocalizedString("Chat Name", comment: "Label for chat name input field"))
                    .font(.headline)
                    .fontWeight(.semibold)
                
                TextField(NSLocalizedString("Enter chat name...", comment: "Placeholder for chat name input"), text: $chatName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            
            // Chat Description Input
            VStack(alignment: .leading, spacing: 8) {
                Text(NSLocalizedString("Description (Optional)", comment: "Label for optional chat description input"))
                    .font(.headline)
                    .fontWeight(.semibold)
                
                TextField(NSLocalizedString("Describe the chat topic...", comment: "Placeholder for chat description input"), text: $chatDescription, axis: .vertical)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .lineLimit(3...6)
            }
            
            // Info Note
            HStack(spacing: 12) {
                Image(systemName: canCreateThemedChats ? "info.circle.fill" : "lock.circle.fill")
                    .foregroundColor(canCreateThemedChats ? .blue : .red)
                
                Text(canCreateThemedChats ? 
                     NSLocalizedString("Themed chats are visible to all fans and can be moderated by assigned moderators.", comment: "Information about themed chats when user can create them") :
                     NSLocalizedString("Only main app admins can assign fan chat moderators who can create themed chats.", comment: "Information about themed chats when user cannot create them"))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(nil)
            }
            .padding()
            .background((canCreateThemedChats ? Color.blue : Color.red).opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            
            Spacer()
        }
        .padding()
    }
    
    // MARK: - Unavailable Type View
    
    private var unavailableTypeView: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundColor(.orange)
            
            Text(NSLocalizedString("Not Available", comment: "Title when chat type is not available"))
                .font(.title2)
                .fontWeight(.bold)
            
            Text(NSLocalizedString("This chat type is not available for regular fans.", comment: "Message explaining chat type unavailability"))
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
    
    // MARK: - Create Chat Button
    
    private var createChatButton: some View {
        VStack(spacing: 12) {
            if canCreateChat {
                Button(action: createChat) {
                    HStack {
                        if isCreating {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "plus.message.fill")
                        }
                        
                        Text(isCreating ? NSLocalizedString("Creating...", comment: "Button text while creating chat") : NSLocalizedString("Create Chat", comment: "Button text to create new chat"))
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(isCreating)
            } else {
                Text(getDisabledReason())
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.secondary.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding()
    }
    
    // MARK: - Helper Methods
    
    private func loadAvailableFans() {
        guard let user = appState.user,
              let groupId = user.fanGroupId else { return }
        
        print("🔍 Loading available fans for group: \(groupId)")
        
        let db = Firestore.firestore()
        
        db.collection("users")
            .whereField("userType", isEqualTo: "Fan")
            .whereField("fanGroupId", isEqualTo: groupId)
            .getDocuments { snapshot, error in
                DispatchQueue.main.async {
                    if let error = error {
                        print("❌ Error loading available fans: \(error)")
                        return
                    }
                    
                    guard let documents = snapshot?.documents else {
                        print("📄 No fans found")
                        return
                    }
                    
                    print("📄 Found \(documents.count) potential fans")
                    
                    availableFans = documents.compactMap { document in
                        let data = document.data()
                        
                        guard let email = data["email"] as? String,
                              let name = data["name"] as? String,
                              document.documentID != user.id else {
                            return nil // Skip current user
                        }
                        
                        return UserModel(
                            id: document.documentID,
                            email: email,
                            name: name,
                            phone: data["phone"] as? String ?? "",
                            groupId: nil, // Fans don't have main group ID
                            role: .member, // Default role for fans
                            isOnline: data["isOnline"] as? Bool,
                            lastSeen: (data["lastSeen"] as? Timestamp)?.dateValue(),
                            avatarURL: data["avatarURL"] as? String,
                            documentPermissions: nil,
                            googleDriveEmail: nil,
                            hasGoogleDriveAccess: false,
                            userType: .fan,
                            fanGroupId: groupId,
                            fanProfile: parseFanProfile(from: data["fanProfile"] as? [String: Any])
                        )
                    }
                    
                    print("✅ Successfully loaded \(availableFans.count) available fans")
                }
            }
    }
    
    private func parseFanProfile(from data: [String: Any]?) -> FanProfile? {
        guard let data = data else { return nil }
        
        // Create a basic fan profile with available data
        return FanProfile(
            nickname: data["nickname"] as? String ?? "Fan",
            joinDate: (data["joinDate"] as? Timestamp)?.dateValue() ?? Date(),
            location: data["location"] as? String ?? "",
            favoriteSong: data["favoriteSong"] as? String ?? "",
            level: .newbie, // Use correct FanLevel case
            achievements: data["achievements"] as? [String] ?? [],
            isModerator: data["isModerator"] as? Bool ?? false,
            stats: FanStats(
                totalMessages: data["totalMessages"] as? Int ?? 0,
                joinDate: (data["joinDate"] as? Timestamp)?.dateValue() ?? Date(),
                lastActive: (data["lastActive"] as? Timestamp)?.dateValue() ?? Date(),
                merchandisePurchased: data["merchandisePurchased"] as? Int ?? 0,
                concertsAttended: data["concertsAttended"] as? Int ?? 0,
                achievementsUnlocked: data["achievementsUnlocked"] as? Int ?? 0
            ),
            notificationSettings: FanNotificationSettings(
                newConcerts: data["newConcerts"] as? Bool ?? true,
                officialNews: data["officialNews"] as? Bool ?? true,
                chatMessages: data["chatMessages"] as? Bool ?? true,
                newMerch: data["newMerch"] as? Bool ?? false,
                achievements: data["achievements"] as? Bool ?? true,
                moderatorActions: data["moderatorActions"] as? Bool ?? true
            )
        )
    }
    
    private func createChat() {
        guard let user = appState.user,
              let groupId = user.fanGroupId else { 
            print("❌ Cannot create chat: no user or fanGroupId")
            return 
        }
        
        print("🚀 Creating chat - User: \(user.id), Group: \(groupId), Type: \(selectedChatType)")
        
        isCreating = true
        
        switch selectedChatType {
        case .privateChat:
            if let fanId = selectedFans.first {
                print("💬 Creating private chat with fan: \(fanId)")
                fanChatService.createPrivateChat(with: fanId, groupId: groupId)
            }
        case .themed:
            if canCreateThemedChats && !chatName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                fanChatService.createThemedChat(
                    name: chatName,
                    description: chatDescription.isEmpty ? nil : chatDescription,
                    groupId: groupId
                )
            }
        default:
            break
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            isCreating = false
            dismiss()
        }
    }
    
    private func getDisabledReason() -> String {
        switch selectedChatType {
        case .privateChat:
            return selectedFans.isEmpty ? NSLocalizedString("Select a fan to chat with", comment: "Message when no fan is selected for private chat") : NSLocalizedString("Select exactly one fan", comment: "Message when multiple fans are selected for private chat")
        case .themed:
            if !canCreateThemedChats {
                return NSLocalizedString("Only admins and moderators can create themed chats", comment: "Message when user cannot create themed chats")
            }
            return chatName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? NSLocalizedString("Enter a chat name", comment: "Message when chat name is empty") : ""
        default:
            return NSLocalizedString("This chat type is not available", comment: "Message when chat type is not available")
        }
    }
    
    // MARK: - Permission Checks
    
    private func checkThemedChatPermissions() {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            print("❌ No current user ID for themed chat permissions")
            canCreateThemedChats = false
            return
        }
        
        print("🔍 Checking themed chat permissions for user: \(currentUserId)")
        
        fanChatService.canUserCreateThemedChats(userId: currentUserId) { canCreate in
            DispatchQueue.main.async {
                print("✅ Themed chat permissions result: \(canCreate)")
                canCreateThemedChats = canCreate
            }
        }
    }
}

// MARK: - Chat Type Button

struct ChatTypeButton: View {
    let type: FanChat.FanChatType
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let isSelected: Bool
    let isDisabled: Bool
    let action: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    init(type: FanChat.FanChatType, title: String, subtitle: String, icon: String, color: Color, isSelected: Bool, isDisabled: Bool = false, action: @escaping () -> Void) {
        self.type = type
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.color = color
        self.isSelected = isSelected
        self.isDisabled = isDisabled
        self.action = action
    }
    
    var body: some View {
        Button(action: isDisabled ? {} : action) {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(isSelected ? color : (isDisabled ? Color.gray.opacity(0.15) : color.opacity(0.15)))
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(isSelected ? .white : (isDisabled ? .gray : color))
                }
                
                VStack(spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(isSelected ? color : (isDisabled ? .gray : .primary))
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(isDisabled ? .gray : .secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(isSelected ? color.opacity(0.1) : (colorScheme == .dark ? Color(UIColor.secondarySystemGroupedBackground) : Color.white))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(isSelected ? color : Color.clear, lineWidth: 2)
                    )
                    .shadow(
                        color: colorScheme == .dark ? Color.clear : Color.black.opacity(0.06),
                        radius: 6,
                        x: 0,
                        y: 2
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Fan Selection Row

struct FanSelectionRow: View {
    let fan: UserModel
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Fan Avatar
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(hex: fan.fanProfile?.level.color ?? "4A90E2"),
                                    Color(hex: fan.fanProfile?.level.color ?? "4A90E2").opacity(0.7)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 40, height: 40)
                    
                    Text(String((fan.fanProfile?.nickname ?? fan.name).prefix(2)).uppercased())
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                
                // Fan Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(fan.fanProfile?.nickname ?? fan.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 8) {
                        if let fanProfile = fan.fanProfile {
                            Text(fanProfile.level.localizedName)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(Color(hex: fanProfile.level.color))
                            
                            if !fanProfile.location.isEmpty {
                                Text("• \(fanProfile.location)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                
                Spacer()
                
                // Selection Indicator
                ZStack {
                    Circle()
                        .stroke(isSelected ? Color.blue : Color.secondary.opacity(0.3), lineWidth: 2)
                        .frame(width: 24, height: 24)
                    
                    if isSelected {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 16, height: 16)
                    }
                }
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
