import SwiftUI

struct ModuleManagementView: View {
    @StateObject private var permissionService = PermissionService.shared
    @State private var modules = ModuleType.allCases
    @State private var enabledModules: Set<ModuleType> = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var successMessage: String?
    
    var body: some View {
        List {
            // Description Section
            Section {
                HStack(spacing: 12) {
                    moduleIcon(icon: "info.circle.fill", color: .blue)
                    
                    Text(NSLocalizedString("Enable or disable modules that will be available to group members.", comment: ""))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
                .padding(.vertical, 4)
            } header: {
                Text(NSLocalizedString("Module Management", comment: ""))
            }
            
            // Available Modules Section
            Section {
                ForEach(modules) { module in
                    HStack(spacing: 12) {
                        moduleIcon(icon: module.icon, color: getModuleColor(for: module))
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(module.displayName)
                                .font(.body)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                            
                            if module == .admin {
                                Text(NSLocalizedString("Always enabled for admins", comment: ""))
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            } else {
                                Text(NSLocalizedString("Toggle module availability", comment: ""))
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                        
                        if module == .admin {
                            Text(NSLocalizedString("Required", comment: ""))
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(Color.gray.opacity(0.1))
                                )
                        } else {
                            Toggle("", isOn: Binding(
                                get: { enabledModules.contains(module) },
                                set: { newValue in
                                    if newValue {
                                        enabledModules.insert(module)
                                    } else {
                                        enabledModules.remove(module)
                                    }
                                }
                            ))
                        }
                    }
                    .padding(.vertical, 4)
                }
            } header: {
                Text(NSLocalizedString("Available Modules", comment: ""))
            }
            
            // Save Changes Section
            Section {
                Button {
                    saveChanges()
                } label: {
                    HStack {
                        moduleIcon(icon: "checkmark.circle.fill", color: .green)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(NSLocalizedString("Save Changes", comment: ""))
                                .font(.body)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                            
                            Text(NSLocalizedString("Apply module settings", comment: ""))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(isLoading)
                .opacity(isLoading ? 0.5 : 1.0)
            }
            
            // Success Message Section
            if let success = successMessage {
                Section {
                    HStack(spacing: 12) {
                        moduleIcon(icon: "checkmark.circle.fill", color: .green)
                        
                        Text(success)
                            .font(.body)
                            .foregroundColor(.green)
                        
                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
            }
            
            // Error Message Section
            if let error = errorMessage {
                Section {
                    HStack(spacing: 12) {
                        moduleIcon(icon: "exclamationmark.triangle.fill", color: .red)
                        
                        Text(error)
                            .font(.body)
                            .foregroundColor(.red)
                        
                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
            }
            
            // Loading Section
            if isLoading {
                Section {
                    HStack(spacing: 12) {
                        ProgressView()
                            .scaleEffect(0.8)
                        
                        Text(NSLocalizedString("Updating module settings...", comment: ""))
                            .font(.body)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }
            }
        }
        .navigationTitle(NSLocalizedString("Module Management", comment: ""))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadModuleSettings()
        }
    }
    
    // MARK: - Helper Views
    
    private func moduleIcon(icon: String, color: Color) -> some View {
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
    
    private func loadModuleSettings() {
        isLoading = true
        successMessage = nil
        errorMessage = nil
        
        if let groupId = AppState.shared.user?.groupId {
            permissionService.fetchPermissions(for: groupId)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                enabledModules = Set(permissionService.permissions?.modules
                    .filter { !$0.roleAccess.isEmpty }
                    .map { $0.moduleId } ?? [])
                
                enabledModules.insert(.admin)
                
                isLoading = false
            }
        } else {
            isLoading = false
            errorMessage = NSLocalizedString("Could not determine group", comment: "")
        }
    }
    
    private func saveChanges() {
        guard (permissionService.permissions?.id) != nil else {
            errorMessage = NSLocalizedString("Could not find permission settings", comment: "")
            return
        }
        
        isLoading = true
        successMessage = nil
        errorMessage = nil
        
        for module in modules where module != .admin {
            if enabledModules.contains(module) {
                switch module {
                case .finances:
                    permissionService.updateModulePermission(
                        moduleId: module,
                        roles: [.admin]
                    )
                case .merchandise:
                    permissionService.updateModulePermission(
                        moduleId: module,
                        roles: [.admin, .manager]
                    )
                case .contacts:
                    permissionService.updateModulePermission(
                        moduleId: module,
                        roles: [.admin]
                    )
                case .documents:
                    permissionService.updateModulePermission(
                        moduleId: module,
                        roles: [.admin, .manager, .musician]
                    )
                case .calendar, .chats:
                    permissionService.updateModulePermission(
                        moduleId: module,
                        roles: [.admin, .manager, .musician, .member]
                    )
                case .setlists, .tasks:
                    permissionService.updateModulePermission(
                        moduleId: module,
                        roles: [.admin, .manager, .musician]
                    )
                default:
                    break
                }
            } else {
                permissionService.updateModulePermission(
                    moduleId: module,
                    roles: []
                )
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            isLoading = false
            successMessage = NSLocalizedString("Module settings successfully updated", comment: "")
        }
    }
}
