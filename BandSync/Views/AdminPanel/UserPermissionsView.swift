import SwiftUI

struct PersonalPermissionsEditorView: View {
    let userId: String
    let userName: String
    @StateObject private var permissionService = PermissionService.shared
    @Environment(\.dismiss) var dismiss
    @State private var selectedModules: Set<ModuleType> = []
    @State private var isLoading = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            List {
                // User Info Section
                Section {
                    HStack(spacing: 12) {
                        editorIcon(icon: "person.crop.rectangle.stack.fill", color: .blue)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Personal Permissions".localized)
                                .font(.body)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                            
                            Text("\("Additional access for".localized) \(userName)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("User Access".localized)
                }
                
                // Description Section
                Section {
                    HStack(spacing: 12) {
                        editorIcon(icon: "info.circle.fill", color: .blue)
                        
                        Text("\("Personal permissions grant additional access beyond the user's role. Select modules that".localized) \(userName) \("should have access to.".localized)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
                
                // Available Modules Section
                Section {
                    ForEach(ModuleType.allCases.filter { $0 != .admin }, id: \.self) { module in
                        Button {
                            toggleModule(module)
                        } label: {
                            HStack(spacing: 12) {
                                editorIcon(icon: module.icon, color: getModuleColor(for: module))
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(module.displayName)
                                        .font(.body)
                                        .fontWeight(.medium)
                                        .foregroundColor(.primary)
                                    
                                    Text("Grant personal access".localized)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                if selectedModules.contains(module) {
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
                    Text("\("Available Modules".localized) (\(selectedModules.count) \("selected".localized))")
                }
                
                // Loading Section
                if isLoading {
                    Section {
                        HStack(spacing: 12) {
                            ProgressView()
                                .scaleEffect(0.8)
                            
                            Text("Saving permissions...".localized)
                                .font(.body)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
            .navigationTitle("Personal Access".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel".localized) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save".localized) {
                        savePermissions()
                    }
                    .disabled(isLoading)
                }
            }
            .onAppear {
                loadCurrentPermissions()
            }
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("Personal Permissions".localized),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK".localized)) {
                        if alertMessage.contains("successfully") {
                            dismiss()
                        }
                    }
                )
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
    
    // MARK: - Functions
    
    private func loadCurrentPermissions() {
        let currentModules = permissionService.getPersonalAccessModules(userId: userId)
        selectedModules = Set(currentModules)
    }
    
    private func toggleModule(_ module: ModuleType) {
        if selectedModules.contains(module) {
            selectedModules.remove(module)
        } else {
            selectedModules.insert(module)
        }
    }
    
    private func savePermissions() {
        isLoading = true
        
        permissionService.updateUserPermissions(
            userId: userId,
            modules: Array(selectedModules)
        )
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            isLoading = false
            alertMessage = "\("Personal permissions updated successfully for".localized) \(userName)"
            showAlert = true
        }
    }
}
