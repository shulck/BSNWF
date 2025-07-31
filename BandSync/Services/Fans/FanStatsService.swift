import Foundation
import FirebaseFirestore
import Combine

final class FanStatsService: ObservableObject {
    static let shared = FanStatsService()
    private let db = Firestore.firestore()
    
    private init() {}
    
    /// Увеличивает счетчик посещенных концертов и проверяет достижения
    func markConcertAttended(fanId: String, groupId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let fanRef = db.collection("users").document(fanId)
        
        // Обновляем статистику в Firebase
        fanRef.updateData([
            "fanProfile.stats.concertsAttended": FieldValue.increment(Int64(1)),
            "fanProfile.stats.lastActive": Timestamp(date: Date())
        ]) { [weak self] error in
            if let error = error {
                print("❌ Failed to update concert attendance: \(error)")
                completion(.failure(error))
                return
            }
            
            print("✅ Concert attendance updated in Firebase")
            // После успешного обновления - получаем новую статистику и проверяем достижения
            self?.fetchUpdatedStatsAndCheckAchievements(fanId: fanId, groupId: groupId, completion: completion)
        }
    }
    
    /// Получает обновленную статистику и запускает проверку достижений
    private func fetchUpdatedStatsAndCheckAchievements(fanId: String, groupId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let fanRef = db.collection("users").document(fanId)
        
        fanRef.getDocument { document, error in
            if let error = error {
                print("❌ Failed to fetch updated stats: \(error)")
                completion(.failure(error))
                return
            }
            
            guard let document = document,
                  let data = document.data(),
                  let fanProfileData = data["fanProfile"] as? [String: Any] else {
                let error = NSError(domain: "FanStatsService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to parse fan profile"])
                completion(.failure(error))
                return
            }
            
            // Парсим обновленный профиль фаната
            guard let fanProfile = self.parseFanProfile(from: fanProfileData) else {
                let error = NSError(domain: "FanStatsService", code: -2, userInfo: [NSLocalizedDescriptionKey: "Failed to parse fan profile data"])
                completion(.failure(error))
                return
            }
            
            print("✅ Updated fan stats - concerts attended: \(fanProfile.stats.concertsAttended)")
            
            // Обновляем локальные данные пользователя
            DispatchQueue.main.async {
                if var currentUser = AppState.shared.user {
                    currentUser.fanProfile = fanProfile
                    AppState.shared.user = currentUser
                    print("✅ Local user profile updated")
                }
            }
            
            // Запускаем проверку достижений
            print("🏆 Checking achievements...")
            FanAchievementService.shared.checkAndUnlockAchievements(
                for: fanId,
                groupId: groupId,
                stats: fanProfile.stats,
                fanProfile: fanProfile
            )
            
            completion(.success(()))
        }
    }
    
    /// Парсит профиль фаната из данных Firebase
    private func parseFanProfile(from data: [String: Any]) -> FanProfile? {
        guard let nickname = data["nickname"] as? String,
              let joinDateTimestamp = data["joinDate"] as? Timestamp,
              let location = data["location"] as? String,
              let favoriteSong = data["favoriteSong"] as? String else {
            return nil
        }
        
        let joinDate = joinDateTimestamp.dateValue()
        let levelString = data["level"] as? String ?? "Newbie"
        let level = FanLevel(rawValue: levelString) ?? .newbie
        let achievements = data["achievements"] as? [String] ?? []
        let isModerator = data["isModerator"] as? Bool ?? false
        
        var stats = FanStats()
        if let statsDict = data["stats"] as? [String: Any] {
            stats = FanStats(
                totalMessages: statsDict["totalMessages"] as? Int ?? 0,
                joinDate: (statsDict["joinDate"] as? Timestamp)?.dateValue() ?? joinDate,
                lastActive: (statsDict["lastActive"] as? Timestamp)?.dateValue() ?? Date(),
                merchandisePurchased: statsDict["merchandisePurchased"] as? Int ?? 0,
                concertsAttended: statsDict["concertsAttended"] as? Int ?? 0,
                achievementsUnlocked: statsDict["achievementsUnlocked"] as? Int ?? 0
            )
        }
        
        var notificationSettings = FanNotificationSettings()
        if let settingsDict = data["notificationSettings"] as? [String: Any] {
            notificationSettings = FanNotificationSettings(
                newConcerts: settingsDict["newConcerts"] as? Bool ?? true,
                officialNews: settingsDict["officialNews"] as? Bool ?? true,
                chatMessages: settingsDict["chatMessages"] as? Bool ?? true,
                newMerch: settingsDict["newMerch"] as? Bool ?? false,
                achievements: settingsDict["achievements"] as? Bool ?? true,
                moderatorActions: settingsDict["moderatorActions"] as? Bool ?? true
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
}
