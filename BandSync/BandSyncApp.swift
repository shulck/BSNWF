import SwiftUI
import FirebaseCore
import Firebase

@main
struct BandSyncApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @Environment(\.scenePhase) private var scenePhase
    
    @StateObject private var navigationManager = NavigationManager()

    init() {
        
    }

    var body: some Scene {
        WindowGroup {
            SplashView()
                .environmentObject(AppState.shared)
                .environmentObject(navigationManager)
                .onOpenURL { url in
                    
                }
                .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("OpenEventNotification"))) { notification in
                    handleEventNotification(notification)
                }
                .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("OpenTaskNotification"))) { notification in
                    handleTaskNotification(notification)
                }
                .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("OpenChatNotification"))) { notification in
                    handleChatNotification(notification)
                }
        }
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .active:
                FirebaseManager.shared.updateUserOnlineStatus(isOnline: true)
                GoogleDriveService.shared.refreshAuthenticationStatus()
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    UnifiedBadgeManager.shared.refreshBadgeCounts()
                }

            case .background, .inactive:
                FirebaseManager.shared.updateUserOnlineStatus(isOnline: false)

            @unknown default:
                break
            }
        }
    }
    
    private func handleEventNotification(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let eventId = userInfo["eventId"] as? String else {
            return
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            navigationManager.switchToTab(.calendar)
            navigationManager.openEvent(eventId: eventId)
        }
    }
    
    private func handleTaskNotification(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let taskId = userInfo["taskId"] as? String else {
            return
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            navigationManager.switchToTab(.tasks)
            navigationManager.openTask(taskId: taskId)
        }
    }
    
    private func handleChatNotification(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let chatId = userInfo["chatId"] as? String else {
            return
        }
        
        let messageId = userInfo["messageId"] as? String ?? ""
        let shouldHighlight = userInfo["shouldHighlight"] as? Bool ?? false
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            navigationManager.switchToTab(.chats)
            navigationManager.openChat(chatId: chatId, messageId: messageId, shouldHighlight: shouldHighlight)
        }
    }
}

class NavigationManager: ObservableObject {
    @Published var selectedTab: TabSelection = .calendar
    @Published var eventToOpen: String?
    @Published var taskToOpen: String?
    @Published var chatToOpen: ChatNavigationData?
    
    enum TabSelection: Int, CaseIterable {
        case home = 0
        case calendar = 1
        case setlists = 2
        case tasks = 3
        case chats = 4
        case more = 5
        
        var title: String {
            switch self {
            case .home: return "Home"
            case .calendar: return "Calendar"
            case .setlists: return "Setlists"
            case .tasks: return "Tasks"
            case .chats: return "Chats"
            case .more: return "More"
            }
        }
        
        var icon: String {
            switch self {
            case .home: return "house"
            case .calendar: return "calendar"
            case .setlists: return "music.note.list"
            case .tasks: return "checklist"
            case .chats: return "message"
            case .more: return "ellipsis.circle"
            }
        }
    }
    
    struct ChatNavigationData: Hashable {
        let chatId: String
        let messageId: String?
        let shouldHighlight: Bool
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(chatId)
            hasher.combine(messageId)
            hasher.combine(shouldHighlight)
        }
        
        static func == (lhs: ChatNavigationData, rhs: ChatNavigationData) -> Bool {
            return lhs.chatId == rhs.chatId &&
                   lhs.messageId == rhs.messageId &&
                   lhs.shouldHighlight == rhs.shouldHighlight
        }
    }
    
    func switchToTab(_ tab: TabSelection) {
        selectedTab = tab
    }
    
    func openEvent(eventId: String) {
        eventToOpen = eventId
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.eventToOpen = nil
        }
    }
    
    func openTask(taskId: String) {
        taskToOpen = taskId
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.taskToOpen = nil
        }
    }
    
    func openChat(chatId: String, messageId: String? = nil, shouldHighlight: Bool = false) {
        chatToOpen = ChatNavigationData(
            chatId: chatId,
            messageId: messageId,
            shouldHighlight: shouldHighlight
        )
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.chatToOpen = nil
        }
    }
}

extension View {
    func dismissKeyboardOnTap() -> some View {
        self.onTapGesture {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first {
                window.endEditing(true)
            }
        }
    }
    
    func hideKeyboardOnTap() -> some View {
        self.onTapGesture {
            UIApplication.shared.sendAction(
                #selector(UIResponder.resignFirstResponder),
                to: nil,
                from: nil,
                for: nil
            )
        }
    }
}

extension UIApplication {
    var keyWindow: UIWindow? {
        connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
    }
    
    func hideKeyboard() {
        keyWindow?.endEditing(true)
    }
}
