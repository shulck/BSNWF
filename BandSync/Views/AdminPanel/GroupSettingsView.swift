//
//  GroupSettingsView.swift
//  BandSync
//
//  Created by Oleksandr Kuziakin on 31.03.2025.
//

import SwiftUI

struct GroupSettingsView: View {
    @StateObject private var groupService = GroupService.shared
    @State private var newName = ""
    @State private var paypalAddress = ""
    @State private var showConfirmation = false
    @State private var showSuccessAlert = false
    
    // ✅ ДОБАВЛЕНО: Поля для информации о группе (точно как в Firebase)
    @State private var groupDescription = ""
    @State private var establishedDate = ""
    @State private var genre = ""
    @State private var location = ""
    
    // ✅ ДОБАВЛЕНО: Поля для социальных сетей (расширенный список)
    @State private var website = ""
    @State private var facebook = ""
    @State private var instagram = ""
    @State private var youtube = ""
    @State private var spotify = ""
    @State private var appleMusic = ""
    @State private var twitter = ""
    @State private var tiktok = ""
    @State private var soundcloud = ""
    @State private var bandcamp = ""
    @State private var patreon = ""
    @State private var discord = ""
    
    var body: some View {
        List {
            // Group Name Section
            Section {
                // Group Logo
                if let group = groupService.group {
                    NavigationLink(destination: GroupEditView(group: group)) {
                        HStack(spacing: 12) {
                            settingsIcon(icon: "photo.fill", color: .pink)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Group Logo".localized)
                                    .font(.body)
                                    .fontWeight(.medium)
                                    .foregroundColor(.primary)
                                
                                Text("Set or change group logo".localized)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            // Show current logo or placeholder
                            if let logoURL = group.logoURL {
                                AsyncImage(url: URL(string: logoURL)) { image in
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                } placeholder: {
                                    Image(systemName: "photo")
                                        .foregroundColor(.gray)
                                }
                                .frame(width: 40, height: 40)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            } else {
                                Image(systemName: "photo")
                                    .foregroundColor(.gray)
                                    .frame(width: 40, height: 40)
                                    .background(Color.gray.opacity(0.1))
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                
                HStack(spacing: 12) {
                    settingsIcon(icon: "music.mic", color: .blue)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Group Name".localized)
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        
                        TextField("Enter group name".localized, text: $newName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.words)
                    }
                    
                    Spacer()
                }
                .padding(.vertical, 4)
                
                Button {
                    updateGroupBasicInfo()
                } label: {
                    HStack {
                        settingsIcon(icon: "checkmark.circle.fill", color: .green)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Update Group Info".localized)
                                .font(.body)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                            
                            Text("Save basic group information".localized)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(newName.isEmpty || groupService.isLoading)
                .opacity(newName.isEmpty || groupService.isLoading ? 0.5 : 1.0)
            } header: {
                Text("Group Information".localized)
            }
            
            // ✅ НОВАЯ СЕКЦИЯ: Band Details
            Section {
                VStack(spacing: 16) {
                    // Description
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        
                        TextField("Brief description of your band", text: $groupDescription, axis: .vertical)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .lineLimit(2...4)
                    }
                    
                    HStack(spacing: 12) {
                        // Established Date
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Established Date")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                            
                            TextField("April 7, 2018", text: $establishedDate)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        
                        // Genre
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Genre")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                            
                            TextField("Rock, Pop, Jazz...", text: $genre)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                    }
                    
                    // Location
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Location")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        
                        TextField("City, Country", text: $location)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                }
                .padding(.vertical, 8)
            } header: {
                Text("Band Details")
            }
            
            // ✅ НОВАЯ СЕКЦИЯ: Main Social Media
            Section {
                VStack(spacing: 16) {
                    // Website
                    socialMediaField(
                        icon: "globe",
                        title: "Official Website",
                        placeholder: "https://your-band.com",
                        text: $website,
                        color: .blue
                    )
                    
                    // Instagram
                    socialMediaField(
                        icon: "camera.fill",
                        title: "Instagram",
                        placeholder: "https://instagram.com/yourband",
                        text: $instagram,
                        color: .pink
                    )
                    
                    // Facebook
                    socialMediaField(
                        icon: "person.2.fill",
                        title: "Facebook",
                        placeholder: "https://facebook.com/yourband",
                        text: $facebook,
                        color: .blue
                    )
                    
                    // YouTube
                    socialMediaField(
                        icon: "play.rectangle.fill",
                        title: "YouTube",
                        placeholder: "https://youtube.com/@yourband",
                        text: $youtube,
                        color: .red
                    )
                }
                .padding(.vertical, 8)
            } header: {
                Text("Main Social Media")
            }
            
            // ✅ НОВАЯ СЕКЦИЯ: Music Platforms
            Section {
                VStack(spacing: 16) {
                    // Spotify
                    socialMediaField(
                        icon: "music.note.list",
                        title: "Spotify",
                        placeholder: "https://open.spotify.com/artist/...",
                        text: $spotify,
                        color: .green
                    )
                    
                    // Apple Music
                    socialMediaField(
                        icon: "music.note",
                        title: "Apple Music",
                        placeholder: "https://music.apple.com/artist/...",
                        text: $appleMusic,
                        color: .gray
                    )
                    
                    // SoundCloud
                    socialMediaField(
                        icon: "waveform",
                        title: "SoundCloud",
                        placeholder: "https://soundcloud.com/yourband",
                        text: $soundcloud,
                        color: .orange
                    )
                    
                    // Bandcamp
                    socialMediaField(
                        icon: "music.quarternote.3",
                        title: "Bandcamp",
                        placeholder: "https://yourband.bandcamp.com",
                        text: $bandcamp,
                        color: .blue
                    )
                }
                .padding(.vertical, 8)
            } header: {
                Text("Music Platforms")
            }
            
            // ✅ НОВАЯ СЕКЦИЯ: Additional Platforms
            Section {
                VStack(spacing: 16) {
                    // Twitter
                    socialMediaField(
                        icon: "bird.fill",
                        title: "Twitter/X",
                        placeholder: "https://twitter.com/yourband",
                        text: $twitter,
                        color: .black
                    )
                    
                    // TikTok
                    socialMediaField(
                        icon: "video.fill",
                        title: "TikTok",
                        placeholder: "https://tiktok.com/@yourband",
                        text: $tiktok,
                        color: .black
                    )
                    
                    // Patreon
                    socialMediaField(
                        icon: "heart.circle.fill",
                        title: "Patreon",
                        placeholder: "https://patreon.com/yourband",
                        text: $patreon,
                        color: .orange
                    )
                    
                    // Discord
                    socialMediaField(
                        icon: "message.circle.fill",
                        title: "Discord",
                        placeholder: "https://discord.gg/yourserver",
                        text: $discord,
                        color: .purple
                    )
                }
                .padding(.vertical, 8)
                
                // ✅ Кнопка сохранения для всей информации о группе
                Button {
                    saveGroupDetails()
                } label: {
                    HStack {
                        settingsIcon(icon: "checkmark.circle.fill", color: .green)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Save Band Details")
                                .font(.body)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                            
                            Text("Update band information and social media")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(groupService.isLoading)
                .opacity(groupService.isLoading ? 0.5 : 1.0)
            } header: {
                Text("Additional Platforms")
            }
            
            // PayPal Settings Section
            Section {
                HStack(spacing: 12) {
                    settingsIcon(icon: "creditcard.fill", color: .blue)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("PayPal Address for Gifts".localized)
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        
                        TextField("Enter PayPal email address".localized, text: $paypalAddress)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                    }
                    
                    Spacer()
                }
                .padding(.vertical, 4)
                
                Button {
                    groupService.updatePayPalAddress(paypalAddress)
                    showSuccessAlert = true
                } label: {
                    HStack {
                        settingsIcon(icon: "checkmark.circle.fill", color: .green)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Save PayPal Address".localized)
                                .font(.body)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                            
                            Text("Save PayPal address for birthday gifts".localized)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(paypalAddress.isEmpty || groupService.isLoading)
                .opacity(paypalAddress.isEmpty || groupService.isLoading ? 0.5 : 1.0)
            } header: {
                Text("Gift Settings".localized)
            }
            
            // Invitation Code Section
            if let group = groupService.group {
                Section {
                    HStack(spacing: 12) {
                        settingsIcon(icon: "qrcode", color: .purple)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Invitation Code".localized)
                                .font(.body)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                            
                            Text(group.code)
                                .font(.system(.title3, design: .monospaced))
                                .fontWeight(.bold)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Button {
                            UIPasteboard.general.string = group.code
                        } label: {
                            Text("Copy".localized)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.purple)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(Color.purple.opacity(0.1))
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.vertical, 4)
                    
                    Button {
                        showConfirmation = true
                    } label: {
                        HStack {
                            settingsIcon(icon: "arrow.clockwise", color: .orange)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Generate New Code".localized)
                                    .font(.body)
                                    .fontWeight(.medium)
                                    .foregroundColor(.primary)
                                
                                Text("Create a new invitation code".localized)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(PlainButtonStyle())
                } header: {
                    Text("Invitation".localized)
                }
            }
            
            // Group Members Section
            Section {
                NavigationLink(destination: UsersListView()) {
                    HStack(spacing: 12) {
                        settingsIcon(icon: "person.3.fill", color: .green)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Manage Members".localized)
                                .font(.body)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                            
                            Text("View and manage group members".localized)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Text("\(groupService.groupMembers.count)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.green.opacity(0.1))
                            )
                    }
                    .padding(.vertical, 4)
                }
            } header: {
                Text("Members".localized)
            }
            
            // Available Modules Section
            Section {
                HStack(spacing: 12) {
                    settingsIcon(icon: "square.grid.2x2.fill", color: .gray)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Module Management".localized)
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        
                        Text("Module management will be available in the next update.".localized)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                .padding(.vertical, 4)
            } header: {
                Text("Available Modules".localized)
            }
            
            // Error Messages Section
            if let error = groupService.errorMessage {
                Section {
                    HStack(spacing: 12) {
                        settingsIcon(icon: "exclamationmark.triangle.fill", color: .red)
                        
                        Text(error)
                            .font(.body)
                            .foregroundColor(.red)
                        
                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
            }
            
            // Loading Section
            if groupService.isLoading {
                Section {
                    HStack(spacing: 12) {
                        ProgressView()
                            .scaleEffect(0.8)
                        
                        Text("Loading...".localized)
                            .font(.body)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }
            }
        }
        .navigationTitle("Group Settings".localized)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadGroupData()
        }
        .onChange(of: groupService.group) {
            loadGroupData()
        }
        .alert("Generate new code?".localized, isPresented: $showConfirmation) {
            Button("Cancel".localized, role: .cancel) {}
            Button("Generate".localized) {
                groupService.regenerateCode()
                showSuccessAlert = true
            }
        } message: {
            Text("The old code will no longer be valid. All members who haven't joined yet will need to use the new code.".localized)
        }
        .alert("Success".localized, isPresented: $showSuccessAlert) {
            Button("OK".localized, role: .cancel) {}
        } message: {
            Text("Changes saved successfully.".localized)
        }
    }
    
    // MARK: - Helper Views
    
    private func socialMediaField(
        icon: String,
        title: String,
        placeholder: String,
        text: Binding<String>,
        color: Color
    ) -> some View {
        HStack(spacing: 12) {
            settingsIcon(icon: icon, color: color)
            
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                TextField(placeholder, text: text)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.URL)
                    .autocapitalization(.none)
            }
        }
    }
    
    // MARK: - Helper Functions
    
    // ✅ ОБНОВЛЕНО: Загрузка данных из реальной Firebase структуры
    private func loadGroupData() {
        if let gid = AppState.shared.user?.groupId {
            groupService.fetchGroup(by: gid)
            
            if let group = groupService.group {
                newName = group.name
                paypalAddress = group.paypalAddress ?? ""
                
                // ✅ Загружаем дополнительную информацию о группе
                groupDescription = group.description ?? ""
                establishedDate = group.establishedDate ?? ""
                genre = group.genre ?? ""
                location = group.location ?? ""
                
                // ✅ Загружаем социальные сети
                if let socialMedia = group.socialMediaLinks {
                    website = socialMedia.website ?? ""
                    facebook = socialMedia.facebook ?? ""
                    instagram = socialMedia.instagram ?? ""
                    youtube = socialMedia.youtube ?? ""
                    spotify = socialMedia.spotify ?? ""
                    appleMusic = socialMedia.appleMusic ?? ""
                    twitter = socialMedia.twitter ?? ""
                    tiktok = socialMedia.tiktok ?? ""
                    soundcloud = socialMedia.soundcloud ?? ""
                    bandcamp = socialMedia.bandcamp ?? ""
                    patreon = socialMedia.patreon ?? ""
                    discord = socialMedia.discord ?? ""
                }
            }
        }
    }
    
    // ✅ ОБНОВЛЕНО: Функция обновления основной информации
    private func updateGroupBasicInfo() {
        groupService.updateGroupName(newName)
        showSuccessAlert = true
    }
    
    // ✅ ОБНОВЛЕНО: Функция сохранения всех деталей группы
    private func saveGroupDetails() {
        let socialMediaLinks = SocialMediaLinks(
            website: website.isEmpty ? nil : website,
            facebook: facebook.isEmpty ? nil : facebook,
            instagram: instagram.isEmpty ? nil : instagram,
            youtube: youtube.isEmpty ? nil : youtube,
            spotify: spotify.isEmpty ? nil : spotify,
            appleMusic: appleMusic.isEmpty ? nil : appleMusic,
            twitter: twitter.isEmpty ? nil : twitter,
            tiktok: tiktok.isEmpty ? nil : tiktok,
            soundcloud: soundcloud.isEmpty ? nil : soundcloud,
            bandcamp: bandcamp.isEmpty ? nil : bandcamp,
            patreon: patreon.isEmpty ? nil : patreon,
            discord: discord.isEmpty ? nil : discord
        )
        
        groupService.updateGroupDetails(
            description: groupDescription.isEmpty ? nil : groupDescription,
            establishedDate: establishedDate.isEmpty ? nil : establishedDate,
            genre: genre.isEmpty ? nil : genre,
            location: location.isEmpty ? nil : location,
            socialMediaLinks: socialMediaLinks.isEmpty ? nil : socialMediaLinks
        )
        showSuccessAlert = true
    }
    
    // MARK: - Helper Views
    
    private func settingsIcon(icon: String, color: Color) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6)
                .fill(color)
                .frame(width: 28, height: 28)
            
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
        }
    }
}
