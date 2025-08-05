import SwiftUI
import Firebase
import FirebaseAuth

struct FanChatAdminView: View {
    @StateObject private var fanChatService = FanChatService.shared
    @State private var selectedSegment = 0
    @State private var reports: [FanChatReport] = []
    @State private var showBlockUserAlert = false
    @State private var selectedUserToBlock: String?
    @State private var blockReason = ""
    @State private var showDeleteMessageAlert = false
    @State private var selectedMessageToDelete: String?
    @State private var showCreateRuleSheet = false
    @State private var newRuleText = ""
    @State private var isLoading = false
    
    private var segments: [String] {
        [
            NSLocalizedString("Active Chats", comment: ""),
            NSLocalizedString("Reports", comment: ""),
            NSLocalizedString("Rules", comment: "")
        ]
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Segment Control
                Picker(NSLocalizedString("Admin Section", comment: ""), selection: $selectedSegment) {
                    ForEach(0..<segments.count, id: \.self) { index in
                        Text(segments[index]).tag(index)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                // Content based on selected segment
                TabView(selection: $selectedSegment) {
                    // Active Chats Tab
                    activeChatsList
                        .tag(0)
                    
                    // Reports Tab
                    reportsList
                        .tag(1)
                    
                    // Rules Tab
                    rulesList
                        .tag(2)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            .navigationTitle(NSLocalizedString("Fan Chat Admin", comment: ""))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink {
                        FanChatModeratorManagementView()
                    } label: {
                        Image(systemName: "person.badge.key")
                            .foregroundColor(.blue)
                    }
                }
            }
            .onAppear {
                loadReports()
            }
            .alert(NSLocalizedString("Block User", comment: ""), isPresented: $showBlockUserAlert) {
                TextField(NSLocalizedString("Reason for blocking", comment: ""), text: $blockReason)
                Button(NSLocalizedString("Block", comment: "")) {
                    if let userId = selectedUserToBlock {
                        blockUser(userId: userId, reason: blockReason)
                    }
                }
                Button(NSLocalizedString("Cancel", comment: ""), role: .cancel) {}
            }
            .alert(NSLocalizedString("Delete Message", comment: ""), isPresented: $showDeleteMessageAlert) {
                Button(NSLocalizedString("Delete", comment: ""), role: .destructive) {
                    if let messageId = selectedMessageToDelete {
                        deleteMessage(messageId: messageId)
                    }
                }
                Button(NSLocalizedString("Cancel", comment: ""), role: .cancel) {}
            } message: {
                Text(NSLocalizedString("This message will be permanently deleted.", comment: ""))
            }
            .sheet(isPresented: $showCreateRuleSheet) {
                createRuleSheet
            }
        }
    }
    
    // MARK: - Active Chats List
    private var activeChatsList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(fanChatService.fanChats) { chat in
                    activeChatRow(chat: chat)
                }
            }
            .padding()
        }
        .refreshable {
            // Reload fan chats data
            if let user = AppState.shared.user,
               let groupId = user.fanGroupId ?? user.groupId {
                fanChatService.startListeningToFanChats(for: groupId)
            }
        }
    }
    
    private func activeChatRow(chat: FanChat) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                // Chat Icon
                Image(systemName: chatIcon(for: chat.type))
                    .foregroundColor(chatColor(for: chat.type))
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(chat.name ?? NSLocalizedString("Unnamed Chat", comment: ""))
                        .font(.headline)
                    
                    Text(String(format: NSLocalizedString("%d participants", comment: ""), chat.participants.count))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if chat.isActive {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 8, height: 8)
                } else {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 8, height: 8)
                }
            }
            
            // Action Buttons
            HStack(spacing: 12) {
                Button(chat.isActive ? NSLocalizedString("Deactivate", comment: "") : NSLocalizedString("Activate", comment: "")) {
                    toggleChatStatus(chat: chat)
                }
                .buttonStyle(.bordered)
                .foregroundColor(chat.isActive ? .red : .green)
                
                NavigationLink(NSLocalizedString("View Messages", comment: "")) {
                    FanChatModerationView(chat: chat)
                }
                .buttonStyle(.bordered)
                
                if chat.type == .mixed {
                    Button(NSLocalizedString("Settings", comment: "")) {
                        // Open mixed chat settings
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    // MARK: - Reports List
    private var reportsList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                if reports.isEmpty {
                    ContentUnavailableView(
                        NSLocalizedString("No Reports", comment: ""),
                        systemImage: "checkmark.shield.fill",
                        description: Text(NSLocalizedString("All fan chats are running smoothly!", comment: ""))
                    )
                    .foregroundColor(.green)
                } else {
                    ForEach(reports, id: \.id) { report in
                        reportRow(report: report)
                    }
                }
            }
            .padding()
        }
        .refreshable {
            loadReports()
        }
    }
    
    private func reportRow(report: FanChatReport) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(report.reason.rawValue)")
                        .font(.headline)
                    
                    Text(String(format: NSLocalizedString("Reported by: %@", comment: ""), report.reporterUserId))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text(timeAgo(from: report.timestamp))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if let description = report.description, !description.isEmpty {
                Text(description)
                    .font(.body)
                    .padding(.vertical, 4)
            }
            
            // Report Actions
            HStack(spacing: 12) {
                Button(NSLocalizedString("View Message", comment: "")) {
                    // Navigate to reported message
                }
                .buttonStyle(.bordered)
                
                Button(NSLocalizedString("Block User", comment: "")) {
                    selectedUserToBlock = report.reportedUserId
                    showBlockUserAlert = true
                }
                .buttonStyle(.bordered)
                .foregroundColor(.red)
                
                Button(NSLocalizedString("Dismiss", comment: "")) {
                    dismissReport(report: report)
                }
                .buttonStyle(.bordered)
                .foregroundColor(.green)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    // MARK: - Rules List
    private var rulesList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                if let rules = fanChatService.chatRules?.rules {
                    ForEach(rules) { rule in
                        ruleRow(rule: rule)
                    }
                }
                
                // Add New Rule Button
                Button(action: {
                    showCreateRuleSheet = true
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text(NSLocalizedString("Add New Rule", comment: ""))
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .foregroundColor(.blue)
                    .cornerRadius(12)
                }
            }
            .padding()
        }
    }
    
    private func ruleRow(rule: FanChatRules.ChatRule) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(rule.title)
                    .font(.headline)
                    .multilineTextAlignment(.leading)
                
                Text(rule.description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
            }
            
            Spacer()
            
            Button(action: {
                removeRule(rule: rule)
            }) {
                Image(systemName: "minus.circle.fill")
                    .foregroundColor(.red)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    // MARK: - Create Rule Sheet
    private var createRuleSheet: some View {
        NavigationView {
            VStack(spacing: 20) {
                TextField(NSLocalizedString("Enter new rule", comment: ""), text: $newRuleText, axis: .vertical)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .lineLimit(3...6)
                
                Spacer()
            }
            .padding()
            .navigationTitle(NSLocalizedString("Add New Rule", comment: ""))
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button(NSLocalizedString("Cancel", comment: "")) {
                    showCreateRuleSheet = false
                    newRuleText = ""
                },
                trailing: Button(NSLocalizedString("Add", comment: "")) {
                    addNewRule()
                }
                .disabled(newRuleText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            )
        }
    }
    
    // MARK: - Helper Functions
    private func chatIcon(for type: FanChat.FanChatType) -> String {
        switch type {
        case .general:
            return "bubble.left.and.bubble.right.fill"
        case .privateChat:
            return "lock.fill"
        case .themed:
            return "music.note"
        case .announcement:
            return "megaphone.fill"
        case .mixed:
            return "person.2.fill"
        }
    }
    
    private func chatColor(for type: FanChat.FanChatType) -> Color {
        switch type {
        case .general:
            return .blue
        case .privateChat:
            return .orange
        case .themed:
            return .purple
        case .announcement:
            return .green
        case .mixed:
            return .pink
        }
    }
    
    private func timeAgo(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    // MARK: - Actions
    private func loadReports() {
        isLoading = true
        // Load reports from Firebase
        let db = Firestore.firestore()
        db.collection("fanChatReports")
            .order(by: "timestamp", descending: true)
            .limit(to: 50)
            .getDocuments { snapshot, error in
                DispatchQueue.main.async {
                    isLoading = false
                    if let documents = snapshot?.documents {
                        reports = documents.compactMap { doc in
                            try? doc.data(as: FanChatReport.self)
                        }
                    }
                }
            }
    }
    
    private func toggleChatStatus(chat: FanChat) {
        if let chatId = chat.id {
            fanChatService.toggleChatStatus(chatId: chatId, isActive: !chat.isActive)
        }
    }
    
    private func blockUser(userId: String, reason: String) {
        // Block user implementation
        let db = Firestore.firestore()
        let blockData: [String: Any] = [
            "userId": userId,
            "reason": reason,
            "blockedAt": Timestamp(),
            "blockedBy": Auth.auth().currentUser?.uid ?? ""
        ]
        
        db.collection("blockedUsers").addDocument(data: blockData) { error in
            if let error = error {
                print("Error blocking user: \(error)")
            } else {
                print("User blocked successfully")
                // Refresh reports
                loadReports()
            }
        }
        
        blockReason = ""
        selectedUserToBlock = nil
    }
    
    private func deleteMessage(messageId: String) {
        // Delete message implementation
        fanChatService.deleteMessage(messageId: messageId)
        selectedMessageToDelete = nil
    }
    
    private func dismissReport(report: FanChatReport) {
        guard let reportId = report.id else { return }
        
        let db = Firestore.firestore()
        db.collection("fanChatReports").document(reportId).updateData([
            "status": "dismissed",
            "dismissedAt": Timestamp(),
            "dismissedBy": Auth.auth().currentUser?.uid ?? ""
        ]) { error in
            if let error = error {
                print("Error dismissing report: \(error)")
            } else {
                loadReports()
            }
        }
    }
    
    private func addNewRule() {
        let trimmedRule = newRuleText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedRule.isEmpty {
            let newRule = FanChatRules.ChatRule(
                title: trimmedRule,
                description: NSLocalizedString("Custom rule", comment: ""),
                icon: "exclamationmark.triangle",
                severity: .info
            )
            fanChatService.addRule(rule: newRule)
            newRuleText = ""
            showCreateRuleSheet = false
        }
    }
    
    private func removeRule(rule: FanChatRules.ChatRule) {
        fanChatService.removeRule(rule: rule)
    }
}

#Preview {
    FanChatAdminView()
}
