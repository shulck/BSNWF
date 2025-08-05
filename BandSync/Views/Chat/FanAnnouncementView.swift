import SwiftUI
import FirebaseAuth

// MARK: - FAN ANNOUNCEMENT VIEW

struct FanAnnouncementView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var fanChatService = FanChatService.shared
    @EnvironmentObject private var appState: AppState
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var announcementTitle = ""
    @State private var announcementMessage = ""
    @State private var isImportant = false
    @State private var isSending = false
    @State private var showingSendConfirmation = false
    @State private var fanCount = 0
    
    private var canSendAnnouncement: Bool {
        let trimmedTitle = announcementTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedMessage = announcementMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        
        return !trimmedTitle.isEmpty && 
               !trimmedMessage.isEmpty && 
               trimmedMessage.count <= 1000 &&
               fanCount > 0
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header Section
                    headerSection
                    
                    // Announcement Details Section
                    announcementDetailsSection
                    
                    // Fan Count Section
                    fanCountSection
                    
                    // Preview Section
                    previewSection
                    
                    // Warning Section
                    warningSection
                }
                .padding()
            }
            .navigationTitle(NSLocalizedString("sendToFans", comment: "Navigation title for fan announcement view"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(NSLocalizedString("cancel", comment: "Cancel button")) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(NSLocalizedString("send", comment: "Send button")) {
                        showingSendConfirmation = true
                    }
                    .disabled(!canSendAnnouncement || isSending)
                    .foregroundColor(canSendAnnouncement ? .blue : .secondary)
                }
            }
            .alert(NSLocalizedString("sendAnnouncementAlert", comment: "Send announcement confirmation alert title"), isPresented: $showingSendConfirmation) {
                Button(NSLocalizedString("cancel", comment: "Cancel button"), role: .cancel) { }
                Button(String.localizedStringWithFormat(NSLocalizedString("sendToFansCount", comment: "Send to X fans button"), fanCount), role: .destructive) {
                    sendAnnouncement()
                }
            } message: {
                Text(NSLocalizedString("announcementReadOnlyMessage", comment: "Announcement read-only message"))
            }
            .onAppear {
                loadFanCount()
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [.purple, .blue]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                    .shadow(color: .purple.opacity(0.3), radius: 12, x: 0, y: 6)
                
                Image(systemName: "speaker.wave.3.fill")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
            }
            
            VStack(spacing: 8) {
                Text(NSLocalizedString("fanAnnouncement", comment: "Fan announcement header title"))
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text(NSLocalizedString("sendMessageToAllFans", comment: "Send message to all fans subtitle"))
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    // MARK: - Announcement Details Section
    
    private var announcementDetailsSection: some View {
        VStack(spacing: 20) {
            // Title Input
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(NSLocalizedString("announcementTitle", comment: "Announcement title label"))
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Text("\(announcementTitle.count)/100")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                TextField(NSLocalizedString("enterAnnouncementTitle", comment: "Enter announcement title placeholder"), text: $announcementTitle)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onChange(of: announcementTitle) { newValue in
                        if newValue.count > 100 {
                            announcementTitle = String(newValue.prefix(100))
                        }
                    }
            }
            
            // Message Input
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(NSLocalizedString("message", comment: "Message label"))
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Text("\(announcementMessage.count)/1000")
                        .font(.caption)
                        .foregroundColor(announcementMessage.count > 800 ? .orange : .secondary)
                }
                
                TextField(NSLocalizedString("typeAnnouncementMessage", comment: "Type announcement message placeholder"), text: $announcementMessage, axis: .vertical)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .lineLimit(8...12)
                    .onChange(of: announcementMessage) { newValue in
                        if newValue.count > 1000 {
                            announcementMessage = String(newValue.prefix(1000))
                        }
                    }
            }
            
            // Important Toggle
            HStack {
                Toggle(isOn: $isImportant) {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(isImportant ? .red : .secondary)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(NSLocalizedString("markAsImportant", comment: "Mark as important label"))
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            Text(NSLocalizedString("fansWillReceivePushNotification", comment: "Fans will receive push notification subtitle"))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .toggleStyle(SwitchToggleStyle())
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.secondary.opacity(0.05))
            )
        }
    }
    
    // MARK: - Fan Count Section
    
    private var fanCountSection: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.15))
                    .frame(width: 48, height: 48)
                
                Image(systemName: "person.3.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.blue)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(NSLocalizedString("recipients", comment: "Recipients label"))
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(String.localizedStringWithFormat(NSLocalizedString("fansWillReceiveThisMessage", comment: "X fans will receive this message"), fanCount))
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(colorScheme == .dark ?
                      Color(UIColor.secondarySystemGroupedBackground) :
                      Color.white)
                .shadow(
                    color: colorScheme == .dark ?
                        Color.clear :
                        Color.black.opacity(0.06),
                    radius: 8,
                    x: 0,
                    y: 2
                )
        )
    }
    
    // MARK: - Preview Section
    
    private var previewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(NSLocalizedString("preview", comment: "Preview section title"))
                .font(.headline)
                .fontWeight(.semibold)
            
            if !announcementTitle.isEmpty || !announcementMessage.isEmpty {
                AnnouncementPreviewCard(
                    title: announcementTitle.isEmpty ? NSLocalizedString("announcementTitle", comment: "Announcement title placeholder") : announcementTitle,
                    message: announcementMessage.isEmpty ? NSLocalizedString("announcementMessagePlaceholder", comment: "Announcement message placeholder") : announcementMessage,
                    isImportant: isImportant,
                    isPreview: true
                )
            } else {
                Text(NSLocalizedString("enterTitleAndMessageForPreview", comment: "Enter title and message to see preview"))
                    .font(.body)
                    .foregroundColor(.secondary)
                    .italic()
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.secondary.opacity(0.1))
                    )
            }
        }
    }
    
    // MARK: - Warning Section
    
    private var warningSection: some View {
        HStack(spacing: 12) {
            Image(systemName: "info.circle.fill")
                .foregroundColor(.orange)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(NSLocalizedString("importantInformation", comment: "Important information title"))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.orange)
                
                Text(NSLocalizedString("announcementWarningText", comment: "Announcement warning text"))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(nil)
            }
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.orange.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.orange.opacity(0.2), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Helper Methods
    
    private func loadFanCount() {
        guard let user = appState.user,
              let groupId = user.groupId else { return }
        
        // TODO: Load actual fan count from Firestore
        // For now, using mock data
        fanCount = 150 // Mock fan count
    }
    
    private func sendAnnouncement() {
        guard let user = appState.user,
              let groupId = user.groupId else { return }
        
        isSending = true
        
        // Create announcement message for fan chat
        let trimmedTitle = announcementTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedMessage = announcementMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        
        let fullMessage = "📢 \(trimmedTitle)\n\n\(trimmedMessage)"
        
        // Send to fan announcement chat
        fanChatService.sendAnnouncementToFans(
            title: trimmedTitle,
            message: fullMessage,
            isImportant: isImportant,
            groupId: groupId
        )
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            isSending = false
            dismiss()
        }
    }
}

// MARK: - ANNOUNCEMENT PREVIEW CARD

struct AnnouncementPreviewCard: View {
    let title: String
    let message: String
    let isImportant: Bool
    let isPreview: Bool
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with icon and badge
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.orange.opacity(0.15))
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: "megaphone.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.orange)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 8) {
                        Text(NSLocalizedString("bandAnnouncement", comment: "Band announcement label"))
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.orange)
                        
                        if isImportant {
                            Text(NSLocalizedString("important", comment: "Important badge text"))
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.red)
                                .clipShape(Capsule())
                        }
                        
                        if isPreview {
                            Text(NSLocalizedString("previewBadge", comment: "Preview badge text"))
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.blue)
                                .clipShape(Capsule())
                        }
                    }
                    
                    Text(NSLocalizedString("justNow", comment: "Just now timestamp"))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            // Title
            Text(title)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .lineLimit(nil)
            
            // Message
            Text(message)
                .font(.body)
                .foregroundColor(.primary)
                .lineLimit(nil)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.orange.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.orange.opacity(0.2), lineWidth: 1)
                )
        )
    }
}
