import SwiftUI

struct TaskDetailView: View {
    let task: TaskModel
    @State private var isEditing = false
    @State private var editedTask: TaskModel
    @State private var showDeleteAlert = false
    
    @State private var editStartDate = Date()
    @State private var editEndDate = Date()
    @State private var editHasTime = false
    @State private var editIsMultiDay = false
    
    @StateObject private var groupService = GroupService.shared
    @StateObject private var taskService = TaskService.shared
    @StateObject private var permissionService = PermissionService.shared
    @Environment(\.dismiss) private var dismiss
    
    init(task: TaskModel) {
        self.task = task
        self._editedTask = State(initialValue: task)
    }
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                LazyVStack(spacing: 16) {
                    taskHeaderCard
                    taskTimeInfoCard
                    taskInfoCompact
                    taskDescriptionCard
                    taskActionsCard
                    
                    Rectangle()
                        .fill(Color.clear)
                        .frame(height: 100)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .frame(maxWidth: .infinity)
            }
            .frame(width: geometry.size.width)
            .clipped()
            .onTapGesture {
                hideKeyboard()
            }
        }
        .navigationTitle(isEditing ? NSLocalizedString("edit_task", comment: "Navigation title for editing task") : NSLocalizedString("task_details", comment: "Navigation title for task details"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            toolbarContent
        }
        .alert(NSLocalizedString("delete_task", comment: "Alert title for deleting task"), isPresented: $showDeleteAlert) {
            deleteAlert
        } message: {
            Text(NSLocalizedString("delete_task_confirmation", comment: "Confirmation message for deleting task"))
        }
        .background(Color(.systemGroupedBackground))
        .onAppear {
            markTaskAsRead()
            setupEditingDates()
        }
        .onDisappear {
            finalizeTaskRead()
        }
    }
    
    private func markTaskAsRead() {
        UnifiedBadgeManager.shared.markTasksAsRead()
        
        DispatchQueue.main.async {
            UnifiedBadgeManager.shared.forceRefreshBadgeCounts()
        }
    }
    
    private func finalizeTaskRead() {
        UnifiedBadgeManager.shared.markTasksAsRead()
        
        DispatchQueue.main.async {
            UnifiedBadgeManager.shared.forceRefreshBadgeCounts()
        }
    }
    
    private var currentTask: TaskModel {
        isEditing ? editedTask : task
    }
    
    private func setupEditingDates() {
        editStartDate = task.startDate
        editEndDate = task.endDate
        editHasTime = task.hasTime
        editIsMultiDay = task.isMultiDay
    }
    
    private var taskHeaderCard: some View {
        VStack(spacing: 16) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 12) {
                    if isEditing {
                        TextField(NSLocalizedString("task_title", comment: "Placeholder for task title field"), text: $editedTask.title)
                            .font(.title3)
                            .fontWeight(.bold)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .onTapGesture {
                                
                            }
                    } else {
                        Text(currentTask.title)
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(currentTask.completed ? .secondary : .primary)
                            .strikethrough(currentTask.completed)
                            .multilineTextAlignment(.leading)
                            .lineLimit(nil)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    
                    HStack(spacing: 8) {
                        priorityBadge
                        categoryBadge
                        Spacer()
                    }
                }
                
                completionButton
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
    
    private var taskTimeInfoCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            if isEditing {
                editingTimeSection
            } else {
                displayTimeSection
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        )
    }
    
    private var editingTimeSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(NSLocalizedString("schedule", comment: "Header for schedule section"))
                .font(.footnote)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack {
                Text(NSLocalizedString("include_time", comment: "Toggle to include time in task"))
                    .font(.body)
                Spacer()
                Toggle("", isOn: $editHasTime)
                    .onChange(of: editHasTime) {
                        if !editHasTime {
                            editStartDate = Calendar.current.startOfDay(for: editStartDate)
                            editEndDate = Calendar.current.startOfDay(for: editEndDate)
                        }
                    }
            }
            
            HStack {
                Text(NSLocalizedString("multi_day_task", comment: "Toggle for multi-day task"))
                    .font(.body)
                Spacer()
                Toggle("", isOn: $editIsMultiDay)
                    .onChange(of: editIsMultiDay) {
                        if !editIsMultiDay {
                            editEndDate = editStartDate
                        }
                    }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text(editHasTime ? NSLocalizedString("start_date_time", comment: "Label for start date and time") : NSLocalizedString("start_date", comment: "Label for start date"))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                if editHasTime {
                    DatePicker("", selection: $editStartDate, displayedComponents: [.date, .hourAndMinute])
                        .datePickerStyle(.compact)
                        .onChange(of: editStartDate) {
                            if editEndDate < editStartDate {
                                editEndDate = editStartDate
                            }
                            if !editIsMultiDay {
                                editEndDate = editStartDate
                            }
                        }
                } else {
                    DatePicker("", selection: $editStartDate, displayedComponents: [.date])
                        .datePickerStyle(.compact)
                        .onChange(of: editStartDate) {
                            if editEndDate < editStartDate {
                                editEndDate = editStartDate
                            }
                            if !editIsMultiDay {
                                editEndDate = editStartDate
                            }
                        }
                }
            }
            
            if editIsMultiDay {
                VStack(alignment: .leading, spacing: 8) {
                    Text(editHasTime ? NSLocalizedString("end_date_time", comment: "Label for end date and time") : NSLocalizedString("end_date", comment: "Label for end date"))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    if editHasTime {
                        DatePicker("", selection: $editEndDate, in: editStartDate..., displayedComponents: [.date, .hourAndMinute])
                            .datePickerStyle(.compact)
                    } else {
                        DatePicker("", selection: $editEndDate, in: editStartDate..., displayedComponents: [.date])
                            .datePickerStyle(.compact)
                    }
                }
            }
        }
    }
    
    private var displayTimeSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(NSLocalizedString("schedule", comment: "Header for schedule section"))
                .font(.footnote)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "calendar")
                        .foregroundColor(.blue)
                        .font(.body)
                        .frame(width: 20, alignment: .center)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        if currentTask.isMultiDay {
                            Text(NSLocalizedString("From:", comment: "Task start date label") + " \(formatDateTime(currentTask.startDate, includeTime: currentTask.hasTime))")
                                .font(.body)
                                .lineLimit(nil)
                            Text(NSLocalizedString("To:", comment: "Task end date label") + " \(formatDateTime(currentTask.endDate, includeTime: currentTask.hasTime))")
                                .font(.body)
                                .lineLimit(nil)
                        } else {
                            Text(formatDateTime(currentTask.startDate, includeTime: currentTask.hasTime))
                                .font(.body)
                                .lineLimit(nil)
                        }
                    }
                    
                    Spacer()
                }
                
                if currentTask.hasTime {
                    HStack(alignment: .center, spacing: 12) {
                        Image(systemName: "clock")
                            .foregroundColor(.orange)
                            .font(.body)
                            .frame(width: 20, alignment: .center)
                        
                        Text(NSLocalizedString("Timed Event", comment: "Task with specific time label"))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                    }
                }
                
                if currentTask.isMultiDay {
                    HStack(alignment: .center, spacing: 12) {
                        Image(systemName: "arrow.right")
                            .foregroundColor(.green)
                            .font(.body)
                            .frame(width: 20, alignment: .center)
                        
                        Text(NSLocalizedString("Duration:", comment: "Task duration label") + " \(formatDuration(from: currentTask.startDate, to: currentTask.endDate))")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(nil)
                        
                        Spacer()
                    }
                }
                
                HStack(alignment: .center, spacing: 12) {
                    Image(systemName: statusIcon)
                        .foregroundColor(statusColor)
                        .font(.body)
                        .frame(width: 20, alignment: .center)
                    
                    Text(statusText)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(statusColor)
                    
                    Spacer()
                }
            }
        }
    }
    
    private var statusIcon: String {
        if currentTask.completed {
            return "checkmark.circle.fill"
        } else if currentTask.isOverdue {
            return "exclamationmark.triangle.fill"
        } else if currentTask.isToday {
            return "star.fill"
        } else if currentTask.isTomorrow {
            return "clock.fill"
        } else {
            return "circle"
        }
    }
    
    private var statusColor: Color {
        if currentTask.completed {
            return .green
        } else if currentTask.isOverdue {
            return .red
        } else if currentTask.isToday {
            return .orange
        } else if currentTask.isTomorrow {
            return .blue
        } else {
            return .secondary
        }
    }
    
    private var statusText: String {
        if currentTask.completed {
            return NSLocalizedString("Completed", comment: "Task completed status")
        } else if currentTask.isOverdue {
            return NSLocalizedString("Overdue", comment: "Task overdue status")
        } else if currentTask.isToday {
            return NSLocalizedString("Today", comment: "Task due today status")
        } else if currentTask.isTomorrow {
            return NSLocalizedString("Tomorrow", comment: "Task due tomorrow status")
        } else {
            return NSLocalizedString("Upcoming", comment: "Task upcoming status")
        }
    }
    
    private var taskInfoCompact: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(NSLocalizedString("by", comment: "Task creator label") + " \(getCreatedByName())")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
            }
            
            if !currentTask.assignedTo.isEmpty {
                HStack {
                    Label(getAssignedNames(), systemImage: "person")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(nil)
                    Spacer()
                }
            }
        }
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var taskDescriptionCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(NSLocalizedString("Description", comment: "Task description header"))
                    .font(.footnote)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                Spacer()
            }
            
            if isEditing {
                TextEditor(text: $editedTask.description)
                    .frame(minHeight: 120)
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(.systemGray6))
                    )
                    .onTapGesture {
                        
                    }
            } else {
                if currentTask.description.isEmpty {
                    Text(NSLocalizedString("No Description", comment: "Empty task description placeholder"))
                        .font(.body)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(currentTask.description)
                            .font(.body)
                            .foregroundColor(.primary)
                            .lineLimit(nil)
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        )
    }
    
    private var taskActionsCard: some View {
        VStack(spacing: 12) {
            Button(action: {
                withAnimation(.spring()) {
                    toggleTaskCompletion()
                }
            }) {
                HStack(spacing: 8) {
                    Image(systemName: currentTask.completed ? "arrow.counterclockwise" : "checkmark")
                        .font(.body)
                    Text(currentTask.completed ? NSLocalizedString("Mark as Incomplete", comment: "Button to mark task as incomplete") : NSLocalizedString("Mark as Complete", comment: "Button to mark task as complete"))
                        .font(.body)
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(currentTask.completed ? Color.orange : Color.green)
                )
                .foregroundColor(.white)
            }
            
            if permissionService.currentUserCanWrite(to: .tasks) {
                if isEditing {
                    VStack(spacing: 8) {
                        Button(NSLocalizedString("Save", comment: "Save button")) {
                            saveTask()
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.blue)
                        )
                        .foregroundColor(.white)
                        .font(.body)
                        .fontWeight(.semibold)
                        
                        Button(NSLocalizedString("Cancel", comment: "Cancel button")) {
                            cancelEditing()
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemGray5))
                        )
                        .foregroundColor(.primary)
                        .font(.body)
                        .fontWeight(.semibold)
                    }
                } else {
                    Button(NSLocalizedString("Edit Task", comment: "Edit task button")) {
                        startEditing()
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.blue)
                    )
                    .foregroundColor(.white)
                    .font(.body)
                    .fontWeight(.semibold)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        )
    }
    
    private var priorityBadge: some View {
        HStack(spacing: 6) {
            Image(systemName: currentTask.priority.iconName)
                .font(.caption)
            Text(NSLocalizedString(currentTask.priority.displayName, comment: "Task priority display name"))
                .font(.caption)
        }
        .fontWeight(.medium)
        .foregroundColor(priorityColor(currentTask.priority))
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(priorityColor(currentTask.priority).opacity(0.15))
        )
    }
    
    private var categoryBadge: some View {
        HStack(spacing: 6) {
            Image(systemName: currentTask.category.iconName)
                .font(.caption)
            Text(NSLocalizedString(currentTask.category.displayName, comment: "Task category display name"))
                .font(.caption)
        }
        .fontWeight(.medium)
        .foregroundColor(.blue)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.blue.opacity(0.15))
        )
    }
    
    private var completionButton: some View {
        Button(action: {
            withAnimation(.spring()) {
                toggleTaskCompletion()
            }
        }) {
            Image(systemName: currentTask.completed ? "checkmark.circle.fill" : "circle")
                .font(.title2)
                .foregroundColor(currentTask.completed ? .green : .gray)
        }
        .frame(width: 44, height: 44)
    }
    
    private var toolbarContent: some ToolbarContent {
        Group {
            ToolbarItem(placement: .navigationBarTrailing) {
                if permissionService.currentUserCanDelete(from: .tasks) && !isEditing {
                    Menu {
                        Button(NSLocalizedString("Delete", comment: "Delete button"), systemImage: "trash", role: .destructive) {
                            showDeleteAlert = true
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
    }
    
    private var deleteAlert: some View {
        Group {
            Button("Delete", role: .destructive) {
                deleteTask()
            }
            Button("Cancel", role: .cancel) { }
        }
    }
    
    private func startEditing() {
        editedTask = task
        setupEditingDates()
        isEditing = true
    }
    
    private func cancelEditing() {
        editedTask = task
        setupEditingDates()
        isEditing = false
    }
    
    private func saveTask() {
        guard !editedTask.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }
        
        if editIsMultiDay && editEndDate <= editStartDate {
            return
        }
        
        editedTask.startDate = editStartDate
        editedTask.endDate = editIsMultiDay ? editEndDate : editStartDate
        editedTask.hasTime = editHasTime
        
        taskService.updateTask(editedTask) { success in
            DispatchQueue.main.async {
                if success {
                    withAnimation(.spring()) {
                        isEditing = false
                    }
                }
            }
        }
    }
    
    private func toggleTaskCompletion() {
        taskService.toggleCompletion(currentTask)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            UnifiedBadgeManager.shared.refreshBadgeCounts()
        }
    }
    
    private func deleteTask() {
        taskService.deleteTask(currentTask) { success in
            DispatchQueue.main.async {
                if success {
                    UnifiedBadgeManager.shared.refreshBadgeCounts()
                    dismiss()
                }
            }
        }
    }
    
    private func priorityColor(_ priority: BandTaskPriority) -> Color {
        switch priority {
        case .high: return .red
        case .medium: return .orange
        case .low: return .green
        }
    }
    
    private func getAssignedNames() -> String {
        let names = currentTask.assignedTo.compactMap { userId in
            groupService.groupMembers.first(where: { $0.id == userId })?.name
        }
        
        if names.isEmpty {
            return NSLocalizedString("Unassigned", comment: "Task unassigned status")
        } else if names.count <= 2 {
            return names.joined(separator: ", ")
        } else {
            return "\(names[0]), \(names[1]) +\(names.count - 2)"
        }
    }
    
    private func getCreatedByName() -> String {
        if let creator = groupService.groupMembers.first(where: { $0.id == currentTask.createdBy }) {
            return creator.name
        }
        return NSLocalizedString("Unknown", comment: "Unknown user")
    }
    
    private func formatDateTime(_ date: Date, includeTime: Bool) -> String {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        
        if calendar.isDateInToday(date) {
            if includeTime {
                formatter.dateFormat = "'Today at' HH:mm"
            } else {
                return NSLocalizedString("Today", comment: "Today date label")
            }
        } else if calendar.isDateInTomorrow(date) {
            if includeTime {
                formatter.dateFormat = "'Tomorrow at' HH:mm"
            } else {
                return NSLocalizedString("Tomorrow", comment: "Tomorrow date label")
            }
        } else if calendar.isDateInYesterday(date) {
            if includeTime {
                formatter.dateFormat = "'Yesterday at' HH:mm"
            } else {
                return NSLocalizedString("Yesterday", comment: "Yesterday date label")
            }
        } else {
            if includeTime {
                formatter.dateFormat = "MMM d, yyyy 'at' HH:mm"
            } else {
                formatter.dateFormat = "MMM d, yyyy"
            }
        }
        
        return formatter.string(from: date)
    }
    
    private func formatDuration(from startDate: Date, to endDate: Date) -> String {
        let duration = endDate.timeIntervalSince(startDate)
        let days = Int(duration / 86400)
        let hours = Int((duration.truncatingRemainder(dividingBy: 86400)) / 3600)
        let minutes = Int((duration.truncatingRemainder(dividingBy: 3600)) / 60)
        
        var components: [String] = []
        
        if days > 0 {
            components.append("\(days) \(pluralizeDays(days))")
        }
        if hours > 0 {
            components.append("\(hours) \(pluralizeHours(hours))")
        }
        if minutes > 0 && days == 0 {
            components.append("\(minutes) \(pluralizeMinutes(minutes))")
        }
        
        return components.isEmpty ? NSLocalizedString("0 minutes", comment: "Zero duration") : components.joined(separator: ", ")
    }
    
    private func pluralizeDays(_ count: Int) -> String {
        if Locale.current.language.languageCode?.identifier == "uk" {
            let remainder10 = count % 10
            let remainder100 = count % 100
            
            if remainder100 >= 11 && remainder100 <= 14 {
                return "днів"
            } else if remainder10 == 1 {
                return "день"
            } else if remainder10 >= 2 && remainder10 <= 4 {
                return "дні"
            } else {
                return "днів"
            }
        } else {
            return count == 1 ? NSLocalizedString("day", comment: "Day singular") : NSLocalizedString("days", comment: "Days plural")
        }
    }
    
    private func pluralizeHours(_ count: Int) -> String {
        if Locale.current.language.languageCode?.identifier == "uk" {
            let remainder10 = count % 10
            let remainder100 = count % 100
            
            if remainder100 >= 11 && remainder100 <= 14 {
                return "годин"
            } else if remainder10 == 1 {
                return "година"
            } else if remainder10 >= 2 && remainder10 <= 4 {
                return "години"
            } else {
                return "годин"
            }
        } else {
            return count == 1 ? NSLocalizedString("hour", comment: "Hour singular") : NSLocalizedString("hours", comment: "Hours plural")
        }
    }
    
    private func pluralizeMinutes(_ count: Int) -> String {
        if Locale.current.language.languageCode?.identifier == "uk" {
            let remainder10 = count % 10
            let remainder100 = count % 100
            
            if remainder100 >= 11 && remainder100 <= 14 {
                return "хвилин"
            } else if remainder10 == 1 {
                return "хвилина"
            } else if remainder10 >= 2 && remainder10 <= 4 {
                return "хвилини"
            } else {
                return "хвилин"
            }
        } else {
            return count == 1 ? NSLocalizedString("minute", comment: "Minute singular") : NSLocalizedString("minutes", comment: "Minutes plural")
        }
    }
}

extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
