import SwiftUI

struct FanRegistrationView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject private var appState: AppState
    @StateObject private var fanService = FanInviteService.shared
    
    // Form fields
    @State private var inviteCode = ""
    @State private var nickname = ""
    @State private var location = ""
    @State private var favoriteSong = ""
    
    // UI state
    @State private var isValidatingCode = false
    @State private var isRegistering = false
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    @State private var validationStatus: ValidationStatus = .none
    
    enum ValidationStatus {
        case none
        case validating
        case valid
        case invalid
    }
    
    var isFormValid: Bool {
        !inviteCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !nickname.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        validationStatus == .valid &&
        !isRegistering
    }
    
    var body: some View {
        NavigationView {
            Form {
                // Header section with fan club info
                Section {
                    VStack(spacing: 16) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.purple)
                        
                        VStack(spacing: 8) {
                            Text(NSLocalizedString("Join Fan Club", comment: ""))
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text(NSLocalizedString("Connect with your favorite band and get exclusive access to events, merchandise, and updates!", comment: ""))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical)
                }
                .listRowBackground(Color.clear)
                
                // Invite code section
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(NSLocalizedString("Invitation Code", comment: ""))
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text(NSLocalizedString("Enter the invite code you received from the band", comment: ""))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            TextField(NSLocalizedString("Enter invite code", comment: ""), text: $inviteCode)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .textInputAutocapitalization(.characters)
                                .disableAutocorrection(true)
                                .onSubmit {
                                    validateInviteCode()
                                }
                                .onChange(of: inviteCode) { oldValue, newValue in
                                    // Reset validation when code changes
                                    validationStatus = .none
                                    
                                    // Auto-validate after user stops typing
                                    if !newValue.isEmpty && newValue != oldValue {
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                            if inviteCode == newValue {
                                                validateInviteCode()
                                            }
                                        }
                                    }
                                }
                            
                            // Validation indicator
                            Group {
                                switch validationStatus {
                                case .none:
                                    EmptyView()
                                case .validating:
                                    ProgressView()
                                        .scaleEffect(0.8)
                                case .valid:
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                case .invalid:
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.red)
                                }
                            }
                            .frame(width: 24, height: 24)
                        }
                        
                        // Validation message
                        if validationStatus == .invalid {
                            Text(NSLocalizedString("Invalid invite code. Please check and try again.", comment: ""))
                                .font(.caption)
                                .foregroundColor(.red)
                        } else if validationStatus == .valid {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text(NSLocalizedString("Valid invite code! You can join this fan club.", comment: ""))
                                    .font(.caption)
                                    .foregroundColor(.green)
                            }
                        }
                    }
                } header: {
                    Text(NSLocalizedString("Step 1", comment: ""))
                }
                
                // Fan profile section
                Section {
                    VStack(alignment: .leading, spacing: 16) {
                        Text(NSLocalizedString("Fan Profile", comment: ""))
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        // Nickname field
                        VStack(alignment: .leading, spacing: 4) {
                            Text(NSLocalizedString("Nickname", comment: ""))
                                .font(.subheadline)
                                .fontWeight(.medium)
                            TextField(NSLocalizedString("Enter your fan nickname", comment: ""), text: $nickname)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        
                        // Location field (optional)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(NSLocalizedString("Location (Optional)", comment: ""))
                                .font(.subheadline)
                                .fontWeight(.medium)
                            TextField(NSLocalizedString("City, Country", comment: ""), text: $location)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        
                        // Favorite song field (optional)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(NSLocalizedString("Favorite Song (Optional)", comment: ""))
                                .font(.subheadline)
                                .fontWeight(.medium)
                            TextField(NSLocalizedString("What's your favorite song?", comment: ""), text: $favoriteSong)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                    }
                } header: {
                    Text(NSLocalizedString("Step 2", comment: ""))
                }
                
                // Join button
                Section {
                    Button(action: joinFanClub) {
                        HStack {
                            if isRegistering {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.9)
                            } else {
                                Image(systemName: "heart.fill")
                                Text(NSLocalizedString("Join Fan Club", comment: ""))
                            }
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [.purple, .purple.opacity(0.8)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(12)
                        .shadow(color: .purple.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(!isFormValid)
                    .opacity(isFormValid ? 1.0 : 0.6)
                }
                .listRowBackground(Color.clear)
            }
            .navigationTitle(NSLocalizedString("Fan Registration", comment: ""))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(NSLocalizedString("Cancel", comment: "")) {
                        dismiss()
                    }
                    .foregroundColor(.primary)
                }
            }
        }
        .alert(NSLocalizedString("Registration Error", comment: ""), isPresented: $showErrorAlert) {
            Button(NSLocalizedString("OK", comment: ""), role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }
    
    // MARK: - Functions
    
    private func validateInviteCode() {
        let trimmedCode = inviteCode.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedCode.isEmpty else {
            validationStatus = .none
            return
        }
        
        validationStatus = .validating
        
        fanService.validateFanInviteCode(trimmedCode) { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    validationStatus = .valid
                case .failure:
                    validationStatus = .invalid
                }
            }
        }
    }
    
    private func joinFanClub() {
        guard isFormValid else { return }
        
        isRegistering = true
        
        // First validate code to get FanInviteCode object
        fanService.validateFanInviteCode(inviteCode.trimmingCharacters(in: .whitespacesAndNewlines)) { result in
            switch result {
            case .success(let inviteCodeObject):
                let fanProfile = FanProfile(
                    nickname: nickname.trimmingCharacters(in: .whitespacesAndNewlines),
                    joinDate: Date(),
                    location: location.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "" : location.trimmingCharacters(in: .whitespacesAndNewlines),
                    favoriteSong: favoriteSong.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "" : favoriteSong.trimmingCharacters(in: .whitespacesAndNewlines)
                )
                
                self.fanService.joinFanClub(inviteCode: inviteCodeObject, fanProfile: fanProfile) { joinResult in
                    DispatchQueue.main.async {
                        self.isRegistering = false
                        
                        switch joinResult {
                        case .success:
                            // Registration successful - update app state
                            self.appState.refreshAuthState()
                            self.dismiss()
                            
                        case .failure(let error):
                            // Show error to user
                            if let fanError = error as? FanInviteError {
                                self.errorMessage = fanError.localizedDescription
                            } else {
                                self.errorMessage = error.localizedDescription
                            }
                            self.showErrorAlert = true
                        }
                    }
                }
                
            case .failure(let error):
                DispatchQueue.main.async {
                    self.isRegistering = false
                    if let fanError = error as? FanInviteError {
                        self.errorMessage = fanError.localizedDescription
                    } else {
                        self.errorMessage = error.localizedDescription
                    }
                    self.showErrorAlert = true
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    FanRegistrationView()
        .environmentObject(AppState.shared)
}
