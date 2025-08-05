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
                        title: NSLocalizedString("Notifications", comment: "Settings section for notifications"),
                        subtitle: NSLocalizedString("Manage alerts and reminders", comment: "Settings subtitle for notifications"),
                        icon: "bell.fill",
                        color: .orange
                    )
                }
            } header: {
                Text(NSLocalizedString("Preferences", comment: "Settings section header for preferences"))
            }
            
            Section {
                NavigationLink(destination: AccountSettingsView()) {
                    settingsRow(
                        title: NSLocalizedString("Account", comment: "Settings section for account"),
                        subtitle: NSLocalizedString("Password, security, delete account", comment: "Settings subtitle for account"),
                        icon: "person.circle",
                        color: .green
                    )
                }
            } header: {
                Text(NSLocalizedString("Account", comment: "Settings section header for account"))
            }
            
            Section {
                NavigationLink(destination: AboutView()) {
                    settingsRow(
                        title: NSLocalizedString("About & Legal", comment: "Settings section for about and legal"),
                        subtitle: NSLocalizedString("App info, terms, privacy, support", comment: "Settings subtitle for about and legal"),
                        icon: "info.circle.fill",
                        color: .purple
                    )
                }
            } header: {
                Text(NSLocalizedString("Information", comment: "Settings section header for information"))
            }
        }
        .navigationTitle(NSLocalizedString("Settings", comment: "Navigation title for settings"))
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
