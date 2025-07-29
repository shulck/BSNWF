import SwiftUI
import UserNotifications

struct MainTabView: View {
    @StateObject private var appState = AppState.shared
    @StateObject private var permissionService = PermissionService.shared
    @StateObject private var badgeManager = UnifiedBadgeManager.shared
    @EnvironmentObject var navigationManager: NavigationManager
    @State private var hasInitialized = false
    
    var body: some View {
        TabView(selection: $navigationManager.selectedTab) {
            if permissionService.currentUserHasAccess(to: .calendar) {
                CalendarViewWrapper()
                .tabItem {
                    Image(systemName: "calendar")
                    Text("Calendar".localized)
                }
                .tag(NavigationManager.TabSelection.calendar)
            }
            
            if permissionService.currentUserHasAccess(to: .setlists) {
                SetlistViewWrapper()
                .tabItem {
                    Image(systemName: "music.note.list")
                    Text("Setlists".localized)
                }
                .tag(NavigationManager.TabSelection.setlists)
            }
            
            if permissionService.currentUserHasAccess(to: .tasks) {
                TasksViewWrapper()
                .tabItem {
                    Image(systemName: "checklist")
                    Text("Tasks".localized)
                }
                .badge(badgeManager.unreadTasksCount > 0 ? Text("\(badgeManager.unreadTasksCount)") : nil)
                .tag(NavigationManager.TabSelection.tasks)
            }
            
            if permissionService.currentUserHasAccess(to: .chats) {
                ChatsListViewWrapper()
                .tabItem {
                    Image(systemName: "message")
                    Text("Chats".localized)
                }
                .badge(badgeManager.unreadChatsCount > 0 ? Text("\(badgeManager.unreadChatsCount)") : nil)
                .tag(NavigationManager.TabSelection.chats)
            }
            
            MoreMenuViewWrapper()
            .tabItem {
                Image(systemName: "ellipsis")
                Text("More".localized)
            }
            .tag(NavigationManager.TabSelection.more)
        }
        .onAppear {
            if !hasInitialized {
                initializeView()
            }
        }
        .onChange(of: navigationManager.selectedTab) { newTab in
            handleTabSelection(newTab)
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("OpenEventFromNotification"))) { notification in
            handleEventNotification(notification)
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("OpenTaskFromNotification"))) { notification in
            handleTaskNotification(notification)
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("OpenChatFromNotification"))) { notification in
            handleChatNotification(notification)
        }
    }
    
    // ИСПРАВЛЕНИЕ: Инициализация только один раз
    private func initializeView() {
        hasInitialized = true
        setupTabBarAppearance()
        badgeManager.startMonitoring()
        ensureValidTab()
    }
    
    private func handleEventNotification(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let eventId = userInfo["eventId"] as? String else {
            return
        }
        
        print("MainTabView: Handling event notification for eventId: \(eventId)")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // Переключаемся на календарь
            navigationManager.selectedTab = .calendar
            
            // Передаем событие через NotificationCenter для Calendar
            NotificationCenter.default.post(
                name: NSNotification.Name("NavigateToEvent"),
                object: nil,
                userInfo: ["eventId": eventId]
            )
        }
    }
    
    private func handleTaskNotification(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let taskId = userInfo["taskId"] as? String else {
            return
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // Переключаемся на задания
            navigationManager.selectedTab = .tasks
            
            // Передаем задание через NotificationCenter для Tasks view
            NotificationCenter.default.post(
                name: NSNotification.Name("NavigateToTask"),
                object: nil,
                userInfo: ["taskId": taskId]
            )
        }
    }
    
    private func handleChatNotification(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let chatId = userInfo["chatId"] as? String else {
            return
        }
        
        let messageId = userInfo["messageId"] as? String
        let shouldHighlight = userInfo["shouldHighlight"] as? Bool ?? false
        
        print("MainTabView: Handling chat notification for chatId: \(chatId), messageId: \(messageId ?? "none")")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // Переключаемся на чат
            navigationManager.selectedTab = .chats
            
            // Передаем чат через NotificationCenter для Chat view
            NotificationCenter.default.post(
                name: NSNotification.Name("NavigateToChat"),
                object: nil,
                userInfo: [
                    "chatId": chatId,
                    "messageId": messageId ?? "",
                    "shouldHighlight": shouldHighlight
                ]
            )
        }
    }
    
    private func setupTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.systemBackground
        
        appearance.shadowColor = UIColor.black.withAlphaComponent(0.1)
        appearance.shadowImage = UIImage()
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
    
    private func handleTabSelection(_ newTab: NavigationManager.TabSelection) {
        switch newTab {
        case .tasks:
            UnifiedBadgeManager.shared.markTasksAsRead()
        case .chats:
            break // Чаты помечаются как прочитанные в самом ChatDetailView
        default:
            break
        }
    }
    
    private func ensureValidTab() {
        let modules = permissionService.getCurrentUserAccessibleModules()
        
        var isCurrentTabAccessible = false
        
        switch navigationManager.selectedTab {
        case .calendar: isCurrentTabAccessible = modules.contains(.calendar)
        case .home: isCurrentTabAccessible = true // Home is always accessible
        case .setlists: isCurrentTabAccessible = modules.contains(.setlists)
        case .tasks: isCurrentTabAccessible = modules.contains(.tasks)
        case .chats: isCurrentTabAccessible = modules.contains(.chats)
        case .more: isCurrentTabAccessible = true // More is always accessible
        }
        
        if !isCurrentTabAccessible {
            if modules.contains(.calendar) {
                navigationManager.selectedTab = .calendar
            } else if modules.contains(.setlists) {
                navigationManager.selectedTab = .setlists
            } else if modules.contains(.tasks) {
                navigationManager.selectedTab = .tasks
            } else if modules.contains(.chats) {
                navigationManager.selectedTab = .chats
            } else {
                navigationManager.selectedTab = .more
            }
        }
    }
}

struct MoreMenuView: View {
    @StateObject private var permissionService = PermissionService.shared
    
    var body: some View {
        List {
            if let user = AppState.shared.user {
                Section {
                    HStack(spacing: 12) {
                        Circle()
                            .fill(LinearGradient(
                                gradient: Gradient(colors: [.blue, .purple]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .frame(width: 50, height: 50)
                            .overlay(
                                Text(String(user.name.first ?? "U"))
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                            )
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(user.name)
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            Text(user.role.rawValue.capitalized)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }
            }
            
            Section {
                if permissionService.currentUserHasAccess(to: .merchandise) {
                    NavigationLink(destination: MerchView()) {
                        moreRow(
                            title: "Merch".localized,
                            icon: "tshirt.fill",
                            color: .orange
                        )
                    }
                }
                
                if permissionService.currentUserHasAccess(to: .contacts) {
                    NavigationLink(destination: ContactsView()) {
                        moreRow(
                            title: "Contacts".localized,
                            icon: "person.crop.circle.fill",
                            color: .teal
                        )
                    }
                }
                
                if permissionService.currentUserHasAccess(to: .finances) {
                    NavigationLink(destination: FinancesView()) {
                        moreRow(
                            title: "Finances".localized,
                            icon: "chart.line.uptrend.xyaxis",
                            color: .green
                        )
                    }
                }
                
                if permissionService.currentUserHasAccess(to: .documents) {
                    NavigationLink(destination: DocumentsView()) {
                        moreRow(
                            title: "Documents".localized,
                            icon: "folder.fill",
                            color: .blue
                        )
                    }
                }
            } header: {
                Text("Additional features".localized)
            }
            
            Section {
                if permissionService.currentUserHasAccess(to: .admin) {
                    NavigationLink(destination: AdminPanelView()) {
                        moreRow(
                            title: "Admin Panel".localized,
                            icon: "person.3.fill",
                            color: .red
                        )
                    }
                }
                
                NavigationLink(destination: SettingsView()) {
                    moreRow(
                        title: "Settings".localized,
                        icon: "gear",
                        color: .gray
                    )
                }
            } header: {
                Text("Settings".localized)
            }
        }
        .navigationTitle("More".localized)
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func moreRow(title: String, icon: String, color: Color) -> some View {
        HStack(spacing: 12) {
            moreIcon(icon: icon, color: color)
            
            Text(title)
                .font(.body)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
    
    private func moreIcon(icon: String, color: Color) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6)
                .fill(color)
                .frame(width: 28, height: 28)
            
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
        }
    }
}

struct MoreMenuViewWrapper: View {
    @State private var navigationPath = NavigationPath()
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            MoreMenuView()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ResetTab4"))) { _ in
            navigationPath = NavigationPath()
        }
    }
}
