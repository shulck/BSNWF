import SwiftUI

struct TasksViewWrapper: View {
    @State private var navigationPath = NavigationPath()
    @EnvironmentObject private var navigationManager: NavigationManager
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            TasksView()
                .navigationDestination(for: String.self) { taskId in
                    if let task = TaskService.shared.tasks.first(where: { $0.id == taskId }) {
                        TaskDetailView(task: task)
                    } else {
                        Text("Task Not Found".localized)
                            .foregroundColor(.secondary)
                    }
                }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ResetTab2"))) { _ in
            navigationPath = NavigationPath()
        }
        .onReceive(navigationManager.$taskToOpen) { taskId in
            if let taskId = taskId, !taskId.isEmpty {
                navigationPath.append(taskId)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("NavigateToTask"))) { notification in
            guard let userInfo = notification.userInfo,
                  let taskId = userInfo["taskId"] as? String else { return }
            
            // Check if task is already loaded
            if TaskService.shared.tasks.contains(where: { $0.id == taskId }) {
                navigationPath.append(taskId)
            } else {
                // Try to fetch the specific task first
                TaskService.shared.fetchTaskById(taskId) { task in
                    DispatchQueue.main.async {
                        if task != nil {
                            // If task exists, load all tasks for the group to ensure consistency
                            if let groupId = AppState.shared.user?.groupId {
                                TaskService.shared.fetchTasks(for: groupId)
                            }
                            // Navigate after a brief delay to ensure the task is in the list
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                navigationPath.append(taskId)
                            }
                        }
                    }
                }
            }
        }
    }
}

struct TasksView: View {
    @StateObject private var viewModel = TasksViewModel()
    @StateObject private var permissionService = PermissionService.shared
    @State private var selectedTask: TaskModel?
    @State private var showAddTask = false
    
    var body: some View {
        VStack(spacing: 0) {
            if viewModel.tasks.isEmpty && !viewModel.isLoading {
                emptyStateView
            } else {
                tasksList
            }
        }
        .navigationTitle("Tasks".localized)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if permissionService.currentUserCanWrite(to: .tasks) {
                    Button(action: { showAddTask = true }) {
                        Image(systemName: "plus")
                            .font(.title2)
                            .fontWeight(.medium)
                            .foregroundColor(.blue)
                    }
                }
            }
        }
        .sheet(isPresented: $showAddTask) {
            AddTaskView()
        }
        .refreshable {
            await viewModel.refreshTasks()
        }
        .onAppear {
            viewModel.startMonitoring()
            UnifiedBadgeManager.shared.markTasksAsRead()
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "checklist")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("No Tasks".localized)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
            
            Text("Create your first task to get started".localized)
            
            if permissionService.currentUserCanWrite(to: .tasks) {
                Button("Create Task".localized) {
                    showAddTask = true
                }
                .buttonStyle(.borderedProminent)
            }
            
            Spacer()
        }
        .padding()
    }
    
    private var tasksList: some View {
        List {
            if viewModel.isLoading && viewModel.tasks.isEmpty {
                loadingRow
            } else {
                ForEach(Array(groupedTasksByDate.keys).sorted(), id: \.self) { dateKey in
                    Section(header: dateHeaderView(for: dateKey)) {
                        ForEach(groupedTasksByDate[dateKey] ?? []) { task in
                            NavigationLink(destination: TaskDetailView(task: task)) {
                                TaskRowComponent(task: task, showDate: false)
                            }
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                        }
                        .onDelete { offsets in
                            deleteTask(from: dateKey, at: offsets)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .contentMargins(.top, 20)
    }
    
    private var loadingRow: some View {
        HStack {
            ProgressView()
                .scaleEffect(0.8)
            Text("Loading tasks...".localized)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .listRowBackground(Color.clear)
    }
    
    private var groupedTasksByDate: [Date: [TaskModel]] {
        let calendar = Calendar.current
        
        let grouped = Dictionary(grouping: viewModel.tasks) { task in
            calendar.startOfDay(for: task.startDate)
        }
        
        var sortedGrouped: [Date: [TaskModel]] = [:]
        for (date, tasks) in grouped {
            sortedGrouped[date] = tasks.sorted { (task1: TaskModel, task2: TaskModel) -> Bool in
                if task1.completed != task2.completed {
                    return !task1.completed
                }
                if task1.priority != task2.priority {
                    return priorityOrder(task1.priority) < priorityOrder(task2.priority)
                }
                if task1.hasTime && task2.hasTime {
                    return task1.startDate < task2.startDate
                }
                if task1.hasTime != task2.hasTime {
                    return task1.hasTime
                }
                return task1.startDate < task2.startDate
            }
        }
        
        return sortedGrouped
    }
    
    private func priorityOrder(_ priority: BandTaskPriority) -> Int {
        switch priority {
        case .high: return 0
        case .medium: return 1
        case .low: return 2
        }
    }
    
    private func dateHeaderView(for date: Date) -> some View {
        HStack {
            Text(formatDateHeader(date))
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(headerTextColor(for: date))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            
            Spacer()
            
            if let tasks = groupedTasksByDate[date] {
                let completedCount = tasks.filter(\.completed).count
                let totalCount = tasks.count
                
                Text("\(completedCount)/\(totalCount)")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(8)
            }
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 2)
    }
    
    private func formatDateHeader(_ date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        
        if calendar.isDateInToday(date) {
            return "Today".localized
        } else if calendar.isDateInTomorrow(date) {
            return "Tomorrow".localized
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday".localized
        } else if date < now {
            let daysAgo = calendar.dateComponents([.day], from: date, to: now).day ?? 0
            if daysAgo <= 7 {
                return "Overdue".localized + " (\(daysAgo) " + pluralizeDaysAgo(daysAgo) + ")"
            } else {
                let formatter = DateFormatter()
                formatter.dateFormat = "MMM d"
                return "Overdue".localized + " - \(formatter.string(from: date))"
            }
        } else {
            let daysAhead = calendar.dateComponents([.day], from: now, to: date).day ?? 0
            if daysAhead <= 7 {
                let formatter = DateFormatter()
                formatter.dateFormat = "EEEE, MMM d"
                return formatter.string(from: date).capitalized
            } else {
                let formatter = DateFormatter()
                formatter.dateFormat = "MMM d, yyyy"
                return formatter.string(from: date)
            }
        }
    }
    
    private func headerTextColor(for date: Date) -> Color {
        let calendar = Calendar.current
        let now = Date()
        
        if calendar.isDateInToday(date) {
            return .primary
        } else if calendar.isDateInTomorrow(date) {
            return .blue
        } else if date < now {
            return .red
        } else {
            return .primary
        }
    }
    
    private func deleteTask(at offsets: IndexSet) {
        guard permissionService.currentUserCanDelete(from: .tasks) else { return }
        
        for index in offsets {
            let task = viewModel.sortedTasks[index]
            viewModel.deleteTask(task)
        }
    }
    
    private func deleteTask(from dateKey: Date, at offsets: IndexSet) {
        guard permissionService.currentUserCanDelete(from: .tasks) else { return }
        guard let tasks = groupedTasksByDate[dateKey] else { return }
        
        for index in offsets {
            let task = tasks[index]
            viewModel.deleteTask(task)
        }
    }
    
    private func formatOverdueText(_ daysAgo: Int) -> String {
        if Locale.current.language.languageCode?.identifier == "uk" {
            return "Просрочено \(daysAgo)д"
        } else {
            return "Overdue".localized + " \(daysAgo)d"
        }
    }
    
    private func pluralizeDaysAgo(_ count: Int) -> String {
        if Locale.current.language.languageCode?.identifier == "uk" {
            let remainder10 = count % 10
            let remainder100 = count % 100
            
            if remainder100 >= 11 && remainder100 <= 14 {
                return "днів тому"
            } else if remainder10 == 1 {
                return "день тому"
            } else if remainder10 >= 2 && remainder10 <= 4 {
                return "дні тому"
            } else {
                return "днів тому"
            }
        } else {
            return count == 1 ? "day ago".localized : "days ago".localized
        }
    }
}

struct TaskRowComponent: View {
    let task: TaskModel
    let showDate: Bool
    @StateObject private var groupService = GroupService.shared
    
    init(task: TaskModel, showDate: Bool = true) {
        self.task = task
        self.showDate = showDate
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Button(action: {
                TaskService.shared.toggleCompletion(task)
            }) {
                Image(systemName: task.completed ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundColor(task.completed ? .green : .gray)
            }
            .buttonStyle(PlainButtonStyle())
            
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(task.title)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(task.completed ? .secondary : .primary)
                        .strikethrough(task.completed)
                        .lineLimit(2)
                    
                    Spacer()
                    
                    if task.priority != .low {
                        priorityBadge
                    }
                }
                
                HStack(spacing: 12) {
                    if showDate {
                        timeInfo
                    }
                    categoryInfo
                    assignedInfo
                }
            }
        }
        .padding(.vertical, 4)
        .opacity(task.completed ? 0.6 : 1.0)
    }
    
    private var priorityBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: priorityIcon)
                .font(.caption)
            Text(task.priority.displayName.localized)
                .font(.caption2)
                .fontWeight(.medium)
        }
        .foregroundColor(priorityColor)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(priorityColor.opacity(0.15))
        .cornerRadius(4)
    }
    
    private var priorityIcon: String {
        switch task.priority {
        case .low: return "arrow.down.circle"
        case .medium: return "minus.circle"
        case .high: return "arrow.up.circle"
        }
    }
    
    private var priorityColor: Color {
        switch task.priority {
        case .high: return .red
        case .medium: return .orange
        case .low: return .blue
        }
    }
    
    private var timeInfo: some View {
        HStack(spacing: 4) {
            Image(systemName: task.hasTime ? "clock" : "calendar")
                .font(.caption)
            
            VStack(alignment: .leading, spacing: 1) {
                if task.isMultiDay {
                    Text(formatDateShort(task.startDate))
                        .font(.caption2)
                    Text("→ \(formatDateShort(task.endDate))")
                        .font(.caption2)
                } else {
                    Text(formatDateTime(task.startDate, includeTime: task.hasTime))
                        .font(.caption)
                }
            }
        }
        .foregroundColor(isOverdue ? .red : .secondary)
    }
    
    private var categoryInfo: some View {
        HStack(spacing: 4) {
            Image(systemName: task.category.icon)
                .font(.caption)
            Text(task.category.displayName.localized)
                .font(.caption)
        }
        .foregroundColor(.secondary)
    }
    
    @ViewBuilder
    private var assignedInfo: some View {
        if !task.assignedTo.isEmpty {
            HStack(spacing: 4) {
                Image(systemName: "person")
                    .font(.caption)
                Text(getAssignedNames())
                    .font(.caption)
                    .lineLimit(1)
            }
            .foregroundColor(.secondary)
        }
    }
    
    private var isOverdue: Bool {
        !task.completed && task.endDate < Date()
    }
    
    private func formatDateTime(_ date: Date, includeTime: Bool) -> String {
        let calendar = Calendar.current
        
        if calendar.isDateInToday(date) {
            if includeTime {
                let formatter = DateFormatter()
                formatter.timeStyle = .short
                return "Today".localized + " \(formatter.string(from: date))"
            } else {
                return "Today".localized
            }
        } else if calendar.isDateInTomorrow(date) {
            if includeTime {
                let formatter = DateFormatter()
                formatter.timeStyle = .short
                return "Tomorrow".localized + " \(formatter.string(from: date))"
            } else {
                return "Tomorrow".localized
            }
        } else if calendar.isDateInYesterday(date) {
            if includeTime {
                let formatter = DateFormatter()
                formatter.timeStyle = .short
                return "Yesterday".localized + " \(formatter.string(from: date))"
            } else {
                return "Yesterday".localized
            }
        } else {
            let formatter = DateFormatter()
            if includeTime {
                formatter.dateFormat = "MMM d HH:mm"
            } else {
                formatter.dateFormat = "MMM d"
            }
            return formatter.string(from: date)
        }
    }
    
    private func formatDateShort(_ date: Date) -> String {
        let calendar = Calendar.current
        
        if calendar.isDateInToday(date) {
            return "Today".localized
        } else if calendar.isDateInTomorrow(date) {
            return "Tomorrow".localized
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday".localized
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            return formatter.string(from: date)
        }
    }
    
    private func getAssignedNames() -> String {
        let names = task.assignedTo.compactMap { userId in
            groupService.groupMembers.first(where: { $0.id == userId })?.name
        }
        
        if names.isEmpty {
            return "Unassigned".localized
        } else if names.count == 1 {
            return names[0]
        } else if names.count == 2 {
            return names.joined(separator: ", ")
        } else {
            return "\(names[0]), \(names[1]) +\(names.count - 2)"
        }
    }
}
