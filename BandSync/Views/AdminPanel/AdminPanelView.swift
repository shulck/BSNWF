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
            Section(header: Text(NSLocalizedString("Band Management", comment: ""))) {
                NavigationLink {
                    GroupSettingsView()
                } label: {
                    adminRow(
                        title: NSLocalizedString("Group Settings", comment: ""),
                        subtitle: NSLocalizedString("Configure band information", comment: ""),
                        icon: "gearshape.fill",
                        color: .blue
                    )
                }
                
                NavigationLink {
                    UsersListView()
                } label: {
                    adminRow(
                        title: NSLocalizedString("Group Members", comment: ""),
                        subtitle: NSLocalizedString("Manage band members", comment: ""),
                        icon: "person.3.fill",
                        color: .green
                    )
                }
                
                NavigationLink {
                    PermissionsView()
                } label: {
                    adminRow(
                        title: NSLocalizedString("Permissions", comment: ""),
                        subtitle: NSLocalizedString("Control access rights", comment: ""),
                        icon: "lock.shield.fill",
                        color: .orange
                    )
                }
                
                NavigationLink {
                    ModuleManagementView()
                } label: {
                    adminRow(
                        title: NSLocalizedString("Module Management", comment: ""),
                        subtitle: NSLocalizedString("Configure available features", comment: ""),
                        icon: "square.grid.2x2.fill",
                        color: .purple
                    )
                }
            }
            
            // Fan Club Management Section
            Section(header: Text("Fan Club")) {
                NavigationLink {
                    FanManagementView()
                } label: {
                    adminRow(
                        title: "Fan Management",
                        subtitle: "Manage your fan club and invite codes",
                        icon: "heart.fill",
                        color: .purple
                    )
                }
                
                NavigationLink {
                    FanStatisticsView()
                } label: {
                    adminRow(
                        title: "Fan Analytics",
                        subtitle: "View fan engagement and statistics",
                        icon: "chart.bar.fill",
                        color: .pink
                    )
                }
            }
            
            // Group Information Section
            if let group = groupService.group {
                Section(header: Text(NSLocalizedString("Group Information", comment: ""))) {
                    HStack(spacing: 12) {
                        adminIcon(icon: "info.circle.fill", color: .blue)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(group.name)
                                .font(.body)
                                .fontWeight(.medium)
                            
                            Text("Group Code: \(group.code)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Button {
                            UIPasteboard.general.string = group.code
                            alertMessage = NSLocalizedString("Code copied to clipboard", comment: "")
                            showAlert = true
                        } label: {
                            Text(NSLocalizedString("Copy", comment: ""))
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.blue)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            
            // Additional Tools Section
            Section(header: Text(NSLocalizedString("Additional Tools", comment: ""))) {
                Button {
                    alertMessage = NSLocalizedString("Data export will be implemented in the next update", comment: "")
                    showAlert = true
                } label: {
                    adminRow(
                        title: NSLocalizedString("Export Group Data", comment: ""),
                        subtitle: NSLocalizedString("Download band information", comment: ""),
                        icon: "square.and.arrow.up.fill",
                        color: .indigo
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .navigationTitle(NSLocalizedString("Admin Panel", comment: ""))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if let groupId = AppState.shared.user?.groupId {
                groupService.fetchGroup(by: groupId)
            }
        }
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text(NSLocalizedString("Information", comment: "")),
                message: Text(alertMessage),
                dismissButton: .default(Text(NSLocalizedString("OK", comment: "")))
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

// MARK: - FanStatisticsView (заглушка)
struct FanStatisticsView: View {
    var body: some View {
        List {
            Section {
                VStack(spacing: 20) {
                    Image(systemName: "chart.bar.xaxis")
                        .font(.system(size: 60))
                        .foregroundColor(.purple)
                    
                    Text("Fan Analytics Coming Soon!")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Here you'll see detailed analytics about your fan club engagement, growth trends, and fan activity.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            }
        }
        .navigationTitle("Fan Analytics")
        .navigationBarTitleDisplayMode(.inline)
    }
}
