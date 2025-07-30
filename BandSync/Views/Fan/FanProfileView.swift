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
                    VStack(spacing: 32) {
                        // Stats Section
                        profileStatsSection
                        
                        // Fan Activity
                        fanActivitySection
                        
                        // Settings & Actions
                        settingsSection
                        
                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, -40) // Overlap with hero
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
    
    // MARK: - Hero Profile Section
    
    private var heroProfileSection: some View {
        ZStack {
            // Dynamic Background with Animated Gradient
            if let user = appState.user, let fanProfile = user.fanProfile {
                ZStack {
                    // Base gradient
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(hex: fanProfile.level.color),
                            Color(hex: fanProfile.level.color).opacity(0.8),
                            Color(hex: fanProfile.level.color).opacity(0.6)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    
                    // Animated floating circles
                    GeometryReader { geometry in
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.1))
                                .frame(width: 120, height: 120)
                                .offset(x: geometry.size.width * 0.8, y: geometry.size.height * 0.2)
                            
                            Circle()
                                .fill(Color.white.opacity(0.15))
                                .frame(width: 80, height: 80)
                                .offset(x: geometry.size.width * 0.1, y: geometry.size.height * 0.6)
                            
                            Circle()
                                .fill(Color.white.opacity(0.08))
                                .frame(width: 200, height: 200)
                                .offset(x: geometry.size.width * 0.7, y: geometry.size.height * 0.8)
                        }
                    }
                    
                    // Mesh gradient effect
                    RadialGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(0.2),
                            Color.clear
                        ]),
                        center: .topTrailing,
                        startRadius: 50,
                        endRadius: 300
                    )
                }
            } else {
                LinearGradient(
                    gradient: Gradient(colors: [.blue, .purple]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        }
        .frame(height: 320)
        .overlay(
            VStack(spacing: 0) {
                // Top spacing
                Spacer()
                    .frame(height: 80)
                
                // Modern Profile Content
                if let user = appState.user, let fanProfile = user.fanProfile {
                    VStack(spacing: 28) {
                        // Avatar with advanced styling
                        ZStack {
                            // Outer glow ring
                            Circle()
                                .stroke(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color.white.opacity(0.6),
                                            Color.white.opacity(0.3),
                                            Color.white.opacity(0.1)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 3
                                )
                                .frame(width: 140, height: 140)
                                .shadow(color: .white.opacity(0.3), radius: 10, x: 0, y: 0)
                            
                            // Progress ring (mock level progress)
                            Circle()
                                .trim(from: 0, to: 0.75) // Mock 75% progress
                                .stroke(
                                    Color.white.opacity(0.8),
                                    style: StrokeStyle(lineWidth: 4, lineCap: .round)
                                )
                                .rotationEffect(.degrees(-90))
                                .frame(width: 130, height: 130)
                            
                            // Avatar background
                            Circle()
                                .fill(.ultraThinMaterial.opacity(0.3))
                                .frame(width: 110, height: 110)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white.opacity(0.4), lineWidth: 2)
                                )
                            
                            // Avatar text with better styling
                            Text(String(fanProfile.nickname.prefix(2)).uppercased())
                                .font(.system(size: 32, weight: .black, design: .rounded))
                                .foregroundColor(.white)
                                .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                        }
                        
                        // Profile info with modern cards
                        VStack(spacing: 20) {
                            // Name with typing effect style
                            Text(fanProfile.nickname)
                                .font(.system(size: 28, weight: .black, design: .rounded))
                                .foregroundColor(.white)
                                .shadow(color: .black.opacity(0.4), radius: 3, x: 0, y: 2)
                            
                            // Level badge with modern design
                            HStack(spacing: 8) {
                                ZStack {
                                    Circle()
                                        .fill(Color.white.opacity(0.2))
                                        .frame(width: 24, height: 24)
                                    
                                    Image(systemName: "star.fill")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(.white)
                                }
                                
                                Text(fanProfile.level.localizedName.uppercased())
                                    .font(.system(size: 14, weight: .black, design: .rounded))
                                    .foregroundColor(.white)
                                    .tracking(1.5)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(.ultraThinMaterial.opacity(0.4))
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .stroke(Color.white.opacity(0.4), lineWidth: 1)
                            )
                            
                            // Compact info cards
                            VStack(spacing: 8) {
                                HStack(spacing: 12) {
                                    if !fanProfile.location.isEmpty {
                                        CompactInfoCard(
                                            icon: "location.fill",
                                            text: fanProfile.location,
                                            maxWidth: 120
                                        )
                                    }
                                    
                                    CompactInfoCard(
                                        icon: "calendar",
                                        text: "Since \(formatJoinDateShort(fanProfile.joinDate))",
                                        maxWidth: 100
                                    )
                                }
                                
                                if !fanProfile.favoriteSong.isEmpty {
                                    CompactInfoCard(
                                        icon: "music.note",
                                        text: fanProfile.favoriteSong,
                                        maxWidth: 200
                                    )
                                }
                            }
                            
                            // Edit button moved down here
                            Button(action: { showingEditProfile = true }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "pencil")
                                        .font(.system(size: 14, weight: .semibold))
                                    Text("Edit Profile")
                                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                                .background(.ultraThinMaterial.opacity(0.4))
                                .clipShape(Capsule())
                                .overlay(
                                    Capsule()
                                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                )
                            }
                        }
                    }
                } else {
                    // Guest state with better styling
                    VStack(spacing: 20) {
                        ZStack {
                            Circle()
                                .fill(.ultraThinMaterial.opacity(0.3))
                                .frame(width: 110, height: 110)
                            
                            Image(systemName: "person.fill")
                                .font(.system(size: 40, weight: .medium))
                                .foregroundColor(.white)
                        }
                        
                        Text("Guest User")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                }
                
                Spacer(minLength: 32)
            }
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
