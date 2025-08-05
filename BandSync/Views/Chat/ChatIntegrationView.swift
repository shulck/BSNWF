//
//  ChatIntegrationView.swift
//  BandSync
//
//  Created by Oleksandr Kuziakin on 26.06.2025.
//

import SwiftUI
import FirebaseAuth

struct ChatIntegrationView: View {
    let message: Message
    let chat: Chat
    @Environment(\.dismiss) private var dismiss
    @StateObject private var taskService = TaskService.shared
    @StateObject private var userService = UserService.shared
    
    @State private var selectedIntegrationType: IntegrationType = .task
    @State private var taskTitle = ""
    @State private var taskDescription = ""
    @State private var taskDueDate = Date().addingTimeInterval(24 * 60 * 60) // Tomorrow
    @State private var taskAssignees: Set<String> = []
    @State private var taskPriority: BandTaskPriority = .medium
    
    @State private var eventTitle = ""
    @State private var eventDescription = ""
    @State private var eventDate = Date().addingTimeInterval(24 * 60 * 60)
    @State private var eventLocation = ""
    
    @State private var isLoading = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    enum IntegrationType: String, CaseIterable {
        case task = "Task"
        case event = "Event"
        case reminder = "Reminder"
        
        var localizedTitle: String {
            switch self {
            case .task:
                return NSLocalizedString("Task", comment: "Task integration type")
            case .event:
                return NSLocalizedString("Event", comment: "Event integration type")
            case .reminder:
                return NSLocalizedString("Reminder", comment: "Reminder integration type")
            }
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(NSLocalizedString("Source message", comment: "Source message section title")) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(message.senderName)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.blue)
                            
                            Spacer()
                            
                            Text(formatDate(message.timestamp))
                                .font(.caption2)
                                .foregroundColor(.gray)
                        }
                        
                        Text(message.content)
                            .font(.body)
                            .padding(8)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                    }
                }
                
                Section(NSLocalizedString("Integration type", comment: "Integration type section title")) {
                    Picker(NSLocalizedString("Type", comment: "Type picker label"), selection: $selectedIntegrationType) {
                        ForEach(IntegrationType.allCases, id: \.self) { type in
                            Text(type.localizedTitle).tag(type)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                switch selectedIntegrationType {
                case .task:
                    TaskCreationSection()
                case .event:
                    EventCreationSection()
                case .reminder:
                    ReminderCreationSection()
                }
            }
            .navigationTitle(NSLocalizedString("Create from message", comment: "Navigation title for create from message view"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(NSLocalizedString("Cancel", comment: "Cancel button")) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(NSLocalizedString("Create", comment: "Create button")) {
                        createIntegration()
                    }
                    .disabled(isLoading || !canCreate)
                }
            }
            .alert(NSLocalizedString("Error", comment: "Error alert title"), isPresented: $showingError) {
                Button(NSLocalizedString("OK", comment: "OK button")) { }
            } message: {
                Text(errorMessage)
            }
        }
        .onAppear {
            setupDefaultValues()
        }
    }
    
    private var canCreate: Bool {
        switch selectedIntegrationType {
        case .task:
            return !taskTitle.isEmpty
        case .event:
            return !eventTitle.isEmpty
        case .reminder:
            return true
        }
    }
    
    private func setupDefaultValues() {
        // Load users for displaying names
        userService.fetchUsers()
        
        // Try to extract information from message for prefilling
        let content = message.content
        
        taskTitle = content.isEmpty ? NSLocalizedString("Task from chat", comment: "Default task title from chat") : String(content.prefix(50))
        taskDescription = content
        
        eventTitle = content.isEmpty ? NSLocalizedString("Event from chat", comment: "Default event title from chat") : String(content.prefix(50))
        eventDescription = content
    }
    
    @ViewBuilder
    private func TaskCreationSection() -> some View {
        Section(NSLocalizedString("Task details", comment: "Task details section title")) {
            TextField(NSLocalizedString("Task title", comment: "Task title text field"), text: $taskTitle)
            
            TextField(NSLocalizedString("Description", comment: "Description text field"), text: $taskDescription, axis: .vertical)
                .lineLimit(3...6)
            
            DatePicker(NSLocalizedString("Due date", comment: "Due date picker"), selection: $taskDueDate, displayedComponents: [.date, .hourAndMinute])
            
            Picker(NSLocalizedString("Priority", comment: "Priority picker"), selection: $taskPriority) {
                Text(NSLocalizedString("Low", comment: "Low priority")).tag(BandTaskPriority.low)
                Text(NSLocalizedString("Medium", comment: "Medium priority")).tag(BandTaskPriority.medium)
                Text(NSLocalizedString("High", comment: "High priority")).tag(BandTaskPriority.high)
            }
        }
        
        Section(NSLocalizedString("Assignees", comment: "Assignees section title")) {
            ForEach(chat.participants, id: \.self) { userId in
                HStack(spacing: 12) {
                    // User avatar
                    if let user = userService.users.first(where: { $0.id == userId }) {
                        AvatarView(user: user, size: 32)
                    } else {
                        AvatarView(avatarURL: nil, name: getUserName(userId), size: 32)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(getUserName(userId))
                            .font(.body)
                            .fontWeight(.medium)
                        
                        if userId == Auth.auth().currentUser?.uid {
                            Text(NSLocalizedString("You", comment: "You label for current user"))
                                .font(.caption)
                                .foregroundColor(.blue)
                        } else {
                            Text(NSLocalizedString("Participant", comment: "Participant label"))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    Button(action: { toggleAssignee(userId) }) {
                        Image(systemName: taskAssignees.contains(userId) ? "checkmark.circle.fill" : "circle")
                            .font(.title2)
                            .foregroundColor(taskAssignees.contains(userId) ? .blue : .gray)
                    }
                }
                .padding(.vertical, 4)
                .contentShape(Rectangle())
                .onTapGesture {
                    toggleAssignee(userId)
                }
            }
        }
    }
    
    @ViewBuilder
    private func EventCreationSection() -> some View {
        Section(NSLocalizedString("Event details", comment: "Event details section title")) {
            TextField(NSLocalizedString("Event title", comment: "Event title text field"), text: $eventTitle)
            
            TextField(NSLocalizedString("Description", comment: "Description text field"), text: $eventDescription, axis: .vertical)
                .lineLimit(3...6)
            
            DatePicker(NSLocalizedString("Date and time", comment: "Date and time picker"), selection: $eventDate, displayedComponents: [.date, .hourAndMinute])
            
            TextField(NSLocalizedString("Location", comment: "Location text field"), text: $eventLocation)
        }
    }
    
    @ViewBuilder
    private func ReminderCreationSection() -> some View {
        Section(NSLocalizedString("Reminder", comment: "Reminder section title")) {
            DatePicker(NSLocalizedString("Remind at", comment: "Remind at date picker"), selection: $eventDate, displayedComponents: [.date, .hourAndMinute])
            
            Text(NSLocalizedString("A reminder will be created about the message:", comment: "Reminder explanation text"))
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(message.content)
                .font(.body)
                .padding(8)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
        }
    }
    
    private func toggleAssignee(_ userId: String) {
        if taskAssignees.contains(userId) {
            taskAssignees.remove(userId)
        } else {
            taskAssignees.insert(userId)
        }
    }
    
    private func createIntegration() {
        isLoading = true
        
        switch selectedIntegrationType {
        case .task:
            createTask()
        case .event:
            createEvent()
        case .reminder:
            createReminder()
        }
    }
    
    private func createTask() {
        guard let currentUserId = Auth.auth().currentUser?.uid,
              let groupId = UserService.shared.currentUser?.groupId else {
            showError(NSLocalizedString("Authentication error", comment: "Authentication error message"))
            return
        }
        
        let task = TaskModel(
            title: taskTitle,
            description: taskDescription,
            assignedTo: Array(taskAssignees),
            startDate: taskDueDate,
            endDate: taskDueDate,
            hasTime: false,
            completed: false,
            groupId: groupId,
            priority: taskPriority,
            category: .other,
            attachments: nil,
            reminders: nil,
            createdBy: currentUserId,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        taskService.addTask(task) { success in
            DispatchQueue.main.async {
                self.isLoading = false
                
                if success {
                    self.sendTaskCreatedMessage(title: self.taskTitle)
                    self.dismiss()
                } else {
                    self.showError(NSLocalizedString("Task creation error", comment: "Task creation error message"))
                }
            }
        }
    }
    
    private func createEvent() {
        guard Auth.auth().currentUser?.uid != nil else {
            showError(NSLocalizedString("Authentication error", comment: "Authentication error message"))
            return
        }
        
        // Here should be event creation logic
        // Placeholder for now
        DispatchQueue.main.async {
            self.isLoading = false
            self.sendEventCreatedMessage(title: self.eventTitle)
            self.dismiss()
        }
    }
    
    private func createReminder() {
        // Here should be reminder creation logic
        // Placeholder for now
        DispatchQueue.main.async {
            self.isLoading = false
            self.dismiss()
        }
    }
    
    private func sendTaskCreatedMessage(title: String) {
        guard let chatId = chat.id else { return }
        
        let message = Message(
            chatId: chatId,
            content: String(format: NSLocalizedString("Task created: %@", comment: "Task created system message"), title),
            senderID: Auth.auth().currentUser?.uid ?? "",
            senderName: UserService.shared.currentUser?.name ?? "System",
            timestamp: Date(),
            type: .system,
            replyToMessageId: message.id
        )
        
        ChatService.shared.sendMessage(message) { _ in }
    }
    
    private func sendEventCreatedMessage(title: String) {
        guard let chatId = chat.id else { return }
        
        let message = Message(
            chatId: chatId,
            content: String(format: NSLocalizedString("Event created: %@", comment: "Event created system message"), title),
            senderID: Auth.auth().currentUser?.uid ?? "",
            senderName: UserService.shared.currentUser?.name ?? "System",
            timestamp: Date(),
            type: .system,
            replyToMessageId: message.id
        )
        
        ChatService.shared.sendMessage(message) { _ in }
    }
    
    private func showError(_ message: String) {
        errorMessage = message
        showingError = true
        isLoading = false
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func getUserName(_ userId: String) -> String {
        // Try to get user name from UserService
        if let user = userService.users.first(where: { $0.id == userId }) {
            return user.name
        }
        
        // Fallback to showing partial ID if user not found
        return "User \(userId.prefix(8))"
    }
}

#Preview {
    let sampleMessage = Message(
        id: "msg1",
        chatId: "chat1",
        content: "Need to prepare presentation for next week",
        senderID: "user1",
        senderName: "User 1",
        timestamp: Date(),
        type: .text
    )
    
    let sampleChat = Chat(
        type: .group,
        participants: ["user1", "user2", "user3"],
        createdBy: "user1",
        createdAt: Date(),
        updatedAt: Date(),
        name: "Work Chat"
    )
    
    ChatIntegrationView(message: sampleMessage, chat: sampleChat)
}
