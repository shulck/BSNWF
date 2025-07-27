import SwiftUI
import FirebaseFirestore

struct RoleView: View {
    let userId: String
    let currentRole: UserModel.UserRole
    @State private var selectedRole: UserModel.UserRole
    @State private var isLoading = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @Environment(\.dismiss) var dismiss

    init(userId: String, currentRole: UserModel.UserRole) {
        self.userId = userId
        self.currentRole = currentRole
        self._selectedRole = State(initialValue: currentRole)
    }

    var body: some View {
        NavigationView {
            List {
                // Role Selection Section
                Section {
                    HStack(spacing: 12) {
                        roleIcon(icon: "person.crop.rectangle.stack.fill", color: .blue)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Select Role".localized)
                                .font(.body)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                            
                            Text("Choose the appropriate role for this user".localized)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Role Assignment".localized)
                }
                
                // Current Role Info
                if currentRole != selectedRole {
                    Section {
                        HStack(spacing: 12) {
                            roleIcon(icon: "info.circle.fill", color: .orange)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("\("Current role:".localized) \(getLocalizedRoleName(for: currentRole))")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                Text("\("Will change to:".localized) \(getLocalizedRoleName(for: selectedRole))")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.blue)
                            }
                            
                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }
                }
                
                // Available Roles Section
                Section {
                    ForEach(UserModel.UserRole.allCases, id: \.self) { role in
                        Button {
                            selectedRole = role
                        } label: {
                            HStack(spacing: 12) {
                                roleIcon(icon: getRoleIcon(for: role), color: getRoleColor(for: role))
                                
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
                                
                                if selectedRole == role {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.title3)
                                        .foregroundColor(.blue)
                                } else if currentRole == role {
                                    Image(systemName: "circle.fill")
                                        .font(.title3)
                                        .foregroundColor(.gray.opacity(0.3))
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
                    Text("Available Roles".localized)
                }
                
                // Loading Section
                if isLoading {
                    Section {
                        HStack(spacing: 12) {
                            ProgressView()
                                .scaleEffect(0.8)
                            
                            Text("Updating role...".localized)
                                .font(.body)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
            .navigationTitle("Change Role".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel".localized) {
                        dismiss()
                    }
                    .disabled(isLoading)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save".localized) {
                        changeRole()
                    }
                    .disabled(isLoading || selectedRole == currentRole)
                }
            }
        }            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("Role Update".localized),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK".localized)) {
                    if alertMessage.contains("successfully") {
                        dismiss()
                    }
                }
            )
        }
    }

    // MARK: - Helper Views
    
    private func roleIcon(icon: String, color: Color) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6)
                .fill(color)
                .frame(width: 28, height: 28)
            
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
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
        case .admin: return "Admin".localized
        case .manager: return "Manager".localized
        case .musician: return "Musician".localized
        case .member: return "Member".localized
        }
    }
    
    private func getRoleDescription(for role: UserModel.UserRole) -> String {
        switch role {
        case .admin: return "Full access to all features and settings".localized
        case .manager: return "Management and coordination responsibilities".localized
        case .musician: return "Band member with musical performance role".localized
        case .member: return "Basic band member with limited access".localized
        }
    }
    
    // MARK: - Functions

    private func changeRole() {
        guard !userId.isEmpty && userId != "temp" else {
            alertMessage = "Invalid user ID".localized
            showAlert = true
            return
        }
        
        isLoading = true
        
        Firestore.firestore().collection("users").document(userId).updateData([
            "role": selectedRole.rawValue
        ]) { [self] error in
            DispatchQueue.main.async {
                isLoading = false
                
                if let error = error {
                    alertMessage = String(format: "Error updating role".localized, error.localizedDescription)
                } else {
                    alertMessage = String(format: "Role updated successfully".localized, getLocalizedRoleName(for: selectedRole))
                    
                    UserService.shared.fetchUsers()
                }
                
                showAlert = true
            }
        }
    }
}
