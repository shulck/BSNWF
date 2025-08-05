import SwiftUI
import UserNotifications

struct FanChatNotificationView: View {
    @StateObject private var fanChatService = FanChatService.shared
    @State private var notificationSettings = FanChatNotificationSettings()
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            List {
                // General Notifications
                Section(header: Text(NSLocalizedString("General Notifications", comment: "Section header for general notification settings"))) {
                    NotificationToggle(
                        title: NSLocalizedString("New Messages", comment: "Setting for new message notifications"),
                        subtitle: NSLocalizedString("Get notified when someone sends a message", comment: "Description for new message notifications"),
                        isOn: $notificationSettings.newMessages
                    )
                    
                    NotificationToggle(
                        title: NSLocalizedString("Mentions", comment: "Setting for mention notifications"),
                        subtitle: NSLocalizedString("Get notified when someone mentions you", comment: "Description for mention notifications"),
                        isOn: $notificationSettings.mentions
                    )
                    
                    NotificationToggle(
                        title: NSLocalizedString("Direct Messages", comment: "Setting for direct message notifications"),
                        subtitle: NSLocalizedString("Get notified for private messages", comment: "Description for direct message notifications"),
                        isOn: $notificationSettings.directMessages
                    )
                }
                
                // Chat Type Notifications
                Section(header: Text(NSLocalizedString("Chat Types", comment: "Section header for chat type notification settings"))) {
                    NotificationToggle(
                        title: NSLocalizedString("Announcements", comment: "Setting for announcement notifications"),
                        subtitle: NSLocalizedString("Important messages from the band", comment: "Description for announcement notifications"),
                        isOn: $notificationSettings.announcements
                    )
                    
                    NotificationToggle(
                        title: NSLocalizedString("General Chat", comment: "Setting for general chat notifications"),
                        subtitle: NSLocalizedString("Messages in general fan chat", comment: "Description for general chat notifications"),
                        isOn: $notificationSettings.generalChat
                    )
                    
                    NotificationToggle(
                        title: NSLocalizedString("Themed Chats", comment: "Setting for themed chat notifications"),
                        subtitle: NSLocalizedString("Messages in themed discussions", comment: "Description for themed chat notifications"),
                        isOn: $notificationSettings.themedChats
                    )
                    
                    NotificationToggle(
                        title: NSLocalizedString("Mixed Chats", comment: "Setting for mixed chat notifications"),
                        subtitle: NSLocalizedString("Chats with band members", comment: "Description for mixed chat notifications"),
                        isOn: $notificationSettings.mixedChats
                    )
                }
                
                // Quiet Hours
                Section(header: Text(NSLocalizedString("Quiet Hours", comment: "Section header for quiet hours settings"))) {
                    Toggle(NSLocalizedString("Enable Quiet Hours", comment: "Toggle to enable quiet hours"), isOn: $notificationSettings.enableQuietHours)
                    
                    if notificationSettings.enableQuietHours {
                        HStack {
                            Text(NSLocalizedString("From", comment: "Label for quiet hours start time"))
                            Spacer()
                            DatePicker("", selection: $notificationSettings.quietHoursStart, displayedComponents: .hourAndMinute)
                                .labelsHidden()
                        }
                        
                        HStack {
                            Text(NSLocalizedString("To", comment: "Label for quiet hours end time"))
                            Spacer()
                            DatePicker("", selection: $notificationSettings.quietHoursEnd, displayedComponents: .hourAndMinute)
                                .labelsHidden()
                        }
                    }
                }
                
                // Notification Sound
                Section(header: Text(NSLocalizedString("Sound & Alerts", comment: "Section header for sound and alert settings"))) {
                    Picker(NSLocalizedString("Notification Sound", comment: "Label for notification sound picker"), selection: $notificationSettings.soundType) {
                        Text(NSLocalizedString("Default", comment: "Default notification sound option")).tag(NotificationSoundType.default)
                        Text(NSLocalizedString("Gentle", comment: "Gentle notification sound option")).tag(NotificationSoundType.gentle)
                        Text(NSLocalizedString("Vibrate Only", comment: "Vibrate only notification option")).tag(NotificationSoundType.vibrate)
                        Text(NSLocalizedString("Silent", comment: "Silent notification option")).tag(NotificationSoundType.silent)
                    }
                    
                    if notificationSettings.soundType != .silent {
                        Toggle(NSLocalizedString("Show Badge", comment: "Toggle to show notification badge"), isOn: $notificationSettings.showBadge)
                        Toggle(NSLocalizedString("Show Preview", comment: "Toggle to show notification preview"), isOn: $notificationSettings.showPreview)
                    }
                }
            }
            .navigationTitle(NSLocalizedString("Notification Settings", comment: "Navigation title for notification settings screen"))
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                loadNotificationSettings()
            }
            .onChange(of: notificationSettings) { _ in
                saveNotificationSettings()
            }
        }
    }
    
    private func loadNotificationSettings() {
        // Load from UserDefaults or Firebase
        if let data = UserDefaults.standard.data(forKey: "fanChatNotificationSettings"),
           let settings = try? JSONDecoder().decode(FanChatNotificationSettings.self, from: data) {
            notificationSettings = settings
        }
    }
    
    private func saveNotificationSettings() {
        if let data = try? JSONEncoder().encode(notificationSettings) {
            UserDefaults.standard.set(data, forKey: "fanChatNotificationSettings")
        }
    }
}

struct NotificationToggle: View {
    let title: String
    let subtitle: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .labelsHidden()
        }
    }
}

// MARK: - Notification Settings Model
struct FanChatNotificationSettings: Codable, Equatable {
    var newMessages: Bool = true
    var mentions: Bool = true
    var directMessages: Bool = true
    var announcements: Bool = true
    var generalChat: Bool = true
    var themedChats: Bool = true
    var mixedChats: Bool = true
    
    var enableQuietHours: Bool = false
    var quietHoursStart: Date = Calendar.current.date(from: DateComponents(hour: 22, minute: 0)) ?? Date()
    var quietHoursEnd: Date = Calendar.current.date(from: DateComponents(hour: 8, minute: 0)) ?? Date()
    
    var soundType: NotificationSoundType = .default
    var showBadge: Bool = true
    var showPreview: Bool = true
}

enum NotificationSoundType: String, CaseIterable, Codable {
    case `default` = "default"
    case gentle = "gentle"
    case vibrate = "vibrate"
    case silent = "silent"
}

// MARK: - Notification Manager
class FanChatNotificationManager: ObservableObject {
    static let shared = FanChatNotificationManager()
    
    private var settings = FanChatNotificationSettings()
    
    init() {
        loadSettings()
        requestNotificationPermission()
    }
    
    func loadSettings() {
        if let data = UserDefaults.standard.data(forKey: "fanChatNotificationSettings"),
           let loadedSettings = try? JSONDecoder().decode(FanChatNotificationSettings.self, from: data) {
            settings = loadedSettings
        }
    }
    
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error)")
            }
        }
    }
    
    func sendLocalNotification(
        chatName: String,
        senderName: String,
        message: String,
        chatType: FanChat.FanChatType
    ) {
        // Check if notifications are enabled for this chat type
        guard shouldSendNotification(for: chatType) else { return }
        
        // Check quiet hours
        if settings.enableQuietHours && isInQuietHours() {
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = chatName
        content.body = settings.showPreview ? "\(senderName): \(message)" : "New message"
        
        if settings.showBadge {
            content.badge = 1
        }
        
        switch settings.soundType {
        case .default:
            content.sound = .default
        case .gentle:
            content.sound = UNNotificationSound(named: UNNotificationSoundName("gentle.wav"))
        case .vibrate:
            content.sound = nil
        case .silent:
            content.sound = nil
        }
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    private func shouldSendNotification(for chatType: FanChat.FanChatType) -> Bool {
        switch chatType {
        case .general:
            return settings.generalChat
        case .privateChat:
            return settings.directMessages
        case .themed:
            return settings.themedChats
        case .announcement:
            return settings.announcements
        case .mixed:
            return settings.mixedChats
        }
    }
    
    private func isInQuietHours() -> Bool {
        let now = Date()
        let calendar = Calendar.current
        
        let currentTime = calendar.dateComponents([.hour, .minute], from: now)
        let startTime = calendar.dateComponents([.hour, .minute], from: settings.quietHoursStart)
        let endTime = calendar.dateComponents([.hour, .minute], from: settings.quietHoursEnd)
        
        let current = currentTime.hour! * 60 + currentTime.minute!
        let start = startTime.hour! * 60 + startTime.minute!
        let end = endTime.hour! * 60 + endTime.minute!
        
        if start < end {
            return current >= start && current <= end
        } else {
            return current >= start || current <= end
        }
    }
}

#Preview {
    FanChatNotificationView()
}
