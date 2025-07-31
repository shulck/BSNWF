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
                    VStack(spacing: 10) { // Увеличили spacing между основными секциями
                        // Stats Section
                        profileStatsSection
                        
                        // Fan Activity
                        fanActivitySection
                        
                        // Settings & Actions
                        settingsSection
                        
                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 30) // Увеличили отступ от hero до stats
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
    
    // MARK: - Hero Profile Section (ИСПРАВЛЕННЫЙ ДИЗАЙН)
    
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
                    .padding(.top, 5)
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
        .frame(height: 280)
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
    
    // MARK: - Profile Stats Section
    
    @ViewBuilder
    private var profileStatsSection: some View {
        if let user = appState.user, let fanProfile = user.fanProfile {
            HStack(spacing: 0) {
                // Events Attended
                StatCard(
                    title: "Events",
                    value: "12", // Mock data
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
                    value: "70%", // Mock data
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
    
    // MARK: - Fan Activity Section
    
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
    
    // MARK: - Settings Section
    
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
}

// MARK: - Supporting Views

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

// MARK: - New Info Card for Profile

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

// MARK: - Edit Profile View (Placeholder)

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



// MARK: - Preview

#Preview {
    FanProfileView()
        .environmentObject(AppState.shared)
}
