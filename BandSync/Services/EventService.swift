//
//  EventService.swift
//  BandSync
//
//  Created by Oleksandr Kuziakin on 31.03.2025.

import Foundation
import FirebaseFirestore
import Network

final class EventService: ObservableObject {
    static let shared = EventService()

    @Published var events: [Event] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var isOfflineMode: Bool = false
    
    private let db = Firestore.firestore()
    private var networkMonitor = NWPathMonitor()
    private var hasLoadedFromCache = false
    
    init() {
        setupNetworkMonitoring()
    }
    
    private func setupNetworkMonitoring() {
        networkMonitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                let isConnected = path.status == .satisfied
                self?.isOfflineMode = !isConnected
                
                if isConnected && self?.hasLoadedFromCache == true {
                    if let groupId = AppState.shared.user?.groupId {
                        self?.fetchEvents(for: groupId)
                    }
                }
            }
        }
        
        let queue = DispatchQueue(label: "NetworkMonitor")
        networkMonitor.start(queue: queue)
    }

    func fetchEvents(for groupId: String) {
        isLoading = true
        errorMessage = nil
        
        if isOfflineMode {
            loadFromCache(groupId: groupId)
            return
        }
        
        db.collection("events")
            .whereField("groupId", isEqualTo: groupId)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    self.isLoading = false
                    
                    if let error = error {
                        self.errorMessage = "Error loading events: \(error.localizedDescription)"
                        self.loadFromCache(groupId: groupId)
                        return
                    }
                    
                    if let docs = snapshot?.documents {
                        let allEvents = docs.compactMap { doc -> Event? in
                            guard var event = try? doc.data(as: Event.self) else { return nil }
                            event.id = doc.documentID
                            return event
                        }
                        
                        let currentUserId = AppState.shared.user?.id
                        let filteredEvents = allEvents.filter { event in
                            if event.isPersonal {
                                return event.createdBy == currentUserId
                            }
                            return true
                        }
                        
                        self.events = filteredEvents
                        CacheService.shared.cacheEvents(filteredEvents, forGroupId: groupId)
                    }
                }
            }
    }
    
    private func loadFromCache(groupId: String) {
        if let cachedEvents = CacheService.shared.getCachedEvents(forGroupId: groupId) {
            let currentUserId = AppState.shared.user?.id
            let filteredEvents = cachedEvents.filter { event in
                if event.isPersonal {
                    return event.createdBy == currentUserId
                }
                return true
            }
            
            self.events = filteredEvents
            self.hasLoadedFromCache = true
            self.isLoading = false
            
            if isOfflineMode {
                self.errorMessage = "Loaded from cache (offline mode)"
            }
        } else {
            self.errorMessage = "No data available in offline mode"
            self.isLoading = false
        }
    }

    func addEvent(_ event: Event, completion: @escaping (Bool, String?) -> Void) {
        isLoading = true
        errorMessage = nil
        
        if isOfflineMode {
            errorMessage = "Cannot add events in offline mode"
            isLoading = false
            completion(false, nil)
            return
        }
        
        do {
            let docRef = try db.collection("events").addDocument(from: event)
            docRef.getDocument { [weak self] snapshot, error in
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    self.isLoading = false
                    
                    if let error = error {
                        self.errorMessage = "Error adding event: \(error.localizedDescription)"
                        completion(false, nil)
                    } else {
                        self.fetchEvents(for: event.groupId)
                        
                        // Используем ID созданного документа
                        let eventId = docRef.documentID
                        NotificationManager.shared.scheduleEventNotification(
                            title: event.title,
                            date: event.date,
                            eventId: eventId
                        ) { success, error in
                        }
                        
                        completion(true, eventId)
                    }
                }
            }
        } catch {
            DispatchQueue.main.async {
                self.isLoading = false
                self.errorMessage = "Event serialization error: \(error)"
                completion(false, nil)
            }
        }
    }

    func updateEvent(_ event: Event, completion: @escaping (Bool) -> Void) {
        guard let id = event.id else {
            completion(false)
            return
        }

        isLoading = true
        errorMessage = nil

        if isOfflineMode {
            errorMessage = "Cannot update events in offline mode"
            isLoading = false
            completion(false)
            return
        }

        do {
            try db.collection("events").document(id).setData(from: event) { [weak self] error in
                guard let self = self else { return }

                DispatchQueue.main.async {
                    self.isLoading = false

                    if let error = error {
                        self.errorMessage = "Error updating event: \(error.localizedDescription)"
                        completion(false)
                    } else {
                        self.fetchEvents(for: event.groupId)

                        NotificationManager.shared.cancelEventNotification(eventId: id)
                        NotificationManager.shared.scheduleEventNotification(
                            title: event.title,
                            date: event.date,
                            eventId: id
                        ) { success, error in
                        }

                        completion(true)
                    }
                }
            }
        } catch {
            DispatchQueue.main.async {
                self.isLoading = false
                self.errorMessage = "Event serialization error: \(error)"
                completion(false)
            }
        }
    }

    func deleteEvent(_ event: Event) {
        guard let id = event.id else { return }
        
        isLoading = true
        errorMessage = nil
        
        if isOfflineMode {
            errorMessage = "Cannot delete events in offline mode"
            isLoading = false
            return
        }
        
        db.collection("events").document(id).delete { [weak self] error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isLoading = false
                
                if let error = error {
                    self.errorMessage = "Error deleting: \(error.localizedDescription)"
                } else if let groupId = AppState.shared.user?.groupId {
                    self.fetchEvents(for: groupId)
                    NotificationManager.shared.cancelEventNotification(eventId: id)
                }
            }
        }
    }
    
    func eventsForDate(_ date: Date) -> [Event] {
        return events.filter {
            Calendar.current.isDate($0.date, inSameDayAs: date)
        }
    }
    
    func upcomingEvents(limit: Int = 5) -> [Event] {
        let now = Date()
        return events
            .filter { $0.date > now }
            .sorted { $0.date < $1.date }
            .prefix(limit)
            .map { $0 }
    }
    
    func eventsByType(_ type: EventType) -> [Event] {
        return events.filter { $0.type == type }
    }
    
    func events(from startDate: Date, to endDate: Date) -> [Event] {
        return events.filter {
            $0.date >= startDate && $0.date <= endDate
        }
    }
    
    func eventsForMonth(month: Int, year: Int) -> [Event] {
        let calendar = Calendar.current
        
        guard let startDate = calendar.date(from: DateComponents(year: year, month: month, day: 1)),
              let endDate = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startDate) else {
            return []
        }
        
        return events(from: startDate, to: endDate)
    }
    
    func clearAllData() {
        events = []
        errorMessage = nil
    }
    
    func fetchEventById(_ eventId: String, completion: @escaping (Event?) -> Void) {
        db.collection("events").document(eventId).getDocument { document, error in
            if let error = error {
                print("Error fetching event by ID: \(error.localizedDescription)")
                completion(nil)
                return
            }
            
            guard let document = document, document.exists, let _ = document.data() else {
                completion(nil)
                return
            }
            
            do {
                let event = try document.data(as: Event.self)
                completion(event)
            } catch {
                print("Error converting event: \(error.localizedDescription)")
                completion(nil)
            }
        }
    }

    deinit {
        networkMonitor.cancel()
    }
}
