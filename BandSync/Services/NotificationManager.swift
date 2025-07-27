import Foundation
import UserNotifications
import UIKit
import FirebaseAuth

enum NotificationError: LocalizedError {
    case notificationsDisabled
    case invalidDate
    case duplicateNotification
    case permissionDenied
    case systemError(String)
    
    var errorDescription: String? {
        switch self {
        case .notificationsDisabled:
            return "Notifications are disabled in settings"
        case .invalidDate:
            return "Invalid or past date for notification"
        case .duplicateNotification:
            return "Notification already exists"
        case .permissionDenied:
            return "Notification permission denied"
        case .systemError(let message):
            return "System error: \(message)"
        }
    }
}

final class NotificationManager {
    static let shared = NotificationManager()
    
    private var recentNotifications: Set<String> = []
    private let notificationCacheLimit = 100
    private var lastCacheCleanup: Date = Date()
    private let cacheCleanupInterval: TimeInterval = 300
    
    private let notificationQueue = DispatchQueue(label: "com.bandsync.notifications", qos: .utility)
    private var pendingNotifications: [String: Date] = [:]
    
    struct Settings: Codable {
        var notificationsEnabled = false
        var soundEnabled = true
        var badgeEnabled = true
        
        var eventNotificationsEnabled = true
        var eventReminderHours = 1
        
        var taskNotificationsEnabled = true
        var taskReminderHours = 24
        
        var chatNotificationsEnabled = true
        var systemNotificationsEnabled = true
        
        var mentionNotificationsEnabled = true
        var directMessageNotificationsEnabled = true
        var groupMessageNotificationsEnabled = true
        var quietHoursEnabled = false
        var quietHoursStart = 22
        var quietHoursEnd = 8
    }
    
    private var settings: Settings {
        get {
            if let data = UserDefaults.standard.data(forKey: "notification_settings"),
               let decoded = try? JSONDecoder().decode(Settings.self, from: data) {
                return decoded
            }
            return Settings()
        }
        set {
            if let encoded = try? JSONEncoder().encode(newValue) {
                UserDefaults.standard.set(encoded, forKey: "notification_settings")
            }
        }
    }
    
    private init() {
        setupPeriodicCleanup()
        setupNotificationCategories()
        checkAndUpdateNotificationStatus()
    }
    
    // MARK: - Core Methods
    
    func requestPermission(completion: @escaping (Bool, Error?) -> Void) {
        let options: UNAuthorizationOptions = [
            .alert,
            .badge,
            .sound,
            .provisional
        ]
        
        UNUserNotificationCenter.current().requestAuthorization(options: options) { granted, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("NotificationManager: Failed to request permission: \(error.localizedDescription)")
                    completion(false, error)
                    return
                }
                
                var newSettings = self.settings
                newSettings.notificationsEnabled = granted
                self.settings = newSettings
                
                if granted {
                    print("NotificationManager: Permission granted")
                    UIApplication.shared.registerForRemoteNotifications()
                    
                    if let userId = Auth.auth().currentUser?.uid {
                        FCMTokenManager.shared.setupFCM(for: userId)
                    }
                    
                    print("NotificationManager: Setup completed successfully")
                } else {
                    print("NotificationManager: Permission denied by user")
                }
                completion(granted, nil)
            }
        }
    }
    
    func checkPermissionStatus(completion: @escaping (Bool, Error?) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                let granted = settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional
                var newSettings = self.settings
                newSettings.notificationsEnabled = granted
                self.settings = newSettings
                
                completion(granted, nil)
            }
        }
    }
    
    func requestPermissionIfNeeded(completion: @escaping (Bool) -> Void) {
        checkPermissionStatus { granted, _ in
            if !granted {
                self.requestPermission { newGranted, _ in
                    completion(newGranted)
                }
            } else {
                completion(true)
            }
        }
    }
    
    func getSettings() -> Settings {
        return settings
    }
    
    func updateSettings(_ newSettings: Settings) {
        settings = newSettings
    }
    
    // MARK: - Notification Scheduling
    
    func scheduleEventNotification(title: String, date: Date, eventId: String, completion: ((Bool, Error?) -> Void)? = nil) {
        print("NotificationManager: Attempting to schedule notification for event: \(eventId), title: \(title)")
        print("NotificationManager: Event date: \(date)")
        print("NotificationManager: Notifications enabled: \(settings.notificationsEnabled)")
        print("NotificationManager: Event notifications enabled: \(settings.eventNotificationsEnabled)")
        
        notificationQueue.async {
            guard self.settings.notificationsEnabled && self.settings.eventNotificationsEnabled else {
                print("NotificationManager: Notifications disabled - notificationsEnabled: \(self.settings.notificationsEnabled), eventNotificationsEnabled: \(self.settings.eventNotificationsEnabled)")
                DispatchQueue.main.async {
                    completion?(false, NotificationError.notificationsDisabled)
                }
                return
            }
            
            let reminderDate = Calendar.current.date(
                byAdding: .hour,
                value: -self.settings.eventReminderHours,
                to: date
            )
            
            guard let reminderDate = reminderDate, reminderDate > Date() else {
                DispatchQueue.main.async {
                    completion?(false, NotificationError.invalidDate)
                }
                return
            }
            
            let content = UNMutableNotificationContent()
            content.title = "Upcoming Event"
            content.body = title
            content.categoryIdentifier = "EVENT_NOTIFICATION"
            
            if self.settings.soundEnabled && !self.isInQuietHours(Date()) {
                content.sound = UNNotificationSound.default
            } else {
                content.sound = nil
            }
            
            if #available(iOS 15.0, *) {
                content.interruptionLevel = .timeSensitive
            }
            
            content.userInfo = [
                "type": "event",
                "eventId": eventId,
                "scheduledAt": Date().timeIntervalSince1970
            ]
            
            let trigger = UNCalendarNotificationTrigger(
                dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: reminderDate),
                repeats: false
            )
            
            let request = UNNotificationRequest(
                identifier: "event_\(eventId)",
                content: content,
                trigger: trigger
            )
            
            UNUserNotificationCenter.current().add(request) { error in
                DispatchQueue.main.async {
                    if let error = error {
                        print("NotificationManager: Failed to schedule event notification: \(error.localizedDescription)")
                        completion?(false, NotificationError.systemError(error.localizedDescription))
                    } else {
                        print("NotificationManager: Event notification scheduled for \(reminderDate)")
                        completion?(true, nil)
                    }
                }
            }
        }
    }
    
    func scheduleTaskNotification(title: String, dueDate: Date, taskId: String, completion: ((Bool, Error?) -> Void)? = nil) {
        notificationQueue.async {
            guard self.settings.notificationsEnabled && self.settings.taskNotificationsEnabled else {
                DispatchQueue.main.async {
                    completion?(false, NotificationError.notificationsDisabled)
                }
                return
            }
            
            let reminderDate = Calendar.current.date(
                byAdding: .hour,
                value: -self.settings.taskReminderHours,
                to: dueDate
            )
            
            guard let reminderDate = reminderDate, reminderDate > Date() else {
                DispatchQueue.main.async {
                    completion?(false, NotificationError.invalidDate)
                }
                return
            }
            
            let content = UNMutableNotificationContent()
            content.title = "Task Due Soon"
            content.body = title
            content.categoryIdentifier = "TASK_NOTIFICATION"
            
            if self.settings.soundEnabled && !self.isInQuietHours(Date()) {
                content.sound = UNNotificationSound.default
            } else {
                content.sound = nil
            }
            
            if #available(iOS 15.0, *) {
                content.interruptionLevel = .active
            }
            
            content.userInfo = [
                "type": "task",
                "taskId": taskId,
                "scheduledAt": Date().timeIntervalSince1970
            ]
            
            let trigger = UNCalendarNotificationTrigger(
                dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: reminderDate),
                repeats: false
            )
            
            let request = UNNotificationRequest(
                identifier: "task_\(taskId)",
                content: content,
                trigger: trigger
            )
            
            UNUserNotificationCenter.current().add(request) { error in
                DispatchQueue.main.async {
                    if let error = error {
                        print("NotificationManager: Failed to schedule task notification: \(error.localizedDescription)")
                        completion?(false, NotificationError.systemError(error.localizedDescription))
                    } else {
                        print("NotificationManager: Task notification scheduled for \(reminderDate)")
                        completion?(true, nil)
                    }
                }
            }
        }
    }
    
    // MARK: - Chat Notifications
    
    func sendChatNotification(
        from senderName: String,
        message: String,
        chatId: String,
        messageId: String,
        completion: ((Bool, Error?) -> Void)? = nil
    ) {
        notificationQueue.async {
            guard self.settings.notificationsEnabled && self.settings.chatNotificationsEnabled else {
                DispatchQueue.main.async {
                    completion?(false, NotificationError.notificationsDisabled)
                }
                return
            }
            
            let notificationKey = "chat_\(chatId)_\(messageId)"
            guard !self.recentNotifications.contains(notificationKey) else {
                DispatchQueue.main.async {
                    completion?(false, NotificationError.duplicateNotification)
                }
                return
            }
            
            if self.settings.quietHoursEnabled && self.isInQuietHours(Date()) {
                DispatchQueue.main.async {
                    completion?(false, NotificationError.systemError("Quiet hours active"))
                }
                return
            }
            
            self.recentNotifications.insert(notificationKey)
            self.cleanupCacheIfNeeded()
            
            let content = UNMutableNotificationContent()
            content.title = senderName
            content.body = message
            content.categoryIdentifier = "CHAT_NOTIFICATION"
            
            if self.settings.soundEnabled {
                content.sound = UNNotificationSound.default
                if #available(iOS 15.0, *) {
                    content.interruptionLevel = .active
                }
            } else {
                content.sound = nil
                if #available(iOS 15.0, *) {
                    content.interruptionLevel = .passive
                }
            }
            
            content.userInfo = [
                "type": "chat",
                "chatId": chatId,
                "messageId": messageId,
                "timestamp": Date().timeIntervalSince1970,
                "senderName": senderName
            ]
            
            let request = UNNotificationRequest(
                identifier: notificationKey,
                content: content,
                trigger: nil
            )
            
            UNUserNotificationCenter.current().add(request) { error in
                DispatchQueue.main.async {
                    if let error = error {
                        print("NotificationManager: Failed to send chat notification: \(error.localizedDescription)")
                        completion?(false, NotificationError.systemError(error.localizedDescription))
                    } else {
                        completion?(true, nil)
                    }
                }
            }
        }
    }
    
    func sendMentionNotification(
        from senderName: String,
        message: String,
        chatId: String,
        messageId: String,
        completion: ((Bool, Error?) -> Void)? = nil
    ) {
        notificationQueue.async {
            guard self.settings.notificationsEnabled &&
                  self.settings.chatNotificationsEnabled &&
                  self.settings.mentionNotificationsEnabled else {
                DispatchQueue.main.async {
                    completion?(false, NotificationError.notificationsDisabled)
                }
                return
            }
            
            let notificationKey = "mention_\(chatId)_\(messageId)"
            guard !self.recentNotifications.contains(notificationKey) else {
                DispatchQueue.main.async {
                    completion?(false, NotificationError.duplicateNotification)
                }
                return
            }
            
            self.recentNotifications.insert(notificationKey)
            self.cleanupCacheIfNeeded()
            
            let content = UNMutableNotificationContent()
            content.title = "\(senderName) mentioned you"
            content.body = message
            content.categoryIdentifier = "MENTION_NOTIFICATION"
            
            content.sound = UNNotificationSound.default
            if #available(iOS 15.0, *) {
                content.interruptionLevel = .timeSensitive
            }
            
            content.userInfo = [
                "type": "mention",
                "chatId": chatId,
                "messageId": messageId,
                "timestamp": Date().timeIntervalSince1970
            ]
            
            let request = UNNotificationRequest(
                identifier: notificationKey,
                content: content,
                trigger: nil
            )
            
            UNUserNotificationCenter.current().add(request) { error in
                DispatchQueue.main.async {
                    if let error = error {
                        print("NotificationManager: Failed to send mention notification: \(error.localizedDescription)")
                        completion?(false, NotificationError.systemError(error.localizedDescription))
                    } else {
                        print("NotificationManager: Mention notification sent successfully")
                        completion?(true, nil)
                    }
                }
            }
        }
    }
    
    // MARK: - Cancel Notifications
    
    func cancelEventNotification(eventId: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: ["event_\(eventId)"]
        )
        print("NotificationManager: Cancelled event notification for ID: \(eventId)")
    }
    
    func cancelTaskNotification(taskId: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: ["task_\(taskId)"]
        )
        print("NotificationManager: Cancelled task notification for ID: \(taskId)")
    }
    
    func cancelChatNotifications(chatId: String) {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let chatNotificationIds = requests
                .filter { $0.identifier.contains("chat_\(chatId)") || $0.identifier.contains("mention_\(chatId)") }
                .map { $0.identifier }
            
            if !chatNotificationIds.isEmpty {
                UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: chatNotificationIds)
                print("NotificationManager: Cancelled \(chatNotificationIds.count) notifications for chat: \(chatId)")
            }
        }
        
        recentNotifications = recentNotifications.filter { !$0.contains(chatId) }
    }
    
    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        clearNotificationCache()
        print("NotificationManager: All notifications cancelled and cache cleared")
    }
    
    // MARK: - Helper Methods
    
    private func setupPeriodicCleanup() {
        Timer.scheduledTimer(withTimeInterval: cacheCleanupInterval, repeats: true) { [weak self] _ in
            self?.cleanupCacheIfNeeded()
        }
    }
    
    private func cleanupCacheIfNeeded() {
        guard Date().timeIntervalSince(lastCacheCleanup) >= cacheCleanupInterval || recentNotifications.count > notificationCacheLimit else {
            return
        }
        
        if recentNotifications.count > notificationCacheLimit {
            let countToRemove = notificationCacheLimit / 2
            recentNotifications = Set(recentNotifications.dropFirst(countToRemove))
        }
        
        lastCacheCleanup = Date()
    }
    
    func clearNotificationCache() {
        recentNotifications.removeAll()
        pendingNotifications.removeAll()
        print("NotificationManager: Notification cache cleared")
    }
    
    // MARK: - Notification Categories Setup
    
    func setupNotificationCategories() {
        let chatCategory = UNNotificationCategory(
            identifier: "CHAT_NOTIFICATION",
            actions: [
                UNNotificationAction(identifier: "REPLY_ACTION", title: "Reply", options: [.foreground]),
                UNNotificationAction(identifier: "MARK_READ_ACTION", title: "Mark as Read", options: [])
            ],
            intentIdentifiers: [],
            options: []
        )
        
        let mentionCategory = UNNotificationCategory(
            identifier: "MENTION_NOTIFICATION",
            actions: [
                UNNotificationAction(identifier: "REPLY_ACTION", title: "Reply", options: [.foreground]),
                UNNotificationAction(identifier: "VIEW_ACTION", title: "View", options: [.foreground])
            ],
            intentIdentifiers: [],
            options: []
        )
        
        let taskCategory = UNNotificationCategory(
            identifier: "TASK_NOTIFICATION",
            actions: [
                UNNotificationAction(identifier: "COMPLETE_TASK_ACTION", title: "Mark Complete", options: []),
                UNNotificationAction(identifier: "VIEW_TASK_ACTION", title: "View Task", options: [.foreground])
            ],
            intentIdentifiers: [],
            options: []
        )
        
        let eventCategory = UNNotificationCategory(
            identifier: "EVENT_NOTIFICATION",
            actions: [
                UNNotificationAction(identifier: "VIEW_EVENT_ACTION", title: "View Event", options: [.foreground])
            ],
            intentIdentifiers: [],
            options: []
        )
        
        UNUserNotificationCenter.current().setNotificationCategories([
            chatCategory,
            mentionCategory,
            taskCategory,
            eventCategory
        ])
        
        print("NotificationManager: Notification categories configured")
    }
    
    // MARK: - Immediate Notifications
    
    func sendTaskNotification(
        title: String,
        message: String,
        taskId: String,
        dueDate: Date? = nil,
        completion: ((Bool, Error?) -> Void)? = nil
    ) {
        notificationQueue.async {
            guard self.settings.notificationsEnabled && self.settings.taskNotificationsEnabled else {
                DispatchQueue.main.async {
                    completion?(false, NotificationError.notificationsDisabled)
                }
                return
            }
            
            let notificationKey = "task_immediate_\(taskId)"
            
            let content = UNMutableNotificationContent()
            content.title = title
            content.body = message
            content.categoryIdentifier = "TASK_NOTIFICATION"
            
            if self.settings.soundEnabled && !self.isInQuietHours(Date()) {
                content.sound = UNNotificationSound.default
            }
            
            content.userInfo = [
                "type": "task",
                "taskId": taskId,
                "timestamp": Date().timeIntervalSince1970
            ]
            
            let request = UNNotificationRequest(
                identifier: notificationKey,
                content: content,
                trigger: nil
            )
            
            UNUserNotificationCenter.current().add(request) { error in
                DispatchQueue.main.async {
                    if let error = error {
                        completion?(false, NotificationError.systemError(error.localizedDescription))
                    } else {
                        completion?(true, nil)
                    }
                }
            }
        }
    }
    
    func sendEventNotification(
        title: String,
        message: String,
        eventId: String,
        eventDate: Date? = nil,
        completion: ((Bool, Error?) -> Void)? = nil
    ) {
        notificationQueue.async {
            guard self.settings.notificationsEnabled && self.settings.eventNotificationsEnabled else {
                DispatchQueue.main.async {
                    completion?(false, NotificationError.notificationsDisabled)
                }
                return
            }
            
            let notificationKey = "event_immediate_\(eventId)"
            
            let content = UNMutableNotificationContent()
            content.title = title
            content.body = message
            content.categoryIdentifier = "EVENT_NOTIFICATION"
            
            if self.settings.soundEnabled && !self.isInQuietHours(Date()) {
                content.sound = UNNotificationSound.default
            }
            
            content.userInfo = [
                "type": "event",
                "eventId": eventId,
                "timestamp": Date().timeIntervalSince1970
            ]
            
            let request = UNNotificationRequest(
                identifier: notificationKey,
                content: content,
                trigger: nil
            )
            
            UNUserNotificationCenter.current().add(request) { error in
                DispatchQueue.main.async {
                    if let error = error {
                        completion?(false, NotificationError.systemError(error.localizedDescription))
                    } else {
                        completion?(true, nil)
                    }
                }
            }
        }
    }
}

// MARK: - Quiet Hours Helper

extension NotificationManager {
    private func isInQuietHours(_ date: Date) -> Bool {
        guard settings.quietHoursEnabled else {
            return false
        }
        
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        
        if settings.quietHoursStart > settings.quietHoursEnd {
            return hour >= settings.quietHoursStart || hour < settings.quietHoursEnd
        } else {
            return hour >= settings.quietHoursStart && hour < settings.quietHoursEnd
        }
    }
}

// MARK: - Settings Management

extension NotificationManager {
    func checkAndUpdateNotificationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                let isAuthorized = settings.authorizationStatus == .authorized || 
                                 settings.authorizationStatus == .provisional
                
                var currentSettings = self.settings
                if currentSettings.notificationsEnabled != isAuthorized {
                    currentSettings.notificationsEnabled = isAuthorized
                    self.settings = currentSettings
                    print("NotificationManager: Updated notification status to \(isAuthorized)")
                }
            }
        }
    }
}
