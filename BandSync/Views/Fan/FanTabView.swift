import SwiftUI

struct FanTabView: View {
    @EnvironmentObject private var appState: AppState
    @State private var selectedTab: FanTab = .home
    
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
            
            // Home Tab - Главная страница фаната
            FanHomeView()
                .tabItem {
                    Image(systemName: FanTab.home.icon)
                    Text(NSLocalizedString(FanTab.home.title, comment: ""))
                }
                .tag(FanTab.home)
            
            // Events Tab - События и концерты
            FanEventsView()
                .tabItem {
                    Image(systemName: FanTab.events.icon)
                    Text(NSLocalizedString(FanTab.events.title, comment: ""))
                }
                .tag(FanTab.events)
            
            // Merchandise Tab - Мерч
            FanMerchandiseView()
                .tabItem {
                    Image(systemName: FanTab.merchandise.icon)
                    Text(NSLocalizedString(FanTab.merchandise.title, comment: ""))
                }
                .tag(FanTab.merchandise)
            
            // Chat Tab - Фан-чаты
            FanChatView()
                .tabItem {
                    Image(systemName: FanTab.chat.icon)
                    Text(NSLocalizedString(FanTab.chat.title, comment: ""))
                }
                .tag(FanTab.chat)
            
            // Profile Tab - Профиль фаната
            FanProfileView()
                .tabItem {
                    Image(systemName: FanTab.profile.icon)
                    Text(NSLocalizedString(FanTab.profile.title, comment: ""))
                }
                .tag(FanTab.profile)
        }
        .accentColor(.purple) // Фиолетовая тема для фанатов
        .onAppear {
            setupTabBarAppearance()
        }
    }
    
    private func setupTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.systemBackground
        
        // Цвет выбранной иконки - фиолетовый
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor.systemPurple
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor.systemPurple
        ]
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}

// MARK: - Fan Home View (заглушка)
struct FanHomeView: View {
    @EnvironmentObject private var appState: AppState
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Приветствие
                    if let user = appState.user, let fanProfile = user.fanProfile {
                        VStack(spacing: 8) {
                            Image(systemName: "heart.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.purple)
                            
                            Text("Welcome, \(fanProfile.nickname)!")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text("Fan Level: \(fanProfile.level.localizedName)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color.purple.opacity(0.1))
                        .cornerRadius(12)
                    }
                    
                    // Заглушки для контента
                    VStack(spacing: 16) {
                        Text("🎵 Latest News")
                            .font(.headline)
                        Text("Coming soon! Here you'll see the latest updates from your favorite band.")
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                    
                    VStack(spacing: 16) {
                        Text("🎤 Upcoming Events")
                            .font(.headline)
                        Text("Check the Events tab to see upcoming concerts and meet & greets!")
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Fan Club")
        }
    }
}

// MARK: - Заглушки для остальных вкладок
struct FanEventsView: View {
    var body: some View {
        NavigationView {
            VStack {
                Image(systemName: "calendar")
                    .font(.system(size: 60))
                    .foregroundColor(.purple)
                Text("Events Coming Soon!")
                    .font(.title2)
                    .fontWeight(.bold)
                Text("Here you'll see upcoming concerts, meet & greets, and exclusive fan events.")
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding()
            }
            .navigationTitle("Events")
        }
    }
}

struct FanMerchandiseView: View {
    var body: some View {
        NavigationView {
            VStack {
                Image(systemName: "bag.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.purple)
                Text("Merchandise Coming Soon!")
                    .font(.title2)
                    .fontWeight(.bold)
                Text("Browse and buy exclusive band merchandise right here!")
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding()
            }
            .navigationTitle("Merchandise")
        }
    }
}

struct FanChatView: View {
    var body: some View {
        NavigationView {
            VStack {
                Image(systemName: "message.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.purple)
                Text("Fan Chat Coming Soon!")
                    .font(.title2)
                    .fontWeight(.bold)
                Text("Connect with other fans and participate in exclusive discussions!")
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding()
            }
            .navigationTitle("Fan Chat")
        }
    }
}

struct FanProfileView: View {
    @EnvironmentObject private var appState: AppState
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if let user = appState.user, let fanProfile = user.fanProfile {
                    VStack(spacing: 16) {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.purple)
                        
                        Text(fanProfile.nickname)
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("Fan Level: \(fanProfile.level.localizedName)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        if !fanProfile.location.isEmpty {
                            Text("📍 \(fanProfile.location)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        if !fanProfile.favoriteSong.isEmpty {
                            Text("🎵 Favorite: \(fanProfile.favoriteSong)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(Color.purple.opacity(0.1))
                    .cornerRadius(12)
                }
                
                Button("Logout") {
                    appState.logout()
                }
                .foregroundColor(.red)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Profile")
        }
    }
}

// MARK: - Preview
#Preview {
    FanTabView()
        .environmentObject(AppState.shared)
}
