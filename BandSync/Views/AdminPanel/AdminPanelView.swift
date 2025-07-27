//
//  AdminPanelView.swift
//  BandSync
//
//  Created by Oleksandr Kuziakin on 31.03.2025.
//

import SwiftUI

struct AdminPanelView: View {
    @StateObject private var groupService = GroupService.shared
    @State private var showAlert = false
    @State private var alertMessage = ""
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        List {
            // Group Management Section
            Section {
                NavigationLink {
                    GroupSettingsView()
                } label: {
                    adminRow(
                        title: "Group Settings".localized,
                        subtitle: "Configure band information".localized,
                        icon: "gearshape.fill",
                        color: .blue
                    )
                }
                
                NavigationLink {
                    UsersListView()
                } label: {
                    adminRow(
                        title: "Group Members".localized,
                        subtitle: "Manage band members".localized,
                        icon: "person.3.fill",
                        color: .green
                    )
                }
                
                NavigationLink {
                    PermissionsView()
                } label: {
                    adminRow(
                        title: "Permissions".localized,
                        subtitle: "Control access rights".localized,
                        icon: "lock.shield.fill",
                        color: .orange
                    )
                }
                
                NavigationLink {
                    ModuleManagementView()
                } label: {
                    adminRow(
                        title: "App Modules".localized,
                        subtitle: "Enable/disable features".localized,
                        icon: "square.grid.2x2.fill",
                        color: .purple
                    )
                }
            } header: {
                Text("Group Management".localized)
            }
            
            // Group Info Section
            Section {
                if let group = groupService.group {
                    HStack {
                        adminIcon(icon: "music.mic", color: .pink)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Group Name".localized)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Text(group.name)
                                .font(.body)
                                .fontWeight(.medium)
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, 4)
                    
                    HStack {
                        adminIcon(icon: "qrcode", color: .cyan)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Invitation Code".localized)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Text(group.code)
                                .font(.body)
                                .fontWeight(.medium)
                        }
                        
                        Spacer()
                        
                        Button {
                            UIPasteboard.general.string = group.code
                            alertMessage = "Code copied to clipboard".localized
                            showAlert = true
                        } label: {
                            Text("Copy".localized)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.blue)
                        }
                    }
                    .padding(.vertical, 4)
                }
            } header: {
                Text("Group Information".localized)
            }
            
            // Additional Tools Section
            Section {
                Button {
                    alertMessage = "Data export will be implemented in the next update".localized
                    showAlert = true
                } label: {
                    adminRow(
                        title: "Export Group Data".localized,
                        subtitle: "Download band information".localized,
                        icon: "square.and.arrow.up.fill",
                        color: .indigo
                    )
                }
                .buttonStyle(PlainButtonStyle())
            } header: {
                Text("Additional Tools".localized)
            }
        }
        .navigationTitle("Admin Panel".localized)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if let groupId = AppState.shared.user?.groupId {
                groupService.fetchGroup(by: groupId)
            }
        }
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("Information".localized),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK".localized))
            )
        }
        .refreshable {
            if let groupId = AppState.shared.user?.groupId {
                groupService.fetchGroup(by: groupId)
            }
        }
    }
    
    // MARK: - Helper Views
    
    private func adminRow(title: String, subtitle: String, icon: String, color: Color) -> some View {
        HStack(spacing: 12) {
            adminIcon(icon: icon, color: color)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
    
    private func adminIcon(icon: String, color: Color) -> some View {
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
