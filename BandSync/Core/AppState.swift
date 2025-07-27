//
//  AppState.swift
//  BandSync
//
//  Created by Oleksandr Kuziakin on 31.03.2025.
//

import Foundation
import Combine
import FirebaseAuth

final class AppState: ObservableObject {
    static let shared = AppState()

    @Published var isLoggedIn: Bool = false
    @Published var user: UserModel?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private var permissionCache: [ModuleType: Bool] = [:]
    private var lastUserIdForCache: String?
    private var isCurrentlyLoading = false
    private var cancellables = Set<AnyCancellable>()

    private init() {
        FirebaseManager.shared.ensureInitialized()
        isLoggedIn = AuthService.shared.isUserLoggedIn()
        
        UserService.shared.$currentUser
            .receive(on: DispatchQueue.main)
            .sink { [weak self] user in
                self?.handleUserUpdate(user)
            }
            .store(in: &cancellables)
    }
    
    private func handleUserUpdate(_ user: UserModel?) {
        self.user = user
        
        if let groupId = user?.groupId {
            PermissionService.shared.fetchPermissions(for: groupId)
        }
    }

    func logout() {
        isLoading = true
        
        AuthService.shared.signOut { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isLoading = false
                
                switch result {
                case .success:
                    self.isLoggedIn = false
                    self.user = nil
                case .failure(let error):
                    self.errorMessage = "Error during logout: \(error.localizedDescription)"
                }
            }
        }
    }

    func loadUser() {
        guard !isCurrentlyLoading else { return }
        
        isLoading = true
        isCurrentlyLoading = true
        
        UserService.shared.fetchCurrentUser { [weak self] success in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isLoading = false
                self.isCurrentlyLoading = false
                self.isLoggedIn = success
                
                if success, let user = self.user {
                    self.saveUserToDefaults(user)
                    self.setupNotifications()
                } else {
                    self.errorMessage = "Failed to load user data"
                }
            }
        }
    }
    
    private func saveUserToDefaults(_ user: UserModel) {
        UserDefaults.standard.set(user.id, forKey: "userID")
        UserDefaults.standard.set(user.name, forKey: "userName")
        UserDefaults.standard.set(user.email, forKey: "userEmail")
        UserDefaults.standard.set(user.groupId, forKey: "userGroupID")
        UserDefaults.standard.set(user.phone, forKey: "userPhone")
        UserDefaults.standard.set(user.role.rawValue, forKey: "userRole")
    }

    func refreshAuthState() {
        guard !isCurrentlyLoading else { return }
        
        isLoading = true
        
        if Auth.auth().currentUser != nil {
            loadUser()
        } else {
            DispatchQueue.main.async {
                self.isLoggedIn = false
                self.user = nil
                self.isLoading = false
            }
        }
    }
    
    func hasAccess(to moduleType: ModuleType) -> Bool {
        guard isLoggedIn, let userRole = user?.role else {
            return false
        }
        
        return PermissionService.shared.hasAccess(to: moduleType, role: userRole)
    }
    
    func hasEditPermission(for moduleType: ModuleType) -> Bool {
        guard isLoggedIn, let userId = user?.id else {
            return false
        }
        
        if lastUserIdForCache != userId {
            permissionCache.removeAll()
            lastUserIdForCache = userId
        }
        
        if let cachedResult = permissionCache[moduleType] {
            return cachedResult
        }
        
        // Use PermissionService for accurate permission checking
        let hasPermission = PermissionService.shared.hasEditPermission(for: moduleType)
        permissionCache[moduleType] = hasPermission
        
        return hasPermission
    }
    
    func setupNotifications() {
        NotificationManager.shared.checkPermissionStatus { granted, error in
            if granted {
                UnifiedBadgeManager.shared.startMonitoring()
            }
        }
    }
    
    func onLoginSuccess() {
        setupNotifications()
    }
}
