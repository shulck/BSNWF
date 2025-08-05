import UIKit
import FirebaseCore
import FirebaseAuth
import FirebaseMessaging
import UserNotifications
import GoogleSignIn

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate, MessagingDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        FirebaseApp.configure()
        FirebaseManager.shared.markAsInitialized()
        
        initGoogleSignIn()
        setupNotifications()
        registerForPushNotifications()
        
        return true
    }
    
    private func setupNotifications() {
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        
        Messaging.messaging().delegate = self
        setupNotificationCategories()
    }
    
    private func setupNotificationCategories() {
        let chatAction = UNNotificationAction(
            identifier: "REPLY_ACTION",
            title: "Reply",
            options: [.foreground]
        )
        
        let markReadAction = UNNotificationAction(
            identifier: "MARK_READ_ACTION",
            title: "Mark as Read",
            options: []
        )
        
        let chatCategory = UNNotificationCategory(
            identifier: "CHAT_NOTIFICATION",
            actions: [chatAction, markReadAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )
        
        let mentionCategory = UNNotificationCategory(
            identifier: "MENTION_NOTIFICATION",
            actions: [chatAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )
        
        // Fan Chat Categories
        let fanChatAction = UNNotificationAction(
            identifier: "FAN_REPLY_ACTION",
            title: "Reply",
            options: [.foreground]
        )
        
        let fanAnnouncementCategory = UNNotificationCategory(
            identifier: "FAN_ANNOUNCEMENT",
            actions: [markReadAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )
        
        let fanChatCategory = UNNotificationCategory(
            identifier: "FAN_CHAT_MESSAGE",
            actions: [fanChatAction, markReadAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )
        
        let mixedChatCategory = UNNotificationCategory(
            identifier: "MIXED_CHAT_MESSAGE",
            actions: [fanChatAction, markReadAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )
        
        let taskCompleteAction = UNNotificationAction(
            identifier: "COMPLETE_TASK_ACTION",
            title: "Complete",
            options: []
        )
        
        let taskViewAction = UNNotificationAction(
            identifier: "VIEW_TASK_ACTION",
            title: "View",
            options: [.foreground]
        )
        
        let taskCategory = UNNotificationCategory(
            identifier: "TASK_NOTIFICATION",
            actions: [taskCompleteAction, taskViewAction],
            intentIdentifiers: [],
            options: []
        )
        
        let eventViewAction = UNNotificationAction(
            identifier: "VIEW_EVENT_ACTION",
            title: "View Event",
            options: [.foreground]
        )
        
        let eventCategory = UNNotificationCategory(
            identifier: "EVENT_NOTIFICATION",
            actions: [eventViewAction],
            intentIdentifiers: [],
            options: []
        )
        
        UNUserNotificationCenter.current().setNotificationCategories([
            chatCategory,
            mentionCategory,
            taskCategory,
            eventCategory,
            fanAnnouncementCategory,
            fanChatCategory,
            mixedChatCategory
        ])
    }
    
    private func registerForPushNotifications() {
        let options: UNAuthorizationOptions = [
            .alert,
            .sound,
            .badge,
            .provisional
        ]
        
        UNUserNotificationCenter.current().requestAuthorization(options: options) { granted, error in
            if granted {
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        }
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        print("✅ Successfully registered for remote notifications")
        print("📱 Device token: \(deviceToken.map { String(format: "%02.2hhx", $0) }.joined())")
        
        Messaging.messaging().apnsToken = deviceToken
        
        Messaging.messaging().token { token, error in
            if let token = token {
                print("🔥 FCM Token: \(token)")
                if let userId = Auth.auth().currentUser?.uid {
                    Task {
                        await FCMTokenManager.shared.saveToken(token, for: userId)
                    }
                } else {
                    print("⚠️ No authenticated user to save FCM token")
                }
            } else if let error = error {
                print("❌ Error getting FCM token: \(error.localizedDescription)")
            }
        }
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("❌ Failed to register for remote notifications: \(error.localizedDescription)")
        print("❌ Error details: \(error)")
    }
    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let fcmToken = fcmToken else { return }
        
        if let userId = Auth.auth().currentUser?.uid {
            Task {
                await FCMTokenManager.shared.saveToken(fcmToken, for: userId)
            }
        }
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .badge, .list])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        
        let userInfo = response.notification.request.content.userInfo
        let actionIdentifier = response.actionIdentifier
        
        switch actionIdentifier {
        case "REPLY_ACTION":
            handleReplyAction(userInfo: userInfo)
        case "FAN_REPLY_ACTION":
            handleFanReplyAction(userInfo: userInfo)
        case "MARK_READ_ACTION":
            handleMarkReadAction(userInfo: userInfo)
        case "COMPLETE_TASK_ACTION":
            handleCompleteTaskAction(userInfo: userInfo)
        case "VIEW_TASK_ACTION", "VIEW_EVENT_ACTION", UNNotificationDefaultActionIdentifier:
            handleNotificationTap(userInfo: userInfo)
        default:
            handleNotificationTap(userInfo: userInfo)
        }
        
        completionHandler()
    }
    
    private func handleNotificationTap(userInfo: [AnyHashable: Any]) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            guard let type = userInfo["type"] as? String else { return }
            
            switch type {
            case "event":
                if let eventId = userInfo["eventId"] as? String {
                    NotificationCenter.default.post(
                        name: NSNotification.Name("OpenEventNotification"),
                        object: nil,
                        userInfo: ["eventId": eventId]
                    )
                }
                
            case "task":
                if let taskId = userInfo["taskId"] as? String {
                    NotificationCenter.default.post(
                        name: NSNotification.Name("OpenTaskNotification"),
                        object: nil,
                        userInfo: ["taskId": taskId]
                    )
                }
                
            case "chat", "mention":
                if let chatId = userInfo["chatId"] as? String {
                    let messageId = userInfo["messageId"] as? String
                    NotificationCenter.default.post(
                        name: NSNotification.Name("OpenChatNotification"),
                        object: nil,
                        userInfo: [
                            "chatId": chatId,
                            "messageId": messageId ?? "",
                            "shouldHighlight": type == "mention"
                        ]
                    )
                }
                
            default:
                break
            }
        }
    }
    
    private func handleReplyAction(userInfo: [AnyHashable: Any]) {
        handleNotificationTap(userInfo: userInfo)
    }
    
    private func handleMarkReadAction(userInfo: [AnyHashable: Any]) {
        if let _ = userInfo["chatId"] as? String,
           let messageId = userInfo["messageId"] as? String,
           let userId = Auth.auth().currentUser?.uid {
            
            ChatService.shared.markMessageAsRead(messageId, userId: userId) { result in
            }
        }
    }
    
    private func handleCompleteTaskAction(userInfo: [AnyHashable: Any]) {
        if let taskId = userInfo["taskId"] as? String {
            if let task = TaskService.shared.tasks.first(where: { $0.id == taskId }) {
                TaskService.shared.toggleCompletion(task)
            }
        }
    }
    
    private func initGoogleSignIn() {
        GIDSignIn.sharedInstance.restorePreviousSignIn { user, error in
            if let user = user {
                GoogleDriveService.shared.updateAuthenticatedState(user: user)
            }
        }
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        return GIDSignIn.sharedInstance.handle(url)
    }
    
    // MARK: - Fan Chat Notification Handlers
    
    private func handleFanReplyAction(userInfo: [AnyHashable: Any]) {
        guard let chatId = userInfo["fanChatId"] as? String,
              let chatType = userInfo["fanChatType"] as? String else {
            return
        }
        
        // Navigate to fan chat
        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: NSNotification.Name("NavigateToFanChat"),
                object: nil,
                userInfo: ["chatId": chatId, "chatType": chatType]
            )
        }
    }
    
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        if let urlContext = options.urlContexts.first {
            let url = urlContext.url
            GIDSignIn.sharedInstance.handle(url)
        }
        
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
    
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        if let urlContext = URLContexts.first {
            let url = urlContext.url
            GIDSignIn.sharedInstance.handle(url)
        }
    }
}
