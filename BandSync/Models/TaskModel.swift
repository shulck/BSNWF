import Foundation
import FirebaseFirestore

enum BandTaskPriority: String, CaseIterable, Codable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    
    var displayName: String {
        switch self {
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        }
    }
    
    var color: String {
        switch self {
        case .low: return "green"
        case .medium: return "yellow"
        case .high: return "red"
        }
    }
    
    var iconName: String {
        switch self {
        case .low: return "arrow.down.circle"
        case .medium: return "minus.circle"
        case .high: return "arrow.up.circle"
        }
    }
}

enum TaskCategory: String, CaseIterable, Codable, Identifiable {
    case rehearsal = "rehearsal"
    case performance = "performance"
    case recording = "recording"
    case photoshoot = "photoshoot"
    case videoshoot = "videoshoot"
    case interview = "interview"
    case promotion = "promotion"
    case business = "business"
    case equipment = "equipment"
    case other = "other"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .rehearsal: return "Rehearsal"
        case .performance: return "Performance"
        case .recording: return "Recording"
        case .photoshoot: return "Photoshoot"
        case .videoshoot: return "Video Shoot"
        case .interview: return "Interview"
        case .promotion: return "Promotion"
        case .business: return "Business"
        case .equipment: return "Equipment"
        case .other: return "Other"
        }
    }
    
    var icon: String {
        switch self {
        case .rehearsal: return "music.note"
        case .performance: return "mic"
        case .recording: return "waveform"
        case .photoshoot: return "camera"
        case .videoshoot: return "video"
        case .interview: return "person.2"
        case .promotion: return "megaphone"
        case .business: return "briefcase"
        case .equipment: return "guitars"
        case .other: return "list.bullet"
        }
    }
    
    var iconName: String {
        switch self {
        case .rehearsal: return "music.note"
        case .performance: return "mic"
        case .recording: return "waveform"
        case .photoshoot: return "camera"
        case .videoshoot: return "video"
        case .interview: return "person.2"
        case .promotion: return "megaphone"
        case .business: return "briefcase"
        case .equipment: return "guitars"
        case .other: return "list.bullet"
        }
    }
}

struct TaskModel: Identifiable, Codable {
    @DocumentID var id: String?
    var title: String
    var description: String
    var assignedTo: [String]
    var startDate: Date
    var endDate: Date
    var hasTime: Bool
    var completed: Bool
    var groupId: String
    var priority: BandTaskPriority
    var category: TaskCategory
    var attachments: [String]?
    var reminders: [Date]?
    var createdBy: String
    var createdAt: Date
    var updatedAt: Date
    
    var isToday: Bool {
        Calendar.current.isDateInToday(startDate)
    }
    
    var isTomorrow: Bool {
        Calendar.current.isDateInTomorrow(startDate)
    }
    
    var isMultiDay: Bool {
        !Calendar.current.isDate(startDate, inSameDayAs: endDate)
    }
    
    var isOverdue: Bool {
        !completed && endDate < Date()
    }
    
    init(
        id: String? = nil,
        title: String,
        description: String,
        assignedTo: [String],
        startDate: Date,
        endDate: Date,
        hasTime: Bool = false,
        completed: Bool = false,
        groupId: String,
        priority: BandTaskPriority = .medium,
        category: TaskCategory = .other,
        attachments: [String]? = nil,
        reminders: [Date]? = nil,
        createdBy: String,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.assignedTo = assignedTo
        self.startDate = startDate
        self.endDate = endDate
        self.hasTime = hasTime
        self.completed = completed
        self.groupId = groupId
        self.priority = priority
        self.category = category
        self.attachments = attachments
        self.reminders = reminders
        self.createdBy = createdBy
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

extension TaskModel {
    static func from(dictionary: [String: Any], id: String) -> TaskModel? {
        guard let title = dictionary["title"] as? String,
              let description = dictionary["description"] as? String,
              let assignedTo = dictionary["assignedTo"] as? [String],
              let groupId = dictionary["groupId"] as? String,
              let createdBy = dictionary["createdBy"] as? String else {
            return nil
        }
        
        let priorityString = dictionary["priority"] as? String ?? "medium"
        let priority = BandTaskPriority(rawValue: priorityString) ?? .medium
        
        let categoryString = dictionary["category"] as? String ?? "other"
        let category = TaskCategory(rawValue: categoryString) ?? .other
        
        let startDate = (dictionary["startDate"] as? Timestamp)?.dateValue() ?? Date()
        let endDate = (dictionary["endDate"] as? Timestamp)?.dateValue() ?? Date()
        let createdAt = (dictionary["createdAt"] as? Timestamp)?.dateValue() ?? Date()
        let updatedAt = (dictionary["updatedAt"] as? Timestamp)?.dateValue() ?? Date()
        
        let hasTime = dictionary["hasTime"] as? Bool ?? false
        let completed = dictionary["completed"] as? Bool ?? false
        let attachments = dictionary["attachments"] as? [String]
        
        var reminders: [Date]?
        if let reminderTimestamps = dictionary["reminders"] as? [Timestamp] {
            reminders = reminderTimestamps.map { $0.dateValue() }
        }
        
        return TaskModel(
            id: id,
            title: title,
            description: description,
            assignedTo: assignedTo,
            startDate: startDate,
            endDate: endDate,
            hasTime: hasTime,
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
}
