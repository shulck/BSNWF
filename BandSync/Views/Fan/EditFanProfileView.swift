//
//  EditFanProfileView.swift
//  BandSync
//
//  Created by Oleksandr Kuziakin on 31.07.2025.
//  Работает с существующей моделью FanProfile из FanModels.swift
//

import SwiftUI
import PhotosUI
import FirebaseFirestore
import FirebaseStorage
import FirebaseAuth

struct EditFanProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appState: AppState
    @Environment(\.colorScheme) private var colorScheme
    
    // MARK: - Profile Data States (точно по вашей UserModel)
    @State private var selectedAvatar: PhotosPickerItem?
    @State private var avatarImage: UIImage?
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var email: String = ""
    @State private var phone: String = ""
    
    // MARK: - Fan Profile States (точно по вашей FanProfile из FanModels.swift)
    @State private var nickname: String = ""
    @State private var location: String = ""
    @State private var favoriteSong: String = ""
    
    // MARK: - Address States
    @State private var selectedCountry: Country = .ukraine
    @State private var addressLine1: String = ""
    @State private var addressLine2: String = ""
    @State private var city: String = ""
    @State private var state: String = ""
    @State private var zipCode: String = ""
    
    // MARK: - UI States
    @State private var isUploading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showSuccessAlert = false
    @State private var showDeleteAccountAlert = false
    @State private var isDeleting = false
    
    // MARK: - Focus State
    @FocusState private var focusedField: EditField?
    
    // MARK: - Private Properties
    private let db = Firestore.firestore()
    private let storage = Storage.storage()
    
    var body: some View {
        NavigationView {
            ZStack {
                backgroundGradient
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        headerSection
                        
                        // Avatar Section
                        avatarSection
                        
                        // Personal Information
                        personalInfoSection
                        
                        // Fan Profile Information
                        fanProfileSection
                        
                        // Address Section
                        addressSection
                        
                        // Delete Account Section
                        deleteAccountSection
                        
                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                loadCurrentUserData()
            }
            .photosPicker(isPresented: .constant(false), selection: $selectedAvatar, matching: .images)
            .onChange(of: selectedAvatar) { oldValue, newValue in
                loadSelectedImage()
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") {}
            } message: {
                Text(errorMessage)
            }
            .alert("Profile Updated", isPresented: $showSuccessAlert) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Your fan profile has been successfully updated! Your address is saved privately and only visible to you.")
            }
            .alert("Delete Account", isPresented: $showDeleteAccountAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Delete Forever", role: .destructive) {
                    deleteAccount()
                }
            } message: {
                Text("This action cannot be undone. Your fan profile, achievements, and all data will be permanently deleted.")
            }
        }
    }
    
    // MARK: - Background
    private var backgroundGradient: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(.systemGroupedBackground),
                Color(.systemGroupedBackground).opacity(0.8)
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 16) {
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .font(.body)
                .foregroundColor(.blue)
                
                Spacer()
                
                VStack(spacing: 4) {
                    Text("Edit Profile")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("Update your fan information")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button("Save") {
                    saveProfile()
                }
                .font(.body)
                .fontWeight(.semibold)
                .foregroundColor(.blue)
                .disabled(isUploading)
            }
            
            if isUploading {
                HStack(spacing: 8) {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Updating profile...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .transition(.opacity)
            }
        }
    }
    
    // MARK: - Avatar Section
    private var avatarSection: some View {
        VStack(spacing: 16) {
            ZStack {
                // Avatar circle
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.white, Color(.systemGray6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                    .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                
                // Avatar content
                if let avatarImage = avatarImage {
                    Image(uiImage: avatarImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 96, height: 96)
                        .clipShape(Circle())
                } else if let currentUser = appState.user, let avatarURL = currentUser.avatarURL {
                    AsyncImage(url: URL(string: avatarURL)) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    } placeholder: {
                        avatarPlaceholder
                    }
                    .frame(width: 96, height: 96)
                    .clipShape(Circle())
                } else {
                    avatarPlaceholder
                }
                
                // Edit button
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        PhotosPicker(selection: $selectedAvatar, matching: .images) {
                            ZStack {
                                Circle()
                                    .fill(.blue)
                                    .frame(width: 32, height: 32)
                                
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                        }
                    }
                }
                .frame(width: 96, height: 96)
            }
            
            Text("Tap to change avatar")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private var avatarPlaceholder: some View {
        Text(getInitials())
            .font(.system(size: 32, weight: .bold, design: .rounded))
            .foregroundColor(.blue)
    }
    
    // MARK: - Personal Information Section
    private var personalInfoSection: some View {
        VStack(spacing: 0) {
            sectionHeader(title: "Personal Information", icon: "person.fill", color: .blue)
            
            VStack(spacing: 16) {
                HStack(spacing: 12) {
                    editField(
                        title: "First Name",
                        text: $firstName,
                        placeholder: "Enter your first name",
                        field: .firstName
                    )
                    
                    editField(
                        title: "Last Name",
                        text: $lastName,
                        placeholder: "Enter your last name",
                        field: .lastName
                    )
                }
                
                editField(
                    title: "Email",
                    text: $email,
                    placeholder: "Enter your email",
                    field: .email,
                    keyboardType: .emailAddress,
                    isDisabled: true
                )
                
                editField(
                    title: "Phone",
                    text: $phone,
                    placeholder: "Enter your phone number",
                    field: .phone,
                    keyboardType: .phonePad
                )
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 20)
        }
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Delete Account Section
    private var deleteAccountSection: some View {
        VStack(spacing: 0) {
            HStack {
                sectionHeader(title: "Danger Zone", icon: "exclamationmark.triangle.fill", color: .red)
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 8)
            
            VStack(spacing: 16) {
                // Warning message
                HStack {
                    Image(systemName: "exclamationmark.circle")
                        .foregroundColor(.red)
                        .font(.caption)
                    Text("Deleting your account is permanent and cannot be undone")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(.horizontal, 20)
                
                // Delete button
                Button(action: {
                    showDeleteAccountAlert = true
                }) {
                    HStack(spacing: 12) {
                        if isDeleting {
                            ProgressView()
                                .scaleEffect(0.8)
                                .tint(.white)
                        } else {
                            Image(systemName: "trash.fill")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        
                        Text(isDeleting ? "Deleting Account..." : "Delete Account")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.red)
                    )
                }
                .disabled(isDeleting || isUploading)
                .padding(.horizontal, 20)
            }
            .padding(.vertical, 20)
        }
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Fan Profile Section
    private var fanProfileSection: some View {
        VStack(spacing: 0) {
            sectionHeader(title: "Fan Profile", icon: "star.fill", color: .purple)
            
            VStack(spacing: 16) {
                editField(
                    title: "Nickname",
                    text: $nickname,
                    placeholder: "Your fan nickname",
                    field: .nickname
                )
                
                editField(
                    title: "Location",
                    text: $location,
                    placeholder: "City, Country",
                    field: .location
                )
                
                editField(
                    title: "Favorite Song",
                    text: $favoriteSong,
                    placeholder: "Your favorite song",
                    field: .favoriteSong
                )
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 20)
        }
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Address Section
    private var addressSection: some View {
        VStack(spacing: 0) {
            HStack {
                sectionHeader(title: "Shipping Address", icon: "location.fill", color: .green)
                
                Spacer()
                
                // Значок приватности
                HStack(spacing: 4) {
                    Image(systemName: "lock.fill")
                        .font(.caption)
                    Text("Private")
                        .font(.caption)
                }
                .foregroundColor(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(6)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 8)
            
            VStack(spacing: 16) {
                // Info message
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundColor(.blue)
                        .font(.caption)
                    Text("This information is private and only visible to you")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(.horizontal, 20)
                
                // Country Picker
                VStack(alignment: .leading, spacing: 8) {
                    Text("Country")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Menu {
                        ForEach(Country.groupedCountries, id: \.region) { group in
                            Section(group.region) {
                                ForEach(group.countries, id: \.self) { country in
                                    Button {
                                        selectedCountry = country
                                        updateAddressFieldsForCountry()
                                    } label: {
                                        HStack {
                                            Text(country.name)
                                            if selectedCountry == country {
                                                Spacer()
                                                Image(systemName: "checkmark")
                                                    .foregroundColor(.blue)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack {
                            Text(selectedCountry.name)
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "chevron.down")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
                .padding(.horizontal, 20)
                
                // Dynamic address fields based on country
                VStack(spacing: 16) {
                    editField(
                        title: selectedCountry.addressLine1Label,
                        text: $addressLine1,
                        placeholder: selectedCountry.addressLine1Placeholder,
                        field: .addressLine1
                    )
                    
                    if selectedCountry.hasAddressLine2 {
                        editField(
                            title: selectedCountry.addressLine2Label,
                            text: $addressLine2,
                            placeholder: selectedCountry.addressLine2Placeholder,
                            field: .addressLine2
                        )
                    }
                    
                    HStack(spacing: 12) {
                        editField(
                            title: selectedCountry.cityLabel,
                            text: $city,
                            placeholder: selectedCountry.cityPlaceholder,
                            field: .city
                        )
                        
                        if selectedCountry.hasStates {
                            editField(
                                title: selectedCountry.stateName,
                                text: $state,
                                placeholder: selectedCountry.statePlaceholder,
                                field: .state
                            )
                        }
                    }
                    
                    if selectedCountry.hasZipCode {
                        editField(
                            title: selectedCountry.zipCodeName,
                            text: $zipCode,
                            placeholder: selectedCountry.zipCodePlaceholder,
                            field: .zipCode
                        )
                    }
                }
                .padding(.horizontal, 20)
            }
            .padding(.vertical, 20)
        }
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Helper Views
    private func sectionHeader(title: String, icon: String, color: Color) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(color.opacity(0.15))
                    .frame(width: 36, height: 36)
                
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(color)
            }
            
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
        }
    }
    
    private func editField(
        title: String,
        text: Binding<String>,
        placeholder: String,
        field: EditField,
        keyboardType: UIKeyboardType = .default,
        isDisabled: Bool = false
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(isDisabled ? .secondary : .primary)
            
            TextField(placeholder, text: text)
                .font(.body)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(isDisabled ? Color(.systemGray5) : Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .keyboardType(keyboardType)
                .focused($focusedField, equals: field)
                .disabled(isDisabled)
                .autocapitalization(keyboardType == .emailAddress ? .none : .sentences)
        }
    }
    
    private var cardBackground: some View {
        colorScheme == .dark ?
        Color(UIColor.secondarySystemGroupedBackground) :
        Color.white
    }
    
    // MARK: - Helper Functions
    private func getInitials() -> String {
        let fullName = "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)
        if fullName.isEmpty {
            return nickname.prefix(2).uppercased()
        }
        let components = fullName.components(separatedBy: " ")
        let firstInitial = components.first?.first?.uppercased() ?? ""
        let lastInitial = components.count > 1 ? components.last?.first?.uppercased() ?? "" : ""
        return firstInitial + lastInitial
    }
    
    // ✅ ОБНОВЛЕННАЯ функция загрузки данных
    private func loadCurrentUserData() {
        guard let user = appState.user else { return }
        
        // Загружаем данные из UserModel
        let nameComponents = user.name.components(separatedBy: " ")
        firstName = nameComponents.first ?? ""
        lastName = nameComponents.count > 1 ? nameComponents.dropFirst().joined(separator: " ") : ""
        
        email = user.email
        phone = user.phone
        
        // Загружаем данные из FanProfile (ваша существующая модель)
        if let fanProfile = user.fanProfile {
            nickname = fanProfile.nickname
            location = fanProfile.location
            favoriteSong = fanProfile.favoriteSong
        }
        
        // ✅ ДОБАВЛЕНО: Загрузка адреса
        loadAddressFromFirebase()
    }
    
    // ✅ НОВАЯ функция загрузки адреса
    private func loadAddressFromFirebase() {
        guard let user = appState.user else { return }
        
        Task {
            do {
                let addressDoc = try await db.collection("users").document(user.id)
                    .collection("profile").document("address").getDocument()
                
                if let addressData = addressDoc.data() {
                    await MainActor.run {
                        if let countryCode = addressData["country"] as? String,
                           let country = Country(rawValue: countryCode) {
                            selectedCountry = country
                        }
                        addressLine1 = addressData["addressLine1"] as? String ?? ""
                        addressLine2 = addressData["addressLine2"] as? String ?? ""
                        city = addressData["city"] as? String ?? ""
                        state = addressData["state"] as? String ?? ""
                        zipCode = addressData["zipCode"] as? String ?? ""
                    }
                }
            } catch {
                print("Error loading address: \(error)")
            }
        }
    }
    
    private func loadSelectedImage() {
        guard let selectedAvatar = selectedAvatar else { return }
        
        Task {
            if let data = try? await selectedAvatar.loadTransferable(type: Data.self) {
                if let uiImage = UIImage(data: data) {
                    await MainActor.run {
                        self.avatarImage = uiImage
                    }
                }
            }
        }
    }
    
    private func updateAddressFieldsForCountry() {
        if !selectedCountry.hasStates {
            state = ""
        }
        if !selectedCountry.hasZipCode {
            zipCode = ""
        }
        if !selectedCountry.hasAddressLine2 {
            addressLine2 = ""
        }
    }
    
    private func saveProfile() {
        guard let user = appState.user else { return }
        
        isUploading = true
        
        Task {
            do {
                var updatedUser = user
                
                // Обновляем основную информацию UserModel
                let fullName = "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)
                updatedUser.name = fullName.isEmpty ? nickname : fullName
                updatedUser.phone = phone
                
                // Загружаем аватар если выбран новый
                if let avatarImage = avatarImage {
                    let avatarURL = try await uploadAvatar(avatarImage, userId: user.id)
                    updatedUser.avatarURL = avatarURL
                }
                
                // Обновляем FanProfile - используем ТОЧНО вашу модель из FanModels.swift
                if let existingFanProfile = updatedUser.fanProfile {
                    // Создаем новый FanProfile с обновленными данными, сохраняя остальное
                    updatedUser.fanProfile = FanProfile(
                        nickname: nickname,
                        joinDate: existingFanProfile.joinDate, // Сохраняем дату присоединения
                        location: location,
                        favoriteSong: favoriteSong,
                        level: existingFanProfile.level, // Сохраняем уровень
                        achievements: existingFanProfile.achievements, // Сохраняем достижения
                        isModerator: existingFanProfile.isModerator, // Сохраняем статус модератора
                        stats: existingFanProfile.stats, // Сохраняем статистику
                        notificationSettings: existingFanProfile.notificationSettings // Сохраняем настройки
                    )
                } else {
                    // Создаем новый FanProfile с базовыми настройками
                    updatedUser.fanProfile = FanProfile(
                        nickname: nickname,
                        location: location,
                        favoriteSong: favoriteSong
                    )
                }
                
                // Сохраняем в Firebase
                try await saveUserToFirebase(updatedUser)
                
                // Сохраняем адрес отдельно
                try await saveAddressToFirebase(userId: user.id)
                
                await MainActor.run {
                    self.appState.user = updatedUser
                    self.isUploading = false
                    self.showSuccessAlert = true
                }
                
            } catch {
                await MainActor.run {
                    self.isUploading = false
                    self.errorMessage = error.localizedDescription
                    self.showError = true
                }
            }
        }
    }
    
    private func uploadAvatar(_ image: UIImage, userId: String) async throws -> String {
        guard let imageData = image.jpegData(compressionQuality: 0.7) else {
            throw ProfileError.imageProcessingFailed
        }
        
        let storageRef = storage.reference().child("avatars/\(userId).jpg")
        
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        _ = try await storageRef.putDataAsync(imageData, metadata: metadata)
        let downloadURL = try await storageRef.downloadURL()
        
        return downloadURL.absoluteString
    }
    
    private func saveUserToFirebase(_ user: UserModel) async throws {
        // Используем ТОЧНО ваш метод toDictionary() из UserModel
        let userData = user.toDictionary()
        
        // Обновляем данные в коллекции пользователей
        try await db.collection("users").document(user.id).updateData(userData)
        
        // Если это фанат, обновляем данные в коллекции фанатов группы
        if user.isFan, let fanGroupId = user.fanGroupId {
            let fanData: [String: Any] = [
                "nickname": user.fanProfile?.nickname ?? "",
                "location": user.fanProfile?.location ?? "",
                "favoriteSong": user.fanProfile?.favoriteSong ?? "",
                "level": user.fanProfile?.level.rawValue ?? "Newbie",
                "avatarURL": user.avatarURL ?? NSNull()
            ]
            
            try await db.collection("groups").document(fanGroupId)
                .collection("fans").document(user.id).updateData(fanData)
        }
    }
    
    private func saveAddressToFirebase(userId: String) async throws {
        guard !addressLine1.isEmpty || !city.isEmpty else { return }
        
        let addressData: [String: Any] = [
            "country": selectedCountry.rawValue,
            "countryName": selectedCountry.name,
            "addressLine1": addressLine1,
            "addressLine2": addressLine2,
            "city": city,
            "state": state,
            "zipCode": zipCode,
            "updatedAt": Timestamp(date: Date())
        ]
        
        try await db.collection("users").document(userId)
            .collection("profile").document("address").setData(addressData)
    }
    
    // MARK: - Delete Account Function
    private func deleteAccount() {
        guard let user = appState.user else { return }
        
        isDeleting = true
        
        Task {
            do {
                // 1. Удаляем из коллекции фанатов группы (если фанат)
                if user.isFan, let fanGroupId = user.fanGroupId {
                    try await db.collection("groups").document(fanGroupId)
                        .collection("fans").document(user.id).delete()
                }
                
                // 2. Удаляем адрес из подколлекции profile
                try await db.collection("users").document(user.id)
                    .collection("profile").document("address").delete()
                
                // 3. Удаляем всю подколлекцию profile (если есть другие документы)
                let profileDocs = try await db.collection("users").document(user.id)
                    .collection("profile").getDocuments()
                
                for doc in profileDocs.documents {
                    try await doc.reference.delete()
                }
                
                // 4. Удаляем аватар из Storage (если есть)
                if let avatarURL = user.avatarURL {
                    let storageRef = storage.reference().child("avatars/\(user.id).jpg")
                    try? await storageRef.delete()
                }
                
                // 5. Удаляем основной документ пользователя
                try await db.collection("users").document(user.id).delete()
                
                // 6. Удаляем аккаунт из Firebase Auth
                try await Auth.auth().currentUser?.delete()
                
                await MainActor.run {
                    // 7. Очищаем состояние приложения
                    self.appState.user = nil
                    self.appState.isLoggedIn = false
                    self.isDeleting = false
                    
                    // 8. Закрываем экран редактирования
                    self.dismiss()
                }
                
            } catch {
                await MainActor.run {
                    self.isDeleting = false
                    self.errorMessage = "Failed to delete account: \(error.localizedDescription)"
                    self.showError = true
                }
            }
        }
    }
}

// MARK: - Supporting Enums

enum EditField: CaseIterable {
    case firstName, lastName, email, phone
    case nickname, location, favoriteSong
    case addressLine1, addressLine2, city, state, zipCode
}

enum Country: String, CaseIterable {
    // North America
    case usa = "US"
    case canada = "CA"
    case mexico = "MX"
    
    // Europe
    case ukraine = "UA"
    case germany = "DE"
    case france = "FR"
    case uk = "GB"
    case poland = "PL"
    case italy = "IT"
    case spain = "ES"
    case netherlands = "NL"
    case sweden = "SE"
    case norway = "NO"
    case denmark = "DK"
    case finland = "FI"
    case austria = "AT"
    case switzerland = "CH"
    case belgium = "BE"
    case czechRepublic = "CZ"
    case slovakia = "SK"
    case hungary = "HU"
    case romania = "RO"
    case bulgaria = "BG"
    case croatia = "HR"
    case slovenia = "SI"
    case lithuania = "LT"
    case latvia = "LV"
    case estonia = "EE"
    case portugal = "PT"
    case greece = "GR"
    case ireland = "IE"
    case iceland = "IS"
    case luxembourg = "LU"
    case malta = "MT"
    case cyprus = "CY"
    
    // Asia-Pacific
    case japan = "JP"
    case southKorea = "KR"
    case china = "CN"
    case singapore = "SG"
    case australia = "AU"
    case newZealand = "NZ"
    case hongKong = "HK"
    case taiwan = "TW"
    case thailand = "TH"
    case vietnam = "VN"
    case malaysia = "MY"
    case philippines = "PH"
    case indonesia = "ID"
    case india = "IN"
    
    // Middle East
    case israel = "IL"
    case uae = "AE"
    case saudiArabia = "SA"
    case turkey = "TR"
    
    // South America
    case brazil = "BR"
    case argentina = "AR"
    case chile = "CL"
    case colombia = "CO"
    case peru = "PE"
    case uruguay = "UY"
    
    // Africa
    case southAfrica = "ZA"
    case egypt = "EG"
    case morocco = "MA"
    
    var name: String {
        switch self {
        case .usa: return "United States"
        case .canada: return "Canada"
        case .mexico: return "Mexico"
        case .ukraine: return "Ukraine"
        case .germany: return "Germany"
        case .france: return "France"
        case .uk: return "United Kingdom"
        case .poland: return "Poland"
        case .italy: return "Italy"
        case .spain: return "Spain"
        case .netherlands: return "Netherlands"
        case .sweden: return "Sweden"
        case .norway: return "Norway"
        case .denmark: return "Denmark"
        case .finland: return "Finland"
        case .austria: return "Austria"
        case .switzerland: return "Switzerland"
        case .belgium: return "Belgium"
        case .czechRepublic: return "Czech Republic"
        case .slovakia: return "Slovakia"
        case .hungary: return "Hungary"
        case .romania: return "Romania"
        case .bulgaria: return "Bulgaria"
        case .croatia: return "Croatia"
        case .slovenia: return "Slovenia"
        case .lithuania: return "Lithuania"
        case .latvia: return "Latvia"
        case .estonia: return "Estonia"
        case .portugal: return "Portugal"
        case .greece: return "Greece"
        case .ireland: return "Ireland"
        case .iceland: return "Iceland"
        case .luxembourg: return "Luxembourg"
        case .malta: return "Malta"
        case .cyprus: return "Cyprus"
        case .japan: return "Japan"
        case .southKorea: return "South Korea"
        case .china: return "China"
        case .singapore: return "Singapore"
        case .australia: return "Australia"
        case .newZealand: return "New Zealand"
        case .hongKong: return "Hong Kong"
        case .taiwan: return "Taiwan"
        case .thailand: return "Thailand"
        case .vietnam: return "Vietnam"
        case .malaysia: return "Malaysia"
        case .philippines: return "Philippines"
        case .indonesia: return "Indonesia"
        case .india: return "India"
        case .israel: return "Israel"
        case .uae: return "United Arab Emirates"
        case .saudiArabia: return "Saudi Arabia"
        case .turkey: return "Turkey"
        case .brazil: return "Brazil"
        case .argentina: return "Argentina"
        case .chile: return "Chile"
        case .colombia: return "Colombia"
        case .peru: return "Peru"
        case .uruguay: return "Uruguay"
        case .southAfrica: return "South Africa"
        case .egypt: return "Egypt"
        case .morocco: return "Morocco"
        }
    }
    
    // Группированные страны по регионам
    static var groupedCountries: [(region: String, countries: [Country])] {
        return [
            ("North America", [.usa, .canada, .mexico]),
            ("Europe", [.ukraine, .germany, .france, .uk, .poland, .italy, .spain, .netherlands, .sweden, .norway, .denmark, .finland, .austria, .switzerland, .belgium, .czechRepublic, .slovakia, .hungary, .romania, .bulgaria, .croatia, .slovenia, .lithuania, .latvia, .estonia, .portugal, .greece, .ireland, .iceland, .luxembourg, .malta, .cyprus]),
            ("Asia-Pacific", [.japan, .southKorea, .china, .singapore, .australia, .newZealand, .hongKong, .taiwan, .thailand, .vietnam, .malaysia, .philippines, .indonesia, .india]),
            ("Middle East", [.israel, .uae, .saudiArabia, .turkey]),
            ("South America", [.brazil, .argentina, .chile, .colombia, .peru, .uruguay]),
            ("Africa", [.southAfrica, .egypt, .morocco])
        ]
    }
    
    // Address structure properties
    var hasStates: Bool {
        switch self {
        case .usa, .canada, .australia, .brazil, .mexico: return true
        default: return false
        }
    }
    
    var hasZipCode: Bool {
        return true
    }
    
    var hasAddressLine2: Bool {
        switch self {
        case .usa, .canada, .uk, .ireland, .australia, .newZealand: return true
        default: return false
        }
    }
    
    var stateName: String {
        switch self {
        case .usa: return "State"
        case .canada: return "Province"
        case .australia: return "State"
        case .brazil: return "State"
        case .mexico: return "State"
        default: return "Region"
        }
    }
    
    var zipCodeName: String {
        switch self {
        case .usa: return "ZIP Code"
        case .canada: return "Postal Code"
        case .uk, .australia, .newZealand: return "Postcode"
        case .brazil: return "CEP"
        case .germany, .austria, .switzerland: return "PLZ"
        case .france, .belgium, .luxembourg: return "Postal Code"
        case .netherlands: return "Postcode"
        case .sweden, .norway, .denmark, .finland: return "Postal Code"
        case .spain, .mexico, .argentina, .chile, .colombia, .peru, .uruguay: return "Postal Code"
        case .italy: return "CAP"
        case .poland: return "Postal Code"
        default: return "Postal Code"
        }
    }
    
    var addressLine1Label: String {
        switch self {
        case .uk, .ireland: return "Address Line 1"
        case .germany, .austria, .switzerland: return "Street & Number"
        case .netherlands: return "Street Name & Number"
        default: return "Street Address"
        }
    }
    
    var addressLine2Label: String {
        switch self {
        case .uk, .ireland: return "Address Line 2 (Optional)"
        case .usa, .canada: return "Apt, Suite, Unit (Optional)"
        default: return "Additional Address Info (Optional)"
        }
    }
    
    var cityLabel: String {
        switch self {
        case .uk, .ireland: return "Town/City"
        case .germany, .austria, .switzerland: return "City"
        case .netherlands: return "City"
        default: return "City"
        }
    }
    
    var addressLine1Placeholder: String {
        switch self {
        case .usa, .canada: return "123 Main Street"
        case .uk, .ireland: return "House number and street name"
        case .germany, .austria, .switzerland: return "Musterstraße 123"
        case .france, .belgium, .luxembourg: return "123 Rue de la Paix"
        case .netherlands: return "Hoofdstraat 123"
        case .sweden, .norway, .denmark, .finland: return "Storgatan 123"
        default: return "Street address"
        }
    }
    
    var addressLine2Placeholder: String {
        switch self {
        case .uk, .ireland: return "Flat, suite, unit, building"
        case .usa, .canada: return "Apartment, suite, unit, building"
        default: return "Additional address information"
        }
    }
    
    var cityPlaceholder: String {
        switch self {
        case .usa: return "New York"
        case .canada: return "Toronto"
        case .uk: return "London"
        case .germany: return "Berlin"
        case .france: return "Paris"
        case .australia: return "Sydney"
        case .japan: return "Tokyo"
        default: return "City"
        }
    }
    
    var statePlaceholder: String {
        switch self {
        case .usa: return "California"
        case .canada: return "Ontario"
        case .australia: return "NSW"
        case .brazil: return "SP"
        case .mexico: return "CDMX"
        default: return "State"
        }
    }
    
    var zipCodePlaceholder: String {
        switch self {
        case .usa: return "90210"
        case .canada: return "K1A 0A6"
        case .uk: return "SW1A 1AA"
        case .germany, .austria: return "10115"
        case .switzerland: return "8001"
        case .france: return "75001"
        case .netherlands: return "1012 AB"
        case .sweden: return "123 45"
        case .norway, .denmark, .finland: return "0150"
        case .australia, .newZealand: return "2000"
        case .brazil: return "01234-567"
        case .japan: return "123-4567"
        default: return "12345"
        }
    }
}

enum ProfileError: LocalizedError {
    case imageProcessingFailed
    case uploadFailed
    case saveFailed
    
    var errorDescription: String? {
        switch self {
        case .imageProcessingFailed:
            return "Failed to process image"
        case .uploadFailed:
            return "Failed to upload image"
        case .saveFailed:
            return "Failed to save profile"
        }
    }
}
