//
//  GroupSelectionView.swift
//  BandSync
//
//  Created by Oleksandr Kuziakin on 31.03.2025.
//  Updated for Fan System - 27.07.2025
//

import SwiftUI

struct GroupSelectionView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.colorScheme) var colorScheme
    @State private var showCreateGroup = false
    @State private var showJoinGroup = false
    @State private var showComingSoonAlert = false // 📝 ДОБАВИЛИ: состояние для alert
    
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

            VStack(spacing: 16) {
                // 📝 ДОБАВИЛИ: Заголовок для музикантов
                Text("For Musicians")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                CardButton(icon: "plus.circle", text: "Create New Group".localized, action: {
                    showCreateGroup = true
                })
                CardButton(icon: "person.badge.plus", text: "Join a Group".localized, action: {
                    showJoinGroup = true
                })
                
                // 📝 ДОБАВИЛИ: Разделитель
                HStack {
                    Rectangle()
                        .fill(Color.secondary.opacity(0.3))
                        .frame(height: 1)
                    Text("or")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                    Rectangle()
                        .fill(Color.secondary.opacity(0.3))
                        .frame(height: 1)
                }
                .padding(.vertical, 8)
                
                // 📝 ДОБАВИЛИ: Секция для фанатов
                Text("For Fans")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                // 📝 ДОБАВИЛИ: Кнопка для фанатов
                Button(action: {
                    showComingSoonAlert = true
                }) {
                    HStack(spacing: 16) {
                        // Фиолетовая иконка с сердцем
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color.purple, Color.pink]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 50, height: 50)
                            
                            Image(systemName: "heart.fill")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        
                        // Текст кнопки
                        VStack(alignment: .leading, spacing: 4) {
                            Text("I'm a Fan!")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.primary)
                            
                            Text("Join your favorite band's fan club")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.leading)
                        }
                        
                        Spacer()
                        
                        // Стрелка
                        Image(systemName: "chevron.right")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.purple)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.purple.opacity(0.3), lineWidth: 1)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(UIColor.secondarySystemBackground))
                            )
                    )
                }
                .buttonStyle(PlainButtonStyle())
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
        // 📝 ДОБАВИЛИ: Alert для кнопки фанатов
        .alert("Coming Soon", isPresented: $showComingSoonAlert) {
            Button("OK") {}
        } message: {
            Text("Fan registration will be available soon!")
        }
    }
}

// Существующий компонент CardButton (БЕЗ ИЗМЕНЕНИЙ)
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
