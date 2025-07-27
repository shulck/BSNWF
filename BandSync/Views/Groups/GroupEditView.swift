//
//  GroupEditView.swift
//  BandSync
//
//  Created by GitHub Copilot on 18.07.2025.
//

import SwiftUI

struct GroupEditView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var groupService = GroupService.shared
    
    @State private var name: String
    @State private var description: String
    @State private var selectedImage: UIImage?
    @State private var showingImagePicker = false
    @State private var showingDeleteConfirmation = false
    @State private var isUploading = false
    @State private var uploadProgress: Double = 0
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var showSuccess = false
    
    private let group: GroupModel
    
    init(group: GroupModel) {
        self.group = group
        self._name = State(initialValue: group.name)
        self._description = State(initialValue: group.description ?? "")
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Logo Section
                    logoSection
                    
                    // Group Form
                    groupForm
                    
                    // Delete Logo Button
                    if group.logoURL != nil {
                        deleteLogoButton
                    }
                }
                .padding()
            }
            .navigationTitle("Edit Group".localized)
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
                        saveGroup()
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
                Text("Group updated successfully".localized)
            }
            .confirmationDialog("Delete Logo".localized, isPresented: $showingDeleteConfirmation) {
                Button("Delete", role: .destructive) {
                    deleteLogo()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Are you sure you want to delete the group logo?".localized)
            }
        }
    }
    
    // MARK: - Logo Section
    
    private var logoSection: some View {
        VStack(spacing: 16) {
            ZStack {
                // Current or new logo
                if let selectedImage = selectedImage {
                    Image(uiImage: selectedImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 120, height: 120)
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                } else {
                    GroupAvatarView(group: group, size: 120)
                }
                
                // Upload progress overlay
                if isUploading {
                    RoundedRectangle(cornerRadius: 24)
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
            
            Text("Tap the camera icon to change the group logo".localized)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    // MARK: - Group Form
    
    private var groupForm: some View {
        VStack(spacing: 20) {
            // Name Field
            VStack(alignment: .leading, spacing: 8) {
                Text("Group Name".localized)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                TextField("Enter group name".localized, text: $name)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .disabled(isUploading)
            }
            
            // Description Field
            VStack(alignment: .leading, spacing: 8) {
                Text("Description".localized)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                TextEditor(text: $description)
                    .frame(minHeight: 80)
                    .padding(8)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                    .disabled(isUploading)
            }
            
            // Group Code Field (Read-only)
            VStack(alignment: .leading, spacing: 8) {
                Text("Group Code".localized)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                HStack {
                    Text(group.code)
                        .foregroundColor(.secondary)
                        .font(.monospaced(.body)())
                    
                    Spacer()
                    
                    Button {
                        UIPasteboard.general.string = group.code
                    } label: {
                        Image(systemName: "doc.on.doc")
                            .foregroundColor(.blue)
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
            }
            
            // Members Count (Read-only)
            VStack(alignment: .leading, spacing: 8) {
                Text("Members".localized)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                HStack {
                    Image(systemName: "person.3.fill")
                        .foregroundColor(.blue)
                    Text("\(group.members.count) members".localized)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
            }
        }
    }
    
    // MARK: - Delete Logo Button
    
    private var deleteLogoButton: some View {
        Button {
            showingDeleteConfirmation = true
        } label: {
            HStack {
                Image(systemName: "trash")
                Text("Delete Logo".localized)
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
        name != group.name || 
        description != (group.description ?? "") || 
        selectedImage != nil
    }
    
    // MARK: - Actions
    
    private func saveGroup() {
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Group name cannot be empty".localized
            showError = true
            return
        }
        
        guard let groupId = group.id else {
            errorMessage = "Group ID not found".localized
            showError = true
            return
        }
        
        isUploading = true
        uploadProgress = 0
        
        // If there's a new image, upload it first
        if let selectedImage = selectedImage {
            uploadProgress = 0.1
            AvatarService.shared.uploadGroupLogo(selectedImage, groupId: groupId) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let logoURL):
                        self.uploadProgress = 0.7
                        self.updateGroupInfo(logoURL: logoURL)
                    case .failure(let error):
                        self.isUploading = false
                        self.errorMessage = error.localizedDescription
                        self.showError = true
                    }
                }
            }
        } else {
            updateGroupInfo(logoURL: group.logoURL)
        }
    }
    
    private func updateGroupInfo(logoURL: String?) {
        uploadProgress = 0.8
        
        var updatedGroup = group
        updatedGroup.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        updatedGroup.description = description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : description.trimmingCharacters(in: .whitespacesAndNewlines)
        if let logoURL = logoURL {
            updatedGroup.logoURL = logoURL
        }
        
        groupService.updateGroup(updatedGroup) { success in
            DispatchQueue.main.async {
                self.uploadProgress = 1.0
                self.isUploading = false
                
                if success {
                    self.showSuccess = true
                } else {
                    self.errorMessage = "Failed to update group".localized
                    self.showError = true
                }
            }
        }
    }
    
    private func deleteLogo() {
        guard let groupId = group.id else {
            errorMessage = "Group ID not found".localized
            showError = true
            return
        }
        
        isUploading = true
        
        AvatarService.shared.deleteGroupLogo(groupId: groupId) { result in
            DispatchQueue.main.async {
                self.isUploading = false
                
                switch result {
                case .success:
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
    GroupEditView(group: GroupModel(
        name: "Test Group",
        code: "TEST123",
        members: ["user1", "user2", "user3"],
        pendingMembers: [],
        description: "This is a test group"
    ))
}
