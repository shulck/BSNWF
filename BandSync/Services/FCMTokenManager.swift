import Firebase
import FirebaseAuth
import FirebaseFirestore
import FirebaseMessaging
import UIKit

class FCMTokenManager: NSObject {
    static let shared = FCMTokenManager()
    private let db = Firestore.firestore()
    private var isSetupInProgress = false
    private var setupCompletedForUsers: Set<String> = []
    
    override private init() {}
    
    func setupFCM(for userId: String) {
        guard !setupCompletedForUsers.contains(userId) else {
            return
        }
        
        guard !isSetupInProgress else {
            return
        }
        
        isSetupInProgress = true
        setupCompletedForUsers.insert(userId)
        
        Messaging.messaging().delegate = self
        performOneTimeCleanup(for: userId)
        updateCurrentToken(for: userId)
        
        // Setup fan chat notification topics
        setupFanChatTopics(for: userId)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.isSetupInProgress = false
        }
    }
    
    private func performOneTimeCleanup(for userId: String) {
        let cleanupKey = "fcm_cleanup_done_\(userId)"
        
        guard !UserDefaults.standard.bool(forKey: cleanupKey) else {
            return
        }
        
        Task {
            await cleanupOldTokens(for: userId)
            UserDefaults.standard.set(true, forKey: cleanupKey)
        }
    }
    
    private func cleanupOldTokens(for userId: String) async {
        do {
            let userRef = db.collection("users").document(userId)
            let document = try await userRef.getDocument()
            
            guard let data = document.data(),
                  let fcmTokens = data["fcmTokens"] as? [[String: Any]] else {
                return
            }
            
            let sortedTokens = fcmTokens.sorted { token1, token2 in
                let time1 = token1["lastUpdated"] as? TimeInterval ?? 0
                let time2 = token2["lastUpdated"] as? TimeInterval ?? 0
                return time1 > time2
            }
            
            var cleanTokens: [[String: Any]] = []
            var seenTokens: Set<String> = []
            
            for token in sortedTokens {
                guard let tokenValue = token["token"] as? String else { continue }
                
                if !seenTokens.contains(tokenValue) && cleanTokens.count < 2 {
                    seenTokens.insert(tokenValue)
                    cleanTokens.append(token)
                }
            }
            
            if cleanTokens.count != fcmTokens.count {
                try await userRef.updateData([
                    "fcmTokens": cleanTokens,
                    "fcmTokenUpdated": FieldValue.serverTimestamp()
                ])
            }
            
        } catch {
        }
    }
    
    private func updateCurrentToken(for userId: String) {
        Messaging.messaging().token { [weak self] token, error in
            guard let self = self, let token = token else {
                return
            }
            
            Task {
                await self.saveToken(token, for: userId)
            }
        }
    }
    
    func saveToken(_ token: String, for userId: String) async {
        print("🔥 FCMTokenManager: Saving token for user \(userId)")
        print("🔥 Token: \(token)")
        
        do {
            let userRef = db.collection("users").document(userId)
            
            let currentTimestamp = CFAbsoluteTimeGetCurrent() + kCFAbsoluteTimeIntervalSince1970
            let tokenData: [String: Any] = [
                "token": token,
                "device": await UIDevice.current.model,
                "platform": "iOS",
                "systemVersion": await UIDevice.current.systemVersion,
                "lastUpdated": currentTimestamp
            ]
            
            let document = try await userRef.getDocument()
            var fcmTokens = document.data()?["fcmTokens"] as? [[String: Any]] ?? []
            
            fcmTokens.removeAll { existingToken in
                (existingToken["token"] as? String) == token
            }
            
            fcmTokens.append(tokenData)
            
            if fcmTokens.count > 3 {
                fcmTokens.sort { token1, token2 in
                    let time1 = token1["lastUpdated"] as? TimeInterval ?? 0
                    let time2 = token2["lastUpdated"] as? TimeInterval ?? 0
                    return time1 > time2
                }
                fcmTokens = Array(fcmTokens.prefix(3))
            }
            
            try await userRef.updateData([
                "fcmToken": token,
                "fcmTokens": fcmTokens,
                "fcmTokenUpdated": FieldValue.serverTimestamp()
            ])
            
            print("✅ FCMTokenManager: Token saved successfully to Firestore")
            
        } catch {
            print("❌ FCMTokenManager: Error saving token: \(error.localizedDescription)")
        }
    }
    
    func resetForUser(_ userId: String) {
        setupCompletedForUsers.remove(userId)
    }
    
    // MARK: - Fan Chat Notifications
    
    /// Setup notification topics for fan chat
    private func setupFanChatTopics(for userId: String) {
        // Subscribe to general fan notifications topic
        if let user = AppState.shared.user,
           let groupId = user.userType == .fan ? user.fanGroupId : user.groupId {
            let fanTopic = "fan_chat_\(groupId)"
            Messaging.messaging().subscribe(toTopic: fanTopic) { error in
                if let error = error {
                    print("Error subscribing to fan chat topic: \(error)")
                } else {
                    print("Subscribed to fan chat topic: \(fanTopic)")
                }
            }
            
            // Subscribe to user-specific fan notifications
            let userFanTopic = "fan_\(userId)_\(groupId)"
            Messaging.messaging().subscribe(toTopic: userFanTopic) { error in
                if let error = error {
                    print("Error subscribing to user fan topic: \(error)")
                } else {
                    print("Subscribed to user fan topic: \(userFanTopic)")
                }
            }
        }
    }
    
    /// Subscribe to specific fan chat notifications
    func subscribeToFanChat(chatId: String, userId: String) {
        let topic = "fan_chat_messages_\(chatId)"
        Messaging.messaging().subscribe(toTopic: topic) { error in
            if let error = error {
                print("Error subscribing to fan chat: \(error)")
            } else {
                print("Subscribed to fan chat: \(topic)")
            }
        }
    }
    
    /// Unsubscribe from fan chat notifications
    func unsubscribeFromFanChat(chatId: String) {
        let topic = "fan_chat_messages_\(chatId)"
        Messaging.messaging().unsubscribe(fromTopic: topic) { error in
            if let error = error {
                print("Error unsubscribing from fan chat: \(error)")
            } else {
                print("Unsubscribed from fan chat: \(topic)")
            }
        }
    }
    
    /// Send fan chat notification
    func sendFanChatNotification(
        to userIds: [String],
        chatName: String,
        senderName: String,
        message: String,
        chatId: String,
        isImportant: Bool = false
    ) {
        // This would be implemented on the server side
        // For now, we'll use local notifications
        DispatchQueue.main.async {
            FanChatNotificationManager.shared.sendLocalNotification(
                chatName: chatName,
                senderName: senderName,
                message: message,
                chatType: .general
            )
        }
    }

}

extension FCMTokenManager: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let fcmToken = fcmToken,
              let userId = Auth.auth().currentUser?.uid else {
            return
        }
        
        Task {
            await saveToken(fcmToken, for: userId)
        }
    }
}

extension FirebaseManager {
    func setupFCMTokens(for userId: String) {
        FCMTokenManager.shared.setupFCM(for: userId)
    }
}
