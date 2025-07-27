//
//  PermissionService.swift
//  BandSync
//
//  Created by Oleksandr Kuziakin on 31.03.2025.
//

import Foundation
import FirebaseFirestore
import Combine

final class PermissionService: ObservableObject {
    static let shared = PermissionService()
    
    @Published var permissions: PermissionModel?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let db = Firestore.firestore()
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Automatic permission check when user changes
        AppState.shared.$user
            .removeDuplicates()
            .sink { [weak self] user in
                if let groupId = user?.groupId {
                    self?.fetchPermissions(for: groupId)
                } else {
                    self?.permissions = nil
                }
            }
            .store(in: &cancellables)
    }
    
    // Get permissions for group
    func fetchPermissions(for groupId: String) {
        isLoading = true
        
        db.collection("permissions")
            .whereField("groupId", isEqualTo: groupId)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    self.isLoading = false
                    
                    if let error = error {
                        self.errorMessage = "Error loading permissions: \(error.localizedDescription)"
                        return
                    }
                    
                    if let document = snapshot?.documents.first,
                       let permissionData = try? document.data(as: PermissionModel.self) {
                        self.permissions = permissionData
                        self.objectWillChange.send()
                    } else {
                        // If no permissions found, create default
                        self.createDefaultPermissions(for: groupId)
                    }
                }
            }
    }
    
    // Create default permissions for new group
    func createDefaultPermissions(for groupId: String) {
        isLoading = true
        
        // Default permissions for all modules with CORRECT roles
        let defaultModules: [PermissionModel.ModulePermission] = ModuleType.allCases.map { moduleType in
            let roles: [UserModel.UserRole]
            
            switch moduleType {
            case .admin:
                // Группа 1: Только админы
                roles = [.admin]
                
            case .finances:
                // ❌ ИСПРАВЛЕНО: Только админы (было: admin + manager)
                roles = [.admin]
                
            case .merchandise:
                // ✅ Админы + Менеджеры
                roles = [.admin, .manager]
                
            case .contacts:
                // ✅ Только админы
                roles = [.admin]
                
            case .documents:
                // ✅ Админы + Менеджеры + Музыканты
                roles = [.admin, .manager, .musician]
                
            case .calendar, .chats:
                // ✅ Все роли
                roles = [.admin, .manager, .musician, .member]
                
            case .setlists, .tasks:
                // ✅ Админы + Менеджеры + Музыканты
                // Примечание: Ограничения для Musician (только чтение в setlists)
                // обрабатываются в функциях write/delete permission
                roles = [.admin, .manager, .musician]
            }
            
            return PermissionModel.ModulePermission(moduleId: moduleType, roleAccess: roles)
        }
        
        let newPermissions = PermissionModel(
            groupId: groupId,
            modules: defaultModules,
            userPermissions: [] // Initialize with empty array
        )
        
        do {
            _ = try db.collection("permissions").addDocument(from: newPermissions) { [weak self] error in
                guard let self = self else { return }
                
                self.isLoading = false
                
                if let error = error {
                    self.errorMessage = "Error creating permissions: \(error.localizedDescription)"
                } else {
                    // Load created permissions
                    self.fetchPermissions(for: groupId)
                }
            }
        } catch {
            isLoading = false
            errorMessage = "Error serializing permission data: \(error.localizedDescription)"
        }
    }
    
    // Update module permissions
    func updateModulePermission(moduleId: ModuleType, roles: [UserModel.UserRole]) {
        guard let permissionId = permissions?.id else {
            return
        }
        
        isLoading = true
        
        // Find existing module to update or add new one
        if var modules = permissions?.modules {
            if let index = modules.firstIndex(where: { $0.moduleId == moduleId }) {
                // Update existing module
                modules[index] = PermissionModel.ModulePermission(moduleId: moduleId, roleAccess: roles)
            } else {
                // Add new module if it doesn't exist
                modules.append(PermissionModel.ModulePermission(moduleId: moduleId, roleAccess: roles))
            }
            
            db.collection("permissions").document(permissionId).updateData([
                "modules": modules.map { [
                    "moduleId": $0.moduleId.rawValue,
                    "roleAccess": $0.roleAccess.map { $0.rawValue }
                ]}
            ]) { [weak self] error in
                guard let self = self else { return }
                
                self.isLoading = false
                
                if let error = error {
                    self.errorMessage = "Error updating permissions: \(error.localizedDescription)"
                } else {
                    // Update local data and refresh
                    DispatchQueue.main.async {
                        self.permissions?.modules = modules
                        // Force a refresh to ensure UI updates
                        self.objectWillChange.send()
                    }
                }
            }
        } else {
            // If no modules array exists, create one with this module
            let newModules = [PermissionModel.ModulePermission(moduleId: moduleId, roleAccess: roles)]
            
            db.collection("permissions").document(permissionId).updateData([
                "modules": newModules.map { [
                    "moduleId": $0.moduleId.rawValue,
                    "roleAccess": $0.roleAccess.map { $0.rawValue }
                ]}
            ]) { [weak self] error in
                guard let self = self else { return }
                
                self.isLoading = false
                
                if let error = error {
                    self.errorMessage = "Error creating modules array: \(error.localizedDescription)"
                } else {
                    // Update local data and refresh
                    DispatchQueue.main.async {
                        self.permissions?.modules = newModules
                        self.objectWillChange.send()
                    }
                }
            }
        }
    }
    
    // Check if user has access to a module
    func hasAccess(to moduleId: ModuleType, role: UserModel.UserRole) -> Bool {
        // Admins always have access to everything
        if role == .admin {
            return true
        }
        
        // Check permissions
        if let modulePermission = permissions?.modules.first(where: { $0.moduleId == moduleId }) {
            return modulePermission.hasAccess(role: role)
        }
        
        // If permissions not found, access is denied by default
        return false
    }
    
    // Check access for current user (WITH personal permissions)
    func currentUserHasAccess(to moduleId: ModuleType) -> Bool {
        guard let userId = AppState.shared.user?.id,
              let userRole = AppState.shared.user?.role else {
            return false
        }
        
        // Explicitly call the function that includes personal permissions
        return hasAccess(to: moduleId, userId: userId, role: userRole)
    }
    
    // Get all modules that the user has access to
    func getAccessibleModules(for role: UserModel.UserRole) -> [ModuleType] {
        // Admins have access to everything
        if role == .admin {
            return ModuleType.allCases
        }
        
        // For other roles, filter modules by permissions
        return permissions?.modules
            .filter { $0.hasAccess(role: role) }
            .map { $0.moduleId } ?? []
    }
    
    // Get accessible modules for current user (WITH personal permissions)
    func getCurrentUserAccessibleModules() -> [ModuleType] {
        guard let userId = AppState.shared.user?.id,
              let userRole = AppState.shared.user?.role else {
            return []
        }
        
        // Get modules accessible by role
        let roleModules = getAccessibleModules(for: userRole)
        
        // Get modules with personal access
        let personalModules = getPersonalAccessModules(userId: userId)
        
        // Combine both (remove duplicates)
        let allModules = Set(roleModules + personalModules)
        return Array(allModules).sorted { $0.displayName < $1.displayName }
    }
    
    // Check if user has edit permission for a module
    // This is a stricter requirement, usually for admins and managers
    func hasEditPermission(for moduleId: ModuleType) -> Bool {
        guard let role = AppState.shared.user?.role,
              let userId = AppState.shared.user?.id else {
            return false
        }
        
        // Check if user has personal access to this module
        if hasPersonalAccess(userId: userId, moduleId: moduleId) {
            return true
        }
        
        // Check role-based permissions
        if let modulePermission = permissions?.modules.first(where: { $0.moduleId == moduleId }) {
            return modulePermission.roleAccess.contains(role)
        }
        
        // Fallback to basic role check for merchandise
        if moduleId == .merchandise {
            return role == .admin || role == .manager
        }
        
        return false
    }
    
    // Reset permissions to default values
    func resetToDefaults() {
        guard let groupId = AppState.shared.user?.groupId,
              let permissionId = permissions?.id else {
            return
        }
        
        // Delete current permissions and create new ones
        db.collection("permissions").document(permissionId).delete { [weak self] error in
            if error == nil {
                self?.createDefaultPermissions(for: groupId)
            }
        }
    }
    
    // Get list of roles that have access to a module
    func getRolesWithAccess(to moduleId: ModuleType) -> [UserModel.UserRole] {
        if let modulePermission = permissions?.modules.first(where: { $0.moduleId == moduleId }) {
            return modulePermission.roleAccess
        }
        return []
    }
    
    // Check user's personal access to module
    func hasPersonalAccess(userId: String, moduleId: ModuleType) -> Bool {
        if let userPermission = permissions?.userPermissions.first(where: { $0.userId == userId }) {
            return userPermission.modules.contains(moduleId)
        }
        return false
    }
    
    // Update user's personal permissions
    func updateUserPermissions(userId: String, modules: [ModuleType]) {
        guard let permissionId = permissions?.id else { return }
        isLoading = true
        
        // Create new permissions structure
        let userPermission = PermissionModel.UserPermission(userId: userId, modules: modules)
        
        // Update local data
        var userPermissions = permissions?.userPermissions ?? []
        if let index = userPermissions.firstIndex(where: { $0.userId == userId }) {
            userPermissions[index] = userPermission
        } else {
            userPermissions.append(userPermission)
        }
        
        // Update in Firestore
        db.collection("permissions").document(permissionId).updateData([
            "userPermissions": userPermissions.map { [
                "userId": $0.userId,
                "modules": $0.modules.map { $0.rawValue }
            ]}
        ]) { [weak self] error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.errorMessage = "Error updating user permissions: \(error.localizedDescription)"
                } else {
                    // Обновляем локальные данные
                    self?.permissions?.userPermissions = userPermissions
                }
            }
        }
    }
    
    // Проверка доступа с учетом персональных разрешений
    func hasAccess(to moduleId: ModuleType, userId: String, role: UserModel.UserRole) -> Bool {
        // Админы всегда имеют доступ
        if role == .admin {
            return true
        }
        
        // Проверяем персональные разрешения
        if hasPersonalAccess(userId: userId, moduleId: moduleId) {
            return true
        }
        
        // Если нет персональных разрешений, проверяем доступ по роли
        return hasAccess(to: moduleId, role: role)
    }
    
    // Получение списка модулей с персональным доступом для пользователя
    func getPersonalAccessModules(userId: String) -> [ModuleType] {
        if let userPermission = permissions?.userPermissions.first(where: { $0.userId == userId }) {
            return userPermission.modules
        }
        return []
    }
    
    // Проверка наличия персональных разрешений у пользователя
    func hasAnyPersonalAccess(userId: String) -> Bool {
        if let userPermission = permissions?.userPermissions.first(where: { $0.userId == userId }) {
            return !userPermission.modules.isEmpty
        }
        return false
    }
    
    // MARK: - Musician Special Permissions
    
    /// Check if current user can write/edit in a module (обновленная версия)
    func currentUserCanWrite(to moduleId: ModuleType) -> Bool {
        guard let role = AppState.shared.user?.role else {
            return false
        }
        
        // Admins and managers can write to all modules they have access to
        if role == .admin || role == .manager {
            return currentUserHasAccess(to: moduleId)
        }
        
        // Special logic for Musicians
        if role == .musician {
            switch moduleId {
            case .calendar:
                // ✅ Musicians can write to calendar
                return currentUserHasAccess(to: moduleId)
            case .documents:
                // ✅ Musicians can write to documents
                return currentUserHasAccess(to: moduleId)
            case .setlists:
                // ❌ Musicians can only READ setlists (no write)
                return false
            case .tasks:
                // ✅ Musicians can write to tasks
                return currentUserHasAccess(to: moduleId)
            case .chats:
                // ✅ Musicians can write to chats
                return currentUserHasAccess(to: moduleId)
            default:
                // For other modules, no write access
                return false
            }
        }
        
        // For Members
        if role == .member {
            switch moduleId {
            case .calendar, .chats:
                // Members can contribute to calendar events and chats
                return currentUserHasAccess(to: moduleId)
            default:
                // For other modules, no write access
                return false
            }
        }
        
        return false
    }
    
    /// Check if current user can delete in a module (обновленная версия)
    func currentUserCanDelete(from moduleId: ModuleType) -> Bool {
        guard let role = AppState.shared.user?.role else {
            return false
        }
        
        // Only admins and managers can delete (more restrictive than write)
        if role == .admin || role == .manager {
            return currentUserHasAccess(to: moduleId)
        }
        
        // Musicians and Members cannot delete anything
        return false
    }
    
    // Force refresh permissions (useful after updates)
    func refreshPermissions() {
        guard let groupId = AppState.shared.user?.groupId else {
            return
        }
        fetchPermissions(for: groupId)
    }
    
    // MARK: - Manager Extended Access Helper Functions
    
    /// Check if current user is a Manager with extended access to specified modules
    /// Manager has read/write/delete access to: calendar, setlists, tasks, documents
    func currentUserIsManagerWithExtendedAccess() -> Bool {
        return AppState.shared.user?.role == .manager
    }
    
    /// Check if current user (Manager) has full access (read/write/delete) to the specified module
    func currentManagerHasFullAccess(to moduleId: ModuleType) -> Bool {
        guard currentUserIsManagerWithExtendedAccess() else {
            return false
        }
        
        // Manager has full access only to these specific modules
        let managerFullAccessModules: [ModuleType] = [
            .calendar, .setlists, .tasks, .documents, .merchandise
        ]
        
        return managerFullAccessModules.contains(moduleId) && currentUserHasAccess(to: moduleId)
    }
    
    /// Get all modules where Manager has full access (read/write/delete)
    func getManagerFullAccessModules() -> [ModuleType] {
        guard currentUserIsManagerWithExtendedAccess() else {
            return []
        }
        
        // Manager has access to these 5 modules
        return [.calendar, .setlists, .tasks, .documents, .merchandise]
    }
    
    // MARK: - Permission Verification Helpers
    
    /// Get detailed permissions for current user role
    func getCurrentUserDetailedPermissions() -> [ModuleType: (read: Bool, write: Bool, delete: Bool)] {
        guard AppState.shared.user?.role != nil else {
            return [:]
        }
        
        var permissions: [ModuleType: (read: Bool, write: Bool, delete: Bool)] = [:]
        
        for module in ModuleType.allCases {
            let read = currentUserHasAccess(to: module)
            let write = currentUserCanWrite(to: module)
            let delete = currentUserCanDelete(from: module)
            
            permissions[module] = (read: read, write: write, delete: delete)
        }
        
        return permissions
    }
    
    /// Verify if current permissions match requirements
    func verifyPermissionsStructure() -> [String: Any] {
        guard let role = AppState.shared.user?.role else {
            return ["error": "No user role found"]
        }
        
        let permissions = getCurrentUserDetailedPermissions()
        var verification: [String: Any] = [:]
        
        verification["userRole"] = role.rawValue
        verification["permissions"] = permissions.mapValues { perm in
            return [
                "read": perm.read,
                "write": perm.write,
                "delete": perm.delete
            ]
        }
        
        // Check specific requirements
        switch role {
        case .admin:
            let allModulesAccess = ModuleType.allCases.allSatisfy { module in
                permissions[module]?.read == true &&
                permissions[module]?.write == true &&
                permissions[module]?.delete == true
            }
            verification["meetsRequirements"] = allModulesAccess
            
        case .manager:
            let requiredAccess = [
                ModuleType.merchandise: (read: true, write: true, delete: true),
                ModuleType.documents: (read: true, write: true, delete: true),
                ModuleType.calendar: (read: true, write: true, delete: true),
                ModuleType.setlists: (read: true, write: true, delete: true),
                ModuleType.tasks: (read: true, write: true, delete: true)
            ]
            
            let meetsRequirements = requiredAccess.allSatisfy { (module, required) in
                let actual = permissions[module]
                return actual?.read == required.read &&
                       actual?.write == required.write &&
                       actual?.delete == required.delete
            }
            verification["meetsRequirements"] = meetsRequirements
            
        case .musician:
            let requiredAccess = [
                ModuleType.documents: (read: true, write: true, delete: false),
                ModuleType.calendar: (read: true, write: true, delete: false),
                ModuleType.chats: (read: true, write: true, delete: false),
                ModuleType.setlists: (read: true, write: false, delete: false), // ❌ Only read
                ModuleType.tasks: (read: true, write: true, delete: false)
            ]
            
            let meetsRequirements = requiredAccess.allSatisfy { (module, required) in
                let actual = permissions[module]
                return actual?.read == required.read &&
                       actual?.write == required.write &&
                       actual?.delete == required.delete
            }
            verification["meetsRequirements"] = meetsRequirements
            
        case .member:
            let requiredAccess = [
                ModuleType.calendar: (read: true, write: true, delete: false),
                ModuleType.chats: (read: true, write: true, delete: false)
            ]
            
            let meetsRequirements = requiredAccess.allSatisfy { (module, required) in
                let actual = permissions[module]
                return actual?.read == required.read &&
                       actual?.write == required.write &&
                       actual?.delete == required.delete
            }
            verification["meetsRequirements"] = meetsRequirements
        }
        
        return verification
    }
    
    // MARK: - Manager Extended Access Verification
    
    /// Verify that Manager role has proper extended access configured
    /// This function validates the current configuration against requirements:
    /// 🟡 Manager - расширенный доступ
    /// ✅ Calendar (чтение/запись/удаление)
    /// ✅ Setlists (чтение/запись/удаление)
    /// ✅ Tasks (чтение/запись/удаление)
    /// ✅ Documents (чтение/запись/удаление)
    /// ✅ Merchandise (чтение/запись/удаление)
    func verifyManagerExtendedAccess() -> [String: Bool] {
        guard currentUserIsManagerWithExtendedAccess() else {
            return [:]
        }
        
        let requiredModules: [ModuleType] = [.calendar, .setlists, .tasks, .documents, .merchandise]
        var verificationResults: [String: Bool] = [:]
        
        for module in requiredModules {
            let hasRead = currentUserHasAccess(to: module)
            let hasWrite = currentUserCanWrite(to: module)
            let hasDelete = currentUserCanDelete(from: module)
            
            let fullAccess = hasRead && hasWrite && hasDelete
            verificationResults[module.displayName] = fullAccess
        }
        
        return verificationResults
    }
}
