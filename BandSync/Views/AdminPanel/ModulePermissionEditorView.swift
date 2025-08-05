import SwiftUI

struct ModulePermissionEditorView: View {
    let module: ModuleType
    @ObservedObject private var permissionService = PermissionService.shared
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedRoles: Set<UserModel.UserRole> = []
    
    var body: some View {
        NavigationStack {
            List {
                // Module Information Section
                Section {
                    HStack(spacing: 12) {
                        editorIcon(icon: module.icon, color: getModuleColor(for: module))
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(module.displayName)
                                .font(.body)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                            
                            Text(NSLocalizedString("Configure access permissions", comment: ""))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text(NSLocalizedString("Module Access", comment: ""))
                }
                
                // Description Section
                Section {
                    HStack(spacing: 12) {
                        editorIcon(icon: "info.circle.fill", color: .blue)
                        
                        Text(String(format: NSLocalizedString("Select roles that will have access to the '%@' module", comment: ""), module.displayName))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
                
                // Roles Section
                Section {
                    ForEach(UserModel.UserRole.allCases, id: \.self) { role in
                        Button {
                            toggleRole(role)
                        } label: {
                            HStack(spacing: 12) {
                                editorIcon(icon: getRoleIcon(for: role), color: getRoleColor(for: role))
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(getLocalizedRoleName(for: role))
                                        .font(.body)
                                        .fontWeight(.medium)
                                        .foregroundColor(.primary)
                                    
                                    Text(getRoleDescription(for: role))
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                if selectedRoles.contains(role) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.title3)
                                        .foregroundColor(.blue)
                                } else {
                                    Image(systemName: "circle")
                                        .font(.title3)
                                        .foregroundColor(.gray.opacity(0.4))
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                } header: {
                    Text(NSLocalizedString("User Roles", comment: ""))
                }
                
                // Loading Section
                if permissionService.isLoading {
                    Section {
                        HStack(spacing: 12) {
                            ProgressView()
                                .scaleEffect(0.8)
                            
                            Text(NSLocalizedString("Saving permissions...", comment: ""))
                                .font(.body)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
            .navigationTitle(module.displayName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(NSLocalizedString("Cancel", comment: "")) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button(NSLocalizedString("Save", comment: "")) {
                        savePermissions()
                    }
                    .disabled(permissionService.isLoading)
                }
            }
            .onAppear {
                loadRoles()
            }
        }
    }
    
    // MARK: - Helper Views
    
    private func editorIcon(icon: String, color: Color) -> some View {
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
    
    private func getRoleIcon(for role: UserModel.UserRole) -> String {
        switch role {
        case .admin: return "crown.fill"
        case .manager: return "person.badge.key.fill"
        case .musician: return "music.note"
        case .member: return "person.fill"
        }
    }
    
    private func getRoleColor(for role: UserModel.UserRole) -> Color {
        switch role {
        case .admin: return .red
        case .manager: return .orange
        case .musician: return .blue
        case .member: return .gray
        }
    }
    
    private func getLocalizedRoleName(for role: UserModel.UserRole) -> String {
        switch role {
        case .admin: return NSLocalizedString("Admin", comment: "")
        case .manager: return NSLocalizedString("Manager", comment: "")
        case .musician: return NSLocalizedString("Musician", comment: "")
        case .member: return NSLocalizedString("Member", comment: "")
        }
    }
    
    private func getRoleDescription(for role: UserModel.UserRole) -> String {
        switch role {
        case .admin: return NSLocalizedString("Full access to all features", comment: "")
        case .manager: return NSLocalizedString("Management and coordination", comment: "")
        case .musician: return NSLocalizedString("Band member with musical role", comment: "")
        case .member: return NSLocalizedString("Basic band member", comment: "")
        }
    }
    
    // MARK: - Functions
    
    private func loadRoles() {
        let currentRoles = permissionService.getRolesWithAccess(to: module)
        selectedRoles = Set(currentRoles)
    }
    
    private func toggleRole(_ role: UserModel.UserRole) {
        if selectedRoles.contains(role) {
            selectedRoles.remove(role)
        } else {
            selectedRoles.insert(role)
        }
    }
    
    private func savePermissions() {
        permissionService.updateModulePermission(
            moduleId: module,
            roles: Array(selectedRoles)
        )
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            permissionService.refreshPermissions()
        }
        
        dismiss()
    }
}
