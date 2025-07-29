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
    
    // ИСПРАВЛЕНИЕ: Кэшируем результаты проверки доступа
    @Published private(set) var accessibleModules: Set<ModuleType> = []
    private var lastCacheUpdate: Date = Date()
    private let cacheTimeout: TimeInterval = 30.0
    
    private let db = Firestore.firestore()
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        AppState.shared.$user
            .removeDuplicates()
            .sink { [weak self] user in
                if let groupId = user?.groupId {
                    self?.fetchPermissions(for: groupId)
                } else {
                    self?.permissions = nil
                    self?.clearAccessCache()
                }
            }
            .store(in: &cancellables)
            
        // Обновляем кэш при изменении разрешений
        $permissions
            .sink { [weak self] _ in
                self?.updateAccessCache()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Fetch Permissions
    func fetchPermissions(for groupId: String) {
        isLoading = true
        errorMessage = nil
        
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
                        self.createDefaultPermissions(for: groupId)
                    }
                }
            }
    }
    
    // Create default permissions for new group
    func createDefaultPermissions(for groupId: String) {
        isLoading = true
        
        let defaultModules: [PermissionModel.ModulePermission] = ModuleType.allCases.map { moduleType in
            let roles: [UserModel.UserRole]
            
            switch moduleType {
            case .admin:
                roles = [.admin]
            case .finances:
                roles = [.admin]
            case .merchandise:
                roles = [.admin, .manager]
            case .contacts:
                roles = [.admin]
            case .documents:
                roles = [.admin, .manager, .musician]
            case .calendar, .chats:
                roles = [.admin, .manager, .musician, .member]
            case .setlists, .tasks:
                roles = [.admin, .manager, .musician]
            }
            
            return PermissionModel.ModulePermission(moduleId: moduleType, roleAccess: roles)
        }
        
        let newPermission = PermissionModel(
            groupId: groupId,
            modules: defaultModules,
            userPermissions: []
        )
        
        do {
            try db.collection("permissions").addDocument(from: newPermission) { [weak self] error in
                DispatchQueue.main.async {
                    self?.isLoading = false
                    
                    if let error = error {
                        self?.errorMessage = "Error creating permissions: \(error.localizedDescription)"
                    } else {
                        self?.permissions = newPermission
                        self?.objectWillChange.send()
                    }
                }
            }
        } catch {
            DispatchQueue.main.async {
                self.isLoading = false
                self.errorMessage = "Error creating permissions: \(error.localizedDescription)"
            }
        }
    }
    
    // MARK: - ИСПРАВЛЕНИЕ: Оптимизированные методы проверки доступа
    
    // Быстрая проверка через кэш
    func currentUserHasAccess(to moduleId: ModuleType) -> Bool {
        // Проверяем кэш сначала
        if isCacheValid() {
            return accessibleModules.contains(moduleId)
        }
        
        // Если кэш устарел, обновляем и проверяем
        updateAccessCache()
        return accessibleModules.contains(moduleId)
    }
    
    private func updateAccessCache() {
        guard let userId = AppState.shared.user?.id,
              let userRole = AppState.shared.user?.role else {
            clearAccessCache()
            return
        }
        
        var newAccessibleModules: Set<ModuleType> = []
        
        for module in ModuleType.allCases {
            if hasAccess(to: module, userId: userId, role: userRole) {
                newAccessibleModules.insert(module)
            }
        }
        
        accessibleModules = newAccessibleModules
        lastCacheUpdate = Date()
    }
    
    private func clearAccessCache() {
        accessibleModules = []
        lastCacheUpdate = Date()
    }
    
    private func isCacheValid() -> Bool {
        return Date().timeIntervalSince(lastCacheUpdate) < cacheTimeout
    }
    
    // MARK: - Update module permissions
    func updateModulePermission(moduleId: ModuleType, roles: [UserModel.UserRole]) {
        guard let permissionId = permissions?.id else { return }
        isLoading = true
        
        var newModules = permissions?.modules ?? []
        if let index = newModules.firstIndex(where: { $0.moduleId == moduleId }) {
            newModules[index] = PermissionModel.ModulePermission(moduleId: moduleId, roleAccess: roles)
        } else {
            newModules.append(PermissionModel.ModulePermission(moduleId: moduleId, roleAccess: roles))
        }
        
        db.collection("permissions").document(permissionId).updateData([
            "modules": newModules.map { [
                "moduleId": $0.moduleId.rawValue,
                "roleAccess": $0.roleAccess.map { $0.rawValue }
            ]}
        ]) { [weak self] error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.errorMessage = "Error updating modules array: \(error.localizedDescription)"
                } else {
                    self?.permissions?.modules = newModules
                    self?.objectWillChange.send()
                }
            }
        }
    }
    
    // MARK: - Access Checking Methods
    
    func hasAccess(to moduleId: ModuleType, role: UserModel.UserRole) -> Bool {
        if role == .admin {
            return true
        }
        
        if let modulePermission = permissions?.modules.first(where: { $0.moduleId == moduleId }) {
            return modulePermission.hasAccess(role: role)
        }
        
        return false
    }
    
    func hasAccess(to moduleId: ModuleType, userId: String, role: UserModel.UserRole) -> Bool {
        if role == .admin {
            return true
        }
        
        if hasPersonalAccess(userId: userId, moduleId: moduleId) {
            return true
        }
        
        if let modulePermission = permissions?.modules.first(where: { $0.moduleId == moduleId }) {
            return modulePermission.roleAccess.contains(role)
        }
        
        return false
    }
    
    func getAccessibleModules(for role: UserModel.UserRole) -> [ModuleType] {
        if role == .admin {
            return ModuleType.allCases
        }
        
        return permissions?.modules
            .filter { $0.hasAccess(role: role) }
            .map { $0.moduleId } ?? []
    }
    
    func getCurrentUserAccessibleModules() -> [ModuleType] {
        guard let userId = AppState.shared.user?.id,
              let userRole = AppState.shared.user?.role else {
            return []
        }
        
        let roleModules = getAccessibleModules(for: userRole)
        let personalModules = getPersonalAccessModules(userId: userId)
        
        let allModules = Set(roleModules + personalModules)
        return Array(allModules).sorted { $0.displayName < $1.displayName }
    }
    
    // MARK: - Personal Permissions
    
    func hasPersonalAccess(userId: String, moduleId: ModuleType) -> Bool {
        if let userPermission = permissions?.userPermissions.first(where: { $0.userId == userId }) {
            return userPermission.modules.contains(moduleId)
        }
        return false
    }
    
    func getPersonalAccessModules(userId: String) -> [ModuleType] {
        if let userPermission = permissions?.userPermissions.first(where: { $0.userId == userId }) {
            return userPermission.modules
        }
        return []
    }
    
    func hasAnyPersonalAccess(userId: String) -> Bool {
        if let userPermission = permissions?.userPermissions.first(where: { $0.userId == userId }) {
            return !userPermission.modules.isEmpty
        }
        return false
    }
    
    func updateUserPermissions(userId: String, modules: [ModuleType]) {
        guard let permissionId = permissions?.id else { return }
        isLoading = true
        
        let userPermission = PermissionModel.UserPermission(userId: userId, modules: modules)
        
        var userPermissions = permissions?.userPermissions ?? []
        if let index = userPermissions.firstIndex(where: { $0.userId == userId }) {
            userPermissions[index] = userPermission
        } else {
            userPermissions.append(userPermission)
        }
        
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
                    self?.permissions?.userPermissions = userPermissions
                }
            }
        }
    }
    
    // MARK: - Edit/Write Permissions
    
    func hasEditPermission(for moduleId: ModuleType) -> Bool {
        guard let role = AppState.shared.user?.role else {
            return false
        }
        
        return currentUserCanWrite(to: moduleId)
    }
    
    func currentUserCanWrite(to moduleId: ModuleType) -> Bool {
        guard let role = AppState.shared.user?.role else {
            return false
        }
        
        if role == .admin || role == .manager {
            return currentUserHasAccess(to: moduleId)
        }
        
        if role == .musician {
            switch moduleId {
            case .calendar, .documents, .tasks, .chats:
                return currentUserHasAccess(to: moduleId)
            case .setlists:
                return false // Musicians can only read setlists
            default:
                return false
            }
        }
        
        if role == .member {
            switch moduleId {
            case .calendar, .chats:
                return currentUserHasAccess(to: moduleId)
            default:
                return false
            }
        }
        
        return false
    }
    
    func currentUserCanDelete(from moduleId: ModuleType) -> Bool {
        guard let role = AppState.shared.user?.role else {
            return false
        }
        
        if role == .admin || role == .manager {
            return currentUserHasAccess(to: moduleId)
        }
        
        return false
    }
    
    // MARK: - Manager Extended Access Helper Functions
    
    func currentUserIsManagerWithExtendedAccess() -> Bool {
        return AppState.shared.user?.role == .manager
    }
    
    func currentManagerHasFullAccess(to moduleId: ModuleType) -> Bool {
        guard currentUserIsManagerWithExtendedAccess() else {
            return false
        }
        
        let managerFullAccessModules: [ModuleType] = [
            .calendar, .setlists, .tasks, .documents, .merchandise
        ]
        
        return managerFullAccessModules.contains(moduleId) && currentUserHasAccess(to: moduleId)
    }
    
    func getManagerFullAccessModules() -> [ModuleType] {
        guard currentUserIsManagerWithExtendedAccess() else {
            return []
        }
        
        return [.calendar, .setlists, .tasks, .documents, .merchandise]
    }
    
    // MARK: - Permission Verification Helpers
    
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
    
    // MARK: - Utility Methods
    
    func resetToDefaults() {
        guard let groupId = AppState.shared.user?.groupId,
              let permissionId = permissions?.id else {
            return
        }
        
        db.collection("permissions").document(permissionId).delete { [weak self] error in
            if error == nil {
                self?.createDefaultPermissions(for: groupId)
            }
        }
    }
    
    func getRolesWithAccess(to moduleId: ModuleType) -> [UserModel.UserRole] {
        if let modulePermission = permissions?.modules.first(where: { $0.moduleId == moduleId }) {
            return modulePermission.roleAccess
        }
        return []
    }
    
    func refreshPermissions() {
        guard let groupId = AppState.shared.user?.groupId else {
            return
        }
        fetchPermissions(for: groupId)
    }
}
