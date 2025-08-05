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
                    Text(NSLocalizedString("Account Information", comment: "Section header for account information"))
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
                Text(NSLocalizedString("Security", comment: "Section header for security options"))
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
                Text(NSLocalizedString("Account Actions", comment: "Section header for account actions"))
            } footer: {
                Text(NSLocalizedString("Deleting your account will permanently remove all your data and cannot be undone.", comment: "Warning about account deletion"))
            }
            
            if isLoading {
                Section {
                    HStack(spacing: 12) {
                        ProgressView()
                            .scaleEffect(0.8)
                        
                        Text(NSLocalizedString("Processing...", comment: "Loading indicator text"))
                            .font(.body)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }
            }
        }
        .navigationTitle(NSLocalizedString("Account", comment: "Navigation title for account settings"))
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showChangePassword) {
            ChangePasswordView()
        }
        .sheet(isPresented: $showProfileEdit) {
            if let user = appState.user {
                ProfileEditView(user: user)
            }
        }
        .alert(NSLocalizedString("Sign Out", comment: "Alert title for sign out confirmation"), isPresented: $showLogoutConfirmation) {
            Button(NSLocalizedString("Cancel", comment: "Cancel button"), role: .cancel) { }
            Button(NSLocalizedString("Sign Out", comment: "Sign out button"), role: .destructive) {
                signOut()
            }
        } message: {
            Text(NSLocalizedString("Are you sure you want to sign out?", comment: "Sign out confirmation message"))
        }
        .alert(NSLocalizedString("Delete Account", comment: "Alert title for delete account confirmation"), isPresented: $showDeleteAccount) {
            Button(NSLocalizedString("Cancel", comment: "Cancel button"), role: .cancel) { }
            Button(NSLocalizedString("Delete", comment: "Delete button"), role: .destructive) {
                deleteAccount()
            }
        } message: {
            Text(NSLocalizedString("This action cannot be undone. All your data will be permanently deleted.", comment: "Delete account warning message"))
        }
        .alert(NSLocalizedString("Error", comment: "Error alert title"), isPresented: $showErrorAlert) {
            Button(NSLocalizedString("OK", comment: "OK button"), role: .cancel) { }
        } message: {
            Text(errorMessage ?? "An unknown error occurred")
        }
    }
    
    private func accountRow(title: String, subtitle: String, icon: String, color: Color) -> some View {
        HStack(spacing: 12) {
            accountIcon(icon: icon, color: color)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(NSLocalizedString(title, comment: "Account row title"))
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text(NSLocalizedString(subtitle, comment: "Account row subtitle"))
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
                SecureField(NSLocalizedString("Current Password", comment: "Placeholder for current password field"), text: $currentPassword)
                    .textContentType(.password)
            } header: {
                Text(NSLocalizedString("Current Password", comment: "Section header for current password"))
            }
            
            Section {
                SecureField(NSLocalizedString("New Password", comment: "Placeholder for new password field"), text: $newPassword)
                    .textContentType(.newPassword)
                
                SecureField(NSLocalizedString("Confirm New Password", comment: "Placeholder for confirm password field"), text: $confirmPassword)
                    .textContentType(.newPassword)
            } header: {
                Text(NSLocalizedString("New Password", comment: "Section header for new password"))
            } footer: {
                Text(NSLocalizedString("Password must be at least 6 characters long", comment: "Password requirements footer"))
            }
            
            if isLoading {
                Section {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text(NSLocalizedString("Updating password...", comment: "Loading text for password update"))
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .navigationTitle(NSLocalizedString("Change Password", comment: "Navigation title for change password screen"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(NSLocalizedString("Cancel", comment: "Cancel button")) {
                    dismiss()
                }
            }
            
            ToolbarItem(placement: .confirmationAction) {
                Button(NSLocalizedString("Update", comment: "Update password button")) {
                    updatePassword()
                }
                .disabled(!isValidInput || isLoading)
            }
        }
        .alert(NSLocalizedString("Error", comment: "Error alert title"), isPresented: $showErrorAlert) {
            Button(NSLocalizedString("OK", comment: "OK button"), role: .cancel) { }
        } message: {
            Text(errorMessage ?? "An unknown error occurred")
        }
        .alert(NSLocalizedString("Success", comment: "Success alert title"), isPresented: $showSuccessAlert) {
            Button(NSLocalizedString("OK", comment: "OK button")) {
                dismiss()
            }
        } message: {
            Text(NSLocalizedString("Your password has been updated successfully", comment: "Password update success message"))
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
