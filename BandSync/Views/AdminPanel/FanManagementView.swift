import SwiftUI

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
    @State private var fanClubEnabled = true
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        List {
            // Fan Club Status Section
            Section {
                HStack(spacing: 12) {
                    fanIcon(icon: fanClubEnabled ? "heart.fill" : "heart", color: fanClubEnabled ? .purple : .gray)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Fan Club Status")
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        
                        Text(fanClubEnabled ? "Active - Fans can join your group" : "Inactive - Fan registration disabled")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Toggle("", isOn: $fanClubEnabled)
                        .toggleStyle(SwitchToggleStyle(tint: .purple))
                }
                .padding(.vertical, 4)
            } header: {
                Text("Fan Club Settings")
            }
            
            // Invite Code Section
            if fanClubEnabled {
                Section {
                    if let inviteCode = currentInviteCode {
                        // Current invite code display
                        HStack(spacing: 12) {
                            fanIcon(icon: "key.fill", color: .purple)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Current Invite Code")
                                    .font(.body)
                                    .fontWeight(.medium)
                                    .foregroundColor(.primary)
                                
                                HStack {
                                    Text(inviteCode.code)
                                        .font(.system(.title3, design: .monospaced))
                                        .fontWeight(.bold)
                                        .foregroundColor(.purple)
                                    
                                    Button {
                                        UIPasteboard.general.string = inviteCode.code
                                        alertMessage = "Invite code copied to clipboard!"
                                        showAlert = true
                                    } label: {
                                        Image(systemName: "doc.on.clipboard")
                                            .foregroundColor(.purple)
                                    }
                                }
                                
                                Text("Uses: \(inviteCode.currentUses)\(inviteCode.maxUses != nil ? "/\(inviteCode.maxUses!)" : "")")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            // Edit button
                            Button {
                                customCodeInput = inviteCode.code
                                showEditCodeSheet = true
                            } label: {
                                Image(systemName: "pencil")
                                    .foregroundColor(.blue)
                                    .font(.subheadline)
                            }
                        }
                        .padding(.vertical, 4)
                        
                        // Replace auto-generation with manual creation
                        Button {
                            customCodeInput = currentInviteCode?.code ?? ""
                            showEditCodeSheet = true
                        } label: {
                            HStack(spacing: 12) {
                                fanIcon(icon: "arrow.clockwise", color: .orange)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Change Invite Code")
                                        .font(.body)
                                        .fontWeight(.medium)
                                        .foregroundColor(.primary)
                                    
                                    Text("Create a new custom code for fans")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                            }
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                    } else {
                        // No invite code - create first one manually
                        Button {
                            customCodeInput = ""
                            showEditCodeSheet = true
                        } label: {
                            HStack(spacing: 12) {
                                fanIcon(icon: "plus.circle.fill", color: .green)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Create Custom Invite Code")
                                        .font(.body)
                                        .fontWeight(.medium)
                                        .foregroundColor(.primary)
                                    
                                    Text("Enter your own unique code for the fan club")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                            }
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                } header: {
                    Text("Fan Invite Code")
                }
            }
            
            // Fan Statistics Section
            Section {
                HStack(spacing: 12) {
                    fanIcon(icon: "chart.bar.fill", color: .blue)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Total Fans")
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        
                        Text("\(fans.count) fans in your club")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Text("\(fans.count)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.purple)
                }
                .padding(.vertical, 4)
                
                if fans.count > 0 {
                    HStack(spacing: 12) {
                        fanIcon(icon: "clock.fill", color: .green)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Recent Activity")
                                .font(.body)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                            
                            Text("Last fan joined: \(getLastJoinedDate())")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
            } header: {
                Text("Fan Club Statistics")
            }
            
            // Fan List Section
            if !fans.isEmpty {
                Section {
                    ForEach(fans, id: \.id) { fan in
                        FanRowView(fan: fan)
                    }
                } header: {
                    Text("Recent Fans (\(min(fans.count, 10)))")
                }
            }
            
            // Loading Section
            if isLoading {
                Section {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Loading fan data...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }
            }
        }
        .navigationTitle("Fan Management")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadFanData()
        }
        .refreshable {
            loadFanData()
        }
        .alert("Change Invite Code", isPresented: $showGenerateCodeAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Change") {
                customCodeInput = currentInviteCode?.code ?? ""
                showEditCodeSheet = true
            }
        } message: {
            Text("Create a new custom invite code. This will replace the current code.")
        }
        .alert("Fan Management", isPresented: $showAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertMessage)
        }
        .sheet(isPresented: $showEditCodeSheet) {
            EditInviteCodeView(
                currentCode: currentInviteCode?.code ?? "",
                customCodeInput: $customCodeInput,
                isValidatingCustomCode: $isValidatingCustomCode,
                customCodeValidationMessage: $customCodeValidationMessage,
                onSave: { newCode in
                    updateInviteCode(newCode: newCode)
                }
            )
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
                case .failure:
                    self.currentInviteCode = nil
                }
            }
        }
        
        // Load fans list
        loadFansList(groupId: groupId)
    }
    
    private func loadFansList(groupId: String) {
        // This would load fans from Firebase
        // For now, we'll simulate loading
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.isLoading = false
            // TODO: Implement actual fan loading from Firebase
            // self.fans = loaded fans
        }
    }
    
    private func generateInviteCode() {
        // This function is no longer used for auto-generation
        // Redirecting to manual creation
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
        return "No recent activity"
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
        
        // Create new invite code with custom value
        let newInviteCode = FanInviteCode(
            groupId: groupId,
            code: cleanCode,
            createdBy: Auth.auth().currentUser?.uid ?? "",
            groupName: groupName,
            currentUses: 0
        )
        
        // Save to Firebase (simplified for now)
        fanService.generateFanInviteCode(for: groupId, groupName: groupName) { result in
            DispatchQueue.main.async {
                self.isLoading = false
                switch result {
                case .success:
                    // In real implementation, update the code to custom value in Firebase
                    self.currentInviteCode = newInviteCode
                    self.alertMessage = "Custom invite code '\(cleanCode)' created successfully!"
                    self.showAlert = true
                    self.showEditCodeSheet = false
                case .failure(let error):
                    self.alertMessage = "Error creating invite code: \(error.localizedDescription)"
                    self.showAlert = true
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
        return code.unicodeScalars.allSatisfy { allowedCharacters.contains($0) }
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
                }
            }
            
            Spacer()
            
            // Join date
            if let fanProfile = fan.fanProfile {
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Joined")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(fanProfile.joinDate.formatted(.dateTime.month().day()))
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Edit Invite Code View
struct EditInviteCodeView: View {
    let currentCode: String
    @Binding var customCodeInput: String
    @Binding var isValidatingCustomCode: Bool
    @Binding var customCodeValidationMessage: String
    let onSave: (String) -> Void
    
    @Environment(\.dismiss) var dismiss
    @State private var isValidCode = false
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(currentCode.isEmpty ? "Create Your Fan Club Code" : "Edit Fan Club Code")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text(currentCode.isEmpty ?
                             "Create a unique code that fans will use to join your fan club." :
                             "Update your fan club invite code. Enter a new custom code.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        TextField("Enter custom code", text: $customCodeInput)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.allCharacters)
                            .disableAutocorrection(true)
                            .onChange(of: customCodeInput) { oldValue, newValue in
                                validateCustomCode(newValue)
                            }
                        
                        // Validation message
                        if !customCodeValidationMessage.isEmpty {
                            HStack {
                                Image(systemName: isValidCode ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .foregroundColor(isValidCode ? .green : .red)
                                
                                Text(customCodeValidationMessage)
                                    .font(.caption)
                                    .foregroundColor(isValidCode ? .green : .red)
                            }
                        }
                    }
                } header: {
                    Text("Custom Invite Code")
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Code Requirements:")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            requirementRow("Up to 25 characters", isValid: customCodeInput.count <= 25 && !customCodeInput.isEmpty)
                            requirementRow("Only letters and numbers", isValid: isAlphanumeric(customCodeInput))
                            requirementRow("Uppercase letters preferred", isValid: customCodeInput == customCodeInput.uppercased())
                        }
                    }
                } header: {
                    Text("Requirements")
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Examples of good codes:")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Text("ROCKBAND2025, MUSIC4US, FANCLUB123, BANDLOVE, MYAWESOMEBAND, JOIN")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Edit Invite Code")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        onSave(customCodeInput.uppercased())
                    }
                    .disabled(!isValidCode || customCodeInput.isEmpty)
                }
            }
        }
        .onAppear {
            validateCustomCode(customCodeInput)
        }
    }
    
    private func requirementRow(_ text: String, isValid: Bool) -> some View {
        HStack {
            Image(systemName: isValid ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isValid ? .green : .gray)
            
            Text(text)
                .font(.caption)
                .foregroundColor(isValid ? .primary : .secondary)
        }
    }
    
    private func validateCustomCode(_ code: String) {
        let cleanCode = code.uppercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Check all requirements
        let lengthValid = cleanCode.count <= 25 && !cleanCode.isEmpty
        let alphanumericValid = isAlphanumeric(cleanCode)
        
        isValidCode = lengthValid && alphanumericValid && !cleanCode.isEmpty
        
        if cleanCode.isEmpty {
            customCodeValidationMessage = ""
        } else if !lengthValid {
            customCodeValidationMessage = "Code must be up to 25 characters long"
        } else if !alphanumericValid {
            customCodeValidationMessage = "Only letters and numbers are allowed"
        } else {
            customCodeValidationMessage = "✓ Valid invite code format"
        }
    }
    
    private func isAlphanumeric(_ string: String) -> Bool {
        return string.range(of: "^[a-zA-Z0-9]+$", options: .regularExpression) != nil
    }
}
