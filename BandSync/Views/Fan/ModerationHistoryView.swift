import SwiftUI
import FirebaseAuth

// MARK: - MODERATION HISTORY VIEW

struct ModerationHistoryView: View {
    let chat: FanChat
    @StateObject private var fanChatService = FanChatService.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var moderationLogs: [ModerationLog] = []
    @State private var isLoading = true
    @State private var showClearConfirmation = false
    @State private var isClearing = false
    
    var body: some View {
        NavigationView {
            VStack {
                if isLoading {
                    ProgressView(NSLocalizedString("Loading moderation history...", comment: "Loading moderation history message"))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if moderationLogs.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "shield.checkered")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text(NSLocalizedString("No Moderation History", comment: "No moderation history title"))
                            .font(.title2)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        
                        Text(NSLocalizedString("This chat has no recorded moderation actions yet.", comment: "No moderation history description"))
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(moderationLogs, id: \.id) { log in
                            ModerationLogRow(log: log, chat: chat)
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle(NSLocalizedString("Moderation History", comment: "Moderation history navigation title"))
            .navigationBarTitleDisplayMode(.large)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(NSLocalizedString("Close", comment: "Close button")) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 16) {
                        // Clear History Button
                        if !moderationLogs.isEmpty {
                            Button {
                                showClearConfirmation = true
                            } label: {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                            }
                            .disabled(isClearing)
                        }
                        
                        // Refresh Button
                        Button {
                            loadModerationHistory()
                        } label: {
                            Image(systemName: "arrow.clockwise")
                        }
                        .disabled(isLoading || isClearing)
                    }
                }
            }
            .onAppear {
                loadModerationHistory()
            }
            .alert(NSLocalizedString("Clear Moderation History", comment: "Clear moderation history alert title"), isPresented: $showClearConfirmation) {
                Button(NSLocalizedString("Cancel", comment: "Cancel button"), role: .cancel) { }
                Button(NSLocalizedString("Clear", comment: "Clear button"), role: .destructive) {
                    clearModerationHistory()
                }
            } message: {
                Text(NSLocalizedString("Are you sure you want to clear all moderation history for this chat? This action cannot be undone.", comment: "Clear moderation history confirmation message"))
            }
            .overlay {
                if isClearing {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.2)
                        
                        Text(NSLocalizedString("Clearing history...", comment: "Clearing history progress message"))
                            .font(.subheadline)
                            .foregroundColor(.white)
                    }
                    .padding(24)
                    .background(Color.black.opacity(0.8))
                    .cornerRadius(12)
                }
            }
        }
    }
    
    private func loadModerationHistory() {
        isLoading = true
        print("🔍 Loading moderation history for chat: \(chat.id ?? "unknown")")
        
        Task {
            let logs = await fanChatService.getModerationHistory(for: chat.id ?? "")
            print("📊 Loaded \(logs.count) moderation logs")
            await MainActor.run {
                self.moderationLogs = logs.sorted { $0.timestamp > $1.timestamp }
                self.isLoading = false
                print("✅ Moderation history updated with \(self.moderationLogs.count) entries")
            }
        }
    }
    
    private func clearModerationHistory() {
        isClearing = true
        print("🧹 Clearing moderation history for chat: \(chat.id ?? "unknown")")
        
        Task {
            let success = await fanChatService.clearModerationHistory(for: chat.id ?? "")
            await MainActor.run {
                self.isClearing = false
                if success {
                    self.moderationLogs = []
                    print("✅ Moderation history cleared successfully")
                } else {
                    print("❌ Failed to clear moderation history")
                    // Optionally show an error alert here
                }
            }
        }
    }
}

// MARK: - MODERATION LOG ROW

struct ModerationLogRow: View {
    let log: ModerationLog
    let chat: FanChat
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 12) {
                // Action Icon
                Image(systemName: actionIcon)
                    .font(.title3)
                    .foregroundColor(actionColor)
                    .frame(width: 24, height: 24)
                
                VStack(alignment: .leading, spacing: 6) {
                    // Action Description
                    HStack {
                        Text(actionDescription)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Text(formatTime(log.timestamp))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // Moderator & Target
                    HStack {
                        Text(NSLocalizedString("by", comment: "Moderation action by label"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(log.moderatorName)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.blue)
                        
                        if !log.targetUserId.isEmpty {
                            Text("→")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text(log.targetUserName)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.orange)
                        }
                    }
                    
                    // Reason
                    if !log.reason.isEmpty {
                        Text(NSLocalizedString("Reason: %@", comment: "Moderation reason label").replacingOccurrences(of: "%@", with: log.reason))
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.top, 2)
                    }
                }
                
                Spacer()
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(Color(.systemGray6).opacity(0.5))
            .cornerRadius(12)
        }
    }
    
    private var actionIcon: String {
        if let action = ModerationLog.ModerationAction(rawValue: log.action) {
            return action.icon
        }
        return "shield"
    }
    
    private var actionColor: Color {
        if let action = ModerationLog.ModerationAction(rawValue: log.action) {
            return Color(action.color)
        }
        return .gray
    }
    
    private var actionDescription: String {
        if let action = ModerationLog.ModerationAction(rawValue: log.action) {
            return action.displayName
        }
        return log.action.capitalized
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        
        if Calendar.current.isDate(date, inSameDayAs: Date()) {
            formatter.dateFormat = "HH:mm"
            return NSLocalizedString("Today", comment: "Today label") + " " + formatter.string(from: date)
        } else if Calendar.current.isDate(date, inSameDayAs: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()) {
            formatter.dateFormat = "HH:mm"
            return NSLocalizedString("Yesterday", comment: "Yesterday label") + " " + formatter.string(from: date)
        } else {
            formatter.dateFormat = "MMM d, HH:mm"
            return formatter.string(from: date)
        }
    }
}

#Preview {
    ModerationHistoryView(chat: FanChat(
        id: "preview",
        type: .general,
        participants: ["user1", "user2"],
        participantNames: ["user1": "John Doe", "user2": "Jane Smith"],
        participantAvatars: [:],
        createdBy: "user1",
        createdAt: Date(),
        updatedAt: Date(),
        name: "Test Chat",
        description: nil,
        lastMessage: nil,
        isDeleted: false,
        groupId: "group1",
        moderatorIds: ["user1"],
        isActive: true,
        chatRulesAccepted: [:]
    ))
}
