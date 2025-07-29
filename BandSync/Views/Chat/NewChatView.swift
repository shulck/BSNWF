import SwiftUI
import FirebaseAuth

struct NewChatView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var chatService = ChatService.shared
    @StateObject private var userService = UserService.shared
    @StateObject private var permissionService = PermissionService.shared
    
    @State private var chatName = ""
    @State private var selectedUsers: Set<String> = []
    @State private var searchText = ""
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showingError = false
    
    private var canCreateBandWideChat: Bool {
        permissionService.currentUserHasAccess(to: .chats) &&
        (userService.currentUser?.role == .admin || userService.currentUser?.role == .manager)
    }
    
    // ИСПРАВЛЕНИЕ: Фильтруем только участников группы (исключаем фанатов)
    private var filteredUsers: [UserModel] {
        let currentUserId = Auth.auth().currentUser?.uid ?? ""
        
        // Показываем только участников группы (БЕЗ фанатов)
        let bandMembers = userService.users.filter { user in
            user.id != currentUserId &&  // Исключаем текущего пользователя
            user.userType == .bandMember &&  // Только участники группы
            user.groupId != nil  // У них должен быть groupId
        }
        
        if searchText.isEmpty {
            return bandMembers
        } else {
            return bandMembers.filter { user in
                user.name.localizedCaseInsensitiveContains(searchText) ||
                user.email.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                if isLoading {
                    ProgressView("Creating chat...".localized)
                        .padding()
                } else {
                    Form {
                        Section(header: Text("Chat Settings".localized)) {
                            TextField("Chat name".localized, text: $chatName)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        
                        Section(header: Text("Participants".localized)) {
                            if canCreateBandWideChat {
                                Button(action: createBandWideChat) {
                                    HStack {
                                        Image(systemName: "megaphone.fill")
                                            .foregroundColor(.orange)
                                        
                                        VStack(alignment: .leading) {
                                            Text("Create band-wide announcement".localized)
                                                .font(.headline)
                                                .foregroundColor(.primary)
                                            
                                            Text("Create announcement for all band members".localized)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        
                                        Spacer()
                                    }
                                    .padding(.vertical, 4)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            
                            SimpleSearchBar(text: $searchText)
                            
                            ForEach(filteredUsers, id: \.id) { user in
                                UserSelectionRow(
                                    user: user,
                                    isSelected: selectedUsers.contains(user.id),
                                    onToggle: {
                                        if selectedUsers.contains(user.id) {
                                            selectedUsers.remove(user.id)
                                        } else {
                                            selectedUsers.insert(user.id)
                                        }
                                    }
                                )
                            }
                        }
                    }
                }
            }
            .navigationTitle("New Chat".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel".localized) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create".localized) {
                        createChat()
                    }
                    .disabled(selectedUsers.isEmpty || isLoading)
                }
            }
            .alert("Error".localized, isPresented: $showingError) {
                Button("OK".localized) { }
            } message: {
                Text(errorMessage)
            }
            .onAppear {
                userService.fetchUsers()
            }
        }
    }
    
    private func createChat() {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        isLoading = true
        
        let chatType: Chat.ChatType = selectedUsers.count == 1 ? .direct : .group
        let finalChatName: String
        
        if chatType == .direct, let otherUserId = selectedUsers.first,
           let otherUser = userService.users.first(where: { $0.id == otherUserId }) {
            finalChatName = otherUser.name
        } else if chatType == .group {
            if !chatName.isEmpty {
                finalChatName = chatName
            } else {
                let names = userService.users.filter { selectedUsers.contains($0.id) || $0.id == currentUserId }.map { $0.name }
                finalChatName = names.joined(separator: ", ")
            }
        } else {
            finalChatName = chatName
        }
        
        var participants = Array(selectedUsers)
        participants.append(currentUserId)
        
        let chat = Chat(
            type: chatType,
            participants: participants,
            createdBy: currentUserId,
            createdAt: Date(),
            updatedAt: Date(),
            name: finalChatName,
            adminIds: chatType == .group ? [currentUserId] : []
        )
        
        chatService.createChat(chat) { result in
            DispatchQueue.main.async {
                isLoading = false
                
                switch result {
                case .success:
                    dismiss()
                case .failure(let error):
                    errorMessage = error.localizedDescription
                    showingError = true
                }
            }
        }
    }
    
    // ИСПРАВЛЕНИЕ: Строгая фильтрация только участников группы (БЕЗ фанатов)
    private func createBandWideChat() {
        guard let currentUserId = Auth.auth().currentUser?.uid,
              let currentGroupId = userService.currentUser?.groupId else { return }
        
        isLoading = true
        
        // КРИТИЧНОЕ ИСПРАВЛЕНИЕ: Только участники группы, исключаем всех фанатов
        let bandMemberIds = userService.users
            .filter { user in
                user.userType == .bandMember &&  // ТОЛЬКО участники группы
                user.groupId == currentGroupId &&  // Проверяем правильный groupId
                user.fanGroupId == nil  // Дополнительная защита: у участников НЕТ fanGroupId
            }
            .map { $0.id }
        
        var participants = bandMemberIds
        participants.append(currentUserId)
        
        print("NewChatView: Creating BandWide chat with \(participants.count) participants (excluding fans)")
        
        let chat = Chat(
            type: .bandWide,
            participants: participants,
            createdBy: currentUserId,
            createdAt: Date(),
            updatedAt: Date(),
            name: chatName.isEmpty ? "Band Announcement".localized : chatName,
            bandId: currentGroupId,
            adminIds: [currentUserId]
        )
        
        chatService.createChat(chat) { result in
            DispatchQueue.main.async {
                isLoading = false
                
                switch result {
                case .success:
                    dismiss()
                case .failure(let error):
                    errorMessage = error.localizedDescription
                    showingError = true
                }
            }
        }
    }
}

struct UserSelectionRow: View {
    let user: UserModel
    let isSelected: Bool
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
            HStack {
                AvatarView(user: user, size: 40)
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(user.name)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        // ДОБАВЛЕНО: Показываем тип пользователя для безопасности
                        if user.userType == .fan {
                            Text("FAN")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 1)
                                .background(Color.orange)
                                .cornerRadius(4)
                        }
                    }
                    
                    Text(user.email)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(user.role.displayName)
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .blue : .gray)
                    .font(.title2)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SimpleSearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField("Search participants...".localized, text: $text)
                .textFieldStyle(PlainTextFieldStyle())
            
            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
}

extension UserModel.UserRole {
    var displayName: String {
        switch self {
        case .admin:
            return "Administrator".localized
        case .manager:
            return "Manager".localized
        case .musician:
            return "Musician".localized
        case .member:
            return "Member".localized
        }
    }
}

#Preview {
    NewChatView()
}
