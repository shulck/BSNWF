import Foundation
import FirebaseFirestore
import FirebaseAuth

final class UserService: ObservableObject {
    static let shared = UserService()
    @Published var currentUser: UserModel?
    @Published var users: [UserModel] = []
    
    private let db = Firestore.firestore()
    private var isCurrentlyFetching = false
    
    init() {}
    
    // MARK: - Fetch Current User (ОБНОВЛЕНО для поддержки фанатов)
    func fetchCurrentUser(completion: @escaping (Bool) -> Void) {
        guard !isCurrentlyFetching else {
            completion(false)
            return
        }
        
        guard let uid = Auth.auth().currentUser?.uid else {
            DispatchQueue.main.async {
                completion(false)
            }
            return
        }
        
        isCurrentlyFetching = true
        
        db.collection("users").document(uid).getDocument { [weak self] snapshot, error in
            defer {
                self?.isCurrentlyFetching = false
            }
            
            if let error = error {
                print("UserService: error loading user: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion(false)
                }
                return
            }
            
            guard let snapshot = snapshot, snapshot.exists, let data = snapshot.data() else {
                DispatchQueue.main.async {
                    completion(false)
                }
                return
            }
            
            // ОБНОВЛЕНО: Создаем UserModel с поддержкой фанатов
            let user = UserModel(
                id: data["id"] as? String ?? uid,
                email: data["email"] as? String ?? "",
                name: data["name"] as? String ?? "",
                phone: data["phone"] as? String ?? "",
                groupId: data["groupId"] as? String,
                role: UserModel.UserRole(rawValue: data["role"] as? String ?? "Member") ?? .member,
                isOnline: data["isOnline"] as? Bool,
                lastSeen: (data["lastSeen"] as? Timestamp)?.dateValue(),
                avatarURL: data["avatarURL"] as? String,
                documentPermissions: nil, // Will be loaded separately if needed
                googleDriveEmail: data["googleDriveEmail"] as? String,
                hasGoogleDriveAccess: data["hasGoogleDriveAccess"] as? Bool,
                userType: UserType(rawValue: data["userType"] as? String ?? "BandMember") ?? .bandMember,
                fanGroupId: data["fanGroupId"] as? String,
                fanProfile: Self.parseFanProfile(from: data["fanProfile"])
            )
            
            DispatchQueue.main.async {
                self?.currentUser = user
                completion(true)
            }
        }
    }
    
    // MARK: - Parse Fan Profile (НОВОЕ)
    private static func parseFanProfile(from data: Any?) -> FanProfile? {
        guard let fanProfileDict = data as? [String: Any],
              let nickname = fanProfileDict["nickname"] as? String,
              let joinDateTimestamp = fanProfileDict["joinDate"] as? Timestamp,
              let location = fanProfileDict["location"] as? String,
              let favoriteSong = fanProfileDict["favoriteSong"] as? String else {
            return nil
        }
        
        let joinDate = joinDateTimestamp.dateValue()
        let levelString = fanProfileDict["level"] as? String ?? "Newbie"
        let level = FanLevel(rawValue: levelString) ?? .newbie
        let achievements = fanProfileDict["achievements"] as? [String] ?? []
        let isModerator = fanProfileDict["isModerator"] as? Bool ?? false
        
        // Parse stats
        var stats = FanStats()
        if let statsDict = fanProfileDict["stats"] as? [String: Any] {
            stats = FanStats(
                totalMessages: statsDict["totalMessages"] as? Int ?? 0,
                joinDate: (statsDict["joinDate"] as? Timestamp)?.dateValue() ?? joinDate,
                lastActive: (statsDict["lastActive"] as? Timestamp)?.dateValue() ?? Date(),
                merchandisePurchased: statsDict["merchandisePurchased"] as? Int ?? 0,
                concertsAttended: statsDict["concertsAttended"] as? Int ?? 0,
                achievementsUnlocked: statsDict["achievementsUnlocked"] as? Int ?? 0
            )
        }
        
        // Parse notification settings
        var notificationSettings = FanNotificationSettings()
        if let notificationDict = fanProfileDict["notificationSettings"] as? [String: Any] {
            notificationSettings = FanNotificationSettings(
                newConcerts: notificationDict["newConcerts"] as? Bool ?? true,
                officialNews: notificationDict["officialNews"] as? Bool ?? true,
                chatMessages: notificationDict["chatMessages"] as? Bool ?? true,
                newMerch: notificationDict["newMerch"] as? Bool ?? true,
                achievements: notificationDict["achievements"] as? Bool ?? true,
                moderatorActions: notificationDict["moderatorActions"] as? Bool ?? false
            )
        }
        
        return FanProfile(
            nickname: nickname,
            joinDate: joinDate,
            location: location,
            favoriteSong: favoriteSong,
            level: level,
            achievements: achievements,
            isModerator: isModerator,
            stats: stats,
            notificationSettings: notificationSettings
        )
    }
    
    // MARK: - Update User (ОБНОВЛЕНО для поддержки фанатов)
    func updateUser(_ user: UserModel, completion: @escaping (Bool) -> Void) {
        var userData: [String: Any] = [
            "id": user.id,
            "email": user.email,
            "name": user.name,
            "phone": user.phone,
            "role": user.role.rawValue,
            "avatarURL": user.avatarURL ?? NSNull(),
            "googleDriveEmail": user.googleDriveEmail ?? NSNull(),
            "hasGoogleDriveAccess": user.hasGoogleDriveAccess ?? NSNull(),
            "userType": user.userType.rawValue
        ]
        
        // ОБНОВЛЕНО: Устанавливаем правильные поля в зависимости от типа пользователя
        switch user.userType {
        case .bandMember:
            userData["groupId"] = user.groupId ?? NSNull()
            userData["fanGroupId"] = NSNull()
            userData["fanProfile"] = NSNull()
            
        case .fan:
            userData["groupId"] = NSNull()
            userData["fanGroupId"] = user.fanGroupId ?? NSNull()
            
            // Сохраняем fanProfile для фанатов
            if let fanProfile = user.fanProfile {
                userData["fanProfile"] = [
                    "nickname": fanProfile.nickname,
                    "joinDate": Timestamp(date: fanProfile.joinDate),
                    "location": fanProfile.location,
                    "favoriteSong": fanProfile.favoriteSong,
                    "level": fanProfile.level.rawValue,
                    "achievements": fanProfile.achievements,
                    "isModerator": fanProfile.isModerator,
                    "stats": [
                        "totalMessages": fanProfile.stats.totalMessages,
                        "joinDate": Timestamp(date: fanProfile.stats.joinDate),
                        "lastActive": Timestamp(date: fanProfile.stats.lastActive),
                        "merchandisePurchased": fanProfile.stats.merchandisePurchased,
                        "concertsAttended": fanProfile.stats.concertsAttended,
                        "achievementsUnlocked": fanProfile.stats.achievementsUnlocked
                    ],
                    "notificationSettings": [
                        "newConcerts": fanProfile.notificationSettings.newConcerts,
                        "officialNews": fanProfile.notificationSettings.officialNews,
                        "chatMessages": fanProfile.notificationSettings.chatMessages,
                        "newMerch": fanProfile.notificationSettings.newMerch,
                        "achievements": fanProfile.notificationSettings.achievements,
                        "moderatorActions": fanProfile.notificationSettings.moderatorActions
                    ]
                ]
            } else {
                userData["fanProfile"] = NSNull()
            }
        }
        
        db.collection("users").document(user.id).setData(userData) { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    print("UserService: error updating user: \(error.localizedDescription)")
                    completion(false)
                } else {
                    self?.currentUser = user
                    completion(true)
                }
            }
        }
    }
    
    // MARK: - Fetch Users for Group (ОБНОВЛЕНО)
    func fetchUsers(for groupId: String, completion: @escaping ([UserModel]) -> Void) {
        db.collection("users")
            .whereField("groupId", isEqualTo: groupId)
            .getDocuments { [weak self] snapshot, error in
                if let error = error {
                    print("UserService: error loading users: \(error.localizedDescription)")
                    DispatchQueue.main.async {
                        completion([])
                    }
                    return
                }
                
                let users = snapshot?.documents.compactMap { doc -> UserModel? in
                    let data = doc.data()
                    return UserModel(
                        id: data["id"] as? String ?? doc.documentID,
                        email: data["email"] as? String ?? "",
                        name: data["name"] as? String ?? "",
                        phone: data["phone"] as? String ?? "",
                        groupId: data["groupId"] as? String,
                        role: UserModel.UserRole(rawValue: data["role"] as? String ?? "Member") ?? .member,
                        isOnline: data["isOnline"] as? Bool,
                        lastSeen: (data["lastSeen"] as? Timestamp)?.dateValue(),
                        avatarURL: data["avatarURL"] as? String,
                        documentPermissions: nil,
                        googleDriveEmail: data["googleDriveEmail"] as? String,
                        hasGoogleDriveAccess: data["hasGoogleDriveAccess"] as? Bool,
                        userType: UserType(rawValue: data["userType"] as? String ?? "BandMember") ?? .bandMember,
                        fanGroupId: data["fanGroupId"] as? String,
                        fanProfile: Self.parseFanProfile(from: data["fanProfile"])
                    )
                } ?? []
                
                DispatchQueue.main.async {
                    self?.users = users
                    completion(users)
                }
            }
    }
    
    // MARK: - Delete User
    func deleteUser(_ userId: String, completion: @escaping (Bool) -> Void) {
        db.collection("users").document(userId).delete { error in
            DispatchQueue.main.async {
                if let error = error {
                    print("UserService: error deleting user: \(error.localizedDescription)")
                    completion(false)
                } else {
                    completion(true)
                }
            }
        }
    }
    
    // MARK: - Update User Group
    func updateUserGroup(userId: String, groupId: String?, completion: @escaping (Bool) -> Void) {
        let updateData: [String: Any] = [
            "groupId": groupId ?? NSNull()
        ]
        
        db.collection("users").document(userId).updateData(updateData) { error in
            DispatchQueue.main.async {
                if let error = error {
                    print("UserService: error updating user group: \(error.localizedDescription)")
                    completion(false)
                } else {
                    completion(true)
                }
            }
        }
    }
    
    // MARK: - Fetch Users (без фильтра)
    func fetchUsers() {
        guard let currentUser = currentUser,
              let groupId = currentUser.groupId else { return }
        
        fetchUsers(for: groupId) { [weak self] users in
            self?.users = users
        }
    }
}
