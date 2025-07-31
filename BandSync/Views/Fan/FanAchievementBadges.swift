//
//  FanAchievementBadges.swift
//  BandSyncApp
//
//  Created by Oleksandr Kuziakin on 31.07.2025.
//

import SwiftUI

// MARK: - Achievement Badges Component
struct FanAchievementBadges: View {
    let fanProfile: FanProfile
    let maxBadges: Int
    let size: FanBadgeSize
    
    @StateObject private var achievementService = FanAchievementService.shared
    @State private var showingAllBadges = false
    
    init(fanProfile: FanProfile, maxBadges: Int = 5, size: FanBadgeSize = .medium) {
        self.fanProfile = fanProfile
        self.maxBadges = maxBadges
        self.size = size
    }
    
    // Получаем разблокированные достижения, отсортированные по важности
    private var unlockedAchievements: [Achievement] {
        let allAchievements = Achievement.defaults
        let unlockedIds = Set(achievementService.fanAchievements.compactMap { key, isUnlocked in
            isUnlocked ? key : nil
        })
        
        return allAchievements
            .filter { unlockedIds.contains($0.id) }
            .sorted { first, second in
                // Сортируем по приоритету: сначала особые, потом по очкам
                if first.category == .special && second.category != .special {
                    return true
                } else if first.category != .special && second.category == .special {
                    return false
                } else {
                    return first.points > second.points
                }
            }
    }
    
    // Достижения для отображения
    private var displayedAchievements: [Achievement] {
        Array(unlockedAchievements.prefix(maxBadges))
    }
    
    // Количество скрытых достижений
    private var hiddenCount: Int {
        max(0, unlockedAchievements.count - maxBadges)
    }
    
    var body: some View {
        if !displayedAchievements.isEmpty {
            HStack(spacing: size.spacing) {
                // Отображаем значки достижений
                ForEach(displayedAchievements, id: \.id) { achievement in
                    FanAchievementBadge(
                        achievement: achievement,
                        size: size
                    )
                    .onTapGesture {
                        showingAllBadges = true
                    }
                }
                
                // Показываем "+N" если есть скрытые достижения
                if hiddenCount > 0 {
                    Button {
                        showingAllBadges = true
                    } label: {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color(.systemGray4), Color(.systemGray5)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: size.diameter, height: size.diameter)
                            
                            Text("+\(hiddenCount)")
                                .font(.system(size: size.fontSize, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                        }
                        .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                    }
                }
            }
            .sheet(isPresented: $showingAllBadges) {
                FanAchievementBadgesDetailView(fanProfile: fanProfile)
            }
        }
    }
}

// MARK: - Individual Achievement Badge
struct FanAchievementBadge: View {
    let achievement: Achievement
    let size: FanBadgeSize
    
    var body: some View {
        ZStack {
            // Фоновый круг с градиентом по категории
            Circle()
                .fill(
                    LinearGradient(
                        colors: [achievementColor, achievementColor.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size.diameter, height: size.diameter)
            
            // Иконка достижения
            Image(systemName: achievement.iconName)
                .font(.system(size: size.iconSize, weight: .bold))
                .foregroundColor(.white)
        }
        .shadow(color: achievementColor.opacity(0.3), radius: 3, x: 0, y: 2)
        .scaleEffect(1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: achievement.id)
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

// MARK: - Badge Size Configuration
enum FanBadgeSize {
    case small, medium, large
    
    var diameter: CGFloat {
        switch self {
        case .small: return 20
        case .medium: return 28
        case .large: return 36
        }
    }
    
    var iconSize: CGFloat {
        switch self {
        case .small: return 10
        case .medium: return 14
        case .large: return 18
        }
    }
    
    var fontSize: CGFloat {
        switch self {
        case .small: return 8
        case .medium: return 10
        case .large: return 12
        }
    }
    
    var spacing: CGFloat {
        switch self {
        case .small: return 4
        case .medium: return 6
        case .large: return 8
        }
    }
}

// MARK: - Detail View for All Badges
struct FanAchievementBadgesDetailView: View {
    let fanProfile: FanProfile
    @StateObject private var achievementService = FanAchievementService.shared
    @Environment(\.dismiss) private var dismiss
    
    private var unlockedAchievements: [Achievement] {
        let allAchievements = Achievement.defaults
        let unlockedIds = Set(achievementService.fanAchievements.compactMap { key, isUnlocked in
            isUnlocked ? key : nil
        })
        
        return allAchievements
            .filter { unlockedIds.contains($0.id) }
            .sorted { $0.points > $1.points }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header с информацией о фанате
                    VStack(spacing: 16) {
                        // Аватар
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color(hex: fanProfile.level.color),
                                            Color(hex: fanProfile.level.color).opacity(0.7)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 80, height: 80)
                            
                            Text(String(fanProfile.nickname.prefix(2)).uppercased())
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                        }
                        
                        VStack(spacing: 4) {
                            Text(fanProfile.nickname)
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text(fanProfile.level.localizedName)
                                .font(.subheadline)
                                .foregroundColor(Color(hex: fanProfile.level.color))
                                .fontWeight(.semibold)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.systemGray6))
                    )
                    .padding(.horizontal)
                    
                    // Заголовок достижений
                    HStack {
                        Text("Unlocked Achievements")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Spacer()
                        
                        Text("\(unlockedAchievements.count)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                    }
                    .padding(.horizontal)
                    
                    // Сетка достижений
                    if unlockedAchievements.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "trophy")
                                .font(.system(size: 48))
                                .foregroundColor(.gray)
                            
                            Text("No achievements yet")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            Text("Keep participating to unlock achievements!")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding()
                    } else {
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 20) {
                            ForEach(unlockedAchievements, id: \.id) { achievement in
                                VStack(spacing: 12) {
                                    // Большой значок
                                    ZStack {
                                        Circle()
                                            .fill(
                                                LinearGradient(
                                                    colors: [achievementColor(achievement), achievementColor(achievement).opacity(0.7)],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                            .frame(width: 60, height: 60)
                                        
                                        Image(systemName: achievement.iconName)
                                            .font(.system(size: 24, weight: .bold))
                                            .foregroundColor(.white)
                                    }
                                    .shadow(color: achievementColor(achievement).opacity(0.3), radius: 8, x: 0, y: 4)
                                    
                                    // Информация
                                    VStack(spacing: 4) {
                                        Text(achievement.title)
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                            .multilineTextAlignment(.center)
                                            .lineLimit(2)
                                        
                                        HStack(spacing: 2) {
                                            Image(systemName: "star.fill")
                                                .font(.caption2)
                                                .foregroundColor(.yellow)
                                            
                                            Text("\(achievement.points)")
                                                .font(.caption2)
                                                .fontWeight(.semibold)
                                        }
                                    }
                                }
                                .padding(.vertical, 8)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .navigationTitle("Achievements")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func achievementColor(_ achievement: Achievement) -> Color {
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

// MARK: - Extension для легкого использования
extension View {
    func fanAchievementBadges(fanProfile: FanProfile, maxBadges: Int = 5, size: FanBadgeSize = .medium) -> some View {
        VStack(spacing: 8) {
            self
            FanAchievementBadges(fanProfile: fanProfile, maxBadges: maxBadges, size: size)
        }
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 40) {
        // Пример аватара с достижениями
        VStack(spacing: 12) {
            // Аватар
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.blue, .blue.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                
                Text("JD")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
            }
            
            // Имя
            Text("John Doe")
                .font(.headline)
                .fontWeight(.bold)
            
            // Достижения
            FanAchievementBadges(
                fanProfile: FanProfile(
                    nickname: "John Doe",
                    location: "New York",
                    favoriteSong: "Bohemian Rhapsody",
                    level: .regular,
                    achievements: ["first_concert", "active_chatter", "early_adopter"],
                    stats: FanStats(
                        totalMessages: 150,
                        joinDate: Date(),
                        lastActive: Date(),
                        merchandisePurchased: 0,
                        concertsAttended: 5,
                        achievementsUnlocked: 0
                    )
                ),
                maxBadges: 4,
                size: .medium
            )
        }
        
        Spacer()
    }
    .padding()
}
