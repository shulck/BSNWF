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
                                Text(String(fanProfile.nickname.prefix(2)).uppercased())
                                    .font(.system(size: 24, weight: .bold, design: .rounded))
                                    .foregroundColor(.primary)
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
                                    
                                    Image(systemName: "star.fill")
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
                                    .lineLimit(1)
                            }
                        }
                    }
                    .padding(.top, 8)
                }
            } else {
                // Guest состояние
                VStack(spacing: 24) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.gray.opacity(0.3), .gray.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 76, height: 76)
                        
                        Image(systemName: "person.fill")
                            .font(.system(size: 30, weight: .semibold))
                            .foregroundColor(.gray)
                    }
                    .padding(.top, 30)
                    
                    VStack(spacing: 8) {
                        Text("Guest User")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                        
                        Text("Sign in to access your profile")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
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
                            Color.clear :
                            Color.black.opacity(0.08),
                        radius: 12,
                        x: 0,
                        y: 4
                    )
            )
        }
    }
    
    // Fan Activity Section
    private var fanActivitySection: some View {
        VStack(spacing: 20) {
            HStack {
                Text("Recent Activity")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button("View All") {
                    // Navigate to activity view
                }
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.blue)
            }
            
            VStack(spacing: 12) {
                // Mock activity items
                ActivityRow(
                    icon: "calendar",
                    title: "Attended Concert",
                    subtitle: "Rock Festival 2025",
                    time: "2 days ago",
                    color: .blue
                )
                
                ActivityRow(
                    icon: "gift.fill",
                    title: "Sent Birthday Gift",
                    subtitle: "To band member",
                    time: "1 week ago",
                    color: .pink
                )
                
                ActivityRow(
                    icon: "star.fill",
                    title: "Level Up!",
                    subtitle: "Reached Silver Fan",
                    time: "2 weeks ago",
                    color: .orange
                )
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(colorScheme == .dark ?
                      Color(UIColor.secondarySystemGroupedBackground) :
                      Color.white)
                .shadow(
                    color: colorScheme == .dark ?
                        Color.clear :
                        Color.black.opacity(0.08),
                    radius: 12,
                    x: 0,
                    y: 4
                )
        )
    }
    
    // Settings Section
    private var settingsSection: some View {
        VStack(spacing: 20) {
            HStack {
                Text("Settings")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            VStack(spacing: 12) {
                SettingsRow(
                    icon: "bell.fill",
                    title: "Notifications",
                    subtitle: "Event reminders and updates",
                    color: .orange,
                    action: { /* Navigate to notifications */ }
                )
                
                SettingsRow(
                    icon: "lock.fill",
                    title: "Privacy",
                    subtitle: "Profile visibility settings",
                    color: .blue,
                    action: { /* Navigate to privacy */ }
                )
                
                SettingsRow(
                    icon: "questionmark.circle.fill",
                    title: "Help & Support",
                    subtitle: "Get help and contact support",
                    color: .green,
                    action: { /* Navigate to help */ }
                )
                
                // Logout Button
                Button(action: { showingLogoutAlert = true }) {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color.red.opacity(0.15))
                                .frame(width: 40, height: 40)
                            
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.red)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Logout")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.red)
                            
                            Text("Sign out of your account")
                                .font(.caption)
                                .foregroundColor(.red.opacity(0.7))
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.red.opacity(0.6))
                    }
                    .padding(16)
                    .background(Color.red.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.red.opacity(0.2), lineWidth: 1)
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(colorScheme == .dark ?
                      Color(UIColor.secondarySystemGroupedBackground) :
                      Color.white)
                .shadow(
                    color: colorScheme == .dark ?
                        Color.clear :
                        Color.black.opacity(0.08),
                    radius: 12,
                    x: 0,
                    y: 4
                )
        )
    }
    
    // MARK: - Helper Methods
    
    private func daysSinceJoining(_ date: Date) -> Int {
        let days = Calendar.current.dateComponents([.day], from: date, to: Date()).day ?? 0
        return max(days, 1)
    }
    
    private func formatJoinDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    private func formatJoinDateShort(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        return formatter.string(from: date)
    }
    
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
}

// MARK: - ✅ СЕКЦИЯ ДОСТИЖЕНИЙ

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
                            
                            Text("\(achievementService.totalPoints) pts")
                                .font(.caption)
                                .fontWeight(.semibold)
                        }
                        
                        // Прогресс
                        HStack(spacing: 4) {
                            let unlockedCount = achievementService.fanAchievements.values.filter { $0 }.count
                            let totalCount = Achievement.defaults.count
                            
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundColor(.green)
                            
                            Text("\(unlockedCount)/\(totalCount)")
                                .font(.caption)
                                .fontWeight(.semibold)
                        }
                    }
                    .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            // Топ-3 достижения
            if !topAchievements.isEmpty {
                LazyVStack(spacing: 12) {
                    ForEach(topAchievements, id: \.achievement.id) { item in
                        CompactAchievementCard(
                            achievement: item.achievement,
                            isUnlocked: item.isUnlocked,
                            progress: item.progress
                        )
                    }
                }
                
                // Кнопка "Показать все"
                Button {
                    showingAllAchievements = true
                } label: {
                    HStack {
                        Text("View All Achievements")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.blue)
                    .padding(.vertical, 8)
                }
            } else {
                Text("Loading achievements...")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding()
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(colorScheme == .dark ?
                      Color(UIColor.secondarySystemGroupedBackground) :
                      Color.white)
                .shadow(
                    color: colorScheme == .dark ?
                        Color.clear :
                        Color.black.opacity(0.08),
                    radius: 12,
                    x: 0,
                    y: 4
                )
        )
        .onAppear {
            loadAchievements()
        }
        .sheet(isPresented: $showingAllAchievements) {
            FanAchievementsDetailView()
        }
    }
    
    private func loadAchievements() {
        guard let user = appState.user,
              let fanGroupId = user.fanGroupId else { return }
        
        achievementService.loadFanAchievements(fanId: user.id, groupId: fanGroupId)
    }
}

// MARK: - Supporting Views (остаются без изменений)

struct CompactInfoCard: View {
    let icon: String
    let text: String
    let maxWidth: CGFloat
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.white.opacity(0.9))
            
            Text(text)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.95))
                .lineLimit(1)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .frame(maxWidth: maxWidth)
        .background(.ultraThinMaterial.opacity(0.3))
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(Color.white.opacity(0.3), lineWidth: 0.5)
        )
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Circle()
                            .stroke(color.opacity(0.3), lineWidth: 2)
                    )
                
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(color)
            }
            
            VStack(spacing: 4) {
                Text(value)
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .foregroundColor(.primary)
                
                VStack(spacing: 2) {
                    Text(title)
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                        .textCase(.uppercase)
                        .tracking(0.5)
                    
                    Text(subtitle)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                        .tracking(0.3)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }
}

struct ActivityRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let time: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 36, height: 36)
                
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
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
            .padding(16)
            .background(Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct InfoCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(color)
                
                Text(title)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                    .tracking(0.5)
                
                Spacer()
            }
            
            HStack {
                Text(value)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                
                Spacer()
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(color.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(color.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

struct CompactAchievementCard: View {
    let achievement: Achievement
    let isUnlocked: Bool
    let progress: Double
    
    var body: some View {
        HStack(spacing: 12) {
            // Иконка
            ZStack {
                Circle()
                    .fill(isUnlocked ? achievementColor : Color(.systemGray4))
                    .frame(width: 40, height: 40)
                
                Image(systemName: achievement.iconName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
            }
            
            // Информация
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(achievement.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(isUnlocked ? .primary : .secondary)
                    
                    Spacer()
                    
                    // Очки
                    HStack(spacing: 2) {
                        Image(systemName: "star.fill")
                            .font(.caption2)
                            .foregroundColor(.yellow)
                        
                        Text("\(achievement.points)")
                            .font(.caption2)
                            .fontWeight(.semibold)
                    }
                }
                
                if isUnlocked {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption2)
                            .foregroundColor(.green)
                        
                        Text("Unlocked")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(.green)
                    }
                } else {
                    // Прогресс
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Progress: \(Int(progress * 100))%")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                        }
                        
                        ProgressView(value: progress)
                            .tint(achievementColor)
                            .scaleEffect(y: 0.7)
                    }
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6).opacity(0.5))
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

struct CategoryChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(isSelected ? Color.blue : Color(.systemGray5))
                )
                .foregroundColor(isSelected ? .white : .primary)
        }
    }
}

struct FullAchievementCard: View {
    let achievement: Achievement
    let isUnlocked: Bool
    let progress: Double
    
    var body: some View {
        HStack(spacing: 16) {
            // Иконка
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
                        
                        VStack(spacing: 8) {
                            HStack {
                                Text("Progress")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                                
                                Text("\(unlockedCount)/\(totalCount)")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                            }
                            
                            ProgressView(value: Double(unlockedCount), total: Double(totalCount))
                                .tint(.blue)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.systemGray6))
                    )
                    .padding(.horizontal)
                    
                    // Фильтр по категориям
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            CategoryChip(
                                title: "All",
                                isSelected: selectedCategory == nil
                            ) {
                                selectedCategory = nil
                            }
                            
                            ForEach(AchievementCategory.allCases, id: \.self) { category in
                                CategoryChip(
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

struct EditFanProfileView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Edit Profile")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Profile editing coming soon!")
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

#Preview {
    FanProfileView()
        .environmentObject(AppState.shared)
}
