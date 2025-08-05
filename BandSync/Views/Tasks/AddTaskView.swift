import SwiftUI

struct AddTaskView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var groupService = GroupService.shared
    @StateObject private var taskService = TaskService.shared
    @State private var title = ""
    @State private var description = ""
    @State private var assignedTo = ""
    
    @State private var startDate = Date()
    @State private var endDate = Date()
    @State private var hasTime = false
    @State private var isMultiDay = false
    
    @State private var priority: BandTaskPriority = .medium
    @State private var category: TaskCategory = .other
    @State private var showUserPicker = false
    @State private var selectedUsers: [UserModel] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var addReminder = false
    
    @State private var groupMembers: [UserModel] = []
    
    private func priorityColor(_ priority: BandTaskPriority) -> Color {
        switch priority {
        case .high: return .red
        case .medium: return .orange
        case .low: return .green
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Task Information".localized)) {
                    TextField("Task Title".localized, text: $title)
                    
                    dateTimeSection
                    
                    Picker("Priority".localized, selection: $priority) {
                        ForEach(BandTaskPriority.allCases, id: \.self) { taskPriority in
                            HStack {
                                Circle()
                                    .fill(priorityColor(taskPriority))
                                    .frame(width: 12, height: 12)
                                Text(taskPriority.displayName.localized)
                            }
                            .tag(taskPriority)
                        }
                    }
                    
                    Picker("Category".localized, selection: $category) {
                        ForEach(TaskCategory.allCases) { category in
                            Label(category.displayName.localized, systemImage: category.iconName)
                                .tag(category)
                        }
                    }
                    
                    HStack {
                        Text("Assigned To".localized)
                        Spacer()
                        
                        Button(action: {
                            if groupMembers.isEmpty {
                                loadGroupMembers()
                            }
                            showUserPicker = true
                        }) {
                            if isLoading {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                if selectedUsers.isEmpty {
                                    Text("Select Users".localized)
                                        .foregroundColor(.blue)
                                } else {
                                    Text("\(selectedUsers.count) \(selectedUsers.count == 1 ? "User".localized : "Users".localized) " + "Selected".localized)
                                        .foregroundColor(.primary)
                                }
                            }
                        }
                        .disabled(isLoading)
                    }
                }
                
                Section(header: Text("Description".localized)) {
                    TextEditor(text: $description)
                        .frame(minHeight: 100)
                }
                
                Section(header: Text("Reminder".localized)) {
                    Toggle("Add Reminder".localized, isOn: $addReminder)
                }
                
                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("New Task".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save".localized) {
                        saveTask()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading)
                }
                
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel".localized) {
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadGroupMembers()
                endDate = startDate
            }
            .sheet(isPresented: $showUserPicker) {
                UserPickerView(selectedUsers: $selectedUsers, users: groupMembers)
            }
            .overlay {
                if isLoading {
                    ProgressView()
                        .padding()
                        .background(Color.white.opacity(0.8))
                        .cornerRadius(8)
                }
            }
        }
    }
    
    private var dateTimeSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Include Time".localized)
                Spacer()
                Toggle("", isOn: $hasTime)
                    .onChange(of: hasTime) {
                        if !hasTime {
                            startDate = Calendar.current.startOfDay(for: startDate)
                            endDate = Calendar.current.startOfDay(for: endDate)
                        }
                    }
            }
            
            HStack {
                Text("Multi-day Task".localized)
                Spacer()
                Toggle("", isOn: $isMultiDay)
                    .onChange(of: isMultiDay) {
                        if !isMultiDay {
                            endDate = startDate
                        }
                    }
            }
            
            if hasTime {
                DatePicker("Start Date & Time".localized, selection: $startDate, displayedComponents: [.date, .hourAndMinute])
                    .onChange(of: startDate) {
                        if endDate < startDate {
                            endDate = startDate
                        }
                        if !isMultiDay {
                            endDate = startDate
                        }
                    }
            } else {
                DatePicker("Start Date".localized, selection: $startDate, displayedComponents: [.date])
                    .onChange(of: startDate) {
                        if endDate < startDate {
                            endDate = startDate
                        }
                        if !isMultiDay {
                            endDate = startDate
                        }
                    }
            }
            
            if isMultiDay {
                if hasTime {
                    DatePicker("End Date & Time".localized, selection: $endDate, in: startDate..., displayedComponents: [.date, .hourAndMinute])
                } else {
                    DatePicker("End Date".localized, selection: $endDate, in: startDate..., displayedComponents: [.date])
                }
            }
            
            if isMultiDay {
                HStack {
                    Text("Duration".localized)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(formatDuration())
                        .foregroundColor(.secondary)
                }
                .font(.caption)
            }
        }
    }
    
    private func formatDuration() -> String {
        let duration = endDate.timeIntervalSince(startDate)
        let days = Int(duration / 86400)
        let hours = Int((duration.truncatingRemainder(dividingBy: 86400)) / 3600)
        let minutes = Int((duration.truncatingRemainder(dividingBy: 3600)) / 60)
        
        var components: [String] = []
        
        if days > 0 {
            components.append("\(days) \(days == 1 ? "day".localized : "days".localized)")
        }
        if hours > 0 {
            components.append("\(hours) \(hours == 1 ? "hour".localized : "hours".localized)")
        }
        if minutes > 0 && days == 0 {
            components.append("\(minutes) \(minutes == 1 ? "minute".localized : "minutes".localized)")
        }
        
        return components.isEmpty ? "0 minutes".localized : components.joined(separator: ", ")
    }
    
    private func loadGroupMembers() {
        guard let groupId = AppState.shared.user?.groupId else {
            self.errorMessage = "No group ID found".localized
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        if !groupService.groupMembers.isEmpty {
            self.groupMembers = groupService.groupMembers
            self.isLoading = false
            return
        }
        
        groupService.fetchGroup(by: groupId)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.groupMembers = self.groupService.groupMembers
            self.isLoading = false
            
            if self.groupMembers.isEmpty {
                self.errorMessage = "Failed to load group members. Please try again.".localized
            }
        }
    }
    
    private func saveTask() {
        guard let user = AppState.shared.user,
              let groupId = user.groupId else {
            errorMessage = "Missing user or group information".localized
            return
        }
        
        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Please enter a task title".localized
            return
        }
        
        if isMultiDay && endDate <= startDate {
            errorMessage = "End date must be after start date".localized
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        var reminders: [Date]?
        if addReminder {
            let reminderDate = Calendar.current.date(byAdding: .hour, value: -1, to: startDate) ?? startDate
            reminders = [reminderDate]
        }
        
        var assignedUserIds = selectedUsers.map { $0.id }
        
        if !assignedUserIds.contains(user.id) {
            assignedUserIds.append(user.id)
        }
        
        if assignedUserIds.isEmpty {
            assignedUserIds = [user.id]
        }
        
        let cleanDescription = description.trimmingCharacters(in: .whitespacesAndNewlines)
        
        let task = TaskModel(
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            description: cleanDescription.isEmpty ? "No description".localized : cleanDescription,
            assignedTo: assignedUserIds,
            startDate: startDate,
            endDate: isMultiDay ? endDate : startDate,
            hasTime: hasTime,
            groupId: groupId,
            priority: priority,
            category: category,
            attachments: nil,
            reminders: reminders,
            createdBy: user.id
        )
        
        taskService.addTask(task) { success in
            DispatchQueue.main.async {
                self.isLoading = false
                
                if success {
                    self.dismiss()
                } else {
                    self.errorMessage = self.taskService.errorMessage ?? "Failed to save task. Please try again.".localized
                }
            }
        }
    }
}

struct UserPickerView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var selectedUsers: [UserModel]
    let users: [UserModel]
    @State private var isLoading = false
    @State private var errorMessage: String?
    @StateObject private var groupService = GroupService.shared
    
    var body: some View {
        NavigationView {
            Group {
                if isLoading {
                    ProgressView("Loading users...".localized)
                } else if let error = errorMessage {
                    VStack {
                        Text(error)
                            .foregroundColor(.red)
                            .padding()
                        
                        Button("Retry".localized) {
                            loadUsersIfNeeded()
                        }
                        .padding()
                    }
                } else if users.isEmpty {
                    VStack {
                        Text("No users found".localized)
                            .foregroundColor(.gray)
                            .padding()
                        
                        if groupService.groupMembers.isEmpty {
                            Button("Load Group Members".localized) {
                                loadGroupMembers()
                            }
                            .padding()
                        }
                    }
                } else {
                    List {
                        ForEach(users) { user in
                            Button(action: {
                                toggleUserSelection(user)
                            }) {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(user.name)
                                            .font(.headline)
                                        
                                        Text(user.role.rawValue)
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                    
                                    Spacer()
                                    
                                    if isUserSelected(user) {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.blue)
                                    }
                                }
                            }
                            .foregroundColor(.primary)
                        }
                    }
                }
            }
            .navigationTitle("Select Users".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel".localized) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done".localized) {
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadUsersIfNeeded()
            }
        }
    }
    
    private func toggleUserSelection(_ user: UserModel) {
        if isUserSelected(user) {
            selectedUsers.removeAll { $0.id == user.id }
        } else {
            selectedUsers.append(user)
        }
    }
    
    private func isUserSelected(_ user: UserModel) -> Bool {
        return selectedUsers.contains { $0.id == user.id }
    }
    
    private func loadUsersIfNeeded() {
        if users.isEmpty && groupService.groupMembers.isEmpty {
            loadGroupMembers()
        }
    }
    
    private func loadGroupMembers() {
        isLoading = true
        errorMessage = nil
        
        if let groupId = AppState.shared.user?.groupId {
            groupService.fetchGroup(by: groupId)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.isLoading = false
                if self.groupService.groupMembers.isEmpty {
                    self.errorMessage = "Failed to load group members".localized
                }
            }
        } else {
            isLoading = false
            errorMessage = "No group ID found".localized
        }
    }
}

