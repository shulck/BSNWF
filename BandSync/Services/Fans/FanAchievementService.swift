//
//  FanAchievementService.swift
//  BandSyncApp
//
//  Created by Oleksandr Kuziakin on 31.07.2025.
//


//
//  FanAchievementService.swift
//  BandSync
//
//  Created by Claude on 31.07.2025.
//

import Foundation
import FirebaseFirestore
import Combine

final class FanAchievementService: ObservableObject {
    static let shared = FanAchievementService()
    
    @Published var fanAchievements: [String: Bool] = [:] // achievementId -> isUnlocked
    @Published var recentlyUnlocked: [Achievement] = []
    @Published var totalPoints: Int = 0
    
    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// Загружает достижения для текущего фаната
    func loadFanAchievements(fanId: String, groupId: String) {
        // Останавливаем предыдущий listener
        listener?.remove()
        
        // Слушаем изменения достижений в реальном времени
        listener = db.collection("groups").document(groupId)
            .collection("fanAchievements")
            .whereField("fanId", isEqualTo: fanId)
            .addSnapshotListener { [weak self] snapshot, error in
                if let error = error {
                    print("❌ Error loading fan achievements: \(error)")
                    return
                }
                
                self?.processFanAchievements(snapshot?.documents ?? [])
            }
    }
    
    /// Проверяет и разблокирует достижения на основе статистики фаната
    func checkAndUnlockAchievements(for fanId: String, groupId: String, stats: FanStats, fanProfile: FanProfile) {
        let batch = db.batch()
        var newlyUnlocked: [Achievement] = []
        
        // Проверяем каждое достижение из списка по умолчанию
        for achievement in Achievement.defaults {
            let achievementRef = db.collection("groups").document(groupId)
                .collection("fanAchievements")
                .document("\(fanId)_\(achievement.id)")
            
            // Проверяем, выполнены ли требования
            if shouldUnlockAchievement(achievement, stats: stats, fanProfile: fanProfile) {
                // Проверяем, не разблокировано ли уже
                if fanAchievements[achievement.id] != true {
                    let achievementData: [String: Any] = [
                        "fanId": fanId,
                        "achievementId": achievement.id,
                        "isUnlocked": true,
                        "unlockedDate": Timestamp(date: Date()),
                        "progress": 1.0,
                        "points": achievement.points
                    ]
                    
                    batch.setData(achievementData, forDocument: achievementRef, merge: true)
                    newlyUnlocked.append(achievement)
                    
                    print("🏆 New achievement unlocked: \(achievement.title)")
                }
            } else {
                // Обновляем прогресс для недостигнутых целей
                let progress = calculateProgress(for: achievement, stats: stats, fanProfile: fanProfile)
                let achievementData: [String: Any] = [
                    "fanId": fanId,
                    "achievementId": achievement.id,
                    "isUnlocked": false,
                    "progress": progress,
                    "points": 0
                ]
                
                batch.setData(achievementData, forDocument: achievementRef, merge: true)
            }
        }
        
        // Применяем изменения
        batch.commit { [weak self] error in
            if let error = error {
                print("❌ Error updating achievements: \(error)")
                return
            }
            
            DispatchQueue.main.async {
                // Добавляем новые достижения к списку недавно разблокированных
                self?.recentlyUnlocked.append(contentsOf: newlyUnlocked)
                
                // Показываем уведомления о новых достижениях
                for achievement in newlyUnlocked {
                    self?.showAchievementNotification(achievement)
                }
            }
        }
    }
    
    /// Очищает список недавно разблокированных достижений
    func clearRecentlyUnlocked() {
        recentlyUnlocked.removeAll()
    }
    
    /// Останавливает мониторинг достижений
    func stopMonitoring() {
        listener?.remove()
        listener = nil
    }
    
    // MARK: - Private Methods
    
    private func processFanAchievements(_ documents: [QueryDocumentSnapshot]) {
        var achievements: [String: Bool] = [:]
        var points = 0
        
        for doc in documents {
            let data = doc.data()
            if let achievementId = data["achievementId"] as? String,
               let isUnlocked = data["isUnlocked"] as? Bool {
                achievements[achievementId] = isUnlocked
                
                if isUnlocked, let achievementPoints = data["points"] as? Int {
                    points += achievementPoints
                }
            }
        }
        
        DispatchQueue.main.async {
            self.fanAchievements = achievements
            self.totalPoints = points
        }
    }
    
    private func shouldUnlockAchievement(_ achievement: Achievement, stats: FanStats, fanProfile: FanProfile) -> Bool {
        let requirements = achievement.requirements
        
        // Проверяем концерты
        if let requiredConcerts = requirements.concertsAttended {
            if stats.concertsAttended < requiredConcerts {
                return false
            }
        }
        
        // Проверяем дни с момента регистрации
        if let requiredDays = requirements.daysSinceJoining {
            if fanProfile.daysSinceJoining < requiredDays {
                return false
            }
        }
        
        // Проверяем количество сообщений
        if let requiredMessages = requirements.messagesCount {
            if stats.totalMessages < requiredMessages {
                return false
            }
        }
        
        // Проверяем покупки мерча
        if let requiredPurchases = requirements.merchPurchases {
            if stats.merchandisePurchased < requiredPurchases {
                return false
            }
        }
        
        // Проверяем "среди первых" (это проверяется отдельно при регистрации)
        if requirements.isAmongFirst != nil {
            // Это достижение должно быть разблокировано при регистрации
            return fanAchievements[achievement.id] == true
        }
        
        return true
    }
    
    private func calculateProgress(for achievement: Achievement, stats: FanStats, fanProfile: FanProfile) -> Double {
        let requirements = achievement.requirements
        
        if let requiredConcerts = requirements.concertsAttended {
            return min(1.0, Double(stats.concertsAttended) / Double(requiredConcerts))
        }
        
        if let requiredDays = requirements.daysSinceJoining {
            return min(1.0, Double(fanProfile.daysSinceJoining) / Double(requiredDays))
        }
        
        if let requiredMessages = requirements.messagesCount {
            return min(1.0, Double(stats.totalMessages) / Double(requiredMessages))
        }
        
        if let requiredPurchases = requirements.merchPurchases {
            return min(1.0, Double(stats.merchandisePurchased) / Double(requiredPurchases))
        }
        
        return 0.0
    }
    
    private func showAchievementNotification(_ achievement: Achievement) {
        // Здесь можно добавить системное уведомление или показать в UI
        print("🎉 Achievement Unlocked: \(achievement.title) - \(achievement.description)")
        
        // Можно добавить HapticFeedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }
}

// MARK: - Convenience Methods
extension FanAchievementService {
    
    /// Получает процент выполнения конкретного достижения
    func getAchievementProgress(achievementId: String, stats: FanStats, fanProfile: FanProfile) -> Double {
        guard let achievement = Achievement.defaults.first(where: { $0.id == achievementId }) else {
            return 0.0
        }
        
        if fanAchievements[achievementId] == true {
            return 1.0
        }
        
        return calculateProgress(for: achievement, stats: stats, fanProfile: fanProfile)
    }
    
    /// Проверяет, разблокировано ли достижение
    func isAchievementUnlocked(_ achievementId: String) -> Bool {
        return fanAchievements[achievementId] == true
    }
    
    /// Получает список всех достижений с их статусом
    func getAllAchievementsWithStatus(stats: FanStats, fanProfile: FanProfile) -> [(achievement: Achievement, isUnlocked: Bool, progress: Double)] {
        return Achievement.defaults.map { achievement in
            let isUnlocked = fanAchievements[achievement.id] == true
            let progress = isUnlocked ? 1.0 : calculateProgress(for: achievement, stats: stats, fanProfile: fanProfile)
            return (achievement, isUnlocked, progress)
        }
    }
}
