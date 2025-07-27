import SwiftUI

struct UsersListView: View {
    @StateObject private var groupService = GroupService.shared
    @StateObject private var permissionService = PermissionService.shared
    
    var body: some View {
        List {
            // Loading Section
            if groupService.isLoading {
                Section {
                    HStack(spacing: 12) {
                        ProgressView()
                            .scaleEffect(0.8)
                        
                        Text("Loading members...".localized)
                            .font(.body)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }
            } else {
                // Group Members Section
                if !groupService.groupMembers.isEmpty {
                    Section {
                        ForEach(groupService.groupMembers) { user in
                            UserRowView(
                                user: user,
                                permissionService: permissionService,
                                groupService: groupService
                            )
                        }
                    } header: {
                        Text("\("Group Members".localized) (\(groupService.groupMembers.count))")
                    }
                }
                
                // Pending Approvals Section
                if !groupService.pendingMembers.isEmpty {
                    Section {
                        ForEach(groupService.pendingMembers) { user in
                            HStack(spacing: 12) {
                                usersIcon(icon: "person.badge.clock.fill", color: .orange)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(user.name)
                                        .font(.body)
                                        .fontWeight(.medium)
                                        .foregroundColor(.primary)
                                    
                                    Text(user.email)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                // Accept/reject buttons
                                Button {
                                    groupService.approveUser(userId: user.id)
                                } label: {
                                    Text("Accept".localized)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(.green)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(
                                            RoundedRectangle(cornerRadius: 6)
                                                .fill(Color.green.opacity(0.1))
                                        )
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                Button {
                                    groupService.rejectUser(userId: user.id)
                                } label: {
                                    Text("Decline".localized)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(.red)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(
                                            RoundedRectangle(cornerRadius: 6)
                                                .fill(Color.red.opacity(0.1))
                                        )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            .padding(.vertical, 4)
                        }
                    } header: {
                        Text("\("Awaiting Approval".localized) (\(groupService.pendingMembers.count))")
                    }
                }
                
                // Invitation Code Section
                if let group = groupService.group {
                    Section {
                        HStack(spacing: 12) {
                            usersIcon(icon: "qrcode", color: .purple)
                            
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
                            groupService.regenerateCode()
                        } label: {
                            HStack {
                                usersIcon(icon: "arrow.clockwise", color: .orange)
                                
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
            }
            
            // Error Section
            if let error = groupService.errorMessage {
                Section {
                    HStack(spacing: 12) {
                        usersIcon(icon: "exclamationmark.triangle.fill", color: .red)
                        
                        Text(error)
                            .font(.body)
                            .foregroundColor(.red)
                        
                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("Group Members".localized)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if let gid = AppState.shared.user?.groupId {
                groupService.fetchGroup(by: gid)
                permissionService.fetchPermissions(for: gid)
            }
        }
        .refreshable {
            if let gid = AppState.shared.user?.groupId {
                groupService.fetchGroup(by: gid)
            }
        }
    }
    
    // MARK: - Helper Views
    
    private func usersIcon(icon: String, color: Color, size: CGFloat = 28) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6)
                .fill(color)
                .frame(width: size, height: size)
            
            Image(systemName: icon)
                .font(.system(size: size * 0.5, weight: .medium))
                .foregroundColor(.white)
        }
    }
}

// MARK: - User Row Component

struct UserRowView: View {
    let user: UserModel
    let permissionService: PermissionService
    let groupService: GroupService
    
    @State private var showingRoleView = false
    @State private var showingPersonalAccessView = false
    
    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                userIcon(role: user.role)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(user.name)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text(user.email)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("\("Role:".localized) \(getLocalizedRoleName(for: user.role))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Action buttons
                if user.id != AppState.shared.user?.id {
                    Menu {
                        Button("Change role".localized) {
                            showingRoleView = true
                        }
                        
                        Button("Personal access".localized) {
                            showingPersonalAccessView = true
                        }
                        
                        Button("Remove from group".localized, role: .destructive) {
                            groupService.removeUser(userId: user.id)
                        }
                    } label: {
                        usersIcon(icon: "ellipsis.circle.fill", color: .gray)
                    }
                }
            }
            
            // Personal Access Information
            if permissionService.hasAnyPersonalAccess(userId: user.id) {
                Button {
                    showingPersonalAccessView = true
                } label: {
                    HStack(spacing: 8) {
                        usersIcon(icon: "key.fill", color: .blue, size: 20)
                        
                        let modules = permissionService.getPersonalAccessModules(userId: user.id)
                        Text("\("Personal access".localized) (\(modules.count) \("modules".localized))")
                            .font(.caption)
                            .foregroundColor(.blue)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.blue.opacity(0.1))
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.vertical, 4)
        .sheet(isPresented: $showingRoleView) {
            RoleView(userId: user.id, currentRole: user.role)
        }
        .sheet(isPresented: $showingPersonalAccessView) {
            PersonalPermissionsEditorView(userId: user.id, userName: user.name)
        }
    }
    
    private func userIcon(role: UserModel.UserRole) -> some View {
        let (icon, color) = getUserRoleIconAndColor(for: role)
        return usersIcon(icon: icon, color: color)
    }
    
    private func getLocalizedRoleName(for role: UserModel.UserRole) -> String {
        switch role {
        case .admin: return "Admin".localized
        case .manager: return "Manager".localized
        case .musician: return "Musician".localized
        case .member: return "Member".localized
        }
    }
    
    private func getUserRoleIconAndColor(for role: UserModel.UserRole) -> (String, Color) {
        switch role {
        case .admin: return ("crown.fill", .red)
        case .manager: return ("person.badge.key.fill", .orange)
        case .musician: return ("music.note", .blue)
        case .member: return ("person.fill", .gray)
        }
    }
    
    private func usersIcon(icon: String, color: Color, size: CGFloat = 28) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6)
                .fill(color)
                .frame(width: size, height: size)
            
            Image(systemName: icon)
                .font(.system(size: size * 0.5, weight: .medium))
                .foregroundColor(.white)
        }
    }
}
