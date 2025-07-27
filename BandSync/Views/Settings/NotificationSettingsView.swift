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
                Toggle("Enable Notifications".localized, isOn: $settings.notificationsEnabled)
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
                        Text("Notifications are enabled".localized)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            if settings.notificationsEnabled {
                Section("Notification Types".localized) {
                    Toggle("Events".localized, isOn: $settings.eventNotificationsEnabled)
                        .onChange(of: settings.eventNotificationsEnabled) {
                            saveSettings()
                        }
                    Toggle("Tasks".localized, isOn: $settings.taskNotificationsEnabled)
                        .onChange(of: settings.taskNotificationsEnabled) {
                            saveSettings()
                        }
                    Toggle("Chats".localized, isOn: $settings.chatNotificationsEnabled)
                        .onChange(of: settings.chatNotificationsEnabled) {
                            saveSettings()
                        }
                    Toggle("System".localized, isOn: $settings.systemNotificationsEnabled)
                        .onChange(of: settings.systemNotificationsEnabled) {
                            saveSettings()
                        }
                }
                
                Section("Reminder Times".localized) {
                    Picker("Event Reminders".localized, selection: $settings.eventReminderHours) {
                        Text("30 minutes before".localized).tag(0)
                        Text("1 hour before".localized).tag(1)
                        Text("2 hours before".localized).tag(2)
                        Text("1 day before".localized).tag(24)
                        Text("2 days before".localized).tag(48)
                        Text("1 week before".localized).tag(168)
                    }
                    .onChange(of: settings.eventReminderHours) {
                        saveSettings()
                    }
                    
                    Picker("Task Reminders".localized, selection: $settings.taskReminderHours) {
                        Text("1 hour before".localized).tag(1)
                        Text("2 hours before".localized).tag(2)
                        Text("1 day before".localized).tag(24)
                        Text("2 days before".localized).tag(48)
                        Text("1 week before".localized).tag(168)
                    }
                    .onChange(of: settings.taskReminderHours) {
                        saveSettings()
                    }
                }
                
                Section("Chat Notifications".localized) {
                    Toggle("Mentions".localized, isOn: $settings.mentionNotificationsEnabled)
                        .onChange(of: settings.mentionNotificationsEnabled) {
                            saveSettings()
                        }
                    
                    Toggle("Direct Messages".localized, isOn: $settings.directMessageNotificationsEnabled)
                        .onChange(of: settings.directMessageNotificationsEnabled) {
                            saveSettings()
                        }
                    
                    Toggle("Group Messages".localized, isOn: $settings.groupMessageNotificationsEnabled)
                        .onChange(of: settings.groupMessageNotificationsEnabled) {
                            saveSettings()
                        }
                }
                
                Section("Sound & Badge".localized) {
                    Toggle("Sound".localized, isOn: $settings.soundEnabled)
                        .onChange(of: settings.soundEnabled) {
                            saveSettings()
                        }
                    Toggle("Badge".localized, isOn: $settings.badgeEnabled)
                        .onChange(of: settings.badgeEnabled) {
                            saveSettings()
                        }
                }
                
                Section("Quiet Hours".localized) {
                    Toggle("Enable Quiet Hours".localized, isOn: $settings.quietHoursEnabled)
                        .onChange(of: settings.quietHoursEnabled) {
                            saveSettings()
                        }
                    
                    if settings.quietHoursEnabled {
                        Picker("Start Time".localized, selection: $settings.quietHoursStart) {
                            ForEach(0..<24, id: \.self) { hour in
                                Text(formatHour(hour)).tag(hour)
                            }
                        }
                        .onChange(of: settings.quietHoursStart) {
                            saveSettings()
                        }
                        
                        Picker("End Time".localized, selection: $settings.quietHoursEnd) {
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
        .navigationTitle("Notifications".localized)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadCurrentSettings()
            checkCurrentPermissions()
        }
        .alert("Permission Required".localized, isPresented: $showPermissionAlert) {
            Button("Settings".localized) {
                openSettings()
            }
            Button("Cancel".localized) {
                settings.notificationsEnabled = false
            }
        } message: {
            Text("Please enable notifications in Settings to receive alerts.".localized)
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
