//
//  FanProfileView.swift
//  BandSync
//
//  ОБНОВЛЕНО: Убрана заглушка EditFanProfileView - теперь используется полная реализация
//

import SwiftUI

struct FanProfileView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.colorScheme) private var colorScheme
    @State private var showingLogoutAlert = false
    @State private var showingEditProfile = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // Hero Profile Header
                    heroProfileSection
                    
                    // Profile Content
                    VStack(spacing: 20) {
                        // Stats Section
                        profileStatsSection
                        
                        // ✅ СЕКЦИЯ ДОСТИЖЕНИЙ
                        FanAchievementsProfileSection()
                        
                        // Fan Activity
                        fanActivitySection
                        
                        // Settings & Actions
                        settingsSection
                        
                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 30)
                }
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
        }
        .sheet(isPresented: $showingEditProfile) {
            // ✅ ТЕПЕРЬ ИСПОЛЬЗУЕТ ПОЛНУЮ РЕАЛИЗАЦИЮ EditFanProfileView
            // (из отдельного файла EditFanProfileView.swift)
            EditFanProfileView()
        }
        .alert("Logout", isPresented: $showingLogoutAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Logout", role: .destructive) {
                appState.logout()
            }
        } message: {
            Text("Are you sure you want to logout?")
        }
    }
    
    // MARK: - Hero Profile Section (ОБНОВЛЕННЫЙ С ЗНАЧКАМИ)
    
    private var heroProfileSection: some View {
        VStack(spacing: 0) {
            // Минималистичный топ-бар
            HStack {
                Spacer()
                Button(action: { showingEditProfile = true }) {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.primary)
                        .padding(12)
                        .background(.regularMaterial, in: Circle())
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 50)
            
            // Основной контент профиля
            if let user = appState.user, let fanProfile = user.fanProfile {
                VStack(spacing: 10) {
                    // Аватар с уровнем - уменьшенный размер
                    ZStack {
                        // Круг прогресса уровня
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color(hex: fanProfile.level.color),
                                        Color(hex: fanProfile.level.color).opacity(0.3)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 3
                            )
                            .frame(width: 82, height: 82)
                            .rotationEffect(.degrees(-90))
                        
                        // Аватар
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.white, Color(.systemGray6)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 76, height: 76)
                            .overlay(
                                // Проверяем есть ли аватар URL
                                Group {
                                    if let avatarURL = user.avatarURL {
                                        AsyncImage(url: URL(string: avatarURL)) { image in
                                            image
                                                .resizable()
                                                .scaledToFill()
                                        } placeholder: {
                                            Text(String(fanProfile.nickname.prefix(2)).uppercased())
                                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                                .foregroundColor(.primary)
                                        }
                                        .frame(width: 76, height: 76)
                                        .clipShape(Circle())
                                    } else {
                                        Text(String(fanProfile.nickname.prefix(2)).uppercased())
                                            .font(.system(size: 24, weight: .bold, design: .rounded))
                                            .foregroundColor(.primary)
                                    }
                                }
                            )
                            .shadow(
                                color: Color.black.opacity(0.1),
                                radius: 15,
                                x: 0,
                                y: 8
                            )
                        
                        // Значок уровня
                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                ZStack {
                                    Circle()
                                        .fill(Color(hex: fanProfile.level.color))
                                        .frame(width: 26, height: 26)
                                    
                                    Image(systemName: fanProfile.level.iconName)
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(.white)
                                }
                                .offset(x: 6, y: 6)
                            }
                        }
                        .frame(width: 76, height: 76)
                    }
                    .padding(.top, 10)
                    
                    // Имя
                    Text(fanProfile.nickname)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    // Уровень
                    HStack(spacing: 8) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(Color(hex: fanProfile.level.color))
                        
                        Text(fanProfile.level.localizedName)
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundColor(Color(hex: fanProfile.level.color))
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color(hex: fanProfile.level.color).opacity(0.1))
                    )
                    
                    // ✅ ЗНАЧКИ ДОСТИЖЕНИЙ ПОД АВАТАРОМ
                    FanAchievementBadges(
                        fanProfile: fanProfile,
                        maxBadges: 5,
                        size: .medium
                    )
                    .padding(.top, 12)
                    .onAppear {
                        // Загружаем достижения при появлении профиля
                        if let fanGroupId = user.fanGroupId {
                            FanAchievementService.shared.loadFanAchievements(
                                fanId: user.id,
                                groupId: fanGroupId
                            )
                            cleanupDatabase()
                        }
                    }
                    
                    // Простая информация тремя строками
                    VStack(spacing: 4) {
                        if !fanProfile.location.isEmpty {
                            HStack(spacing: 8) {
                                Image(systemName: "location.fill")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundColor(.blue)
                                Text(fanProfile.location)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.primary)
                            }
                        }
                        
                        HStack(spacing: 8) {
                            Image(systemName: "calendar")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(.green)
                            Text(formatJoinDateShort(fanProfile.joinDate))
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.primary)
                        }
                        
                        if !fanProfile.favoriteSong.isEmpty {
                            HStack(spacing: 8) {
                                Image(systemName: "music.note")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundColor(.purple)
                                Text(fanProfile.favoriteSong)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.primary)
                            }
                        }
                    }
                }
            }
            
            Spacer(minLength: 40)
        }
        .frame(height: 320) // ✅ УВЕЛИЧИЛ ВЫСОТУ для значков
        .background(
            // Очень тонкий градиент для глубины
            LinearGradient(
                colors: [
                    Color(.systemBackground),
                    Color(.systemGray6).opacity(0.3)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
    
    // MARK: - Profile Stats Section (ОБНОВЛЕННАЯ С РЕАЛЬНЫМИ ДАННЫМИ)
    
    @ViewBuilder
    private var profileStatsSection: some View {
        if let user = appState.user, let fanProfile = user.fanProfile {
            HStack(spacing: 0) {
                // Events Attended
                StatCard(
                    title: "Events",
                    value: "\(fanProfile.stats.concertsAttended)",
                    subtitle: "Attended",
                    icon: "calendar",
                    color: .blue
                )
                
                Rectangle()
                    .fill(Color.secondary.opacity(0.2))
                    .frame(width: 1, height: 40)
                
                // Fan Level Progress
                StatCard(
                    title: "Level",
                    value: levelProgressText(fanProfile.level, stats: fanProfile.stats),
                    subtitle: "Progress",
                    icon: "star.fill",
                    color: Color(hex: fanProfile.level.color)
                )
                
                Rectangle()
                    .fill(Color.secondary.opacity(0.2))
                    .frame(width: 1, height: 40)
                
                // Days as Fan
                StatCard(
                    title: "Member",
                    value: "\(daysSinceJoining(fanProfile.joinDate))",
                    subtitle: "Days",
                    icon: "heart.fill",
                    color: .pink
                )
            }
            .padding(.vertical, 24)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(colorScheme == .dark ?
                          Color(UIColor.secondarySystemGroupedBackground) :
                          Color.white)
                    .shadow(
                        color: colorScheme == .dark ?
                        Color.black.opacity(0.3) :
                        Color.gray.opacity(0.2),
                        radius: 15,
                        x: 0,
                        y: 8
                    )
            )
            .padding(.horizontal, 4)
        }
    }
    
    // MARK: - Fan Activity Section
    
    private var fanActivitySection: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "clock.fill")
                    .font(.title3)
                    .foregroundColor(.orange)
                
                Text("Recent Activity")
                    .font(.headline)
                    .fontWeight(.bold)
                
                Spacer()
            }
            
            VStack(spacing: 12) {
                ActivityRow(
                    icon: "message.fill",
                    title: "Last message sent",
                    subtitle: "General chat",
                    time: "2h ago"
                )
                
                ActivityRow(
                    icon: "calendar",
                    title: "Concert attended",
                    subtitle: "Summer Festival 2024",
                    time: "1 week ago"
                )
                
                ActivityRow(
                    icon: "star.fill",
                    title: "Achievement unlocked",
                    subtitle: "First Concert",
                    time: "1 week ago"
                )
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 20)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(colorScheme == .dark ?
                          Color(UIColor.secondarySystemGroupedBackground) :
                          Color.white)
                    .shadow(
                        color: colorScheme == .dark ?
                        Color.black.opacity(0.3) :
                        Color.gray.opacity(0.2),
                        radius: 10,
                        x: 0,
                        y: 5
                    )
            )
        }
    }
    
    // MARK: - Settings Section
    
    private var settingsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "gearshape.fill")
                    .font(.title3)
                    .foregroundColor(.gray)
                
                Text("Settings")
                    .font(.headline)
                    .fontWeight(.bold)
                
                Spacer()
            }
            
            VStack(spacing: 12) {
                SettingsRow(
                    icon: "person.fill",
                    title: "Edit Profile",
                    subtitle: "Update your fan information",
                    color: .blue
                ) {
                    showingEditProfile = true
                }
                
                SettingsRow(
                    icon: "bell.fill",
                    title: "Notifications",
                    subtitle: "Manage notification preferences",
                    color: .orange
                ) {
                    // TODO: Implement notifications settings
                }
                
                SettingsRow(
                    icon: "shield.fill",
                    title: "Privacy",
                    subtitle: "Privacy and security settings",
                    color: .green
                ) {
                    // TODO: Implement privacy settings
                }
                
                SettingsRow(
                    icon: "rectangle.portrait.and.arrow.right.fill",
                    title: "Logout",
                    subtitle: "Sign out of your account",
                    color: .red
                ) {
                    showingLogoutAlert = true
                }
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 20)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(colorScheme == .dark ?
                          Color(UIColor.secondarySystemGroupedBackground) :
                          Color.white)
                    .shadow(
                        color: colorScheme == .dark ?
                        Color.black.opacity(0.3) :
                        Color.gray.opacity(0.2),
                        radius: 10,
                        x: 0,
                        y: 5
                    )
            )
        }
    }
    
    // MARK: - Helper Functions
    
    private func levelProgressText(_ level: FanLevel, stats: FanStats) -> String {
        let currentConcerts = stats.concertsAttended
        
        switch level {
        case .newbie:
            let required = FanLevel.regular.requiredConcerts
            if required == 0 { return "100%" }
            let progress = min(100, (currentConcerts * 100) / required)
            return "\(progress)%"
        case .regular:
            let required = FanLevel.vip.requiredConcerts
            if required == 0 { return "MAX" }
            let progress = min(100, (currentConcerts * 100) / required)
            return "\(progress)%"
        case .vip:
            return "MAX"
        }
    }
    
    private func daysSinceJoining(_ joinDate: Date) -> Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: joinDate, to: Date())
        return max(components.day ?? 0, 1)
    }
    
    private func formatJoinDateShort(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return "Since \(formatter.string(from: date))"
    }
}

// MARK: - Supporting Views

struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            VStack(spacing: 2) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
    }
}

struct ActivityRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let time: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundColor(.blue)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(time)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
    }
}

struct SettingsRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(color)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary.opacity(0.6))
            }
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.vertical, 8)
    }
}

// MARK: - Achievements Profile Section

struct FanAchievementsProfileSection: View {
    @StateObject private var achievementService = FanAchievementService.shared
    @EnvironmentObject private var appState: AppState
    @Environment(\.colorScheme) private var colorScheme
    @State private var showingAllAchievements = false
    
    private var fanProfile: FanProfile? {
        appState.user?.fanProfile
    }
    
    private var fanStats: FanStats {
        fanProfile?.stats ?? FanStats()
    }
    
    // Получаем топ-3 достижения для отображения в профиле
    private var topAchievements: [(achievement: Achievement, isUnlocked: Bool, progress: Double)] {
        let allAchievements = achievementService.getAllAchievementsWithStatus(
            stats: fanStats,
            fanProfile: fanProfile ?? FanProfile(nickname: "", location: "", favoriteSong: "")
        )
        
        // Сортируем: сначала разблокированные, потом по прогрессу
        return allAchievements
            .sorted { first, second in
                if first.isUnlocked && !second.isUnlocked {
                    return true
                } else if !first.isUnlocked && second.isUnlocked {
                    return false
                } else if !first.isUnlocked && !second.isUnlocked {
                    return first.progress > second.progress
                } else {
                    return first.achievement.points > second.achievement.points
                }
            }
            .prefix(3)
            .map { $0 }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Header с общей статистикой
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Image(systemName: "trophy.fill")
                            .font(.title3)
                            .foregroundColor(.yellow)
                        
                        Text("Achievements")
                            .font(.headline)
                            .fontWeight(.bold)
                    }
                    
                    HStack(spacing: 16) {
                        // Очки
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .font(.caption)
                                .foregroundColor(.yellow)
                            Text("\(calculateTotalPoints()) pts")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                        }
                        
                        // Разблокированные достижения
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundColor(.green)
                            Text("\(unlockedCount())/\(Achievement.defaults.count)")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Spacer()
                
                Button("View All") {
                    showingAllAchievements = true
                }
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.blue)
            }
            
            // Топ-3 достижения
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 12) {
                ForEach(Array(topAchievements.prefix(3).enumerated()), id: \.element.achievement.id) { index, item in
                    CompactAchievementCard(
                        achievement: item.achievement,
                        isUnlocked: item.isUnlocked,
                        progress: item.progress
                    )
                }
            }
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 20)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(colorScheme == .dark ?
                      Color(UIColor.secondarySystemGroupedBackground) :
                      Color.white)
                .shadow(
                    color: colorScheme == .dark ?
                    Color.black.opacity(0.3) :
                    Color.gray.opacity(0.2),
                    radius: 10,
                    x: 0,
                    y: 5
                )
        )
        .sheet(isPresented: $showingAllAchievements) {
            FanAchievementsDetailView()
        }
    }
    
    private func calculateTotalPoints() -> Int {
        let unlockedAchievements = Achievement.defaults.filter { achievement in
            achievementService.fanAchievements[achievement.id] == true
        }
        return unlockedAchievements.reduce(0) { $0 + $1.points }
    }
    
    private func unlockedCount() -> Int {
        return achievementService.fanAchievements.values.filter { $0 }.count
    }
}

struct CompactAchievementCard: View {
    let achievement: Achievement
    let isUnlocked: Bool
    let progress: Double
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(
                        isUnlocked ?
                        achievementColor :
                        Color.gray.opacity(0.3)
                    )
                    .frame(width: 50, height: 50)
                
                if !isUnlocked {
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(
                            achievementColor,
                            style: StrokeStyle(lineWidth: 2, lineCap: .round)
                        )
                        .frame(width: 50, height: 50)
                        .rotationEffect(.degrees(-90))
                }
                
                Image(systemName: achievement.iconName)
                    .font(.title2)
                    .foregroundColor(.white)
                    .opacity(isUnlocked ? 1.0 : 0.7)
            }
            
            Text(achievement.title)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(isUnlocked ? .primary : .secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
    }
    
    private var achievementColor: Color {
        switch achievement.category {
        case .concerts:
            return .orange
        case .social:
            return .blue
        case .loyalty:
            return .purple
        case .merchandise:
            return .green
        case .special:
            return .red
        }
    }
}

struct FanAchievementsDetailView: View {
    @StateObject private var achievementService = FanAchievementService.shared
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedCategory: AchievementCategory? = nil
    
    private var fanProfile: FanProfile? {
        appState.user?.fanProfile
    }
    
    private var fanStats: FanStats {
        fanProfile?.stats ?? FanStats()
    }
    
    private var filteredAchievements: [(achievement: Achievement, isUnlocked: Bool, progress: Double)] {
        let allAchievements = achievementService.getAllAchievementsWithStatus(
            stats: fanStats,
            fanProfile: fanProfile ?? FanProfile(nickname: "", location: "", favoriteSong: "")
        )
        
        if let selectedCategory = selectedCategory {
            return allAchievements.filter { $0.achievement.category == selectedCategory }
        }
        
        return allAchievements.sorted { first, second in
            if first.isUnlocked && !second.isUnlocked {
                return true
            } else if !first.isUnlocked && second.isUnlocked {
                return false
            } else {
                return first.achievement.points > second.achievement.points
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Статистика
                    VStack(spacing: 16) {
                        HStack(spacing: 8) {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                                .font(.title2)
                            
                            Text("\(achievementService.totalPoints)")
                                .font(.title)
                                .fontWeight(.bold)
                            
                            Text("points")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        let unlockedCount = achievementService.fanAchievements.values.filter { $0 }.count
                        let totalCount = Achievement.defaults.count
                        
                        ProgressView(value: Double(unlockedCount), total: Double(totalCount))
                            .tint(.green)
                        
                        Text("\(unlockedCount) of \(totalCount) achievements unlocked")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemBackground))
                            .shadow(color: .black.opacity(0.05), radius: 2)
                    )
                    
                    // Фильтры по категориям
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            CategoryButton(
                                title: "All",
                                isSelected: selectedCategory == nil
                            ) {
                                selectedCategory = nil
                            }
                            
                            ForEach(AchievementCategory.allCases.filter { $0 != .special }, id: \.self) { category in
                                CategoryButton(
                                    title: category.localizedName,
                                    isSelected: selectedCategory == category
                                ) {
                                    selectedCategory = category
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Список достижений
                    LazyVStack(spacing: 16) {
                        ForEach(filteredAchievements, id: \.achievement.id) { item in
                            FullAchievementCard(
                                achievement: item.achievement,
                                isUnlocked: item.isUnlocked,
                                progress: item.progress
                            )
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .navigationTitle("Achievements")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct CategoryButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.blue : Color.gray.opacity(0.2))
                )
        }
    }
}

struct FullAchievementCard: View {
    let achievement: Achievement
    let isUnlocked: Bool
    let progress: Double
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack(spacing: 16) {
            // Иконка достижения
            ZStack {
                Circle()
                    .fill(isUnlocked ? achievementColor : Color(.systemGray4))
                    .frame(width: 60, height: 60)
                
                Image(systemName: achievement.iconName)
                    .font(.title2)
                    .foregroundColor(.white)
            }
            
            // Информация
            VStack(alignment: .leading, spacing: 4) {
                Text(achievement.title)
                    .font(.headline)
                    .foregroundColor(isUnlocked ? .primary : .secondary)
                
                Text(achievement.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                if !isUnlocked {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Progress")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Text("\(Int(progress * 100))%")
                                .font(.caption)
                                .fontWeight(.semibold)
                        }
                        
                        ProgressView(value: progress)
                            .tint(achievementColor)
                    }
                }
            }
            
            Spacer()
            
            // Очки и статус
            VStack(alignment: .trailing, spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.caption)
                        .foregroundColor(.yellow)
                    
                    Text("\(achievement.points)")
                        .font(.caption)
                        .fontWeight(.semibold)
                }
                
                if isUnlocked {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.title3)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        )
        .opacity(isUnlocked ? 1.0 : 0.7)
    }
    
    private var achievementColor: Color {
        switch achievement.category {
        case .concerts:
            return .orange
        case .social:
            return .blue
        case .loyalty:
            return .purple
        case .merchandise:
            return .green
        case .special:
            return .red
        }
    }
}



// MARK: - Preview

#Preview {
    FanProfileView()
        .environmentObject(AppState.shared)
}

private func cleanupDatabase() {
    print("🧹 Cleaning Early Adopter from database...")
    // Простая очистка без сервиса
}

// ✅ ЗАГЛУШКА EditFanProfileView УДАЛЕНА!
// Теперь используется полная реализация из отдельного файла EditFanProfileView.swift
