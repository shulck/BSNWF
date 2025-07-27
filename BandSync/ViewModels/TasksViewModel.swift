//
//  TasksViewModel.swift
//  BandSyncApp
//
//  Created by Oleksandr Kuziakin on 18.06.2025.
//


import Foundation
import Combine

@MainActor
final class TasksViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var tasks: [TaskModel] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // MARK: - Private Properties
    private let taskService = TaskService.shared
    private let groupService = GroupService.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Computed Properties
    var sortedTasks: [TaskModel] {
        return tasks.sorted { (task1: TaskModel, task2: TaskModel) in
            // Incomplete tasks first
            if task1.completed != task2.completed {
                return !task1.completed && task2.completed
            }
            
            // Then by priority
            if task1.priority != task2.priority {
                let priority1 = priorityOrder(task1.priority)
                let priority2 = priorityOrder(task2.priority)
                return priority1 < priority2
            }
            
            // Finally by start date
            return task1.startDate < task2.startDate
        }
    }
    
    // MARK: - Initialization
    init() {
        setupBindings()
        loadInitialData()
    }
    
    // MARK: - Public Methods
    func startMonitoring() {
        loadInitialData()
    }
    
    func refreshTasks() async {
        await loadTasks()
    }
    
    func deleteTask(_ task: TaskModel) {
        guard let taskId = task.id else { return }
        
        // Optimistic update
        tasks.removeAll { $0.id == taskId }
        
        // Delete from service
        taskService.deleteTask(task) { [weak self] success in
            DispatchQueue.main.async {
                if !success {
                    // Revert optimistic update on failure
                    self?.loadInitialData()
                    self?.errorMessage = "Failed to delete task"
                }
            }
        }
    }
    
    // MARK: - Private Methods
    private func setupBindings() {
        // Subscribe to TaskService changes
        taskService.$tasks
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newTasks in
                self?.tasks = newTasks
                self?.isLoading = false
            }
            .store(in: &cancellables)
        
        // Subscribe to TaskService loading state
        taskService.$isLoading
            .receive(on: DispatchQueue.main)
            .assign(to: \.isLoading, on: self)
            .store(in: &cancellables)
        
        // Subscribe to TaskService errors
        taskService.$errorMessage
            .receive(on: DispatchQueue.main)
            .assign(to: \.errorMessage, on: self)
            .store(in: &cancellables)
        
        // Load group data when user changes
        AppState.shared.$user
            .compactMap { $0?.groupId }
            .removeDuplicates()
            .sink { [weak self] groupId in
                self?.loadGroup(groupId)
            }
            .store(in: &cancellables)
    }
    
    private func loadInitialData() {
        guard let groupId = AppState.shared.user?.groupId else {
            print("TasksViewModel: No group ID available")
            return
        }
        
        // Load group data first
        loadGroup(groupId)
        
        // Load tasks
        Task {
            await loadTasks()
        }
    }
    
    private func loadGroup(_ groupId: String) {
        groupService.fetchGroup(by: groupId) { success in
            print("TasksViewModel: Group loaded with success: \(success)")
        }
    }
    
    private func loadTasks() async {
        guard let groupId = AppState.shared.user?.groupId else {
            print("TasksViewModel: No group ID for loading tasks")
            return
        }
        
        print("TasksViewModel: Loading tasks for group: \(groupId)")
        
        // Use TaskService to load tasks
        await MainActor.run {
            self.isLoading = true
        }
        
        taskService.fetchTasks(for: groupId)
    }
    
    private func priorityOrder(_ priority: BandTaskPriority) -> Int {
        switch priority {
        case .high: return 0
        case .medium: return 1
        case .low: return 2
        }
    }
}

// MARK: - Convenience Extensions
extension TasksViewModel {
    var pendingTasks: [TaskModel] {
        return tasks.filter { !$0.completed }
    }
    
    var completedTasks: [TaskModel] {
        return tasks.filter { $0.completed }
    }
    
    var overdueTasks: [TaskModel] {
        return tasks.filter { !$0.completed && $0.endDate < Date() }
    }
    
    var dueSoonTasks: [TaskModel] {
        let nextWeek = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
        return tasks.filter { 
            !$0.completed && 
            $0.endDate >= Date() && 
            $0.endDate <= nextWeek 
        }
    }
}