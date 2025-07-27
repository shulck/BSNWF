//
//  AvatarView.swift
//  BandSync
//
//  Created by GitHub Copilot on 18.07.2025.
//

import SwiftUI

struct AvatarView: View {
    let avatarURL: String?
    let name: String
    let size: CGFloat
    let role: UserModel.UserRole?
    
    @State private var avatarImage: UIImage?
    @State private var isLoading = false
    
    init(user: UserModel, size: CGFloat = 40) {
        self.avatarURL = user.avatarURL
        self.name = user.name
        self.size = size
        self.role = user.role
    }
    
    init(avatarURL: String?, name: String, size: CGFloat = 40, role: UserModel.UserRole? = nil) {
        self.avatarURL = avatarURL
        self.name = name
        self.size = size
        self.role = role
    }
    
    var body: some View {
        ZStack {
            Circle()
                .fill(backgroundGradient)
                .frame(width: size, height: size)
            
            if let avatarImage = avatarImage {
                Image(uiImage: avatarImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipShape(Circle())
            } else {
                // Плейсхолдер с фиксированным содержимым до загрузки
                ZStack {
                    if isLoading {
                        ProgressView()
                            .scaleEffect(0.5)
                            .foregroundColor(.white)
                    } else {
                        Text(initials)
                            .font(.system(size: size * 0.4, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
                .frame(width: size, height: size) // Фиксируем размер плейсхолдера
            }
            
            if size >= 50, let role = role {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        RoleIndicatorView(role: role, size: size * 0.25)
                            .offset(x: 2, y: 2)
                    }
                }
            }
        }
        .frame(width: size, height: size) // Убеждаемся, что контейнер фиксирован
        .background(Color.clear)
        .onAppear {
            loadAvatar()
        }
        .onChange(of: avatarURL) {
            loadAvatar()
        }
    }
    
    private var initials: String {
        let components = name.components(separatedBy: " ")
        let firstInitial = components.first?.first?.uppercased() ?? ""
        let lastInitial = components.count > 1 ? components.last?.first?.uppercased() ?? "" : ""
        return firstInitial + lastInitial
    }
    
    private var backgroundGradient: LinearGradient {
        let colors = getGradientColors(for: name)
        return LinearGradient(
            gradient: Gradient(colors: colors),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private func getGradientColors(for name: String) -> [Color] {
        let hash = abs(name.hashValue)
        let colorPairs: [[Color]] = [
            [.blue, .purple],
            [.green, .blue],
            [.orange, .red],
            [.purple, .pink],
            [.teal, .blue],
            [.indigo, .purple],
            [.mint, .teal],
            [.cyan, .blue]
        ]
        return colorPairs[hash % colorPairs.count]
    }
    
    private func loadAvatar() {
        guard let avatarURL = avatarURL, !avatarURL.isEmpty else {
            avatarImage = nil
            isLoading = false
            return
        }
        
        isLoading = true
        AvatarService.shared.downloadAvatar(from: avatarURL) { image in
            DispatchQueue.main.async {
                self.avatarImage = image
                self.isLoading = false
            }
        }
    }
    
    func forceReload() {
        avatarImage = nil
        loadAvatar()
    }
}

struct RoleIndicatorView: View {
    let role: UserModel.UserRole
    let size: CGFloat
    
    var body: some View {
        ZStack {
            Circle()
                .fill(roleColor)
                .frame(width: size, height: size)
            
            Image(systemName: roleIcon)
                .font(.system(size: size * 0.6, weight: .bold))
                .foregroundColor(.white)
        }
        .overlay(
            Circle()
                .stroke(Color.white, lineWidth: 1)
        )
    }
    
    private var roleIcon: String {
        switch role {
        case .admin: return "crown.fill"
        case .manager: return "star.fill"
        case .musician: return "music.note"
        case .member: return "person.fill"
        }
    }
    
    private var roleColor: Color {
        switch role {
        case .admin: return .red
        case .manager: return .orange
        case .musician: return .blue
        case .member: return .gray
        }
    }
}

struct GroupAvatarView: View {
    let logoURL: String?
    let name: String
    let size: CGFloat
    
    @State private var logoImage: UIImage?
    @State private var isLoading = false
    
    init(group: GroupModel, size: CGFloat = 40) {
        self.logoURL = group.logoURL
        self.name = group.name
        self.size = size
    }
    
    init(logoURL: String?, name: String, size: CGFloat = 40) {
        self.logoURL = logoURL
        self.name = name
        self.size = size
    }
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.2)
                .fill(backgroundGradient)
                .frame(width: size, height: size)
            
            if let logoImage = logoImage {
                Image(uiImage: logoImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipShape(RoundedRectangle(cornerRadius: size * 0.2))
            } else {
                ZStack {
                    if isLoading {
                        ProgressView()
                            .scaleEffect(0.5)
                            .foregroundColor(.white)
                    } else {
                        VStack(spacing: 2) {
                            Image(systemName: "music.note.house.fill")
                                .font(.system(size: size * 0.3, weight: .bold))
                                .foregroundColor(.white)
                            
                            if size >= 60 {
                                Text(groupInitials)
                                    .font(.system(size: size * 0.2, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                        }
                    }
                }
                .frame(width: size, height: size)
            }
        }
        .frame(width: size, height: size)
        .background(Color.clear)
        .onAppear {
            loadLogo()
        }
        .onChange(of: logoURL) {
            loadLogo()
        }
    }
    
    private var groupInitials: String {
        let components = name.components(separatedBy: " ")
        return components.compactMap { $0.first?.uppercased() }.prefix(2).joined()
    }
    
    private var backgroundGradient: LinearGradient {
        return LinearGradient(
            gradient: Gradient(colors: [.purple, .blue]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private func loadLogo() {
        guard let logoURL = logoURL, !logoURL.isEmpty else {
            logoImage = nil
            isLoading = false
            return
        }
        
        isLoading = true
        AvatarService.shared.downloadAvatar(from: logoURL) { image in
            DispatchQueue.main.async {
                self.logoImage = image
                self.isLoading = false
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        HStack(spacing: 15) {
            AvatarView(
                avatarURL: nil,
                name: "John Doe",
                size: 50,
                role: .admin
            )
            
            AvatarView(
                avatarURL: nil,
                name: "Jane Smith",
                size: 50,
                role: .musician
            )
            
            AvatarView(
                avatarURL: nil,
                name: "Bob Wilson",
                size: 50,
                role: .member
            )
        }
        
        HStack(spacing: 15) {
            GroupAvatarView(
                logoURL: nil,
                name: "Rock Band",
                size: 60
            )
            
            GroupAvatarView(
                logoURL: nil,
                name: "Jazz Ensemble",
                size: 60
            )
        }
    }
    .padding()
}
