import SwiftUI

struct PermissionsView: View {
    @ObservedObject private var permissionService = PermissionService.shared
    @State private var selectedModule: ModuleType?
    @State private var showModuleEditor = false
    @State private var showResetConfirmation = false
    @State private var hasAppeared = false
    @State private var forceShowContent = false
    
    var body: some View {
        Group {
            if (permissionService.permissions == nil && (permissionService.isLoading || !hasAppeared)) && !forceShowContent {
                // Show loading screen when permissions are being loaded or haven't appeared yet
                List {
                    Section {
                        HStack(spacing: 12) {
                            ProgressView()
                                .scaleEffect(0.8)
                            
                            Text(NSLocalizedString("Loading permissions...", comment: ""))
                                .font(.body)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                        }
                        .padding(.vertical, 8)
                        
                        Button {
                            loadPermissions()
                        } label: {
                            HStack {
                                permissionsIcon(icon: "arrow.clockwise", color: .blue)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(NSLocalizedString("Retry Loading", comment: ""))
                                        .font(.body)
                                        .fontWeight(.medium)
                                        .foregroundColor(.primary)
                                    
                                    Text(NSLocalizedString("Try to load permissions again", comment: ""))
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                            }
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .onAppear {
                    if !hasAppeared {
                        hasAppeared = true
                        loadPermissions()
                        
                        // Force show content after 3 seconds if still loading
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                            if permissionService.permissions == nil {
                                forceShowContent = true
                            }
                        }
                    }
                }
            } else {
                // Show the list when permissions are loaded
                List {
                    // Information Section
                    Section {
                        HStack(spacing: 12) {
                            permissionsIcon(icon: "info.circle.fill", color: .blue)
                            
                            Text(NSLocalizedString("Here you can configure which roles have access to different application modules.", comment: ""))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                        }
                        .padding(.vertical, 4)
                    } header: {
                        Text(NSLocalizedString("Access Management", comment: ""))
                    }
                    
                    // Modules Section
                    Section {
                        ForEach(getVisibleModules()) { module in
                            Button {
                                selectedModule = module
                                showModuleEditor = true
                            } label: {
                                HStack(spacing: 12) {
                                    permissionsIcon(icon: module.icon, color: getModuleColor(for: module))
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(module.displayName)
                                            .font(.body)
                                            .fontWeight(.medium)
                                            .foregroundColor(.primary)
                                        
                                        Text(accessRolesText(for: module))
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                }
                                .padding(.vertical, 4)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    } header: {
                        Text(NSLocalizedString("Module Permissions", comment: ""))
                    }
                    
                    // Reset Settings Section
                    Section {
                        Button {
                            showResetConfirmation = true
                        } label: {
                            HStack {
                                permissionsIcon(icon: "arrow.counterclockwise", color: .red)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(NSLocalizedString("Reset to Default", comment: ""))
                                        .font(.body)
                                        .fontWeight(.medium)
                                        .foregroundColor(.red)
                                    
                                    Text(NSLocalizedString("Restore default permission settings", comment: ""))
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                            }
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    // Loading Section
                    if permissionService.isLoading {
                        Section {
                            HStack(spacing: 12) {
                                ProgressView()
                                    .scaleEffect(0.8)
                                
                                Text(NSLocalizedString("Updating permissions...", comment: ""))
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                            }
                            .padding(.vertical, 8)
                        }
                    }
                    
                    // Error Message Section
                    if let error = permissionService.errorMessage {
                        Section {
                            HStack(spacing: 12) {
                                permissionsIcon(icon: "exclamationmark.triangle.fill", color: .red)
                                
                                Text(error)
                                    .font(.body)
                                    .foregroundColor(.red)
                                
                                Spacer()
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
        }
        .navigationTitle(NSLocalizedString("Permissions", comment: ""))
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showModuleEditor) {
            if let module = selectedModule {
                ModulePermissionEditorView(module: module)
            }
        }
        .alert(NSLocalizedString("Reset permissions?", comment: ""), isPresented: $showResetConfirmation) {
            Button(NSLocalizedString("Cancel", comment: ""), role: .cancel) {}
            Button(NSLocalizedString("Reset", comment: ""), role: .destructive) {
                permissionService.resetToDefaults()
            }
        } message: {
            Text(NSLocalizedString("This action will reset all permission settings to default values. Are you sure?", comment: ""))
        }
        .onAppear {
            if !hasAppeared {
                hasAppeared = true
                loadPermissions()
            }
        }
    }
    
    // MARK: - Helper Views
    
    private func permissionsIcon(icon: String, color: Color) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6)
                .fill(color)
                .frame(width: 28, height: 28)
            
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
        }
    }
    
    private func getModuleColor(for module: ModuleType) -> Color {
        switch module {
        case .admin: return .red
        case .calendar: return .blue
        case .setlists: return .purple
        case .tasks: return .orange
        case .finances: return .mint
        case .merchandise: return .brown
        case .contacts: return .teal
        case .documents: return .indigo
        case .chats: return .green
        }
    }
    
    // MARK: - Functions
    
    private func loadPermissions() {
        guard let groupId = AppState.shared.user?.groupId else {
            return
        }
        
        permissionService.fetchPermissions(for: groupId)
    }
    
    private func accessRolesText(for module: ModuleType) -> String {
        let roles = permissionService.getRolesWithAccess(to: module)
        
        if roles.isEmpty {
            return NSLocalizedString("No access configured", comment: "")
        }
        
        return roles.map { getLocalizedRoleName(for: $0) }.joined(separator: ", ")
    }
    
    private func getLocalizedRoleName(for role: UserModel.UserRole) -> String {
        switch role {
        case .admin: return NSLocalizedString("Admin", comment: "")
        case .manager: return NSLocalizedString("Manager", comment: "")
        case .musician: return NSLocalizedString("Musician", comment: "")
        case .member: return NSLocalizedString("Member", comment: "")
        }
    }
    
    private func getVisibleModules() -> [ModuleType] {
        guard let currentUserRole = AppState.shared.user?.role else {
            return []
        }
        
        switch currentUserRole {
        case .admin:
            return ModuleType.allCases
        case .manager:
            return [.calendar, .setlists, .tasks, .documents]
        case .musician, .member:
            return [.calendar, .setlists, .tasks]
        }
    }
}
