//
//  GroupSettingsView.swift
//  BandSync
//
//  Created by Oleksandr Kuziakin on 31.03.2025.
//

import SwiftUI

struct GroupSettingsView: View {
    @StateObject private var groupService = GroupService.shared
    @State private var newName = ""
    @State private var paypalAddress = ""
    @State private var showConfirmation = false
    @State private var showSuccessAlert = false
    
    var body: some View {
        List {
            // Group Name Section
            Section {
                // Group Logo
                if let group = groupService.group {
                    NavigationLink(destination: GroupEditView(group: group)) {
                        HStack(spacing: 12) {
                            settingsIcon(icon: "photo.fill", color: .pink)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Group Logo".localized)
                                    .font(.body)
                                    .fontWeight(.medium)
                                    .foregroundColor(.primary)
                                
                                Text("Set or change group logo".localized)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            // Show current logo or placeholder
                            if let logoURL = group.logoURL {
                                AsyncImage(url: URL(string: logoURL)) { image in
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                } placeholder: {
                                    Image(systemName: "photo")
                                        .foregroundColor(.gray)
                                }
                                .frame(width: 40, height: 40)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            } else {
                                Image(systemName: "photo")
                                    .foregroundColor(.gray)
                                    .frame(width: 40, height: 40)
                                    .background(Color.gray.opacity(0.1))
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                
                HStack(spacing: 12) {
                    settingsIcon(icon: "music.mic", color: .blue)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Group Name".localized)
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        
                        TextField("Enter group name".localized, text: $newName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.words)
                    }
                    
                    Spacer()
                }
                .padding(.vertical, 4)
                
                Button {
                    groupService.updateGroupName(newName)
                    showSuccessAlert = true
                } label: {
                    HStack {
                        settingsIcon(icon: "checkmark.circle.fill", color: .green)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Update Name".localized)
                                .font(.body)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                            
                            Text("Save the new group name".localized)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(newName.isEmpty || groupService.isLoading)
                .opacity(newName.isEmpty || groupService.isLoading ? 0.5 : 1.0)
            } header: {
                Text("Group Information".localized)
            }
            
            // PayPal Settings Section
            Section {
                HStack(spacing: 12) {
                    settingsIcon(icon: "creditcard.fill", color: .blue)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("PayPal Address for Gifts".localized)
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        
                        TextField("Enter PayPal email address".localized, text: $paypalAddress)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                    }
                    
                    Spacer()
                }
                .padding(.vertical, 4)
                
                Button {
                    groupService.updatePayPalAddress(paypalAddress)
                    showSuccessAlert = true
                } label: {
                    HStack {
                        settingsIcon(icon: "checkmark.circle.fill", color: .green)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Save PayPal Address".localized)
                                .font(.body)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                            
                            Text("Save PayPal address for birthday gifts".localized)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(paypalAddress.isEmpty || groupService.isLoading)
                .opacity(paypalAddress.isEmpty || groupService.isLoading ? 0.5 : 1.0)
            } header: {
                Text("Gift Settings".localized)
            }
            
            // Invitation Code Section
            if let group = groupService.group {
                Section {
                    HStack(spacing: 12) {
                        settingsIcon(icon: "qrcode", color: .purple)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Invitation Code".localized)
                                .font(.body)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                            
                            Text(group.code)
                                .font(.system(.title3, design: .monospaced))
                                .fontWeight(.bold)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Button {
                            UIPasteboard.general.string = group.code
                        } label: {
                            Text("Copy".localized)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.purple)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(Color.purple.opacity(0.1))
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.vertical, 4)
                    
                    Button {
                        showConfirmation = true
                    } label: {
                        HStack {
                            settingsIcon(icon: "arrow.clockwise", color: .orange)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Generate New Code".localized)
                                    .font(.body)
                                    .fontWeight(.medium)
                                    .foregroundColor(.primary)
                                
                                Text("Create a new invitation code".localized)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(PlainButtonStyle())
                } header: {
                    Text("Invitation".localized)
                }
            }
            
            // Group Members Section
            Section {
                NavigationLink(destination: UsersListView()) {
                    HStack(spacing: 12) {
                        settingsIcon(icon: "person.3.fill", color: .green)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Manage Members".localized)
                                .font(.body)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                            
                            Text("View and manage group members".localized)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Text("\(groupService.groupMembers.count)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.green.opacity(0.1))
                            )
                    }
                    .padding(.vertical, 4)
                }
            } header: {
                Text("Members".localized)
            }
            
            // Available Modules Section
            Section {
                HStack(spacing: 12) {
                    settingsIcon(icon: "square.grid.2x2.fill", color: .gray)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Module Management".localized)
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        
                        Text("Module management will be available in the next update.".localized)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                .padding(.vertical, 4)
            } header: {
                Text("Available Modules".localized)
            }
            
            // Error Messages Section
            if let error = groupService.errorMessage {
                Section {
                    HStack(spacing: 12) {
                        settingsIcon(icon: "exclamationmark.triangle.fill", color: .red)
                        
                        Text(error)
                            .font(.body)
                            .foregroundColor(.red)
                        
                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
            }
            
            // Loading Section
            if groupService.isLoading {
                Section {
                    HStack(spacing: 12) {
                        ProgressView()
                            .scaleEffect(0.8)
                        
                        Text("Loading...".localized)
                            .font(.body)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }
            }
        }
        .navigationTitle("Group Settings".localized)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if let gid = AppState.shared.user?.groupId {
                groupService.fetchGroup(by: gid)
                newName = groupService.group?.name ?? ""
                paypalAddress = groupService.group?.paypalAddress ?? ""
            }
        }
        // Using onChange API
        .onChange(of: groupService.group) {
            if let name = groupService.group?.name {
                newName = name
            }
            paypalAddress = groupService.group?.paypalAddress ?? ""
        }
        .alert("Generate new code?".localized, isPresented: $showConfirmation) {
            Button("Cancel".localized, role: .cancel) {}
            Button("Generate".localized) {
                groupService.regenerateCode()
                showSuccessAlert = true
            }
        } message: {
            Text("The old code will no longer be valid. All members who haven't joined yet will need to use the new code.".localized)
        }
        .alert("Success".localized, isPresented: $showSuccessAlert) {
            Button("OK".localized, role: .cancel) {}
        } message: {
            Text("Changes saved successfully.".localized)
        }
    }
    
    // MARK: - Helper Views
    
    private func settingsIcon(icon: String, color: Color) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6)
                .fill(color)
                .frame(width: 28, height: 28)
            
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
        }
    }
}
