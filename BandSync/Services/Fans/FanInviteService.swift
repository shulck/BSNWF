//
//  FanInviteService.swift
//  BandSync
//
//  Created by Claude on 27.07.2025.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

final class FanInviteService: ObservableObject {
    static let shared = FanInviteService()
    
    @Published var currentInviteCode: FanInviteCode?
    
    private let db = Firestore.firestore()
    private init() {}
    
    // MARK: - Generate Fan Invite Code (СТАРЫЙ МЕТОД - больше не используется для автогенерации)
    func generateFanInviteCode(for groupId: String, groupName: String, completion: @escaping (Result<FanInviteCode, Error>) -> Void) {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            completion(.failure(FanInviteError.userNotAuthenticated))
            return
        }
        
        // Generate unique code (только для обратной совместимости)
        let code = generateUniqueCode()
        
        let inviteCode = FanInviteCode(
            groupId: groupId,
            code: code,
            createdBy: currentUserId,
            currentUses: 0,
            groupName: groupName
        )
        
        let docRef = db.collection("groups").document(groupId).collection("fanInviteCode").document("current")
        
        do {
            try docRef.setData(from: inviteCode) { [weak self] error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    DispatchQueue.main.async {
                        self?.currentInviteCode = inviteCode
                    }
                    completion(.success(inviteCode))
                }
            }
        } catch {
            completion(.failure(error))
        }
    }
    
    // MARK: - Create Custom Invite Code (НОВЫЙ МЕТОД - для создания кастомных кодов)
    func createCustomInviteCode(for groupId: String, customCode: String, groupName: String, completion: @escaping (Result<FanInviteCode, Error>) -> Void) {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            completion(.failure(FanInviteError.userNotAuthenticated))
            return
        }
        
        print("🔧 Creating custom invite code: '\(customCode)' for group: \(groupId)")
        
        let inviteCode = FanInviteCode(
            groupId: groupId,
            code: customCode,
            createdBy: currentUserId,
            currentUses: 0,
            groupName: groupName
        )
        
        let docRef = db.collection("groups").document(groupId).collection("fanInviteCode").document("current")
        
        do {
            try docRef.setData(from: inviteCode) { [weak self] error in
                if let error = error {
                    print("❌ Error saving invite code: \(error)")
                    completion(.failure(error))
                } else {
                    print("✅ Successfully saved invite code to Firebase")
                    DispatchQueue.main.async {
                        self?.currentInviteCode = inviteCode
                    }
                    completion(.success(inviteCode))
                }
            }
        } catch {
            print("❌ Error encoding invite code: \(error)")
            completion(.failure(error))
        }
    }
    
    // MARK: - Update Custom Invite Code (НОВЫЙ МЕТОД - для обновления кодов)
    func updateCustomInviteCode(for groupId: String, newCode: String, groupName: String, completion: @escaping (Result<FanInviteCode, Error>) -> Void) {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            completion(.failure(FanInviteError.userNotAuthenticated))
            return
        }
        
        print("🔧 Updating invite code to: '\(newCode)' for group: \(groupId)")
        
        let docRef = db.collection("groups").document(groupId).collection("fanInviteCode").document("current")
        
        // Первый шаг: получаем текущий код для сохранения currentUses
        docRef.getDocument { [weak self] snapshot, error in
            if let error = error {
                print("❌ Error getting current code: \(error)")
                completion(.failure(error))
                return
            }
            
            // Сохраняем текущие использования или 0 для нового кода
            let currentUses = snapshot?.data()?["currentUses"] as? Int ?? 0
            print("📊 Current uses: \(currentUses)")
            
            // Создаем обновленный код с сохранением использований
            let updatedCode = FanInviteCode(
                groupId: groupId,
                code: newCode,
                createdBy: currentUserId,
                currentUses: currentUses,
                groupName: groupName
            )
            
            // Обновляем код в Firebase
            do {
                try docRef.setData(from: updatedCode) { error in
                    if let error = error {
                        print("❌ Error updating invite code: \(error)")
                        completion(.failure(error))
                    } else {
                        print("✅ Successfully updated invite code")
                        DispatchQueue.main.async {
                            self?.currentInviteCode = updatedCode
                        }
                        completion(.success(updatedCode))
                    }
                }
            } catch {
                print("❌ Error encoding updated code: \(error)")
                completion(.failure(error))
            }
        }
    }
    
    // MARK: - Delete Invite Code (НОВЫЙ МЕТОД - для удаления кодов)
    func deleteInviteCode(for groupId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let docRef = db.collection("groups").document(groupId).collection("fanInviteCode").document("current")
        
        docRef.delete { [weak self] error in
            if let error = error {
                completion(.failure(error))
            } else {
                DispatchQueue.main.async {
                    self?.currentInviteCode = nil
                }
                completion(.success(()))
            }
        }
    }
    
    // MARK: - Validate Fan Invite Code
    func validateFanInviteCode(_ code: String, completion: @escaping (Result<FanInviteCode, Error>) -> Void) {
        let formattedCode = code.uppercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        print("🔍 Validating code: '\(formattedCode)'")
        
        // ✅ НОВЫЙ ПОДХОД: перебираем все группы вместо collectionGroup
        // Сначала получаем список групп
        db.collection("groups").getDocuments { [weak self] snapshot, error in
            if let error = error {
                print("❌ Error getting groups: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            guard let self = self else { return }
            guard let documents = snapshot?.documents, !documents.isEmpty else {
                print("❌ No groups found")
                completion(.failure(FanInviteError.invalidCode))
                return
            }
            
            print("📄 Found \(documents.count) groups to search")
            
            // Ищем код в каждой группе
            let group = DispatchGroup()
            var foundCode: FanInviteCode?
            var searchError: Error?
            
            for groupDoc in documents {
                group.enter()
                
                // ✅ ПРЯМОЙ ЗАПРОС К КОНКРЕТНОЙ ГРУППЕ - НЕ ТРЕБУЕТ ИНДЕКСА
                self.db.collection("groups")
                    .document(groupDoc.documentID)
                    .collection("fanInviteCode")
                    .document("current")
                    .getDocument { docSnapshot, docError in
                        defer { group.leave() }
                        
                        if let docError = docError {
                            print("❌ Error getting invite code for group \(groupDoc.documentID): \(docError)")
                            searchError = docError
                            return
                        }
                        
                        guard let docSnapshot = docSnapshot,
                              docSnapshot.exists,
                              let data = docSnapshot.data() else {
                            return
                        }
                        
                        // Проверяем соответствие кода
                        if let storedCode = data["code"] as? String,
                           storedCode.uppercased() == formattedCode {
                            
                            print("✅ Found matching code in group \(groupDoc.documentID)")
                            
                            do {
                                let inviteCode = try docSnapshot.data(as: FanInviteCode.self)
                                foundCode = inviteCode
                            } catch {
                                print("❌ Error parsing FanInviteCode: \(error)")
                                searchError = error
                            }
                        }
                    }
            }
            
            group.notify(queue: .main) {
                if let error = searchError {
                    completion(.failure(error))
                    return
                }
                
                guard let inviteCode = foundCode else {
                    print("❌ No matching invite code found")
                    completion(.failure(FanInviteError.invalidCode))
                    return
                }
                
                print("✅ Successfully found FanInviteCode: \(inviteCode.code)")
                
                // ✅ ПРОВЕРЯЕМ isActive ЛОКАЛЬНО
                if !inviteCode.isActive {
                    print("❌ Code is not active")
                    completion(.failure(FanInviteError.codeExpired))
                    return
                }
                
                // Check if code can still be used
                if !inviteCode.canBeUsed {
                    print("❌ Code expired or reached max uses")
                    completion(.failure(FanInviteError.codeExpired))
                    return
                }
                
                print("✅ Code is valid and can be used")
                completion(.success(inviteCode))
            }
        }
    }
    
    // MARK: - Join Fan Club
    func joinFanClub(inviteCode: FanInviteCode, fanProfile: FanProfile, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            completion(.failure(FanInviteError.userNotAuthenticated))
            return
        }
        
        // Check if user is already a fan of this group
        let userRef = db.collection("users").document(currentUserId)
        
        userRef.getDocument { [weak self] snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            // Check if user already has fanGroupId
            if let userData = snapshot?.data(),
               let existingGroupId = userData["fanGroupId"] as? String,
               existingGroupId == inviteCode.groupId {
                completion(.failure(FanInviteError.alreadyAFan))
                return
            }
            
            self?.performJoinFanClub(inviteCode: inviteCode, fanProfile: fanProfile, userId: currentUserId, completion: completion)
        }
    }
    
    private func performJoinFanClub(inviteCode: FanInviteCode, fanProfile: FanProfile, userId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let batch = db.batch()
        
        // 1. Update user profile to include fan information
        let userRef = db.collection("users").document(userId)
        let userUpdateData: [String: Any] = [
            "userType": UserType.fan.rawValue,
            "fanGroupId": inviteCode.groupId,
            "fanProfile": [
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
        ]
        batch.updateData(userUpdateData, forDocument: userRef)
        
        // 2. Increment invite code usage
        let inviteRef = db.collection("groups").document(inviteCode.groupId).collection("fanInviteCode").document("current")
        batch.updateData(["currentUses": FieldValue.increment(Int64(1))], forDocument: inviteRef)
        
        // 3. Add fan to group's fan list
        let fanRef = db.collection("groups").document(inviteCode.groupId).collection("fans").document(userId)
        let fanData: [String: Any] = [
            "userId": userId,
            "nickname": fanProfile.nickname,
            "joinDate": Timestamp(date: fanProfile.joinDate),
            "level": fanProfile.level.rawValue,
            "isActive": true,
            "isModerator": false
        ]
        batch.setData(fanData, forDocument: fanRef)
        
        // Commit batch
        batch.commit { error in
            if let error = error {
                completion(.failure(error))
            } else {
                // Setup default achievements for the new fan
                self.setupDefaultAchievements(for: userId, groupId: inviteCode.groupId)
                completion(.success(()))
            }
        }
    }
    
    // MARK: - Get Current Invite Code
    func getCurrentInviteCode(for groupId: String, completion: @escaping (Result<FanInviteCode?, Error>) -> Void) {
        db.collection("groups").document(groupId).collection("fanInviteCode").document("current")
            .getDocument { [weak self] snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let snapshot = snapshot, snapshot.exists else {
                    completion(.success(nil))
                    return
                }
                
                do {
                    let inviteCode = try snapshot.data(as: FanInviteCode.self)
                    DispatchQueue.main.async {
                        self?.currentInviteCode = inviteCode
                    }
                    completion(.success(inviteCode))
                } catch {
                    completion(.failure(error))
                }
            }
    }
    
    // MARK: - Regenerate Invite Code (УСТАРЕВШИЙ МЕТОД - теперь используется updateCustomInviteCode)
    func regenerateInviteCode(for groupId: String, groupName: String, completion: @escaping (Result<FanInviteCode, Error>) -> Void) {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            completion(.failure(FanInviteError.userNotAuthenticated))
            return
        }
        
        // Deactivate old code first
        let docRef = db.collection("groups").document(groupId).collection("fanInviteCode").document("current")
        
        docRef.updateData(["isActive": false]) { error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            // Generate new code
            self.generateFanInviteCode(for: groupId, groupName: groupName, completion: completion)
        }
    }
    
    // MARK: - Private Helper Methods
    private func generateUniqueCode() -> String {
        let letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        let prefix = "BAND"
        let suffix = String((0..<4).map { _ in letters.randomElement()! })
        return prefix + suffix
    }
    
    private func setupDefaultAchievements(for fanId: String, groupId: String) {
        let batch = db.batch()
        
        // Настройка базовых достижений для нового фаната
        let defaultAchievements = [
            "first_join": false,
            "first_message": false,
            "first_concert": false,
            "loyal_fan": false
        ]
        
        for (achievementId, isUnlocked) in defaultAchievements {
            let achievementRef = db.collection("groups").document(groupId).collection("fanAchievements").document("\(fanId)_\(achievementId)")
            let achievementData: [String: Any] = [
                "fanId": fanId,
                "achievementId": achievementId,
                "isUnlocked": isUnlocked,
                "unlockedDate": isUnlocked ? Timestamp(date: Date()) : NSNull(),
                "progress": isUnlocked ? 1.0 : 0.0
            ]
            batch.setData(achievementData, forDocument: achievementRef)
        }
        
        batch.commit { error in
            if let error = error {
                print("Error setting up default achievements: \(error.localizedDescription)")
            } else {
                print("✅ Default achievements set up for fan: \(fanId)")
            }
        }
    }
}

// MARK: - Fan Invite Errors
enum FanInviteError: LocalizedError {
    case userNotAuthenticated
    case invalidCode
    case codeExpired
    case alreadyAFan
    case groupNotFound
    
    var errorDescription: String? {
        switch self {
        case .userNotAuthenticated:
            return "User not authenticated"
        case .invalidCode:
            return "Invalid invite code"
        case .codeExpired:
            return "Invite code expired or reached maximum uses"
        case .alreadyAFan:
            return "You are already a fan of this group"
        case .groupNotFound:
            return "Group not found"
        }
    }
}
