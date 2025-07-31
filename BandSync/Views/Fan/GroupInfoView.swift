//
//  GroupInfoView.swift
//  BandSync
//
//  Created by Oleksandr Kuziakin on 01.08.2025.
//

import SwiftUI
import FirebaseFirestore

struct GroupInfoView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.colorScheme) private var colorScheme
    @State private var groupInfo: GroupInfo?
    @State private var fanCount: Int = 0
    @State private var isLoading = true
    
    private let db = Firestore.firestore()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    if isLoading {
                        loadingView
                    } else if let groupInfo = groupInfo {
                        // Header с логотипом и названием
                        headerSection(groupInfo: groupInfo)
                        
                        // Основная информация
                        basicInfoSection(groupInfo: groupInfo)
                        
                        // Контакты и соцсети
                        contactsSection(groupInfo: groupInfo)
                        
                        // Статистика фан-клуба
                        statsSection(groupInfo: groupInfo)
                    } else {
                        emptyStateView
                    }
                    
                    Spacer(minLength: 50)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(.systemGroupedBackground),
                        Color(.systemGroupedBackground).opacity(0.8)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
            .navigationTitle("About Band")
            .navigationBarTitleDisplayMode(.large)
        }
        .onAppear {
            loadGroupInfo()
        }
    }
    
    // MARK: - Header Section
    
    private func headerSection(groupInfo: GroupInfo) -> some View {
        VStack(spacing: 16) {
            // Логотип группы
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.white, Color(.systemGray6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                    .shadow(color: .black.opacity(0.1), radius: 15, x: 0, y: 8)
                
                if let logoURL = groupInfo.logoURL {
                    AsyncImage(url: URL(string: logoURL)) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    } placeholder: {
                        groupInitials(groupInfo.name)
                    }
                    .frame(width: 116, height: 116)
                    .clipShape(Circle())
                } else {
                    groupInitials(groupInfo.name)
                }
            }
            
            // Название группы
            Text(groupInfo.name)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
            
            // Описание (если есть)
            if let description = groupInfo.description, !description.isEmpty {
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
            }
        }
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity)
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
    }
    
    // MARK: - Basic Info Section
    
    private func basicInfoSection(groupInfo: GroupInfo) -> some View {
        VStack(spacing: 16) {
            sectionHeader(title: "Band Information", icon: "info.circle.fill", color: .blue)
            
            VStack(spacing: 12) {
                if let foundedYear = groupInfo.foundedYear {
                    InfoRow(
                        icon: "calendar",
                        title: "Founded",
                        value: "\(foundedYear)"
                    )
                }
                
                if let genre = groupInfo.genre, !genre.isEmpty {
                    InfoRow(
                        icon: "music.note",
                        title: "Genre",
                        value: genre
                    )
                }
                
                if let location = groupInfo.location, !location.isEmpty {
                    InfoRow(
                        icon: "location.fill",
                        title: "Location",
                        value: location
                    )
                }
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 20)
            .background(cardBackground)
            .cornerRadius(16)
        }
    }
    
    // MARK: - Contacts Section
    
    private func contactsSection(groupInfo: GroupInfo) -> some View {
        VStack(spacing: 16) {
            sectionHeader(title: "Follow Us", icon: "link.circle.fill", color: .green)
            
            VStack(spacing: 12) {
                if let website = groupInfo.website, !website.isEmpty {
                    SocialLinkRow(
                        icon: "globe",
                        title: "Official Website",
                        url: website,
                        color: .blue
                    )
                }
                
                if let instagram = socialMedia.instagram, !instagram.isEmpty {
                    SocialLinkRow(
                        icon: "camera.fill",
                        title: "Instagram",
                        url: instagram,
                        color: .pink
                    )
                }
                
                if let facebook = socialMedia.facebook, !facebook.isEmpty {
                    SocialLinkRow(
                        icon: "person.2.fill",
                        title: "Facebook",
                        url: facebook,
                        color: .blue
                    )
                }
                
                if let youtube = socialMedia.youtube, !youtube.isEmpty {
                    SocialLinkRow(
                        icon: "play.rectangle.fill",
                        title: "YouTube",
                        url: youtube,
                        color: .red
                    )
                }
                
                if let spotify = socialMedia.spotify, !spotify.isEmpty {
                    SocialLinkRow(
                        icon: "music.note.list",
                        title: "Spotify",
                        url: spotify,
                        color: .green
                    )
                }
                
                if let appleMusic = socialMedia.appleMusic, !appleMusic.isEmpty {
                    SocialLinkRow(
                        icon: "music.note",
                        title: "Apple Music",
                        url: appleMusic,
                        color: .gray
                    )
                }
                
                if let twitter = socialMedia.twitter, !twitter.isEmpty {
                    SocialLinkRow(
                        icon: "bird.fill",
                        title: "Twitter/X",
                        url: twitter,
                        color: .black
                    )
                }
                
                if let tiktok = socialMedia.tiktok, !tiktok.isEmpty {
                    SocialLinkRow(
                        icon: "video.fill",
                        title: "TikTok",
                        url: tiktok,
                        color: .black
                    )
                }
                
                if let soundcloud = socialMedia.soundcloud, !soundcloud.isEmpty {
                    SocialLinkRow(
                        icon: "waveform",
                        title: "SoundCloud",
                        url: soundcloud,
                        color: .orange
                    )
                }
                
                if let bandcamp = socialMedia.bandcamp, !bandcamp.isEmpty {
                    SocialLinkRow(
                        icon: "music.quarternote.3",
                        title: "Bandcamp",
                        url: bandcamp,
                        color: .blue
                    )
                }
                
                if let patreon = socialMedia.patreon, !patreon.isEmpty {
                    SocialLinkRow(
                        icon: "heart.circle.fill",
                        title: "Patreon",
                        url: patreon,
                        color: .orange
                    )
                }
                
                if let discord = socialMedia.discord, !discord.isEmpty {
                    SocialLinkRow(
                        icon: "message.circle.fill",
                        title: "Discord",
                        url: discord,
                        color: .purple
                    )
                }
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 20)
            .background(cardBackground)
            .cornerRadius(16)
        }
    }
    
    // MARK: - Stats Section
    
    private func statsSection(groupInfo: GroupInfo) -> some View {
        VStack(spacing: 16) {
            sectionHeader(title: "Fan Club Statistics", icon: "chart.bar.fill", color: .purple)
            
            VStack(spacing: 16) {
                HStack(spacing: 0) {
                    StatCard(
                        icon: "heart.fill",
                        title: "Fans",
                        value: "\(fanCount)",
                        subtitle: "Members",
                        color: .red
                    )
                    
                    Rectangle()
                        .fill(Color.secondary.opacity(0.2))
                        .frame(width: 1, height: 50)
                    
                    StatCard(
                        icon: "calendar.badge.plus",
                        title: "Since",
                        value: formatDate(groupInfo.fanClubCreatedAt),
                        subtitle: "Active",
                        color: .green
                    )
                }
                .padding(.vertical, 20)
            }
            .background(cardBackground)
            .cornerRadius(16)
        }
    }
    
    // MARK: - Helper Views
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(.blue)
            
            Text("Loading band information...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 100)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "music.note.house")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("No Band Information")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Text("Band information is not available at the moment")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 100)
    }
    
    private func groupInitials(_ name: String) -> some View {
        Text(String(name.prefix(2)).uppercased())
            .font(.system(size: 36, weight: .bold, design: .rounded))
            .foregroundColor(.blue)
    }
    
    private func sectionHeader(title: String, icon: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.title3)
            
            Text(title)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Spacer()
        }
    }
    
    private var cardBackground: some View {
        colorScheme == .dark ?
        Color(UIColor.secondarySystemGroupedBackground) :
        Color.white
    }
    
    // MARK: - Helper Functions
    
    private func loadGroupInfo() {
        guard let user = appState.user,
              let fanGroupId = user.fanGroupId else {
            isLoading = false
            return
        }
        
        // ✅ ОБНОВЛЕНО: Используем GroupService для загрузки данных
        GroupService.shared.fetchGroup(by: fanGroupId) { [weak self] success in
            DispatchQueue.main.async {
                if success, let group = GroupService.shared.group {
                    // ✅ Создаем GroupInfo из реальных данных Firebase
                    let groupInfo = GroupInfo(
                        id: fanGroupId,
                        name: group.name,
                        description: group.description,
                        logoURL: group.logoURL,
                        foundedYear: self?.parseYearFromDate(group.establishedDate),
                        genre: group.genre,
                        location: group.location,
                        website: group.socialMediaLinks?.website,
                        socialMedia: group.socialMediaLinks,
                        fanClubCreatedAt: group.createdAt ?? Date()
                    )
                    
                    self?.groupInfo = groupInfo
                    self?.loadFanCount(groupId: fanGroupId)
                } else {
                    self?.isLoading = false
                }
            }
        }
    }
    
    // ✅ НОВЫЙ: Парсинг года из даты
    private func parseYearFromDate(_ dateString: String?) -> Int? {
        guard let dateString = dateString else { return nil }
        
        // Попробуем извлечь год из строки типа "April 7, 2018"
        let components = dateString.components(separatedBy: " ")
        for component in components {
            if let year = Int(component), year > 1900 && year < 2100 {
                return year
            }
        }
        return nil
    }
    
    private func loadFanCount(groupId: String) {
        db.collection("groups").document(groupId).collection("fans").getDocuments { snapshot, error in
            DispatchQueue.main.async {
                self.fanCount = snapshot?.documents.count ?? 0
                self.isLoading = false
            }
        }
    }
    
    private func parseSocialMedia(from data: Any?) -> SocialMediaLinks? {
        // Эта функция больше не нужна, так как используем GroupService
        return nil
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

// MARK: - Supporting Views

struct InfoRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 20)
                .font(.system(size: 16, weight: .medium))
            
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(width: 80, alignment: .leading)
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            Spacer()
        }
    }
}

struct SocialLinkRow: View {
    let icon: String
    let title: String
    let url: String
    let color: Color
    
    var body: some View {
        Button(action: {
            if let url = URL(string: url) {
                UIApplication.shared.open(url)
            }
        }) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: icon)
                        .foregroundColor(color)
                        .font(.system(size: 16, weight: .semibold))
                }
                
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Image(systemName: "arrow.up.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct StatCard: View {
    let icon: String
    let title: String
    let value: String
    let subtitle: String
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
    }
}

// MARK: - Data Models

struct GroupInfo {
    let id: String
    let name: String
    let description: String?
    let logoURL: String?
    let foundedYear: Int?
    let genre: String?
    let location: String?
    let website: String?
    let socialMedia: SocialMediaLinks?
    let fanClubCreatedAt: Date
}

struct SocialMediaLinks {
    let instagram: String?
    let facebook: String?
    let twitter: String?
    let youtube: String?
    let tiktok: String?
}

// MARK: - Preview

#Preview {
    GroupInfoView()
        .environmentObject(AppState.shared)
}
