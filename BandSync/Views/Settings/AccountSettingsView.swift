//
//  AccountSettingsView.swift
//  BandSync
//
//  Created by Developer on 23.06.2025.
//

import SwiftUI
import FirebaseAuth

struct AccountSettingsView: View {
    @EnvironmentObject private var appState: AppState
    
    @State private var showChangePassword = false
    @State private var showDeleteAccount = false
    @State private var showLogoutConfirmation = false
    @State private var showProfileEdit = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showErrorAlert = false
    
    var body: some View {
        List {
            if let user = appState.user {
                Section {
                    HStack(spacing: 12) {
                        AvatarView(user: user, size: 50)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(user.name)
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            Text(user.email)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Text(user.role.rawValue)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.blue.opacity(0.1))
                                .foregroundColor(.blue)
                                .clipShape(Capsule())
                        }
                        
                        Spacer()
                        
                        Button {
                            showProfileEdit = true
                        } label: {
                            Image(systemName: "pencil")
                                .foregroundColor(.blue)
                                .font(.title2)
                        }
                    }
                    .padding(.vertical, 8)
                } header: {
                    Text("Account Information".localized)
                }
            }
            
            Section {
                Button {
                    showChangePassword = true
                } label: {
                    accountRow(
                        title: "Change Password",
                        subtitle: "Update your account password",
                        icon: "key.fill",
                        color: .orange
                    )
                }
                .buttonStyle(PlainButtonStyle())
            } header: {
                Text("Security".localized)
            }
            
            Section {
                Button {
                    showLogoutConfirmation = true
                } label: {
                    accountRow(
                        title: "Sign Out",
                        subtitle: "Sign out of your account",
                        icon: "rectangle.portrait.and.arrow.right",
                        color: .blue
                    )
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(isLoading)
                
                Button {
                    showDeleteAccount = true
                } label: {
                    accountRow(
                        title: "Delete Account",
                        subtitle: "Permanently delete your account and data",
                        icon: "trash.fill",
                        color: .red
                    )
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(isLoading)
            } header: {
                Text("Account Actions".localized)
            } footer: {
                Text("Deleting your account will permanently remove all your data and cannot be undone.".localized)
            }
            
            if isLoading {
                Section {
                    HStack(spacing: 12) {
                        ProgressView()
                            .scaleEffect(0.8)
                        
                        Text("Processing...".localized)
                            .font(.body)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }
            }
        }
        .navigationTitle("Account".localized)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showChangePassword) {
            ChangePasswordView()
        }
        .sheet(isPresented: $showProfileEdit) {
            if let user = appState.user {
                ProfileEditView(user: user)
            }
        }
        .alert("Sign Out".localized, isPresented: $showLogoutConfirmation) {
            Button("Cancel".localized, role: .cancel) { }
            Button("Sign Out".localized, role: .destructive) {
                signOut()
            }
        } message: {
            Text("Are you sure you want to sign out?".localized)
        }
        .alert("Delete Account".localized, isPresented: $showDeleteAccount) {
            Button("Cancel".localized, role: .cancel) { }
            Button("Delete".localized, role: .destructive) {
                deleteAccount()
            }
        } message: {
            Text("This action cannot be undone. All your data will be permanently deleted.".localized)
        }
        .alert("Error".localized, isPresented: $showErrorAlert) {
            Button("OK".localized, role: .cancel) { }
        } message: {
            Text(errorMessage ?? "An unknown error occurred")
        }
    }
    
    private func accountRow(title: String, subtitle: String, icon: String, color: Color) -> some View {
        HStack(spacing: 12) {
            accountIcon(icon: icon, color: color)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title.localized)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text(subtitle.localized)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
    
    private func accountIcon(icon: String, color: Color) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6)
                .fill(color)
                .frame(width: 28, height: 28)
            
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
        }
    }
    
    private func signOut() {
        isLoading = true
        appState.logout()
        isLoading = false
    }
    
    private func deleteAccount() {
        isLoading = true
        
        guard let currentUser = Auth.auth().currentUser else {
            errorMessage = "No authenticated user found"
            showErrorAlert = true
            isLoading = false
            return
        }
        
        currentUser.delete { [self] error in
            DispatchQueue.main.async {
                isLoading = false
                
                if let error = error {
                    errorMessage = error.localizedDescription
                    showErrorAlert = true
                } else {
                    appState.logout()
                }
            }
        }
    }
}

struct ChangePasswordView: View {
    @Environment(\.dismiss) var dismiss
    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showErrorAlert = false
    @State private var showSuccessAlert = false
    
    var body: some View {
        Form {
            Section {
                SecureField("Current Password".localized, text: $currentPassword)
                    .textContentType(.password)
            } header: {
                Text("Current Password".localized)
            }
            
            Section {
                SecureField("New Password".localized, text: $newPassword)
                    .textContentType(.newPassword)
                
                SecureField("Confirm New Password".localized, text: $confirmPassword)
                    .textContentType(.newPassword)
            } header: {
                Text("New Password".localized)
            } footer: {
                Text("Password must be at least 6 characters long".localized)
            }
            
            if isLoading {
                Section {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Updating password...".localized)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .navigationTitle("Change Password".localized)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel".localized) {
                    dismiss()
                }
            }
            
            ToolbarItem(placement: .confirmationAction) {
                Button("Update".localized) {
                    updatePassword()
                }
                .disabled(!isValidInput || isLoading)
            }
        }
        .alert("Error".localized, isPresented: $showErrorAlert) {
            Button("OK".localized, role: .cancel) { }
        } message: {
            Text(errorMessage ?? "An unknown error occurred")
        }
        .alert("Success".localized, isPresented: $showSuccessAlert) {
            Button("OK".localized) {
                dismiss()
            }
        } message: {
            Text("Your password has been updated successfully".localized)
        }
    }
    
    private var isValidInput: Bool {
        !currentPassword.isEmpty &&
        !newPassword.isEmpty &&
        newPassword.count >= 6 &&
        newPassword == confirmPassword
    }
    
    private func updatePassword() {
        isLoading = true
        
        guard let user = Auth.auth().currentUser,
              let email = user.email else {
            errorMessage = "User not found"
            showErrorAlert = true
            isLoading = false
            return
        }
        
        let credential = EmailAuthProvider.credential(withEmail: email, password: currentPassword)
        
        user.reauthenticate(with: credential) { result, error in
            if let error = error {
                DispatchQueue.main.async {
                    errorMessage = error.localizedDescription
                    showErrorAlert = true
                    isLoading = false
                }
                return
            }
            
            user.updatePassword(to: newPassword) { error in
                DispatchQueue.main.async {
                    isLoading = false
                    
                    if let error = error {
                        errorMessage = error.localizedDescription
                        showErrorAlert = true
                    } else {
                        showSuccessAlert = true
                    }
                }
            }
        }
    }
}
