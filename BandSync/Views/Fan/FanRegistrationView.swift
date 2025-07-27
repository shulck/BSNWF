//
//  FanRegistrationView.swift
//  BandSyncApp
//
//  Created by Oleksandr Kuziakin on 28.07.2025.
//


//
//  FanRegistrationView.swift
//  BandSync
//
//  Created by Claude on 27.07.2025.
//

import SwiftUI

struct FanRegistrationView: View {
    @StateObject private var viewModel = FanRegistrationViewModel()
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        colorScheme == .dark ? Color(red: 0.1, green: 0.05, blue: 0.2) : Color(red: 0.98, green: 0.95, blue: 1.0),
                        colorScheme == .dark ? Color(red: 0.2, green: 0.1, blue: 0.3) : Color(red: 0.95, green: 0.9, blue: 1.0)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 30) {
                        // Header
                        VStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [Color.purple, Color.pink]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 80, height: 80)
                                    .shadow(color: .purple.opacity(0.3), radius: 15, x: 0, y: 8)
                                
                                Image(systemName: "heart.fill")
                                    .font(.system(size: 35, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            
                            VStack(spacing: 8) {
                                Text("Join as a Fan!")
                                    .font(.system(size: 28, weight: .bold, design: .rounded))
                                    .foregroundColor(.primary)
                                
                                Text("Connect with your favorite band")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                        }
                        .padding(.top, 20)
                        
                        // Form Section
                        VStack(spacing: 24) {
                            // Invite Code Input
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image(systemName: "key.fill")
                                        .foregroundColor(.purple)
                                    Text("Band Invite Code")
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                }
                                
                                TextField("Enter invite code (e.g., BAND1234)", text: $viewModel.inviteCode)
                                    .textFieldStyle(CustomTextFieldStyle())
                                    .autocapitalization(.allCharacters)
                                    .disableAutocorrection(true)
                                    .onChange(of: viewModel.inviteCode) { _, newValue in
                                        viewModel.inviteCode = newValue.uppercased()
                                    }
                                
                                if let validationResult = viewModel.codeValidationResult {
                                    HStack {
                                        Image(systemName: validationResult.isValid ? "checkmark.circle.fill" : "xmark.circle.fill")
                                            .foregroundColor(validationResult.isValid ? .green : .red)
                                        Text(validationResult.message)
                                            .font(.caption)
                                            .foregroundColor(validationResult.isValid ? .green : .red)
                                    }
                                    .padding(.top, 4)
                                }
                            }
                            
                            // Fan Profile Section
                            if viewModel.codeValidationResult?.isValid == true {
                                VStack(alignment: .leading, spacing: 20) {
                                    HStack {
                                        Image(systemName: "person.fill")
                                            .foregroundColor(.purple)
                                        Text("Your Fan Profile")
                                            .font(.headline)
                                            .foregroundColor(.primary)
                                    }
                                    
                                    VStack(spacing: 16) {
                                        // Nickname
                                        VStack(alignment: .leading, spacing: 8) {
                                            Text("Nickname")
                                                .font(.subheadline)
                                                .fontWeight(.medium)
                                                .foregroundColor(.primary)
                                            
                                            TextField("Your fan nickname", text: $viewModel.nickname)
                                                .textFieldStyle(CustomTextFieldStyle())
                                        }
                                        
                                        // Location
                                        VStack(alignment: .leading, spacing: 8) {
                                            Text("Location")
                                                .font(.subheadline)
                                                .fontWeight(.medium)
                                                .foregroundColor(.primary)
                                            
                                            TextField("City, Country", text: $viewModel.location)
                                                .textFieldStyle(CustomTextFieldStyle())
                                        }
                                        
                                        // Favorite Song
                                        VStack(alignment: .leading, spacing: 8) {
                                            Text("Favorite Song")
                                                .font(.subheadline)
                                                .fontWeight(.medium)
                                                .foregroundColor(.primary)
                                            
                                            TextField("Your favorite song by the band", text: $viewModel.favoriteSong)
                                                .textFieldStyle(CustomTextFieldStyle())
                                        }
                                    }
                                }
                                .transition(.move(edge: .top).combined(with: .opacity))
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // Join Button
                        if viewModel.canJoin {
                            Button(action: {
                                viewModel.joinFanClub()
                            }) {
                                HStack {
                                    if viewModel.isLoading {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    } else {
                                        Image(systemName: "heart.fill")
                                            .font(.system(size: 16, weight: .semibold))
                                    }
                                    
                                    Text(viewModel.isLoading ? "Joining..." : "Join Fan Club")
                                        .font(.system(size: 18, weight: .semibold))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color.purple, Color.pink]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(16)
                                .shadow(color: .purple.opacity(0.3), radius: 10, x: 0, y: 5)
                            }
                            .disabled(viewModel.isLoading)
                            .padding(.horizontal, 20)
                            .transition(.scale.combined(with: .opacity))
                        }
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.vertical)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.purple)
                }
            }
            .alert("Error", isPresented: $viewModel.showingError) {
                Button("OK") {}
            } message: {
                Text(viewModel.errorMessage)
            }
            .alert("Success!", isPresented: $viewModel.showingSuccess) {
                Button("Continue") {
                    dismiss()
                    // Navigate to fan interface
                    AppState.shared.refreshAuthState()
                }
            } message: {
                Text("Welcome to the fan club! 🎉")
            }
            .onReceive(viewModel.$inviteCode.debounce(for: .milliseconds(500), scheduler: RunLoop.main)) { code in
                if !code.isEmpty && code.count >= 4 {
                    viewModel.validateInviteCode()
                }
            }
        }
    }
}

// MARK: - Custom Text Field Style
struct CustomTextFieldStyle: TextFieldStyle {
    @Environment(\.colorScheme) private var colorScheme
    
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(colorScheme == .dark ? Color(.systemGray6) : Color.white)
                    .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.purple.opacity(0.2), lineWidth: 1)
            )
    }
}

// MARK: - Fan Registration ViewModel
@MainActor
final class FanRegistrationViewModel: ObservableObject {
    @Published var inviteCode = ""
    @Published var nickname = ""
    @Published var location = ""
    @Published var favoriteSong = ""
    @Published var isLoading = false
    @Published var showingError = false
    @Published var showingSuccess = false
    @Published var errorMessage = ""
    @Published var codeValidationResult: CodeValidationResult?
    
    private let fanInviteService = FanInviteService.shared
    
    struct CodeValidationResult {
        let isValid: Bool
        let message: String
        let groupName: String?
    }
    
    var canJoin: Bool {
        guard let validation = codeValidationResult, validation.isValid else { return false }
        return !nickname.isEmpty && !location.isEmpty && !favoriteSong.isEmpty && !isLoading
    }
    
    func validateInviteCode() {
        guard !inviteCode.isEmpty else {
            codeValidationResult = nil
            return
        }
        
        fanInviteService.validateFanInviteCode(inviteCode) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let inviteCodeData):
                    self?.codeValidationResult = CodeValidationResult(
                        isValid: true,
                        message: "✓ Valid code for \(inviteCodeData.groupName)",
                        groupName: inviteCodeData.groupName
                    )
                case .failure(let error):
                    self?.codeValidationResult = CodeValidationResult(
                        isValid: false,
                        message: error.localizedDescription,
                        groupName: nil
                    )
                }
            }
        }
    }
    
    func joinFanClub() {
        guard canJoin else { return }
        
        isLoading = true
        
        // First validate the code again to get the latest data
        fanInviteService.validateFanInviteCode(inviteCode) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let inviteCodeData):
                // Create fan profile
                let fanProfile = FanProfile(
                    nickname: self.nickname,
                    location: self.location,
                    favoriteSong: self.favoriteSong
                )
                
                // Join the fan club
                self.fanInviteService.joinFanClub(inviteCode: inviteCodeData, fanProfile: fanProfile) { joinResult in
                    DispatchQueue.main.async {
                        self.isLoading = false
                        
                        switch joinResult {
                        case .success:
                            self.showingSuccess = true
                        case .failure(let error):
                            self.errorMessage = error.localizedDescription
                            self.showingError = true
                        }
                    }
                }
                
            case .failure(let error):
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.errorMessage = error.localizedDescription
                    self.showingError = true
                }
            }
        }
    }
}

// MARK: - Preview
struct FanRegistrationView_Previews: PreviewProvider {
    static var previews: some View {
        FanRegistrationView()
    }
}