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
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Source message".localized) {
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
                
                Section("Integration type".localized) {
                    Picker("Type".localized, selection: $selectedIntegrationType) {
                        ForEach(IntegrationType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
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
            .navigationTitle("Create from message".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel".localized) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create".localized) {
                        createIntegration()
                    }
                    .disabled(isLoading || !canCreate)
                }
            }
            .alert("Error".localized, isPresented: $showingError) {
                Button("OK".localized) { }
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
        
        taskTitle = content.isEmpty ? "Task from chat".localized : String(content.prefix(50))
        taskDescription = content
        
        eventTitle = content.isEmpty ? "Event from chat".localized : String(content.prefix(50))
        eventDescription = content
    }
    
    @ViewBuilder
    private func TaskCreationSection() -> some View {
        Section("Task details".localized) {
            TextField("Task title".localized, text: $taskTitle)
            
            TextField("Description".localized, text: $taskDescription, axis: .vertical)
                .lineLimit(3...6)
            
            DatePicker("Due date".localized, selection: $taskDueDate, displayedComponents: [.date, .hourAndMinute])
            
            Picker("Priority".localized, selection: $taskPriority) {
                Text("Low".localized).tag(BandTaskPriority.low)
                Text("Medium".localized).tag(BandTaskPriority.medium)
                Text("High".localized).tag(BandTaskPriority.high)
            }
        }
        
        Section("Assignees".localized) {
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
                            Text("You".localized)
                                .font(.caption)
                                .foregroundColor(.blue)
                        } else {
                            Text("Participant".localized)
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
        Section("Event details".localized) {
            TextField("Event title".localized, text: $eventTitle)
            
            TextField("Description".localized, text: $eventDescription, axis: .vertical)
                .lineLimit(3...6)
            
            DatePicker("Date and time".localized, selection: $eventDate, displayedComponents: [.date, .hourAndMinute])
            
            TextField("Location".localized, text: $eventLocation)
        }
    }
    
    @ViewBuilder
    private func ReminderCreationSection() -> some View {
        Section("Reminder".localized) {
            DatePicker("Remind at".localized, selection: $eventDate, displayedComponents: [.date, .hourAndMinute])
            
            Text("A reminder will be created about the message:".localized)
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
            showError("Authentication error".localized)
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
                    self.showError("Task creation error".localized)
                }
            }
        }
    }
    
    private func createEvent() {
        guard Auth.auth().currentUser?.uid != nil else {
            showError("Authentication error".localized)
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
            content: String(format: "Task created".localized, title),
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
            content: String(format: "Event created".localized, title),
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
