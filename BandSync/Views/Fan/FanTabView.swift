//
//  FanTabView.swift (ОБНОВЛЕННЫЙ)
//  BandSync
//
//  Created by Claude on 28.07.2025.
//

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
            
            // Home Tab - Главная страница фаната
            FanHomeView(selectedTab: $selectedTab)
                .tabItem {
                    Image(systemName: FanTab.home.icon)
                    Text(NSLocalizedString(FanTab.home.title, comment: ""))
                }
                .tag(FanTab.home)
            
            // Events Tab - ОБНОВЛЕНО: Реальный календарь вместо заглушки
            FanCalendarViewWrapper()
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

        .onAppear {
            if !hasInitialized {
                initializeView()
            }
        }
    }
    
    // ИСПРАВЛЕНИЕ: Инициализация только один раз (как в MainTabView)
    private func initializeView() {
        hasInitialized = true
        setupTabBarAppearance()
    }
    
    private func setupTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.systemBackground
        
        // ДОБАВЛЕНО: Тень как в MainTabView
        appearance.shadowColor = UIColor.black.withAlphaComponent(0.1)
        appearance.shadowImage = UIImage()
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}

// MARK: - Fan Home View (заглушка)
struct FanHomeView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var eventService = EventService.shared
    @Binding var selectedTab: FanTabView.FanTab
    
    // Фильтрация событий для фанатов (как в FanCalendarView)
    private var fanVisibleEvents: [Event] {
        return eventService.events.filter { event in
            // 1. Приватные события НЕ видны фанатам
            if event.isPersonal {
                return false
            }
            
            // 2. Только определенные типы событий видны фанатам
            let fanVisibleTypes: [EventType] = [.concert, .festival, .birthday]
            return fanVisibleTypes.contains(event.type)
        }.sorted { $0.date < $1.date }
    }
    
    // Ближайшие события (следующие 6)
    private var upcomingEvents: [Event] {
        let now = Date()
        let futureEvents = fanVisibleEvents.filter { $0.date >= now }
        return Array(futureEvents.prefix(6))
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Приветствие
                    if let user = appState.user, let fanProfile = user.fanProfile {
                        VStack(spacing: 8) {
                            Text("Welcome, \(fanProfile.nickname)!")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text("Fan Level: \(fanProfile.level.localizedName)")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(Color(hex: fanProfile.level.color))
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                    }
                    
                    // Ближайшие события
                    VStack(spacing: 16) {
                        HStack {
                            Text("🎤 Upcoming Events")
                                .font(.headline)
                            Spacer()
                        }
                        
                        if eventService.isLoading {
                            ProgressView("Loading events...")
                                .frame(maxWidth: .infinity)
                                .padding()
                        } else if upcomingEvents.isEmpty {
                            VStack(spacing: 8) {
                                Image(systemName: "calendar.badge.exclamationmark")
                                    .font(.system(size: 30))
                                    .foregroundColor(.gray.opacity(0.6))
                                
                                Text("No upcoming events")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                Text("Check back later for new concerts!")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                        } else {
                            VStack(spacing: 8) {
                                ForEach(upcomingEvents, id: \.id) { event in
                                    NavigationLink(destination: FanEventDetailView(fanEvent: event)) {
                                        UpcomingEventRow(event: event)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                                
                                if fanVisibleEvents.count > 6 {
                                    Button("See all events") {
                                        selectedTab = .events
                                    }
                                    .font(.caption)
                                    .foregroundColor(.blue)
                                    .padding(.top, 4)
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Fan Club")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                loadEvents()
            }
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

// MARK: - Upcoming Event Row
struct UpcomingEventRow: View {
    let event: Event
    
    var body: some View {
        HStack(spacing: 12) {
            // Иконка типа события
            Image(systemName: event.type.icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Color(hex: event.type.colorHex))
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(event.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Text(formatEventDate(event.date))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if let location = event.location, !location.isEmpty {
                        Text("•")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Image(systemName: "location")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        Text(location)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color.white.opacity(0.8))
        .cornerRadius(8)
    }
    
    private func formatEventDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Заглушки для остальных вкладок
struct FanMerchandiseView: View {
    var body: some View {
        NavigationView {
            VStack {
                Image(systemName: "bag.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
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
                    .foregroundColor(.blue)
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
                            .foregroundColor(.blue)
                        
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
                    .background(Color.gray.opacity(0.1))
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
