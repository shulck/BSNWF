import SwiftUI
import UserNotifications

struct NotificationSettingsView: View {
    @State private var settings = NotificationManager.shared.getSettings()
    @State private var isLoading = false
    @State private var showPermissionAlert = false
    @EnvironmentObject private var appState: AppState
    
    var body: some View {
        Form {
            Section {
                Toggle(NSLocalizedString("Enable Notifications", comment: "Notification settings - enable notifications toggle"), isOn: $settings.notificationsEnabled)
                    .onChange(of: settings.notificationsEnabled) {
                        if settings.notificationsEnabled {
                            requestPermissions()
                        } else {
                            saveSettings()
                        }
                    }
                
                if settings.notificationsEnabled {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text(NSLocalizedString("Notifications are enabled", comment: "Notification settings - notifications enabled status"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            if settings.notificationsEnabled {
                Section(NSLocalizedString("Notification Types", comment: "Section header for notification types")) {
                    Toggle(NSLocalizedString("Events", comment: "Toggle for event notifications"), isOn: $settings.eventNotificationsEnabled)
                        .onChange(of: settings.eventNotificationsEnabled) {
                            saveSettings()
                        }
                    Toggle(NSLocalizedString("Tasks", comment: "Toggle for task notifications"), isOn: $settings.taskNotificationsEnabled)
                        .onChange(of: settings.taskNotificationsEnabled) {
                            saveSettings()
                        }
                    Toggle(NSLocalizedString("Chats", comment: "Toggle for chat notifications"), isOn: $settings.chatNotificationsEnabled)
                        .onChange(of: settings.chatNotificationsEnabled) {
                            saveSettings()
                        }
                    Toggle(NSLocalizedString("System", comment: "Toggle for system notifications"), isOn: $settings.systemNotificationsEnabled)
                        .onChange(of: settings.systemNotificationsEnabled) {
                            saveSettings()
                        }
                }
                
                Section(NSLocalizedString("Reminder Times", comment: "Section header for reminder time settings")) {
                    Picker(NSLocalizedString("Event Reminders", comment: "Picker for event reminder timing"), selection: $settings.eventReminderHours) {
                        Text(NSLocalizedString("30 minutes before", comment: "Event reminder option")).tag(0)
                        Text(NSLocalizedString("1 hour before", comment: "Event reminder option")).tag(1)
                        Text(NSLocalizedString("2 hours before", comment: "Event reminder option")).tag(2)
                        Text(NSLocalizedString("1 day before", comment: "Event reminder option")).tag(24)
                        Text(NSLocalizedString("2 days before", comment: "Event reminder option")).tag(48)
                        Text(NSLocalizedString("1 week before", comment: "Event reminder option")).tag(168)
                    }
                    .onChange(of: settings.eventReminderHours) {
                        saveSettings()
                    }
                    
                    Picker(NSLocalizedString("Task Reminders", comment: "Picker for task reminder timing"), selection: $settings.taskReminderHours) {
                        Text(NSLocalizedString("1 hour before", comment: "Task reminder option")).tag(1)
                        Text(NSLocalizedString("2 hours before", comment: "Task reminder option")).tag(2)
                        Text(NSLocalizedString("1 day before", comment: "Task reminder option")).tag(24)
                        Text(NSLocalizedString("2 days before", comment: "Task reminder option")).tag(48)
                        Text(NSLocalizedString("1 week before", comment: "Task reminder option")).tag(168)
                    }
                    .onChange(of: settings.taskReminderHours) {
                        saveSettings()
                    }
                }
                
                Section(NSLocalizedString("Chat Notifications", comment: "Section header for chat notification settings")) {
                    Toggle(NSLocalizedString("Mentions", comment: "Toggle for mention notifications"), isOn: $settings.mentionNotificationsEnabled)
                        .onChange(of: settings.mentionNotificationsEnabled) {
                            saveSettings()
                        }
                    
                    Toggle(NSLocalizedString("Direct Messages", comment: "Toggle for direct message notifications"), isOn: $settings.directMessageNotificationsEnabled)
                        .onChange(of: settings.directMessageNotificationsEnabled) {
                            saveSettings()
                        }
                    
                    Toggle(NSLocalizedString("Group Messages", comment: "Toggle for group message notifications"), isOn: $settings.groupMessageNotificationsEnabled)
                        .onChange(of: settings.groupMessageNotificationsEnabled) {
                            saveSettings()
                        }
                }
                
                Section(NSLocalizedString("Sound & Badge", comment: "Section header for sound and badge settings")) {
                    Toggle(NSLocalizedString("Sound", comment: "Toggle for notification sounds"), isOn: $settings.soundEnabled)
                        .onChange(of: settings.soundEnabled) {
                            saveSettings()
                        }
                    Toggle(NSLocalizedString("Badge", comment: "Toggle for notification badges"), isOn: $settings.badgeEnabled)
                        .onChange(of: settings.badgeEnabled) {
                            saveSettings()
                        }
                }
                
                Section(NSLocalizedString("Quiet Hours", comment: "Section header for quiet hours settings")) {
                    Toggle(NSLocalizedString("Enable Quiet Hours", comment: "Toggle for quiet hours"), isOn: $settings.quietHoursEnabled)
                        .onChange(of: settings.quietHoursEnabled) {
                            saveSettings()
                        }
                    
                    if settings.quietHoursEnabled {
                        Picker(NSLocalizedString("Start Time", comment: "Picker for quiet hours start time"), selection: $settings.quietHoursStart) {
                            ForEach(0..<24, id: \.self) { hour in
                                Text(formatHour(hour)).tag(hour)
                            }
                        }
                        .onChange(of: settings.quietHoursStart) {
                            saveSettings()
                        }
                        
                        Picker(NSLocalizedString("End Time", comment: "Picker for quiet hours end time"), selection: $settings.quietHoursEnd) {
                            ForEach(0..<24, id: \.self) { hour in
                                Text(formatHour(hour)).tag(hour)
                            }
                        }
                        .onChange(of: settings.quietHoursEnd) {
                            saveSettings()
                        }
                    }
                }
            }
        }
        .navigationTitle(NSLocalizedString("Notifications", comment: "Navigation title for notifications settings"))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadCurrentSettings()
            checkCurrentPermissions()
        }
        .alert(NSLocalizedString("Permission Required", comment: "Alert title for notification permission"), isPresented: $showPermissionAlert) {
            Button(NSLocalizedString("Settings", comment: "Button to open settings")) {
                openSettings()
            }
            Button(NSLocalizedString("Cancel", comment: "Cancel button")) {
                settings.notificationsEnabled = false
            }
        } message: {
            Text(NSLocalizedString("Please enable notifications in Settings to receive alerts.", comment: "Alert message for notification permission"))
        }
    }
    
    private func loadCurrentSettings() {
        settings = NotificationManager.shared.getSettings()
    }
    
    private func checkCurrentPermissions() {
        NotificationManager.shared.checkPermissionStatus { granted, error in
            DispatchQueue.main.async {
                settings.notificationsEnabled = granted
            }
        }
    }
    
    private func requestPermissions() {
        isLoading = true
        NotificationManager.shared.requestPermission { granted, error in
            DispatchQueue.main.async {
                isLoading = false
                if granted {
                    saveSettings()
                } else {
                    settings.notificationsEnabled = false
                    showPermissionAlert = true
                }
            }
        }
    }
    
    private func saveSettings() {
        NotificationManager.shared.updateSettings(settings)
    }
    
    private func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
    
    private func formatHour(_ hour: Int) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        let date = Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: Date()) ?? Date()
        return formatter.string(from: date)
    }
}
