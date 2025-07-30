import SwiftUI

struct FanRegistrationView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject private var appState: AppState
    @StateObject private var fanService = FanInviteService.shared
    @Environment(\.colorScheme) private var colorScheme
    
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
            ScrollView {
                VStack(spacing: 32) {
                    // Hero Section
                    heroSection
                    
                    // Form Sections
                    VStack(spacing: 24) {
                        inviteCodeSection
                        profileSection
                        joinButton
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer(minLength: 100)
                }
            }
            .background(
                ZStack {
                    // Base background
                    Color(UIColor.systemGroupedBackground)
                        .ignoresSafeArea()
                    
                    // Gradient overlay
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.purple.opacity(0.03),
                            Color.blue.opacity(0.03),
                            Color.clear
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .ignoresSafeArea()
                }
            )
            .navigationBarHidden(true)
        }
        .alert("Registration Error", isPresented: $showErrorAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }
    
    // MARK: - Hero Section
    
    private var heroSection: some View {
        VStack(spacing: 24) {
            // Close Button
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .frame(width: 44, height: 44)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                }
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 60)
            
            // Hero Content
            VStack(spacing: 24) {
                // Animated Hero Icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [.purple, .blue]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 120, height: 120)
                        .shadow(color: .purple.opacity(0.3), radius: 20, x: 0, y: 10)
                    
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    Color.white.opacity(0.2),
                                    Color.clear
                                ]),
                                center: .topLeading,
                                startRadius: 20,
                                endRadius: 60
                            )
                        )
                        .frame(width: 120, height: 120)
                    
                    Image(systemName: "heart.fill")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(.white)
                }
                
                VStack(spacing: 16) {
                    Text("Join Fan Club")
                        .font(.largeTitle)
                        .fontWeight(.heavy)
                        .foregroundColor(.primary)
                    
                    Text("Connect with your favorite band and get exclusive access to events, merchandise, and updates!")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(nil)
                        .padding(.horizontal, 20)
                }
            }
        }
    }
    
    // MARK: - Invite Code Section
    
    private var inviteCodeSection: some View {
        VStack(spacing: 20) {
            // Section Header
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.purple)
                            .frame(width: 32, height: 32)
                        
                        Text("1")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Invitation Code")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text("Enter the invite code you received from the band")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
            }
            
            // Input Field with Modern Design
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        TextField("Enter invite code", text: $inviteCode)
                            .textFieldStyle(PlainTextFieldStyle())
                            .font(.body)
                            .fontWeight(.medium)
                            .textInputAutocapitalization(.characters)
                            .disableAutocorrection(true)
                            .onSubmit {
                                validateInviteCode()
                            }
                            .onChange(of: inviteCode) { oldValue, newValue in
                                validationStatus = .none
                                
                                if !newValue.isEmpty && newValue != oldValue {
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                        if inviteCode == newValue {
                                            validateInviteCode()
                                        }
                                    }
                                }
                            }
                    }
                    
                    // Validation Status Icon
                    Group {
                        switch validationStatus {
                        case .none:
                            Image(systemName: "key.fill")
                                .font(.title3)
                                .foregroundColor(.secondary.opacity(0.5))
                        case .validating:
                            ProgressView()
                                .scaleEffect(0.8)
                                .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                        case .valid:
                            Image(systemName: "checkmark.circle.fill")
                                .font(.title3)
                                .foregroundColor(.green)
                        case .invalid:
                            Image(systemName: "xmark.circle.fill")
                                .font(.title3)
                                .foregroundColor(.red)
                        }
                    }
                    .frame(width: 28, height: 28)
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(colorScheme == .dark ?
                              Color(UIColor.secondarySystemGroupedBackground) :
                              Color.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(
                                    validationStatus == .valid ? Color.green :
                                        validationStatus == .invalid ? Color.red :
                                        Color.secondary.opacity(0.2),
                                    lineWidth: validationStatus != .none ? 2 : 1
                                )
                        )
                        .shadow(
                            color: colorScheme == .dark ?
                                Color.clear :
                                Color.black.opacity(0.05),
                            radius: 8,
                            x: 0,
                            y: 2
                        )
                )
                
                // Validation Message
                Group {
                    if validationStatus == .invalid {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.caption)
                                .foregroundColor(.red)
                            Text("Invalid invite code. Please check and try again.")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                        .transition(.asymmetric(
                            insertion: .scale.combined(with: .opacity),
                            removal: .opacity
                        ))
                    } else if validationStatus == .valid {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundColor(.green)
                            Text("Valid invite code! You can join this fan club.")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                        .transition(.asymmetric(
                            insertion: .scale.combined(with: .opacity),
                            removal: .opacity
                        ))
                    }
                }
                .animation(.easeInOut(duration: 0.3), value: validationStatus)
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(colorScheme == .dark ?
                      Color(UIColor.secondarySystemGroupedBackground) :
                      Color.white)
                .shadow(
                    color: colorScheme == .dark ?
                        Color.clear :
                        Color.black.opacity(0.08),
                    radius: 12,
                    x: 0,
                    y: 4
                )
        )
    }
    
    // MARK: - Profile Section
    
    private var profileSection: some View {
        VStack(spacing: 20) {
            // Section Header
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 32, height: 32)
                    
                    Text("2")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Fan Profile")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("Tell us about yourself")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            // Form Fields
            VStack(spacing: 16) {
                modernTextField(
                    title: "Nickname",
                    placeholder: "Enter your fan nickname",
                    text: $nickname,
                    icon: "person.fill",
                    required: true
                )
                
                modernTextField(
                    title: "Location",
                    placeholder: "City, Country",
                    text: $location,
                    icon: "location.fill",
                    required: false
                )
                
                modernTextField(
                    title: "Favorite Song",
                    placeholder: "What's your favorite song?",
                    text: $favoriteSong,
                    icon: "music.note",
                    required: false
                )
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(colorScheme == .dark ?
                      Color(UIColor.secondarySystemGroupedBackground) :
                      Color.white)
                .shadow(
                    color: colorScheme == .dark ?
                        Color.clear :
                        Color.black.opacity(0.08),
                    radius: 12,
                    x: 0,
                    y: 4
                )
        )
    }
    
    // MARK: - Modern Text Field
    
    private func modernTextField(title: String, placeholder: String, text: Binding<String>, icon: String, required: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                if !required {
                    Text("Optional")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.secondary.opacity(0.1))
                        .clipShape(Capsule())
                }
                
                Spacer()
            }
            
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.blue)
                    .frame(width: 20, height: 20)
                
                TextField(placeholder, text: text)
                    .textFieldStyle(PlainTextFieldStyle())
                    .font(.body)
                    .fontWeight(.medium)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(UIColor.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                    )
            )
        }
    }
    
    // MARK: - Join Button
    
    private var joinButton: some View {
        Button(action: joinFanClub) {
            HStack(spacing: 12) {
                if isRegistering {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.9)
                } else {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 18, weight: .semibold))
                    Text("Join Fan Club")
                        .font(.headline)
                        .fontWeight(.bold)
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                Group {
                    if isFormValid {
                        LinearGradient(
                            gradient: Gradient(colors: [.purple, .blue]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    } else {
                        LinearGradient(
                            gradient: Gradient(colors: [.gray, .gray.opacity(0.8)]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(
                color: isFormValid ?
                    .purple.opacity(0.3) :
                    .clear,
                radius: 12,
                x: 0,
                y: 6
            )
            .scaleEffect(isFormValid ? 1.0 : 0.98)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(!isFormValid)
        .animation(.easeInOut(duration: 0.2), value: isFormValid)
        .animation(.easeInOut(duration: 0.2), value: isRegistering)
    }
    
    // MARK: - Helper Methods (остаются без изменений)
    
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
                            self.appState.refreshAuthState()
                            self.dismiss()
                            
                        case .failure(let error):
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
