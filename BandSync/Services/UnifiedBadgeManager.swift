import Foundation
import Combine
import FirebaseFirestore
import FirebaseDatabase
import FirebaseAuth
import UIKit
import UserNotifications

extension Notification.Name {
    static let chatMarkedAsRead = Notification.Name("chatMarkedAsRead")
    static let badgeCountUpdated = Notification.Name("badgeCountUpdated")
    static let messagesUpdated = Notification.Name("messagesUpdated")
}

final class UnifiedBadgeManager: ObservableObject {
    static let shared = UnifiedBadgeManager()
    
    @Published var unreadTasksCount: Int = 0
    @Published var unreadChatsCount: Int = 0
    @Published var totalBadgeCount: Int = 0
    
    private let firestore = Firestore.firestore()
    private let rtdb = Database.database().reference()
    private var firestoreListeners: [ListenerRegistration] = []
    private var rtdbListeners: [String: DatabaseHandle] = [:]
    private var cancellables = Set<AnyCancellable>()
    
    private var isMonitoring = false
    
    private var currentUserId: String? {
        return Auth.auth().currentUser?.uid ?? UserDefaults.standard.string(forKey: "userID")
    }
    
    private init() {
        setupNotificationObservers()
        setupPublishers()
    }
    
    deinit {
        cleanup()
    }
    
    private func setupNotificationObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
    }
    
    private func setupPublishers() {
        Publishers.CombineLatest($unreadTasksCount, $unreadChatsCount)
            .map { tasks, chats in tasks + chats }
            .receive(on: DispatchQueue.main)
            .assign(to: &$totalBadgeCount)
        
        $totalBadgeCount
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { count in
                if #available(iOS 16.0, *) {
                    UNUserNotificationCenter.current().setBadgeCount(count) { error in
                        if let error = error {
                            print("BadgeManager: Error setting badge: \(error)")
                        }
                    }
                } else {
                    UIApplication.shared.applicationIconBadgeNumber = count
                }
            }
            .store(in: &cancellables)
    }
    
    func startMonitoring() {
        guard let userId = currentUserId else {
            return
        }
        
        if isMonitoring {
            return
        }
        
        stopAllMonitoring()
        isMonitoring = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.startMonitoringTasks(for: userId)
            self.startMonitoringChats(for: userId)
            self.refreshBadgeCounts()
        }
    }
    
    func stopAllMonitoring() {
        isMonitoring = false
        
        for listener in firestoreListeners {
            listener.remove()
        }
        firestoreListeners.removeAll()
        
        for (path, handle) in rtdbListeners {
            rtdb.child(path).removeObserver(withHandle: handle)
        }
        rtdbListeners.removeAll()
    }
    
    func refreshBadgeCounts() {
        guard let userId = currentUserId else { return }
        
        calculateUnreadTasksCount(for: userId)
        calculateUnreadChatsCount(for: userId)
    }
    
    func forceRefreshBadgeCounts() {
        refreshBadgeCounts()
    }
    
    @objc private func appDidBecomeActive() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.refreshBadgeCounts()
        }
    }
    
    @objc private func appDidEnterBackground() {
        // No action needed
    }
    
    // MARK: - Task Monitoring
    
    func markTasksAsRead() {
        UserDefaults.standard.set(Date(), forKey: "lastTaskCheck")
        
        DispatchQueue.main.async {
            self.unreadTasksCount = 0
        }
    }
    
    private func startMonitoringTasks(for userId: String) {
        guard let groupId = UserDefaults.standard.string(forKey: "userGroupID") else {
            return
        }
        
        let listener = firestore.collection("tasks")
            .whereField("groupId", isEqualTo: groupId)
            .whereField("assignedTo", arrayContains: userId)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("BadgeManager: Error monitoring tasks: \(error.localizedDescription)")
                    return
                }
                
                self.calculateUnreadTasksCount(for: userId)
            }
        
        firestoreListeners.append(listener)
    }
    
    private func calculateUnreadTasksCount(for userId: String) {
        guard let groupId = UserDefaults.standard.string(forKey: "userGroupID") else {
            DispatchQueue.main.async {
                self.unreadTasksCount = 0
            }
            return
        }
        
        firestore.collection("tasks")
            .whereField("groupId", isEqualTo: groupId)
            .whereField("assignedTo", arrayContains: userId)
            .whereField("completed", isEqualTo: false)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self,
                      let documents = snapshot?.documents else {
                    DispatchQueue.main.async {
                        self?.unreadTasksCount = 0
                    }
                    return
                }
                
                var count = 0
                let lastCheckTime = UserDefaults.standard.object(forKey: "lastTaskCheck") as? Date ?? Date().addingTimeInterval(-24*60*60)
                
                for document in documents {
                    let data = document.data()
                    
                    let createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date.distantPast
                    let updatedAt = (data["updatedAt"] as? Timestamp)?.dateValue() ?? createdAt
                    let taskTime = max(createdAt, updatedAt)
                    
                    if taskTime > lastCheckTime {
                        count += 1
                    }
                }
                
                DispatchQueue.main.async {
                    self.unreadTasksCount = count
                }
            }
    }
    
    // MARK: - Chat Monitoring
    
    private func startMonitoringChats(for userId: String) {
        let chatsHandle = rtdb.child("chats")
            .observe(.value) { [weak self] snapshot in
                guard let self = self else { return }
                self.calculateUnreadChatsCount(for: userId)
            }
        
        rtdbListeners["chats"] = chatsHandle
    }
    
    private func calculateUnreadChatsCount(for userId: String) {
        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let self = self else { return }
            
            self.rtdb.child("chats")
                .observeSingleEvent(of: .value) { [weak self] snapshot in
                    guard let self = self else { return }
                    
                    var userChats: [String] = []
                    
                    for child in snapshot.children {
                        guard let childSnapshot = child as? DataSnapshot,
                              let chatData = childSnapshot.value as? [String: Any] else { continue }
                        
                        let chatId = childSnapshot.key
                        let isDeleted = chatData["isDeleted"] as? Bool ?? false
                        
                        if !isDeleted {
                            if let participants = chatData["participants"] as? [String] {
                                if participants.contains(userId) {
                                    userChats.append(chatId)
                                }
                            } else if let participantsDict = chatData["participants"] as? [String: Bool] {
                                if participantsDict[userId] == true {
                                    userChats.append(chatId)
                                }
                            }
                        }
                    }
                    
                    if userChats.isEmpty {
                        DispatchQueue.main.async {
                            self.unreadChatsCount = 0
                        }
                        return
                    }
                    
                    self.countUnreadMessagesInChats(userChats, for: userId)
                }
        }
    }
    
    private func countUnreadMessagesInChats(_ chatIds: [String], for userId: String) {
        let group = DispatchGroup()
        var totalUnreadCount = 0
        let countLock = NSLock()
        
        for chatId in chatIds {
            group.enter()
            
            let lastReadKey = "lastReadTime_\(chatId)"
            let lastReadTime = UserDefaults.standard.object(forKey: lastReadKey) as? Date ?? Date().addingTimeInterval(-7 * 24 * 60 * 60)
            
            self.rtdb.child("messages").child(chatId)
                .queryOrdered(byChild: "timestamp")
                .queryStarting(atValue: lastReadTime.timeIntervalSince1970 * 1000)
                .observeSingleEvent(of: .value) { snapshot in
                    defer { group.leave() }
                    
                    var chatUnreadCount = 0
                    
                    for child in snapshot.children {
                        guard let childSnapshot = child as? DataSnapshot,
                              let messageData = childSnapshot.value as? [String: Any] else { continue }
                        
                        let senderId = messageData["senderID"] as? String ?? messageData["senderId"] as? String
                        
                        guard let actualSenderId = senderId,
                              actualSenderId != userId,
                              let isDeleted = messageData["isDeleted"] as? Bool,
                              !isDeleted else { continue }
                        
                        if let timestamp = messageData["timestamp"] as? TimeInterval {
                            let messageDate = Date(timeIntervalSince1970: timestamp / 1000)
                            if messageDate > lastReadTime {
                                chatUnreadCount += 1
                            }
                        }
                    }
                    
                    countLock.lock()
                    totalUnreadCount += chatUnreadCount
                    countLock.unlock()
                }
        }
        
        group.notify(queue: .main) { [weak self] in
            guard let self = self else { return }
            self.unreadChatsCount = totalUnreadCount
        }
    }
    
    func markChatAsRead(_ chatId: String) {
        let currentTime = Date()
        let lastReadKey = "lastReadTime_\(chatId)"
        UserDefaults.standard.set(currentTime, forKey: lastReadKey)
        
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .chatMarkedAsRead, object: chatId)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            guard let self = self, let userId = self.currentUserId else { return }
            self.calculateUnreadChatsCount(for: userId)
        }
    }
    
    func markAllChatsAsRead() {
        guard let userId = currentUserId else { return }
        
        rtdb.child("chats").observeSingleEvent(of: .value) { [weak self] snapshot in
            for child in snapshot.children {
                guard let childSnapshot = child as? DataSnapshot,
                      let chatData = childSnapshot.value as? [String: Any] else { continue }
                
                let chatId = childSnapshot.key
                let isDeleted = chatData["isDeleted"] as? Bool ?? false
                
                if !isDeleted {
                    var isParticipant = false
                    
                    if let participants = chatData["participants"] as? [String] {
                        isParticipant = participants.contains(userId)
                    } else if let participantsDict = chatData["participants"] as? [String: Bool] {
                        isParticipant = participantsDict[userId] == true
                    }
                    
                    if isParticipant {
                        let lastReadKey = "lastReadTime_\(chatId)"
                        UserDefaults.standard.set(Date(), forKey: lastReadKey)
                    }
                }
            }
            
            DispatchQueue.main.async {
                self?.unreadChatsCount = 0
            }
        }
    }
    
    func debugBadgeState() {
        print("BADGE DEBUG STATE:")
        print("   - Unread tasks: \(unreadTasksCount)")
        print("   - Unread chats: \(unreadChatsCount)")
        print("   - Total badge: \(totalBadgeCount)")
        print("   - App badge: \(totalBadgeCount)") // Since we set it to totalBadgeCount
        print("   - Is monitoring: \(isMonitoring)")
    }
    
    private func cleanup() {
        stopAllMonitoring()
        NotificationCenter.default.removeObserver(self)
        cancellables.removeAll()
    }
}
