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
                        
                        Text(NSLocalizedString("Loading members...", comment: ""))
                            .font(.body)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }
            } else {
                // ✅ ДОБАВЛЕНО: Сообщение когда нет участников
                if groupService.groupMembers.isEmpty && groupService.pendingMembers.isEmpty && !groupService.isLoading {
                    Section {
                        VStack(spacing: 12) {
                            Image(systemName: "person.3.fill")
                                .font(.largeTitle)
                                .foregroundColor(.secondary)
                            
                            Text(NSLocalizedString("No Members Found", comment: ""))
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Text(NSLocalizedString("This group has no members yet. Check your network connection or try refreshing.", comment: ""))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                            
                            Button(NSLocalizedString("Refresh", comment: "")) {
                                if let gid = AppState.shared.user?.groupId {
                                    groupService.fetchGroup(by: gid)
                                }
                            }
                            .buttonStyle(.bordered)
                        }
                        .padding(.vertical, 20)
                        .frame(maxWidth: .infinity)
                    }
                }
                
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
                        Text(String(format: NSLocalizedString("%@ (%d)", comment: ""), NSLocalizedString("Group Members", comment: ""), groupService.groupMembers.count))
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
                                    groupService.approveUser(user.id) { success in
                                        // Handle success/failure silently or show user feedback if needed
                                    }
                                } label: {
                                    Text(NSLocalizedString("Accept", comment: ""))
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
                                    groupService.rejectUser(user.id) { success in
                                        // Handle success/failure silently or show user feedback if needed
                                    }
                                } label: {
                                    Text(NSLocalizedString("Decline", comment: ""))
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
                        Text(String(format: NSLocalizedString("%@ (%d)", comment: ""), NSLocalizedString("Awaiting Approval", comment: ""), groupService.pendingMembers.count))
                    }
                }
                
                // Invitation Code Section
                if let group = groupService.group {
                    Section {
                        HStack(spacing: 12) {
                            usersIcon(icon: "qrcode", color: .purple)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(NSLocalizedString("Invitation Code", comment: ""))
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
                                Text(NSLocalizedString("Copy", comment: ""))
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
                                    Text(NSLocalizedString("Generate New Code", comment: ""))
                                        .font(.body)
                                        .fontWeight(.medium)
                                        .foregroundColor(.primary)
                                    
                                    Text(NSLocalizedString("Create a new invitation code", comment: ""))
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                            }
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(PlainButtonStyle())
                    } header: {
                        Text(NSLocalizedString("Invitation", comment: ""))
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
        .navigationTitle(NSLocalizedString("Group Members", comment: ""))
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
                    
                    Text(String(format: NSLocalizedString("Role: %@", comment: ""), getLocalizedRoleName(for: user.role)))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Action buttons
                if user.id != AppState.shared.user?.id {
                    Menu {
                        Button(NSLocalizedString("Change role", comment: "")) {
                            showingRoleView = true
                        }
                        
                        Button(NSLocalizedString("Personal access", comment: "")) {
                            showingPersonalAccessView = true
                        }
                        
                        Button(NSLocalizedString("Remove from group", comment: ""), role: .destructive) {
                            groupService.removeUser(user.id) { success in
                                // Handle success/failure silently or show user feedback if needed
                            }
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
                        Text(String(format: NSLocalizedString("%@ (%d %@)", comment: ""), NSLocalizedString("Personal access", comment: ""), modules.count, NSLocalizedString("modules", comment: "")))
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
        case .admin: return NSLocalizedString("Admin", comment: "")
        case .manager: return NSLocalizedString("Manager", comment: "")
        case .musician: return NSLocalizedString("Musician", comment: "")
        case .member: return NSLocalizedString("Member", comment: "")
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

