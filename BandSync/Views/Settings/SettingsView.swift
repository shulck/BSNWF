//
//  SettingsView.swift
//  BandSync
//
//  Created by Developer on 23.06.2025.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var appState: AppState
    
    var body: some View {
        List {
            Section {
                NavigationLink(destination: NotificationSettingsView()) {
                    settingsRow(
                        title: "Notifications".localized,
                        subtitle: "Manage alerts and reminders".localized,
                        icon: "bell.fill",
                        color: .orange
                    )
                }
            } header: {
                Text("Preferences".localized)
            }
            
            Section {
                NavigationLink(destination: AccountSettingsView()) {
                    settingsRow(
                        title: "Account".localized,
                        subtitle: "Password, security, delete account".localized,
                        icon: "person.circle",
                        color: .green
                    )
                }
            } header: {
                Text("Account".localized)
            }
            
            Section {
                NavigationLink(destination: AboutView()) {
                    settingsRow(
                        title: "About & Legal".localized,
                        subtitle: "App info, terms, privacy, support".localized,
                        icon: "info.circle.fill",
                        color: .purple
                    )
                }
            } header: {
                Text("Information".localized)
            }
        }
        .navigationTitle("Settings".localized)
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func settingsRow(title: String, subtitle: String, icon: String, color: Color) -> some View {
        HStack(spacing: 12) {
            settingsIcon(icon: icon, color: color)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
    
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
