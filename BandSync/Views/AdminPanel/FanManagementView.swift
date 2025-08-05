import SwiftUI
import FirebaseAuth
import FirebaseFirestore  // ✅ ДОБАВЛЕН ИМПОРТ ДЛЯ FIRESTORE

struct FanManagementView: View {
    @StateObject private var fanService = FanInviteService.shared
    @StateObject private var groupService = GroupService.shared
    @State private var currentInviteCode: FanInviteCode?
    @State private var fans: [UserModel] = []
    @State private var isLoading = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var showGenerateCodeAlert = false
    @State private var showEditCodeSheet = false
    @State private var customCodeInput = ""
    @State private var isValidatingCustomCode = false
    @State private var customCodeValidationMessage = ""
    @State private var showDeleteCodeAlert = false
    @State private var isCopyingCode = false
    @State private var fanClubEnabled = true
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        List {
            // Fan Club Status Section
            Section {
                HStack(spacing: 12) {
                    fanIcon(icon: fanClubEnabled ? "heart.fill" : "heart", color: fanClubEnabled ? .purple : .gray)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(NSLocalizedString("Fan Club Status", comment: ""))
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        
                        Text(fanClubEnabled ? NSLocalizedString("Active", comment: "") : NSLocalizedString("Inactive", comment: ""))
                            .font(.caption)
                            .foregroundColor(fanClubEnabled ? .green : .red)
                    }
                    
                    Spacer()
                    
                    Toggle("", isOn: $fanClubEnabled)
                        .labelsHidden()
                        .toggleStyle(SwitchToggleStyle(tint: .purple))
                }
                .padding(.vertical, 4)
            } header: {
                Text(NSLocalizedString("Settings", comment: ""))
            }
            
            // Invite Code Section - НОВАЯ ПРОСТАЯ ВЕРСИЯ
            if fanClubEnabled {
                Section {
                    if let inviteCode = currentInviteCode {
                        // ✅ ПРОСТАЯ И НАДЕЖНАЯ СЕКЦИЯ С КОДОМ
                        VStack(spacing: 12) {
                            // Заголовок
                            HStack {
                                Text(NSLocalizedString("Current Invite Code", comment: ""))
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Spacer()
                            }
                            
                            // Код в простой рамке
                            HStack {
                                Text(inviteCode.code)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.purple)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(Color.purple.opacity(0.1))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 10)
                                                    .stroke(Color.purple, lineWidth: 2)
                                            )
                                    )
                                    .minimumScaleFactor(0.6)
                            }
                            
                            // ✅ ИКОНКИ БЕЗ ТЕКСТА, ОДИНАКОВОГО РАЗМЕРА
                            HStack(spacing: 12) {
                                // Copy Button
                                Button {
                                    copyInviteCode()
                                } label: {
                                    Image(systemName: "doc.on.doc")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.white)
                                        .frame(width: 44, height: 44)
                                        .background(Color.blue)
                                        .cornerRadius(8)
                                }
                                .disabled(isCopyingCode)
                                .buttonStyle(PlainButtonStyle())
                                
                                // Edit Button
                                Button {
                                    customCodeInput = inviteCode.code
                                    showEditCodeSheet = true
                                } label: {
                                    Image(systemName: "pencil")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.white)
                                        .frame(width: 44, height: 44)
                                        .background(Color.orange)
                                        .cornerRadius(8)
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                // Delete Button
                                Button {
                                    showDeleteCodeAlert = true
                                } label: {
                                    Image(systemName: "trash")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.white)
                                        .frame(width: 44, height: 44)
                                        .background(Color.red)
                                        .cornerRadius(8)
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                Spacer()
                            }
                            
                            // Статистика
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(NSLocalizedString("Uses", comment: ""))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text("\(inviteCode.currentUses)")
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .trailing) {
                                    Text(NSLocalizedString("Created", comment: ""))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text(formatDate(inviteCode.createdAt))
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                }
                            }
                        }
                        .padding(.vertical, 8)
                        
                    } else {
                        // ✅ ПРОСТАЯ СЕКЦИЯ ДЛЯ СОЗДАНИЯ КОДА
                        VStack(spacing: 16) {
                            Image(systemName: "ticket")
                                .font(.largeTitle)
                                .foregroundColor(.purple.opacity(0.6))
                            
                            Text(NSLocalizedString("No Invite Code", comment: ""))
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Text(NSLocalizedString("Create a custom code for fans to join your fan club", comment: ""))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                            
                            Button(NSLocalizedString("Create Invite Code", comment: "")) {
                                customCodeInput = ""
                                showEditCodeSheet = true
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(Color.purple)
                            .cornerRadius(10)
                        }
                        .padding(.vertical, 20)
                    }
                } header: {
                    Text(NSLocalizedString("Invite Code", comment: ""))
                }
            }
            
            // Fan Statistics Section
            if fanClubEnabled {
                Section {
                    HStack {
                        fanIcon(icon: "person.2.fill", color: .blue)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(NSLocalizedString("Total Fans", comment: ""))
                                .font(.body)
                                .fontWeight(.medium)
                            Text(String(format: NSLocalizedString("%d members", comment: ""), fans.count))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Text("\(fans.count)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                    }
                    
                    HStack {
                        fanIcon(icon: "calendar", color: .green)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(NSLocalizedString("Recent Activity", comment: ""))
                                .font(.body)
                                .fontWeight(.medium)
                            Text(NSLocalizedString("Last fan joined", comment: ""))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Text(getLastJoinedDate())
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                } header: {
                    Text(NSLocalizedString("Statistics", comment: ""))
                }
            }
            
            // Fans List Section - ЗАМЕНЕНО НА КНОПКУ
            if fanClubEnabled {
                Section {
                    NavigationLink {
                        FanClubMembersView(totalFans: fans.count)
                    } label: {
                        HStack(spacing: 12) {
                            fanIcon(icon: "person.3.fill", color: .purple)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(NSLocalizedString("View All Members", comment: ""))
                                    .font(.body)
                                    .fontWeight(.medium)
                                    .foregroundColor(.primary)
                                
                                Text(String(format: NSLocalizedString("%d fans in your club", comment: ""), fans.count))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Text("\(fans.count)")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.purple)
                            
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                } header: {
                    Text(NSLocalizedString("Fan Club Members", comment: ""))
                }
            }
            
            if isLoading {
                Section {
                    HStack {
                        Spacer()
                        ProgressView()
                            .tint(.purple)
                        Spacer()
                    }
                    .padding()
                }
            }
        }
        .navigationTitle(NSLocalizedString("Fan Management", comment: ""))
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            loadFanData()
        }
        .confirmationDialog(NSLocalizedString("Create Invite Code", comment: ""), isPresented: $showGenerateCodeAlert) {
            Button(NSLocalizedString("Create Custom Code", comment: "")) {
                customCodeInput = ""
                showEditCodeSheet = true
            }
        } message: {
            Text(NSLocalizedString("Create a new custom invite code. This will replace the current code.", comment: ""))
        }
        .alert(NSLocalizedString("Fan Management", comment: ""), isPresented: $showAlert) {
            Button(NSLocalizedString("OK", comment: ""), role: .cancel) {
                // Сбрасываем все состояния при закрытии алерта
                alertMessage = ""
                isCopyingCode = false
            }
        } message: {
            Text(alertMessage)
        }
        .alert(currentInviteCode?.code.isEmpty == false ? NSLocalizedString("Edit Invite Code", comment: "") : NSLocalizedString("Create Invite Code", comment: ""), isPresented: $showEditCodeSheet) {
            TextField(NSLocalizedString("Enter custom code (e.g. ROCKBAND)", comment: ""), text: $customCodeInput)
                .autocapitalization(.allCharacters)
                .disableAutocorrection(true)
            
            Button(NSLocalizedString("Cancel", comment: ""), role: .cancel) {
                customCodeInput = ""
            }
            
            Button(NSLocalizedString("Save", comment: "")) {
                updateInviteCode(newCode: customCodeInput)
            }
            .disabled(customCodeInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        } message: {
            Text(currentInviteCode?.code.isEmpty == false ?
                 NSLocalizedString("Enter a new custom invite code (up to 25 characters, letters and numbers only)", comment: "") :
                 NSLocalizedString("Create a unique code that fans will use to join your fan club", comment: ""))
        }
        // ✅ НОВЫЙ ALERT ДЛЯ УДАЛЕНИЯ КОДА
        .alert(NSLocalizedString("Delete Invite Code", comment: ""), isPresented: $showDeleteCodeAlert) {
            Button(NSLocalizedString("Cancel", comment: ""), role: .cancel) {}
            Button(NSLocalizedString("Delete", comment: ""), role: .destructive) {
                deleteInviteCode()
            }
        } message: {
            Text(NSLocalizedString("Are you sure you want to delete the current invite code? This action cannot be undone and will prevent new fans from joining until you create a new code.", comment: ""))
        }
    }
    
    // MARK: - Helper Views
    
    private func fanIcon(icon: String, color: Color) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6)
                .fill(color)
                .frame(width: 28, height: 28)
            
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
        }
    }
    
    // MARK: - Functions
    
    private func loadFanData() {
        guard let groupId = AppState.shared.user?.groupId,
              let groupName = groupService.group?.name else {
            return
        }
        
        isLoading = true
        
        // Load current invite code
        fanService.getCurrentInviteCode(for: groupId) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let inviteCode):
                    self.currentInviteCode = inviteCode
                case .failure(let error):
                    self.currentInviteCode = nil
                    // ✅ ПОКАЗЫВАЕМ ОШИБКУ ПОЛЬЗОВАТЕЛЮ
                    self.alertMessage = "Failed to load invite code: \(error.localizedDescription)"
                    self.showAlert = true
                }
            }
        }
        
        // Load fans list
        loadFansList(groupId: groupId)
    }
    
    private func loadFansList(groupId: String) {
        // ✅ РЕАЛЬНАЯ ЗАГРУЗКА ФАНАТОВ ИЗ FIREBASE
        let db = Firestore.firestore()
        
        db.collection("groups").document(groupId).collection("fans")
            .order(by: "joinDate", descending: true)
            .limit(to: 50)
            .getDocuments { snapshot, error in
                DispatchQueue.main.async {
                    self.isLoading = false
                    
                    if let error = error {
                        self.alertMessage = "Failed to load fans: \(error.localizedDescription)"
                        self.showAlert = true
                        return
                    }
                    
                    // Преобразуем документы в UserModel (упрощенная версия для фанатов)
                    self.fans = snapshot?.documents.compactMap { doc in
                        let data = doc.data()
                        guard let userId = data["userId"] as? String,
                              let nickname = data["nickname"] as? String,
                              let joinTimestamp = data["joinDate"] as? Timestamp else {
                            return nil
                        }
                        
                        // Создаем упрощенный UserModel для фана
                        let fanProfile = FanProfile(
                            nickname: nickname,
                            joinDate: joinTimestamp.dateValue(),
                            location: data["location"] as? String ?? "",
                            favoriteSong: data["favoriteSong"] as? String ?? "",
                            level: FanLevel(rawValue: data["level"] as? String ?? "newbie") ?? .newbie
                        )
                        
                        // ✅ ПРАВИЛЬНЫЕ ПАРАМЕТРЫ UserModel
                        return UserModel(
                            id: userId,
                            email: "", // Пустой email для фанатов
                            name: nickname, // ✅ name вместо displayName
                            phone: "", // Пустой телефон для фанатов
                            groupId: nil, // У фанатов нет groupId
                            role: .member, // Роль по умолчанию
                            userType: .fan,
                            fanGroupId: data["groupId"] as? String, // ID группы которую они фоловят
                            fanProfile: fanProfile
                        )
                    } ?? []
                }
            }
    }
    
    private func generateInviteCode() {
        // This function is no longer used for auto-generation
        // Redirecting to manual creation
        customCodeInput = ""
        showEditCodeSheet = true
    }
    
    private func copyInviteCode() {
        guard !isCopyingCode else { return }  // ✅ ЗАЩИТА ОТ МНОЖЕСТВЕННЫХ НАЖАТИЙ
        
        if let code = currentInviteCode?.code {
            isCopyingCode = true
            
            UIPasteboard.general.string = code
            alertMessage = "Invite code '\(code)' copied to clipboard!"
            showAlert = true
            
            // Сбрасываем флаг через небольшую задержку
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.isCopyingCode = false
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }
    
    private func regenerateInviteCode() {
        customCodeInput = ""
        showEditCodeSheet = true
    }
    
    private func getLastJoinedDate() -> String {
        if let lastFan = fans.first,
           let fanProfile = lastFan.fanProfile {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return formatter.string(from: fanProfile.joinDate)
        }
        return NSLocalizedString("No recent activity", comment: "")
    }
    
    private func updateInviteCode(newCode: String) {
        guard let groupId = AppState.shared.user?.groupId,
              let groupName = groupService.group?.name else {
            alertMessage = "Error: Group information not available"
            showAlert = true
            return
        }
        
        isLoading = true
        
        // Validate custom code format
        let cleanCode = newCode.uppercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard isValidCustomCode(cleanCode) else {
            isLoading = false
            alertMessage = "Invalid code format. Use up to 25 characters (letters and numbers only)"
            showAlert = true
            return
        }
        
        // ✅ ВЫБИРАЕМ ПРАВИЛЬНЫЙ МЕТОД: создание или обновление
        if currentInviteCode == nil {
            // Создаем новый код
            fanService.createCustomInviteCode(
                for: groupId,
                customCode: cleanCode,
                groupName: groupName
            ) { result in
                self.handleInviteCodeResult(result, action: "created")
            }
        } else {
            // Обновляем существующий код
            fanService.updateCustomInviteCode(
                for: groupId,
                newCode: cleanCode,
                groupName: groupName
            ) { result in
                self.handleInviteCodeResult(result, action: "updated")
            }
        }
    }
    
    private func handleInviteCodeResult(_ result: Result<FanInviteCode, Error>, action: String) {
        DispatchQueue.main.async {
            self.isLoading = false
            
            switch result {
            case .success(let updatedCode):
                self.currentInviteCode = updatedCode
                self.showEditCodeSheet = false
                self.customCodeInput = ""
                
                // ✅ ОБНОВЛЯЕМ ДАННЫЕ ИЗ FIREBASE
                self.loadFanData()
                
                // Показываем успешное сообщение
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    self.alertMessage = "Invite code \(action) to '\(updatedCode.code)' successfully!"
                    self.showAlert = true
                }
                
            case .failure(let error):
                // Показываем ошибку
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.alertMessage = "Failed to \(action.replacingOccurrences(of: "ed", with: "e")) invite code: \(error.localizedDescription)"
                    self.showAlert = true
                }
            }
        }
    }
    
    // ✅ ФУНКЦИЯ УДАЛЕНИЯ КОДА С ОБНОВЛЕНИЕМ
    private func deleteInviteCode() {
        guard let groupId = AppState.shared.user?.groupId else {
            alertMessage = "Error: Group information not available"
            showAlert = true
            return
        }
        
        isLoading = true
        
        fanService.deleteInviteCode(for: groupId) { result in
            DispatchQueue.main.async {
                self.isLoading = false
                
                switch result {
                case .success:
                    self.currentInviteCode = nil
                    
                    // ✅ ОБНОВЛЯЕМ ДАННЫЕ ИЗ FIREBASE
                    self.loadFanData()
                    
                    // Показываем успешное сообщение
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        self.alertMessage = "Invite code deleted successfully!"
                        self.showAlert = true
                    }
                    
                case .failure(let error):
                    // Показываем ошибку
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        self.alertMessage = "Failed to delete invite code: \(error.localizedDescription)"
                        self.showAlert = true
                    }
                }
            }
        }
    }
    
    private func isValidCustomCode(_ code: String) -> Bool {
        // Check length - only maximum limit
        guard code.count <= 25 else {
            return false
        }
        
        // Must not be empty
        guard !code.isEmpty else {
            return false
        }
        
        // Check only alphanumeric characters
        let allowedCharacters = CharacterSet.alphanumerics
        guard code.unicodeScalars.allSatisfy({ allowedCharacters.contains($0) }) else {
            return false
        }
        
        // ✅ ПРОВЕРКА НА ЗАПРЕЩЕННЫЕ СЛОВА
        let forbiddenWords = ["admin", "test", "temp", "delete", "null", "undefined", "fuck", "shit", "damn"]
        let lowerCode = code.lowercased()
        
        for word in forbiddenWords {
            if lowerCode.contains(word) {
                return false
            }
        }
        
        return true
    }
}

// MARK: - Fan Row Component
struct FanRowView: View {
    let fan: UserModel
    
    var body: some View {
        HStack(spacing: 12) {
            // Fan avatar
            ZStack {
                Circle()
                    .fill(Color.purple.opacity(0.2))
                    .frame(width: 40, height: 40)
                
                if let avatarURL = fan.avatarURL {
                    AsyncImage(url: URL(string: avatarURL)) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    } placeholder: {
                        Text(fan.initials)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.purple)
                    }
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
                } else {
                    Text(fan.displayName.prefix(2).uppercased())
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.purple)
                }
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(fan.displayName)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                if let fanProfile = fan.fanProfile {
                    HStack {
                        Image(systemName: fanProfile.level.iconName)
                            .foregroundColor(Color(hex: fanProfile.level.color))
                        
                        Text(fanProfile.level.localizedName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if !fanProfile.location.isEmpty {
                            Text("• \(fanProfile.location)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Text(String(format: NSLocalizedString("Joined %@", comment: ""), formatDate(fanProfile.joinDate)))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Fan level indicator
            if let fanProfile = fan.fanProfile {
                VStack {
                    Image(systemName: fanProfile.level.iconName)
                        .foregroundColor(Color(hex: fanProfile.level.color))
                        .font(.caption)
                }
            }
        }
        .padding(.vertical, 2)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - FanClubMembersView - ОТДЕЛЬНЫЙ ВЬЮ ДЛЯ ВСЕХ ФАНАТОВ
struct FanClubMembersView: View {
    let totalFans: Int
    @State private var fans: [UserModel] = []
    @State private var isLoading = false
    @State private var searchText = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var filteredFans: [UserModel] {
        if searchText.isEmpty {
            return fans
        } else {
            return fans.filter { fan in
                fan.displayName.localizedCaseInsensitiveContains(searchText) ||
                (fan.fanProfile?.location.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
    }
    
    var body: some View {
        List {
            if isLoading {
                Section {
                    HStack {
                        Spacer()
                        ProgressView(NSLocalizedString("Loading fans...", comment: ""))
                            .tint(.purple)
                        Spacer()
                    }
                    .padding()
                }
            } else if fans.isEmpty {
                Section {
                    VStack(spacing: 16) {
                        Image(systemName: "person.2.slash")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        
                        Text(NSLocalizedString("No Fans Yet", comment: ""))
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text(NSLocalizedString("Share your invite code to get your first fans!", comment: ""))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.vertical, 40)
                }
            } else {
                Section {
                    ForEach(filteredFans, id: \.id) { fan in
                        FanRowView(fan: fan)
                    }
                } header: {
                    HStack {
                        Text(String(format: NSLocalizedString("Members (%d)", comment: ""), filteredFans.count))
                        Spacer()
                        if !searchText.isEmpty {
                            Text(String(format: NSLocalizedString("Filtered from %d", comment: ""), fans.count))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle(NSLocalizedString("Fan Club Members", comment: ""))
        .navigationBarTitleDisplayMode(.large)
        .searchable(text: $searchText, prompt: NSLocalizedString("Search fans...", comment: ""))
        .onAppear {
            loadFans()
        }
        .alert(NSLocalizedString("Error", comment: ""), isPresented: $showAlert) {
            Button(NSLocalizedString("OK", comment: ""), role: .cancel) {}
        } message: {
            Text(alertMessage)
        }
    }
    
    private func loadFans() {
        guard let groupId = AppState.shared.user?.groupId else {
            alertMessage = "Group information not available"
            showAlert = true
            return
        }
        
        isLoading = true
        
        let db = Firestore.firestore()
        
        db.collection("groups").document(groupId).collection("fans")
            .order(by: "joinDate", descending: true)
            .getDocuments { snapshot, error in
                DispatchQueue.main.async {
                    self.isLoading = false
                    
                    if let error = error {
                        self.alertMessage = "Failed to load fans: \(error.localizedDescription)"
                        self.showAlert = true
                        return
                    }
                    
                    self.fans = snapshot?.documents.compactMap { doc in
                        let data = doc.data()
                        guard let userId = data["userId"] as? String,
                              let nickname = data["nickname"] as? String,
                              let joinTimestamp = data["joinDate"] as? Timestamp else {
                            return nil
                        }
                        
                        let fanProfile = FanProfile(
                            nickname: nickname,
                            joinDate: joinTimestamp.dateValue(),
                            location: data["location"] as? String ?? "",
                            favoriteSong: data["favoriteSong"] as? String ?? "",
                            level: FanLevel(rawValue: data["level"] as? String ?? "newbie") ?? .newbie
                        )
                        
                        return UserModel(
                            id: userId,
                            email: "",
                            name: nickname,
                            phone: "",
                            groupId: nil,
                            role: .member,
                            userType: .fan,
                            fanGroupId: data["groupId"] as? String,
                            fanProfile: fanProfile
                        )
                    } ?? []
                }
            }
    }
}
