//
//  GroupSelectionView.swift
//  BandSync
//
//  Created by Oleksandr Kuziakin on 31.03.2025.
//

import SwiftUI

struct GroupSelectionView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.colorScheme) var colorScheme
    @State private var showCreateGroup = false
    @State private var showJoinGroup = false
    @State private var showFanRegistration = false
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
        
            Image("bandlogo")
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)
                .padding(.bottom, 10)
            
            VStack(spacing: 8) {
                Text("Welcome to BandSync".localized)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("Get started instruction".localized)
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 24)
            }

            VStack(spacing: 20) {
                // For Musicians Section
                VStack(spacing: 12) {
                    Text("For Musicians".localized)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    VStack(spacing: 12) {
                        CardButton(
                            icon: "plus.circle",
                            text: "Create New Group".localized,
                            action: { showCreateGroup = true }
                        )
                        
                        CardButton(
                            icon: "person.badge.plus",
                            text: "Join a Group".localized,
                            action: { showJoinGroup = true }
                        )
                    }
                }
                
                // "or" Divider
                HStack {
                    VStack { Divider() }
                    Text("or".localized)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 16)
                    VStack { Divider() }
                }
                .padding(.horizontal, 32)
                
                // For Fans Section
                VStack(spacing: 12) {
                    Text("For Fans".localized)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    FanCardButton(
                        icon: "heart.fill",
                        text: "I'm a Fan!".localized,
                        subtitle: "Join your favorite band's fan club".localized,
                        action: { showFanRegistration = true }
                    )
                }
            }
            .padding(.top, 20)
            .padding(.horizontal, 32)

            Spacer()
            
            Button(action: {
                appState.logout()
            }) {
                Text("Log out".localized)
                    .font(.footnote)
                    .foregroundColor(.red)
            }
            .padding(.bottom, 20)
        }
        .navigationBarBackButtonHidden(true)
        .padding()
        .background(Color(UIColor.systemBackground))
        .sheet(isPresented: $showCreateGroup) {
            CreateGroupView()
        }
        .sheet(isPresented: $showJoinGroup) {
            JoinGroupView()
        }
        .sheet(isPresented: $showFanRegistration) {
            FanRegistrationView()
        }
    }
}

// MARK: - Reusable card button view for musicians
struct CardButton: View {
    let icon: String
    let text: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title3)
                Text(text)
                    .font(.body)
                    .fontWeight(.medium)
            }
            .foregroundColor(.primary)
            .padding()
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.primary.opacity(0.2), lineWidth: 1)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(UIColor.secondarySystemBackground))
                    )
            )
        }
    }
}

// MARK: - Special fan card button with purple styling
struct FanCardButton: View {
    let icon: String
    let text: String
    let subtitle: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                HStack(spacing: 12) {
                    Image(systemName: icon)
                        .font(.title3)
                    Text(text)
                        .font(.body)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 20)
            .frame(maxWidth: .infinity)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [.purple, .purple.opacity(0.8)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(12)
            .shadow(color: .purple.opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
