//
//  FanInviteService.swift
//  BandSyncApp
//
//  Created by Oleksandr Kuziakin on 27.07.2025.
//


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
    
    // MARK: - Generate Fan Invite Code
    func generateFanInviteCode(for groupId: String, groupName: String, completion: @escaping (Result<FanInviteCode, Error>) -> Void) {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            completion(.failure(FanInviteError.userNotAuthenticated))
            return
        }
        
        // Generate unique code
        let code = generateUniqueCode()
        
        let inviteCode = FanInviteCode(
            groupId: groupId,
            code: code,
            createdBy: currentUserId,
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
    
    // MARK: - Validate Fan Invite Code
    func validateFanInviteCode(_ code: String, completion: @escaping (Result<FanInviteCode, Error>) -> Void) {
        let formattedCode = code.uppercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        db.collectionGroup("fanInviteCode")
            .whereField("code", isEqualTo: formattedCode)
            .whereField("isActive", isEqualTo: true)
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let documents = snapshot?.documents, !documents.isEmpty else {
                    completion(.failure(FanInviteError.invalidCode))
                    return
                }
                
                // Take the first matching document
                let document = documents[0]
                do {
                    let inviteCode = try document.data(as: FanInviteCode.self)
                    
                    if inviteCode.canBeUsed {
                        completion(.success(inviteCode))
                    } else {
                        completion(.failure(FanInviteError.codeExpired))
                    }
                } catch {
                    completion(.failure(error))
                }
            }
    }
    
    // MARK: - Join Fan Club
    func joinFanClub(inviteCode: FanInviteCode, fanProfile: FanProfile, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            completion(.failure(FanInviteError.userNotAuthenticated))
            return
        }
        
        let batch = db.batch()
        
        // 1. Update user document to become a fan
        let userRef = db.collection("users").document(currentUserId)
        let userUpdates: [String: Any] = [
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
        batch.updateData(userUpdates, forDocument: userRef)
        
        // 2. Increment invite code usage
        let inviteRef = db.collection("groups").document(inviteCode.groupId).collection("fanInviteCode").document("current")
        batch.updateData(["currentUses": FieldValue.increment(Int64(1))], forDocument: inviteRef)
        
        // 3. Add fan to group's fan list
        let fanRef = db.collection("groups").document(inviteCode.groupId).collection("fans").document(currentUserId)
        let fanData: [String: Any] = [
            "userId": currentUserId,
            "nickname": fanProfile.nickname,
            "joinDate": Timestamp(date: fanProfile.joinDate),
            "level": fanProfile.level.rawValue,
            "isActive": true,
            "isModerator": false
        ]
        batch.setData(fanData, forDocument: fanRef)
        
        // 4. Check if eligible for "early adopter" achievement
        let currentUses = inviteCode.currentUses + 1
        if currentUses <= 100 {
            // This fan is among the first 100
            let achievementRef = db.collection("groups").document(inviteCode.groupId).collection("fanAchievements").document(currentUserId)
            let achievementData: [String: Any] = [
                "fanId": currentUserId,
                "achievementId": "early_adopter",
                "isUnlocked": true,
                "unlockedDate": Timestamp(date: Date()),
                "progress": 1.0
            ]
            batch.setData(achievementData, forDocument: achievementRef, merge: true)
        }
        
        // Commit batch
        batch.commit { error in
            if let error = error {
                completion(.failure(error))
            } else {
                // Setup default achievements for the new fan
                self.setupDefaultAchievements(for: currentUserId, groupId: inviteCode.groupId)
                completion(.success(()))
            }
        }
    }
    
    // MARK: - Get Current Invite Code
    func getCurrentInviteCode(for groupId: String, completion: @escaping (Result<FanInviteCode?, Error>) -> Void) {
        db.collection("groups").document(groupId).collection("fanInviteCode").document("current")
            .getDocument { snapshot, error in
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
                        self.currentInviteCode = inviteCode
                    }
                    completion(.success(inviteCode))
                } catch {
                    completion(.failure(error))
                }
            }
    }
    
    // MARK: - Regenerate Invite Code
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
        
        for achievement in Achievement.defaults {
            let achievementRef = db.collection("groups").document(groupId).collection("fanAchievements").document("\(fanId)_\(achievement.id)")
            let achievementData: [String: Any] = [
                "fanId": fanId,
                "achievementId": achievement.id,
                "isUnlocked": false,
                "unlockedDate": NSNull(),
                "progress": 0.0
            ]
            batch.setData(achievementData, forDocument: achievementRef)
        }
        
        batch.commit { error in
            if let error = error {
                print("Error setting up default achievements: \(error.localizedDescription)")
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
            return "User not authenticated".localized
        case .invalidCode:
            return "Invalid invite code".localized
        case .codeExpired:
            return "Invite code expired or reached maximum uses".localized
        case .alreadyAFan:
            return "You are already a fan of this group".localized
        case .groupNotFound:
            return "Group not found".localized
        }
    }
}