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
                            Text("Join Fan Club".localized)
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text("Connect with your favorite band and get exclusive access to events, merchandise, and updates!".localized)
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
                        Text("Invitation Code".localized)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text("Enter the invite code you received from the band".localized)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            TextField("Enter invite code".localized, text: $inviteCode)
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
                            Text("Invalid invite code. Please check and try again.".localized)
                                .font(.caption)
                                .foregroundColor(.red)
                        } else if validationStatus == .valid {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("Valid invite code! You can join this fan club.".localized)
                                    .font(.caption)
                                    .foregroundColor(.green)
                            }
                        }
                    }
                } header: {
                    Text("Step 1".localized)
                }
                
                // Fan profile section
                Section {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Fan Profile".localized)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        // Nickname field
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Nickname".localized)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            TextField("Enter your fan nickname".localized, text: $nickname)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        
                        // Location field (optional)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Location (Optional)".localized)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            TextField("City, Country".localized, text: $location)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        
                        // Favorite song field (optional)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Favorite Song (Optional)".localized)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            TextField("What's your favorite song?".localized, text: $favoriteSong)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                    }
                } header: {
                    Text("Step 2".localized)
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
                                Text("Join Fan Club".localized)
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
            .navigationTitle("Fan Registration".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel".localized) {
                        dismiss()
                    }
                    .foregroundColor(.primary)
                }
            }
        }
        .alert("Registration Error".localized, isPresented: $showErrorAlert) {
            Button("OK".localized, role: .cancel) {}
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
        
        let fanProfile = FanProfile(
            nickname: nickname.trimmingCharacters(in: .whitespacesAndNewlines),
            joinDate: Date(),
            location: location.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "" : location.trimmingCharacters(in: .whitespacesAndNewlines),
            favoriteSong: favoriteSong.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "" : favoriteSong.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        
        fanService.joinFanClub(
            inviteCode: inviteCode.trimmingCharacters(in: .whitespacesAndNewlines),
            fanProfile: fanProfile
        ) { result in
            DispatchQueue.main.async {
                isRegistering = false
                
                switch result {
                case .success:
                    // Registration successful - update app state
                    appState.refreshAuthState()
                    dismiss()
                    
                case .failure(let error):
                    // Show error to user
                    if let fanError = error as? FanInviteService.FanInviteError {
                        errorMessage = fanError.localizedDescription
                    } else {
                        errorMessage = error.localizedDescription
                    }
                    showErrorAlert = true
                }
            }
        }
    }
}

// MARK: - Localization Extensions

extension String {
    var localized: String {
        return NSLocalizedString(self, comment: "")
    }
}

// MARK: - Preview

#Preview {
    FanRegistrationView()
        .environmentObject(AppState.shared)
}
