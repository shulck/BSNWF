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
                            
                            Text("Loading permissions...".localized)
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
                                    Text("Retry Loading".localized)
                                        .font(.body)
                                        .fontWeight(.medium)
                                        .foregroundColor(.primary)
                                    
                                    Text("Try to load permissions again".localized)
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
                            
                            Text("Here you can configure which roles have access to different application modules.".localized)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                        }
                        .padding(.vertical, 4)
                    } header: {
                        Text("Access Management".localized)
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
                        Text("Module Permissions".localized)
                    }
                    
                    // Reset Settings Section
                    Section {
                        Button {
                            showResetConfirmation = true
                        } label: {
                            HStack {
                                permissionsIcon(icon: "arrow.counterclockwise", color: .red)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Reset to Default".localized)
                                        .font(.body)
                                        .fontWeight(.medium)
                                        .foregroundColor(.red)
                                    
                                    Text("Restore default permission settings".localized)
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
                                
                                Text("Updating permissions...".localized)
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
        .navigationTitle("Permissions".localized)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showModuleEditor) {
            if let module = selectedModule {
                ModulePermissionEditorView(module: module)
            }
        }
        .alert("Reset permissions?".localized, isPresented: $showResetConfirmation) {
            Button("Cancel".localized, role: .cancel) {}
            Button("Reset".localized, role: .destructive) {
                permissionService.resetToDefaults()
            }
        } message: {
            Text("This action will reset all permission settings to default values. Are you sure?".localized)
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
            return "No access configured".localized
        }
        
        return roles.map { getLocalizedRoleName(for: $0) }.joined(separator: ", ")
    }
    
    private func getLocalizedRoleName(for role: UserModel.UserRole) -> String {
        switch role {
        case .admin: return "Admin".localized
        case .manager: return "Manager".localized
        case .musician: return "Musician".localized
        case .member: return "Member".localized
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
