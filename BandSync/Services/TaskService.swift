import Foundation
import FirebaseFirestore
import Combine

final class TaskService: ObservableObject {
    static let shared = TaskService()

    @Published var tasks: [TaskModel] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private let db = Firestore.firestore()
    private var cancellables = Set<AnyCancellable>()
    private var listener: ListenerRegistration?

    func fetchTasks(for groupId: String) {
        isLoading = true
        errorMessage = nil
        
        guard let currentUserId = AppState.shared.user?.id else {
            isLoading = false
            return
        }
        
        listener?.remove()
        
        listener = db.collection("tasks")
            .whereField("groupId", isEqualTo: groupId)
            .order(by: "startDate")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    self.isLoading = false
                    
                    if let error = error {
                        self.errorMessage = "Error loading tasks: \(error.localizedDescription)"
                        return
                    }
                    
                    if let docs = snapshot?.documents {
                        var loadedTasks: [TaskModel] = []
                        
                        for doc in docs {
                            do {
                                let task = try doc.data(as: TaskModel.self)
                                if task.createdBy == currentUserId || task.assignedTo.contains(currentUserId) {
                                    loadedTasks.append(task)
                                }
                            } catch {
                                if let legacyTask = self.convertLegacyTask(from: doc.data()) {
                                    if legacyTask.createdBy == currentUserId || legacyTask.assignedTo.contains(currentUserId) {
                                        loadedTasks.append(legacyTask)
                                    }
                                }
                            }
                        }
                        
                        self.tasks = loadedTasks
                        
                        let userTasks = loadedTasks.filter { $0.assignedTo.contains(currentUserId) }
                        self.scheduleTaskReminders(userTasks)
                    }
                }
            }
    }

    func addTask(_ task: TaskModel, completion: @escaping (Bool) -> Void) {
        isLoading = true
        errorMessage = nil
        
        do {
            var newTask = task
            newTask.updatedAt = Date()
            
            let _ = try db.collection("tasks").addDocument(from: newTask) { [weak self] error in
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    self.isLoading = false
                    
                    if let error = error {
                        self.errorMessage = "Error adding task: \(error.localizedDescription)"
                        completion(false)
                    } else {
                        self.sendTaskNotifications(newTask)
                        completion(true)
                    }
                }
            }
        } catch {
            DispatchQueue.main.async {
                self.isLoading = false
                self.errorMessage = "Error serializing task: \(error.localizedDescription)"
                completion(false)
            }
        }
    }

    func toggleCompletion(_ task: TaskModel) {
        guard task.id != nil else { return }
        
        var updatedTask = task
        updatedTask.completed = !task.completed
        updatedTask.updatedAt = Date()
        
        updateTask(updatedTask) { _ in }
    }

    func updateTask(_ task: TaskModel, completion: @escaping (Bool) -> Void) {
        guard let id = task.id else {
            completion(false)
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            var updatedTask = task
            updatedTask.updatedAt = Date()
            
            try db.collection("tasks").document(id).setData(from: updatedTask) { [weak self] error in
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    self.isLoading = false
                    
                    if let error = error {
                        self.errorMessage = "Error updating task: \(error.localizedDescription)"
                        completion(false)
                    } else {
                        if let index = self.tasks.firstIndex(where: { $0.id == id }) {
                            self.tasks[index] = updatedTask
                        }
                        
                        NotificationManager.shared.cancelTaskNotification(taskId: id)
                        if !updatedTask.completed {
                            NotificationManager.shared.scheduleTaskNotification(
                                title: updatedTask.title,
                                dueDate: updatedTask.startDate,
                                taskId: id
                            ) { success, error in
                                if let error = error {
                                    print("Failed to schedule task notification: \(error.localizedDescription)")
                                }
                            }
                        }
                        
                        completion(true)
                    }
                }
            }
        } catch {
            DispatchQueue.main.async {
                self.isLoading = false
                self.errorMessage = "Error serializing task: \(error.localizedDescription)"
                completion(false)
            }
        }
    }

    func deleteTask(_ task: TaskModel, completion: @escaping (Bool) -> Void = { _ in }) {
        guard let id = task.id else {
            completion(false)
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        db.collection("tasks").document(id).delete { [weak self] error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isLoading = false
                
                if let error = error {
                    self.errorMessage = "Error deleting task: \(error.localizedDescription)"
                    completion(false)
                } else {
                    NotificationManager.shared.cancelTaskNotification(taskId: id)
                    self.tasks.removeAll { $0.id == id }
                    completion(true)
                }
            }
        }
    }
    
    private func scheduleTaskReminders(_ tasks: [TaskModel]) {
        guard let currentUserId = AppState.shared.user?.id else { return }
        
        for task in tasks {
            guard let id = task.id, !task.completed else { continue }
            
            guard task.assignedTo.contains(currentUserId) else { continue }
            
            NotificationManager.shared.scheduleTaskNotification(
                title: task.title,
                dueDate: task.startDate,
                taskId: id
            ) { success, error in
                if let error = error {
                    print("Failed to schedule task reminder: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    func getPendingTasks() -> [TaskModel] {
        return tasks.filter { !$0.completed }.sorted { $0.startDate < $1.startDate }
    }
    
    func getCompletedTasks() -> [TaskModel] {
        return tasks.filter { $0.completed }.sorted { $0.startDate > $1.startDate }
    }
    
    func getTasks(withPriority priority: BandTaskPriority) -> [TaskModel] {
        return tasks.filter { $0.priority == priority }
    }
    
    func getTasks(withCategory category: TaskCategory) -> [TaskModel] {
        return tasks.filter { $0.category == category }
    }
    
    func getTasks(assignedTo userId: String) -> [TaskModel] {
        return tasks.filter { $0.assignedTo.contains(userId) }
    }
    
    func getTasks(createdBy userId: String) -> [TaskModel] {
        return tasks.filter { $0.createdBy == userId }
    }
    
    func getTasksDueSoon() -> [TaskModel] {
        let nextWeek = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
        return tasks.filter { !$0.completed && $0.startDate <= nextWeek && $0.startDate >= Date() }
    }
    
    func getOverdueTasks() -> [TaskModel] {
        return tasks.filter { !$0.completed && $0.endDate < Date() }
    }
    
    func getTasksToday() -> [TaskModel] {
        return tasks.filter { $0.isToday }
    }
    
    func getTasksTomorrow() -> [TaskModel] {
        return tasks.filter { $0.isTomorrow }
    }
    
    func getMultiDayTasks() -> [TaskModel] {
        return tasks.filter { $0.isMultiDay }
    }
    
    func getTimedTasks() -> [TaskModel] {
        return tasks.filter { $0.hasTime }
    }
    
    func searchTasks(query: String) -> [TaskModel] {
        let lowercasedQuery = query.lowercased()
        return tasks.filter {
            $0.title.lowercased().contains(lowercasedQuery) ||
            $0.description.lowercased().contains(lowercasedQuery)
        }
    }
    
    private func sendTaskNotifications(_ task: TaskModel) {
        guard let taskId = task.id else { return }
        
        for userId in task.assignedTo {
            if userId != task.createdBy && !task.completed {
                NotificationManager.shared.scheduleTaskNotification(
                    title: task.title,
                    dueDate: task.startDate,
                    taskId: taskId
                )
            }
        }
    }
    
    private func convertLegacyTask(from data: [String: Any]) -> TaskModel? {
        guard let title = data["title"] as? String,
              let description = data["description"] as? String,
              let assignedTo = data["assignedTo"] as? [String],
              let groupId = data["groupId"] as? String,
              let createdBy = data["createdBy"] as? String,
              let completed = data["completed"] as? Bool else {
            return nil
        }
        
        let dueDate: Date
        if let dueDateTimestamp = data["dueDate"] as? Timestamp {
            dueDate = dueDateTimestamp.dateValue()
        } else if let dueDateString = data["dueDate"] as? String {
            let formatter = ISO8601DateFormatter()
            dueDate = formatter.date(from: dueDateString) ?? Date()
        } else {
            dueDate = Date()
        }
        
        let priority = BandTaskPriority(rawValue: data["priority"] as? String ?? "medium") ?? .medium
        let category = TaskCategory(rawValue: data["category"] as? String ?? "other") ?? .other
        let attachments = data["attachments"] as? [String]
        let reminders = (data["reminders"] as? [Timestamp])?.map { $0.dateValue() }
        
        let createdAt: Date
        if let createdAtTimestamp = data["createdAt"] as? Timestamp {
            createdAt = createdAtTimestamp.dateValue()
        } else {
            createdAt = Date()
        }
        
        let updatedAt: Date
        if let updatedAtTimestamp = data["updatedAt"] as? Timestamp {
            updatedAt = updatedAtTimestamp.dateValue()
        } else {
            updatedAt = Date()
        }
        
        return TaskModel(
            title: title,
            description: description,
            assignedTo: assignedTo,
            startDate: dueDate,
            endDate: dueDate,
            hasTime: false,
            completed: completed,
            groupId: groupId,
            priority: priority,
            category: category,
            attachments: attachments,
            reminders: reminders,
            createdBy: createdBy,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
    
    func fetchTaskById(_ taskId: String, completion: @escaping (TaskModel?) -> Void) {
        db.collection("tasks").document(taskId).getDocument { document, error in
            if let error = error {
                print("Error fetching task by ID: \(error.localizedDescription)")
                completion(nil)
                return
            }
            
            guard let document = document, document.exists, let data = document.data() else {
                completion(nil)
                return
            }
            
            do {
                let task = try document.data(as: TaskModel.self)
                completion(task)
            } catch {
                // Try legacy conversion
                if let legacyTask = self.convertLegacyTask(from: data) {
                    completion(legacyTask)
                } else {
                    print("Error converting task: \(error.localizedDescription)")
                    completion(nil)
                }
            }
        }
    }

    deinit {
        listener?.remove()
    }
}
