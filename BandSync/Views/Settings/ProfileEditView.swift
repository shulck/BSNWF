//
//  ProfileEditView.swift
//  BandSync
//
//  Created by GitHub Copilot on 18.07.2025.
//

import SwiftUI
import PhotosUI

struct ProfileEditView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appState: AppState
    @StateObject private var userService = UserService.shared
    
    @State private var name: String
    @State private var phone: String
    @State private var selectedImage: UIImage?
    @State private var showingImagePicker = false
    @State private var showingDeleteConfirmation = false
    @State private var isUploading = false
    @State private var uploadProgress: Double = 0
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var showSuccess = false
    
    private let user: UserModel
    
    init(user: UserModel) {
        self.user = user
        self._name = State(initialValue: user.name)
        self._phone = State(initialValue: user.phone)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Avatar Section
                    avatarSection
                    
                    // Profile Form
                    profileForm
                    
                    // Delete Avatar Button
                    if user.avatarURL != nil {
                        deleteAvatarButton
                    }
                }
                .padding()
            }
            .navigationTitle("Edit Profile".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel".localized) {
                        dismiss()
                    }
                    .disabled(isUploading)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save".localized) {
                        saveProfile()
                    }
                    .disabled(isUploading || !hasChanges)
                }
            }
            .sheet(isPresented: $showingImagePicker) {
                ImagePickerView(selectedImage: $selectedImage)
            }
            .alert("Error".localized, isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorMessage ?? "Unknown error".localized)
            }
            .alert("Success".localized, isPresented: $showSuccess) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Profile updated successfully".localized)
            }
            .confirmationDialog("Delete Avatar".localized, isPresented: $showingDeleteConfirmation) {
                Button("Delete".localized, role: .destructive) {
                    deleteAvatar()
                }
                Button("Cancel".localized, role: .cancel) { }
            } message: {
                Text("Are you sure you want to delete your avatar?".localized)
            }
        }
    }
    
    // MARK: - Avatar Section
    
    private var avatarSection: some View {
        VStack(spacing: 16) {
            ZStack {
                // Current or new avatar
                if let selectedImage = selectedImage {
                    Image(uiImage: selectedImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 120, height: 120)
                        .clipShape(Circle())
                } else {
                    AvatarView(user: user, size: 120)
                }
                
                // Upload progress overlay
                if isUploading {
                    Circle()
                        .fill(Color.black.opacity(0.5))
                        .frame(width: 120, height: 120)
                    
                    VStack {
                        ProgressView(value: uploadProgress)
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.5)
                        
                        Text("\(Int(uploadProgress * 100))%")
                            .font(.caption)
                            .foregroundColor(.white)
                    }
                }
                
                // Camera button
                if !isUploading {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Button {
                                showingImagePicker = true
                            } label: {
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(width: 32, height: 32)
                                    .background(Color.blue)
                                    .clipShape(Circle())
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white, lineWidth: 2)
                                    )
                            }
                            .offset(x: -8, y: -8)
                        }
                    }
                }
            }
            
            Text("Tap the camera icon to change your avatar".localized)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    // MARK: - Profile Form
    
    private var profileForm: some View {
        VStack(spacing: 20) {
            // Name Field
            VStack(alignment: .leading, spacing: 8) {
                Text("Name".localized)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                TextField("Enter your name".localized, text: $name)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .disabled(isUploading)
            }
            
            // Phone Field
            VStack(alignment: .leading, spacing: 8) {
                Text("Phone".localized)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                TextField("Enter your phone number".localized, text: $phone)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.phonePad)
                    .disabled(isUploading)
            }
            
            // Email Field (Read-only)
            VStack(alignment: .leading, spacing: 8) {
                Text("Email".localized)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(user.email)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                    .foregroundColor(.secondary)
            }
            
            // Role Field (Read-only)
            VStack(alignment: .leading, spacing: 8) {
                Text("Role".localized)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                HStack {
                    RoleIndicatorView(role: user.role, size: 20)
                    Text(user.role.rawValue)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
            }
        }
    }
    
    // MARK: - Delete Avatar Button
    
    private var deleteAvatarButton: some View {
        Button {
            showingDeleteConfirmation = true
        } label: {
            HStack {
                Image(systemName: "trash")
                Text("Delete Avatar".localized)
            }
            .foregroundColor(.red)
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.red.opacity(0.1))
            .cornerRadius(12)
        }
        .disabled(isUploading)
    }
    
    // MARK: - Computed Properties
    
    private var hasChanges: Bool {
        name != user.name || 
        phone != user.phone || 
        selectedImage != nil
    }
    
    // MARK: - Actions
    
    private func saveProfile() {
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Name cannot be empty".localized
            showError = true
            return
        }
        
        isUploading = true
        uploadProgress = 0
        
        // If there's a new image, upload it first
        if let selectedImage = selectedImage {
            uploadProgress = 0.1
            AvatarService.shared.uploadUserAvatar(selectedImage, userId: user.id) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let avatarURL):
                        self.uploadProgress = 0.7
                        self.updateUserProfile(avatarURL: avatarURL)
                    case .failure(let error):
                        self.isUploading = false
                        self.errorMessage = error.localizedDescription
                        self.showError = true
                    }
                }
            }
        } else {
            updateUserProfile(avatarURL: user.avatarURL)
        }
    }
    
    private func updateUserProfile(avatarURL: String?) {
        uploadProgress = 0.8
        
        var updatedUser = user
        updatedUser.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        updatedUser.phone = phone.trimmingCharacters(in: .whitespacesAndNewlines)
        if let avatarURL = avatarURL {
            updatedUser.avatarURL = avatarURL
        }
        
        userService.updateUser(updatedUser) { success in
            DispatchQueue.main.async {
                self.uploadProgress = 1.0
                self.isUploading = false
                
                if success {
                    // Update current user in app state
                    self.appState.user = updatedUser
                    
                    // Update current user in user service
                    self.userService.currentUser = updatedUser
                    
                    // Update user in users array if it exists
                    if let index = self.userService.users.firstIndex(where: { $0.id == updatedUser.id }) {
                        self.userService.users[index] = updatedUser
                    }
                    
                    // Force refresh users to get latest data
                    self.userService.fetchUsers()
                    
                    // Clear avatar cache to force reload
                    AvatarService.shared.clearCachedAvatar(userId: updatedUser.id)
                    
                    self.showSuccess = true
                } else {
                    self.errorMessage = "Failed to update profile".localized
                    self.showError = true
                }
            }
        }
    }
    
    private func deleteAvatar() {
        isUploading = true
        
        AvatarService.shared.deleteUserAvatar(userId: user.id) { result in
            DispatchQueue.main.async {
                self.isUploading = false
                
                switch result {
                case .success:
                    // Update user model and app state
                    var updatedUser = self.user
                    updatedUser.avatarURL = nil
                    self.appState.user = updatedUser
                    
                    // Update current user in user service
                    self.userService.currentUser = updatedUser
                    
                    // Update user in users array if it exists
                    if let index = self.userService.users.firstIndex(where: { $0.id == updatedUser.id }) {
                        self.userService.users[index] = updatedUser
                    }
                    
                    // Update UI
                    self.selectedImage = nil
                    
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                    self.showError = true
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ProfileEditView(user: UserModel.mock)
        .environmentObject(AppState.shared)
}
