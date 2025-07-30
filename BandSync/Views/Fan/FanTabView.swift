import SwiftUI

struct FanTabView: View {
    @EnvironmentObject private var appState: AppState
    @State private var selectedTab: FanTab = .home
    @State private var hasInitialized = false
    
    enum FanTab: String, CaseIterable {
        case home = "Home"
        case events = "Events"
        case merchandise = "Merch"
        case chat = "Chat"
        case profile = "Profile"
        
        var icon: String {
            switch self {
            case .home: return "house.fill"
            case .events: return "calendar"
            case .merchandise: return "bag.fill"
            case .chat: return "message.fill"
            case .profile: return "person.fill"
            }
        }
        
        var title: String {
            switch self {
            case .home: return "Home"
            case .events: return "Events"
            case .merchandise: return "Merchandise"
            case .chat: return "Chat"
            case .profile: return "Profile"
            }
        }
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            
            // Home Tab
            FanHomeView(selectedTab: $selectedTab)
                .tabItem {
                    Image(systemName: FanTab.home.icon)
                    Text(NSLocalizedString(FanTab.home.title, comment: ""))
                }
                .tag(FanTab.home)
            
            // Events Tab
            FanCalendarViewWrapper()
                .tabItem {
                    Image(systemName: FanTab.events.icon)
                    Text(NSLocalizedString(FanTab.events.title, comment: ""))
                }
                .tag(FanTab.events)
            
            // Merchandise Tab
            FanMerchandiseView()
                .tabItem {
                    Image(systemName: FanTab.merchandise.icon)
                    Text(NSLocalizedString(FanTab.merchandise.title, comment: ""))
                }
                .tag(FanTab.merchandise)
            
            // Chat Tab
            FanChatView()
                .tabItem {
                    Image(systemName: FanTab.chat.icon)
                    Text(NSLocalizedString(FanTab.chat.title, comment: ""))
                }
                .tag(FanTab.chat)
            
            // Profile Tab - NOW USES THE STANDALONE VERSION
            FanProfileView()
                .tabItem {
                    Image(systemName: FanTab.profile.icon)
                    Text(NSLocalizedString(FanTab.profile.title, comment: ""))
                }
                .tag(FanTab.profile)
        }
        .onChange(of: selectedTab) { newTab in
            if newTab == .events {
                NotificationCenter.default.post(name: NSNotification.Name("FanCalendarTabSelected"), object: nil)
            }
        }
        .onAppear {
            if !hasInitialized {
                initializeView()
            }
        }
    }
    
    private func initializeView() {
        hasInitialized = true
        setupTabBarAppearance()
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
                        Text("Fan")
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
                    
                    Text("Upcoming Events")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                if !upcomingEvents.isEmpty {
                    Button("See all") {
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
                    
                    Text("Loading events...")
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
                        Text("No upcoming events")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Text("Check back later for new concerts and events!")
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
                    
                    Text("Quick Actions")
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
                    title: "Merchandise",
                    subtitle: "Browse & buy",
                    icon: "bag.fill",
                    color: .green,
                    action: { selectedTab = .merchandise }
                )
                
                QuickActionCard(
                    title: "Fan Chat",
                    subtitle: "Connect with fans",
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
            return "Good morning"
        case 12..<17:
            return "Good afternoon"
        default:
            return "Good evening"
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
                        Text("Send gift")
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
                        Text("Merchandise Store")
                            .font(.largeTitle)
                            .fontWeight(.heavy)
                            .foregroundColor(.primary)
                        
                        Text("Browse and buy exclusive band merchandise right here! Coming soon with amazing deals and limited edition items.")
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
            .navigationTitle("Merchandise")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct FanChatView: View {
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
                                    gradient: Gradient(colors: [.blue, .purple]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 120, height: 120)
                            .shadow(color: .blue.opacity(0.3), radius: 20, x: 0, y: 10)
                        
                        Image(systemName: "message.fill")
                            .font(.system(size: 40, weight: .bold))
                            .foregroundColor(.white)
                    }
                    
                    VStack(spacing: 16) {
                        Text("Fan Community")
                            .font(.largeTitle)
                            .fontWeight(.heavy)
                            .foregroundColor(.primary)
                        
                        Text("Connect with other fans and participate in exclusive discussions! Share your love for the music and make new friends.")
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
                        Color.blue.opacity(0.02),
                        Color.purple.opacity(0.02)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            )
            .navigationTitle("Fan Chat")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// NOTE: FanProfileView is now implemented as a separate standalone view
// The old embedded profile section has been removed from this file

// MARK: - Preview
#Preview {
    FanTabView()
        .environmentObject(AppState.shared)
}
