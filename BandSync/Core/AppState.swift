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
        
        // ОБНОВЛЕННАЯ ЛОГИКА: Учитываем разные типы пользователей
        if let user = user {
            switch user.userType {
            case .bandMember:
                // Для участников группы загружаем разрешения, если есть groupId
                if let groupId = user.groupId {
                    PermissionService.shared.fetchPermissions(for: groupId)
                }
                
            case .fan:
                // Для фанатов разрешения не нужны (у них свой упрощенный интерфейс)
                // Можно добавить специальную логику для фанатов при необходимости
                break
            }
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
                    // Очистка кэша разрешений
                    self.permissionCache.removeAll()
                    self.lastUserIdForCache = nil
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
        UserDefaults.standard.set(user.phone, forKey: "userPhone")
        UserDefaults.standard.set(user.role.rawValue, forKey: "userRole")
        
        // ОБНОВЛЕНО: Сохраняем разные данные в зависимости от типа пользователя
        UserDefaults.standard.set(user.userType.rawValue, forKey: "userType")
        
        switch user.userType {
        case .bandMember:
            UserDefaults.standard.set(user.groupId, forKey: "userGroupID")
            UserDefaults.standard.removeObject(forKey: "userFanGroupID") // Очищаем fanGroupId
            
        case .fan:
            UserDefaults.standard.set(user.fanGroupId, forKey: "userFanGroupID")
            UserDefaults.standard.removeObject(forKey: "userGroupID") // Очищаем groupId
        }
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
                // Очистка кэша при потере аутентификации
                self.permissionCache.removeAll()
                self.lastUserIdForCache = nil
            }
        }
    }
    
    // ОБНОВЛЕНО: Учитываем тип пользователя при проверке доступа
    func hasAccess(to moduleType: ModuleType) -> Bool {
        guard isLoggedIn, let user = user else {
            return false
        }
        
        // Фанаты имеют доступ только к определенным модулям
        if user.userType == .fan {
            return hasFanAccess(to: moduleType)
        }
        
        // Участники группы - обычная система разрешений
        return PermissionService.shared.hasAccess(to: moduleType, role: user.role)
    }
    
    // НОВОЕ: Система доступа для фанатов
    private func hasFanAccess(to moduleType: ModuleType) -> Bool {
        // Фанаты имеют доступ только к ограниченному набору модулей
        switch moduleType {
        case .calendar:     // Просмотр концертов и событий
            return true
        case .chats:        // Фан-чаты
            return true
        case .merchandise:  // Покупка мерча
            return true
        default:
            return false    // Остальные модули недоступны фанатам
        }
    }
    
    func hasEditPermission(for moduleType: ModuleType) -> Bool {
        guard isLoggedIn, let user = user else {
            return false
        }
        
        // Фанаты не могут редактировать большинство контента
        if user.userType == .fan {
            return hasFanEditPermission(for: moduleType)
        }
        
        // Участники группы - обычная система разрешений
        let userId = user.id
        if lastUserIdForCache != userId {
            permissionCache.removeAll()
            lastUserIdForCache = userId
        }
        
        if let cachedResult = permissionCache[moduleType] {
            return cachedResult
        }
        
        let hasPermission = PermissionService.shared.hasEditPermission(for: moduleType)
        permissionCache[moduleType] = hasPermission
        
        return hasPermission
    }
    
    // НОВОЕ: Права редактирования для фанатов
    private func hasFanEditPermission(for moduleType: ModuleType) -> Bool {
        switch moduleType {
        case .chats:
            return true  // Фанаты могут писать в чатах
        default:
            return false // Остальное редактировать нельзя
        }
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
    
    // НОВОЕ: Проверка что пользователь - фанат
    var isCurrentUserFan: Bool {
        return user?.userType == .fan
    }
    
    // НОВОЕ: Проверка что пользователь - участник группы
    var isCurrentUserBandMember: Bool {
        return user?.userType == .bandMember
    }
}
