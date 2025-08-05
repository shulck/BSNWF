import SwiftUI

struct FanTabView: View {
    @EnvironmentObject private var appState: AppState
    @State private var selectedTab: FanTab = .home
    @State private var hasInitialized = false
    @State private var fanChatInitialized = false
    
    enum FanTab: String, CaseIterable {
        case home = "Home"
        case events = "Events"
        case merchandise = "Merch"
        case chat = "Chat"
        case profile = "Profile"
        case about = "About"
        
        var icon: String {
            switch self {
            case .home: return "house.fill"
            case .events: return "calendar"
            case .merchandise: return "bag.fill"
            case .chat: return "message.fill"
            case .profile: return "person.fill"
            case .about: return "info.circle.fill"
            }
        }
        
        var title: String {
            switch self {
            case .home: return NSLocalizedString("Home", comment: "Home tab title")
            case .events: return NSLocalizedString("Events", comment: "Events tab title")
            case .merchandise: return NSLocalizedString("Merchandise", comment: "Merchandise tab title")
            case .chat: return NSLocalizedString("Chat", comment: "Chat tab title")
            case .profile: return NSLocalizedString("Profile", comment: "Profile tab title")
            case .about: return NSLocalizedString("Band", comment: "Band tab title")
            }
        }
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            
            // Home Tab
            FanHomeView(selectedTab: $selectedTab)
                .tabItem {
                    Image(systemName: FanTab.home.icon)
                    Text(FanTab.home.title)
                }
                .tag(FanTab.home)
            
            // Events Tab
            FanCalendarViewWrapper()
                .tabItem {
                    Image(systemName: FanTab.events.icon)
                    Text(FanTab.events.title)
                }
                .tag(FanTab.events)
            
            // Merchandise Tab
            FanMerchandiseView()
                .tabItem {
                    Image(systemName: FanTab.merchandise.icon)
                    Text(FanTab.merchandise.title)
                }
                .tag(FanTab.merchandise)
            
            // Chat Tab
            FanChatView()
                .tabItem {
                    Image(systemName: FanTab.chat.icon)
                    Text(FanTab.chat.title)
                }
                .tag(FanTab.chat)
            
            // Profile Tab - NOW USES THE STANDALONE VERSION
            FanProfileView()
                .tabItem {
                    Image(systemName: FanTab.profile.icon)
                    Text(FanTab.profile.title)
                }
                .tag(FanTab.profile)
            
            // Band Tab
            GroupInfoView()
                .tabItem {
                    Image(systemName: FanTab.about.icon)
                    Text(FanTab.about.title)
                }
                .tag(FanTab.about)
        }
        .tabViewStyle(DefaultTabViewStyle())
        .onChange(of: selectedTab) { newTab in
            if newTab == .events {
                NotificationCenter.default.post(name: NSNotification.Name("FanCalendarTabSelected"), object: nil)
            }
        }
        .onAppear {
            if !hasInitialized {
                initializeView()
            }
            if !fanChatInitialized {
                setupFanChat()
                fanChatInitialized = true
            }
        }
    }
    
    private func initializeView() {
        hasInitialized = true
        setupTabBarAppearance()
    }
    
    private func setupFanChat() {
        guard let user = appState.user,
              user.userType == .fan,
              let groupId = user.fanGroupId else {
            print("❌ Cannot setup fan chat: invalid user or missing fanGroupId")
            return
        }
        
        print("🚀 Setting up fan chat for user \(user.id) in group \(groupId)")
        
        // Load chat rules first
        let fanChatService = FanChatService.shared
        fanChatService.loadChatRules(for: groupId)
        
        // Start listening to chats (temporarily skip rules check for testing)
        print("✅ Starting to listen to fan chats (skipping rules check for testing)")
        fanChatService.startListeningToFanChats(for: groupId)
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
}

// MARK: - Modern Fan Home View

struct FanHomeView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var eventService = EventService.shared
    @Binding var selectedTab: FanTabView.FanTab
    @Environment(\.colorScheme) private var colorScheme
    
    private var fanVisibleEvents: [Event] {
        return eventService.events.filter { event in
            if event.isPersonal {
                return false
            }
            
            let fanVisibleTypes: [EventType] = [.concert, .festival, .birthday]
            return fanVisibleTypes.contains(event.type)
        }.sorted { $0.date < $1.date }
    }
    
    private var upcomingEvents: [Event] {
        let now = Date()
        let futureEvents = fanVisibleEvents.filter { $0.date >= now }
        return Array(futureEvents.prefix(6))
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 32) {
                    // Hero Welcome Section
                    heroWelcomeSection
                    
                    // Upcoming Events Section
                    upcomingEventsSection
                    
                    // Quick Actions Grid
                    quickActionsSection
                    
                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(UIColor.systemGroupedBackground),
                        Color(UIColor.systemGroupedBackground).opacity(0.8)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
            .navigationBarHidden(true)
            .onAppear {
                loadEvents()
            }
        }
    }
    
    // MARK: - Hero Welcome Section
    
    private var heroWelcomeSection: some View {
        VStack(spacing: 20) {
            // Greeting Header
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text(greetingText())
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    if let user = appState.user, let fanProfile = user.fanProfile {
                        Text(fanProfile.nickname)
                            .font(.largeTitle)
                            .fontWeight(.heavy)
                            .foregroundColor(.primary)
                    } else {
                        Text(NSLocalizedString("Fan", comment: "Default fan username when profile not loaded"))
                            .font(.largeTitle)
                            .fontWeight(.heavy)
                            .foregroundColor(.primary)
                    }
                }
                
                Spacer()
                
                // Fan Level Avatar
                if let user = appState.user, let fanProfile = user.fanProfile {
                    VStack(spacing: 6) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color(hex: fanProfile.level.color),
                                            Color(hex: fanProfile.level.color).opacity(0.7)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 64, height: 64)
                                .shadow(color: Color(hex: fanProfile.level.color).opacity(0.3), radius: 8, x: 0, y: 4)
                            
                            Text(String(fanProfile.nickname.prefix(2)).uppercased())
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                        
                        Text(fanProfile.level.localizedName)
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(Color(hex: fanProfile.level.color))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color(hex: fanProfile.level.color).opacity(0.1))
                            .clipShape(Capsule())
                    }
                }
            }
            .padding(.top, 40)
        }
    }
    
    // MARK: - Upcoming Events Section
    
    private var upcomingEventsSection: some View {
        VStack(spacing: 20) {
            // Section Header
            HStack {
                HStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(Color.blue.opacity(0.15))
                            .frame(width: 32, height: 32)
                        
                        Image(systemName: "calendar.badge.clock")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.blue)
                    }
                    
                    Text(NSLocalizedString("Upcoming Events", comment: "Upcoming events section title"))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                if !upcomingEvents.isEmpty {
                    Button(NSLocalizedString("See all", comment: "See all events button")) {
                        selectedTab = .events
                    }
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue.opacity(0.1))
                    .clipShape(Capsule())
                }
            }
            
            // Events Content
            if eventService.isLoading {
                // Modern Loading State
                VStack(spacing: 20) {
                    ProgressView()
                        .scaleEffect(1.2)
                        .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                    
                    Text(NSLocalizedString("Loading events...", comment: "Loading events message"))
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 50)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(colorScheme == .dark ?
                              Color(UIColor.secondarySystemGroupedBackground) :
                              Color.white)
                        .shadow(
                            color: colorScheme == .dark ?
                                Color.clear :
                                Color.black.opacity(0.06),
                            radius: 12,
                            x: 0,
                            y: 4
                        )
                )
                
            } else if upcomingEvents.isEmpty {
                // Modern Empty State
                VStack(spacing: 20) {
                    ZStack {
                        Circle()
                            .fill(Color.gray.opacity(0.1))
                            .frame(width: 80, height: 80)
                        
                        Image(systemName: "calendar.badge.exclamationmark")
                            .font(.system(size: 32, weight: .medium))
                            .foregroundColor(.gray.opacity(0.6))
                    }
                    
                    VStack(spacing: 8) {
                        Text(NSLocalizedString("No upcoming events", comment: "No upcoming events title"))
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Text(NSLocalizedString("Check back later for new concerts and events!", comment: "No upcoming events description"))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 50)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(colorScheme == .dark ?
                              Color(UIColor.secondarySystemGroupedBackground) :
                              Color.white)
                        .shadow(
                            color: colorScheme == .dark ?
                                Color.clear :
                                Color.black.opacity(0.06),
                            radius: 12,
                            x: 0,
                            y: 4
                        )
                )
                
            } else {
                // Events List
                LazyVStack(spacing: 12) {
                    ForEach(upcomingEvents, id: \.id) { event in
                        NavigationLink(destination: FanEventDetailView(fanEvent: event)) {
                            ModernUpcomingEventCard(event: event)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
        }
    }
    
    // MARK: - Quick Actions Section
    
    private var quickActionsSection: some View {
        VStack(spacing: 20) {
            // Section Header
            HStack {
                HStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(Color.orange.opacity(0.15))
                            .frame(width: 32, height: 32)
                        
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.orange)
                    }
                    
                    Text(NSLocalizedString("Quick Actions", comment: "Quick actions section title"))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
                
                Spacer()
            }
            
            // Actions Grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                QuickActionCard(
                    title: NSLocalizedString("Merchandise", comment: "Merchandise quick action title"),
                    subtitle: NSLocalizedString("Browse & buy", comment: "Merchandise quick action subtitle"),
                    icon: "bag.fill",
                    color: .green,
                    action: { selectedTab = .merchandise }
                )
                
                QuickActionCard(
                    title: NSLocalizedString("Fan Chat", comment: "Fan chat quick action title"),
                    subtitle: NSLocalizedString("Connect with fans", comment: "Fan chat quick action subtitle"),
                    icon: "message.fill",
                    color: .blue,
                    action: { selectedTab = .chat }
                )
            }
        }
    }
    
    private func greetingText() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12:
            return NSLocalizedString("Good morning", comment: "Morning greeting")
        case 12..<17:
            return NSLocalizedString("Good afternoon", comment: "Afternoon greeting")
        default:
            return NSLocalizedString("Good evening", comment: "Evening greeting")
        }
    }
    
    private func loadEvents() {
        guard let user = appState.user else { return }
        
        let groupId: String?
        if user.userType == .fan {
            groupId = user.fanGroupId
        } else {
            groupId = user.groupId
        }
        
        guard let groupId = groupId else { return }
        
        eventService.fetchEvents(for: groupId)
    }
}

// MARK: - Modern Upcoming Event Card

struct ModernUpcomingEventCard: View {
    let event: Event
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack(spacing: 16) {
            // Date Circle
            VStack(spacing: 4) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(hex: event.type.colorHex).opacity(0.15))
                        .frame(width: 56, height: 56)
                    
                    VStack(spacing: 2) {
                        Text(formatDay(event.date))
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(Color(hex: event.type.colorHex))
                        
                        Text(formatMonth(event.date))
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(Color(hex: event.type.colorHex).opacity(0.8))
                    }
                }
                
                Image(systemName: event.type.icon)
                    .font(.caption)
                    .foregroundColor(Color(hex: event.type.colorHex))
            }
            
            // Event Info
            VStack(alignment: .leading, spacing: 6) {
                Text(event.title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                
                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        Image(systemName: "clock.fill")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        Text(formatTime(event.date))
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                    }
                    
                    if let location = event.location, !location.isEmpty, event.type != .birthday {
                        HStack(spacing: 4) {
                            Image(systemName: "location.fill")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            
                            Text(location)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }
                }
                
                // Special badge for birthday events
                if event.type == .birthday {
                    HStack(spacing: 4) {
                        Text("🎉")
                            .font(.caption)
                        Text(NSLocalizedString("Send gift", comment: "Send gift action for birthday events"))
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.pink)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.pink.opacity(0.1))
                    .clipShape(Capsule())
                }
            }
            
            Spacer()
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(colorScheme == .dark ?
                      Color(UIColor.secondarySystemGroupedBackground) :
                      Color.white)
                .shadow(
                    color: colorScheme == .dark ?
                        Color.clear :
                        Color.black.opacity(0.06),
                    radius: 8,
                    x: 0,
                    y: 2
                )
        )
    }
    
    private func formatDay(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
    
    private func formatMonth(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return formatter.string(from: date).uppercased()
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Quick Action Card

struct QuickActionCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let action: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(color)
                }
                
                VStack(spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(colorScheme == .dark ?
                          Color(UIColor.secondarySystemGroupedBackground) :
                          Color.white)
                    .shadow(
                        color: colorScheme == .dark ?
                            Color.clear :
                            Color.black.opacity(0.06),
                        radius: 8,
                        x: 0,
                        y: 2
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Modern Placeholder Views

struct FanMerchandiseView: View {
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        NavigationView {
            VStack(spacing: 40) {
                Spacer()
                
                VStack(spacing: 32) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [.green, .green.opacity(0.7)]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 120, height: 120)
                            .shadow(color: .green.opacity(0.3), radius: 20, x: 0, y: 10)
                        
                        Image(systemName: "bag.fill")
                            .font(.system(size: 40, weight: .bold))
                            .foregroundColor(.white)
                    }
                    
                    VStack(spacing: 16) {
                        Text(NSLocalizedString("Merchandise Store", comment: "Merchandise store title"))
                            .font(.largeTitle)
                            .fontWeight(.heavy)
                            .foregroundColor(.primary)
                        
                        Text(NSLocalizedString("Browse and buy exclusive band merchandise right here! Coming soon with amazing deals and limited edition items.", comment: "Merchandise store description"))
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .lineLimit(nil)
                    }
                }
                .padding(.horizontal, 40)
                
                Spacer()
            }
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.green.opacity(0.02),
                        Color.blue.opacity(0.02)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            )
            .navigationTitle(NSLocalizedString("Merchandise", comment: "Merchandise navigation title"))
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - FAN CHAT VIEW (MAIN INTERFACE)

struct FanChatView: View {
    @StateObject private var fanChatService = FanChatService.shared
    @EnvironmentObject private var appState: AppState
    @State private var showingRulesSheet = false
    @State private var navigationPath = NavigationPath()
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            Group {
                if !fanChatService.hasAcceptedRules {
                    // Show rules acceptance screen
                    FanChatRulesView()
                } else if fanChatService.isLoading {
                    // Loading state
                    FanChatLoadingView()
                } else {
                    // Main chat list
                    FanChatsListView()
                }
            }
            .navigationTitle(NSLocalizedString("Fan Community", comment: "Fan community navigation title"))
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    NavigationLink(destination: FanChatNotificationView()) {
                        Image(systemName: "bell.fill")
                            .foregroundColor(.blue)
                    }
                    
                    Button(action: {
                        showingRulesSheet = true
                    }) {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.blue)
                    }
                }
            }
            .navigationDestination(for: FanChat.self) { chat in
                FanChatDetailView(chat: chat)
            }
            .onAppear {
                // Setup is now handled by FanTabView
            }
            .sheet(isPresented: $showingRulesSheet) {
                FanChatRulesView()
            }
        }
    }
}

// MARK: - FAN CHAT RULES VIEW

struct FanChatRulesView: View {
    @StateObject private var fanChatService = FanChatService.shared
    @EnvironmentObject private var appState: AppState
    @State private var hasScrolledToBottom = false
    @State private var isAccepting = false
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [.blue, .purple]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 80, height: 80)
                            .shadow(color: .blue.opacity(0.3), radius: 12, x: 0, y: 6)
                        
                        Image(systemName: "hand.raised.fill")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)
                    }
                    
                    VStack(spacing: 8) {
                        Text(NSLocalizedString("Welcome to Fan Community!", comment: "Fan community welcome title"))
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text(NSLocalizedString("Before joining our fan community, please read and accept these chat rules.", comment: "Fan community rules description"))
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.horizontal)
                
                // Rules List
                if let rules = fanChatService.chatRules {
                    LazyVStack(spacing: 16) {
                        ForEach(rules.rules) { rule in
                            FanChatRuleCard(rule: rule)
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Bottom spacing for scroll detection
                Rectangle()
                    .fill(Color.clear)
                    .frame(height: 100)
                    .onAppear {
                        hasScrolledToBottom = true
                    }
            }
            .padding(.vertical)
        }
        .safeAreaInset(edge: .bottom) {
            // Accept Button
            VStack(spacing: 12) {
                if hasScrolledToBottom {
                    Button(action: acceptRules) {
                        HStack {
                            if isAccepting {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.title3)
                            }
                            
                            Text(isAccepting ? NSLocalizedString("Accepting...", comment: "Accepting rules loading text") : NSLocalizedString("I Accept These Rules", comment: "Accept rules button text"))
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [.blue, .purple]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    .disabled(isAccepting)
                } else {
                    Text(NSLocalizedString("Scroll down to read all rules", comment: "Scroll to read rules instruction"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding()
                        .background(Color.secondary.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
            .padding()
            .background(
                Rectangle()
                    .fill(colorScheme == .dark ? Color.black : Color.white)
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: -2)
            )
        }
    }
    
    private func acceptRules() {
        guard let user = appState.user,
              let groupId = user.fanGroupId else { return }
        
        isAccepting = true
        fanChatService.acceptChatRules(for: groupId)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            isAccepting = false
        }
    }
}

// MARK: - FAN CHAT RULE CARD

struct FanChatRuleCard: View {
    let rule: FanChatRules.ChatRule
    @Environment(\.colorScheme) private var colorScheme
    
    var severityColor: Color {
        switch rule.severity {
        case .info: return .blue
        case .warning: return .orange
        case .serious: return .red
        }
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(severityColor.opacity(0.15))
                    .frame(width: 48, height: 48)
                
                Image(systemName: rule.icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(severityColor)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(rule.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Text(NSLocalizedString(rule.severity.rawValue.capitalized, comment: "Rule severity level"))
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(severityColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(severityColor.opacity(0.1))
                        .clipShape(Capsule())
                }
                
                Text(rule.description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .lineLimit(nil)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(colorScheme == .dark ?
                      Color(UIColor.secondarySystemGroupedBackground) :
                      Color.white)
                .shadow(
                    color: colorScheme == .dark ?
                        Color.clear :
                        Color.black.opacity(0.06),
                    radius: 8,
                    x: 0,
                    y: 2
                )
        )
    }
}

// MARK: - FAN CHATS LIST VIEW

struct FanChatsListView: View {
    @StateObject private var fanChatService = FanChatService.shared
    @EnvironmentObject private var appState: AppState
    @State private var searchText = ""
    @State private var showingNewChatSheet = false
    @Environment(\.colorScheme) private var colorScheme
    
    private var filteredChats: [FanChat] {
        let allChats = fanChatService.fanChats
        
        if searchText.isEmpty {
            return allChats
        } else {
            let filtered = allChats.filter { chat in
                chat.displayName.localizedCaseInsensitiveContains(searchText) ||
                (chat.description?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
            return filtered
        }
    }
    
    var body: some View {
        VStack {
            // Debug info
            if !fanChatService.fanChats.isEmpty {
                Text(String(format: NSLocalizedString("Debug: %d chats loaded", comment: "Debug message showing number of loaded chats"), fanChatService.fanChats.count))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
            }
            
            if filteredChats.isEmpty {
                // Empty state
                FanChatsEmptyView()
            } else {
                List {
                    ForEach(filteredChats, id: \.id) { chat in
                        NavigationLink(value: chat) {
                            FanChatRowView(chat: chat)
                        }
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                    }
                }
                .listStyle(PlainListStyle())
                .searchable(text: $searchText, prompt: NSLocalizedString("Search chats...", comment: "Search chats placeholder"))
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingNewChatSheet = true
                } label: {
                    Image(systemName: "plus.message.fill")
                        .foregroundColor(.blue)
                }
            }
        }
        .sheet(isPresented: $showingNewChatSheet) {
            FanNewChatView()
        }
        .onAppear {
            // Initial setup completed
        }
    }
}

// MARK: - FAN CHAT ROW VIEW

struct FanChatRowView: View {
    let chat: FanChat
    @Environment(\.colorScheme) private var colorScheme
    
    private var chatIcon: String {
        switch chat.type {
        case .general: return "person.3.fill"
        case .privateChat: return "person.2.fill"
        case .themed: return "tag.fill"
        case .announcement: return "megaphone.fill"
        case .mixed: return "person.2.badge.gearshape.fill"
        }
    }
    
    private var chatIconColor: Color {
        switch chat.type {
        case .general: return .blue
        case .privateChat: return .green
        case .themed: return .purple
        case .announcement: return .orange
        case .mixed: return .red
        }
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Chat Icon or Avatar
            if chat.type == .privateChat, let avatarURL = chat.otherUserAvatarURL, !avatarURL.isEmpty {
                AsyncImage(url: URL(string: avatarURL)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    ZStack {
                        Circle()
                            .fill(chatIconColor.opacity(0.15))
                            .frame(width: 48, height: 48)
                        
                        Image(systemName: "person.fill")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(chatIconColor)
                    }
                }
                .frame(width: 48, height: 48)
                .clipShape(Circle())
            } else {
                // Default chat icon
                ZStack {
                    Circle()
                        .fill(chatIconColor.opacity(0.15))
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: chatIcon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(chatIconColor)
                }
            }
            
            // Chat Info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(chat.displayName)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    if let lastMessage = chat.lastMessage {
                        Text(formatTime(lastMessage.timestamp))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                if let lastMessage = chat.lastMessage {
                    Text(lastMessage.content)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                } else {
                    // Show nothing when no messages
                    Text("")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .italic()
                }
                
                // Chat type indicator
                HStack(spacing: 8) {
                    Text(NSLocalizedString(chat.type.rawValue.capitalized, comment: "Chat type label"))
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(chatIconColor)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(chatIconColor.opacity(0.1))
                        .clipShape(Capsule())
                    
                    if chat.isReadOnlyForFans {
                        Text(NSLocalizedString("Read Only", comment: "Read only chat indicator"))
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(.orange)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.orange.opacity(0.1))
                            .clipShape(Capsule())
                    }
                    
                    Spacer()
                }
            }
        }
        .padding(.vertical, 8)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        let calendar = Calendar.current
        
        if calendar.isDate(date, inSameDayAs: Date()) {
            formatter.timeStyle = .short
        } else if calendar.isDate(date, inSameDayAs: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()) {
            return NSLocalizedString("Yesterday", comment: "Yesterday date label")
        } else {
            formatter.dateStyle = .short
        }
        
        return formatter.string(from: date)
    }
}

// MARK: - FAN CHATS EMPTY VIEW

struct FanChatsEmptyView: View {
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            VStack(spacing: 24) {
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.1))
                        .frame(width: 100, height: 100)
                    
                    Image(systemName: "message.circle")
                        .font(.system(size: 40, weight: .medium))
                        .foregroundColor(.blue.opacity(0.6))
                }
                
                VStack(spacing: 12) {
                    Text(NSLocalizedString("No Chats Yet", comment: "No chats title"))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text(NSLocalizedString("Start connecting with other fans by joining the general chat or creating a private conversation!", comment: "No chats description"))
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(nil)
                }
            }
            .padding(.horizontal, 40)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - FAN CHAT LOADING VIEW

struct FanChatLoadingView: View {
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.2)
                .progressViewStyle(CircularProgressViewStyle(tint: .blue))
            
            Text(NSLocalizedString("Loading chats...", comment: "Loading chats message"))
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// NOTE: FanProfileView is now implemented as a separate standalone view
// The old embedded profile section has been removed from this file

// MARK: - Preview
#Preview {
    FanTabView()
        .environmentObject(AppState.shared)
}
