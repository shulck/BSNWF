//
//  FanEventService.swift
//  BandSync
//
//  Created by Claude on 28.07.2025.
//

import Foundation
import FirebaseFirestore
import Combine

final class FanEventService: ObservableObject {
    static let shared = FanEventService()
    
    @Published var fanEvents: [Event] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// Загружает публичные события для фанатов (концерты, фестивали, дни рождения)
    func loadPublicEvents(for groupId: String) {
        guard !groupId.isEmpty else {
            print("❌ FanEventService: Empty groupId")
            return
        }
        
        // ✅ ЗАЩИТА ОТ МНОЖЕСТВЕННЫХ ВЫЗОВОВ
        guard !isLoading else {
            print("🔄 FanEventService: Already loading, skipping duplicate request")
            return
        }
        
        print("🔄 FanEventService: Loading public events for group: \(groupId)")
        
        isLoading = true
        errorMessage = nil
        
        // Убираем предыдущий listener если есть
        listener?.remove()
        
        // Создаем listener для событий группы - УПРОЩЕННЫЙ ЗАПРОС
        listener = db.collection("events")
            .whereField("groupId", isEqualTo: groupId)
            .addSnapshotListener { [weak self] snapshot, error in
                DispatchQueue.main.async {
                    self?.handleEventsSnapshot(snapshot, error: error)
                }
            }
    }
    
    /// Останавливает загрузку событий
    func stopLoading() {
        listener?.remove()
        listener = nil
        fanEvents = []
    }
    
    // MARK: - Private Methods
    
    private func handleEventsSnapshot(_ snapshot: QuerySnapshot?, error: Error?) {
        isLoading = false
        
        if let error = error {
            print("❌ FanEventService: Error loading events: \(error.localizedDescription)")
            errorMessage = "Failed to load events: \(error.localizedDescription)"
            return
        }
        
        guard let snapshot = snapshot else {
            print("❌ FanEventService: No snapshot received")
            errorMessage = "No events data received"
            return
        }
        
        // Парсим события и фильтруем для фанатов
        let allEvents = snapshot.documents.compactMap { document -> Event? in
            do {
                return try document.data(as: Event.self)
            } catch {
                print("❌ FanEventService: Error parsing event \(document.documentID): \(error)")
                return nil
            }
        }
        
        // Фильтруем только публичные события для фанатов и сортируем по дате
        let publicEvents = allEvents.filter { event in
            isEventVisibleToFans(event)
        }.sorted { $0.date < $1.date } // ✅ Сортировка на клиенте
        
        print("✅ FanEventService: Loaded \(publicEvents.count) public events (from \(allEvents.count) total)")
        
        fanEvents = publicEvents
        errorMessage = nil
    }
    
    /// Проверяет, должно ли событие быть видимо фанатам
    private func isEventVisibleToFans(_ event: Event) -> Bool {
        // 1. Приватные события НЕ видны фанатам
        if event.isPersonal {
            return false
        }
        
        // 2. Только определенные типы событий видны фанатам
        let fanVisibleTypes: [EventType] = [.concert, .festival, .birthday]
        
        return fanVisibleTypes.contains(event.type)
    }
    
    // MARK: - Helper Methods
    
    /// Получает события для конкретной даты
    func getEvents(for date: Date) -> [Event] {
        let calendar = Calendar.current
        return fanEvents.filter { event in
            calendar.isDate(event.date, inSameDayAs: date)
        }
    }
    
    /// Получает все даты с событиями
    func getDatesWithEvents() -> Set<Date> {
        let calendar = Calendar.current
        return Set(fanEvents.map { event in
            calendar.startOfDay(for: event.date)
        })
    }
    
    /// Получает событие по ID
    func getEvent(by id: String) -> Event? {
        return fanEvents.first { $0.id == id }
    }
    
    /// Получает количество событий для даты
    func getEventCount(for date: Date) -> Int {
        return getEvents(for: date).count
    }
    
    /// Получает ближайшие события (следующие 30 дней)
    func getUpcomingEvents(limit: Int = 10) -> [Event] {
        let now = Date()
        let futureEvents = fanEvents.filter { $0.date >= now }
        return Array(futureEvents.prefix(limit))
    }
    
    /// Получает прошедшие события
    func getPastEvents(limit: Int = 10) -> [Event] {
        let now = Date()
        let pastEvents = fanEvents.filter { $0.date < now }.reversed()
        return Array(pastEvents.prefix(limit))
    }
    
    deinit {
        listener?.remove()
    }
}

// MARK: - Extensions for Fan-specific Logic

extension FanEventService {
    
    /// Форматирует событие для отображения фанатам (скрывает приватную информацию)
    func formatEventForFans(_ event: Event) -> Event {
        var fanEvent = event
        
        // Скрываем контактную информацию организаторов/координаторов
        fanEvent.organizerEmail = nil
        fanEvent.organizerPhone = nil
        fanEvent.coordinatorEmail = nil
        fanEvent.coordinatorPhone = nil
        
        // Скрываем информацию об отелях
        fanEvent.hotelName = nil
        fanEvent.hotelAddress = nil
        fanEvent.hotelCheckIn = nil
        fanEvent.hotelCheckOut = nil
        fanEvent.hotelBreakfastIncluded = nil
        
        // ✅ ИСПРАВЛЕНО: НЕ скрываем информацию о платности событий для фанатов
        // Фанаты ДОЛЖНЫ видеть:
        // - fanEvent.isPaidEvent (платное ли событие)
        // - fanEvent.ticketPurchaseUrl (ссылка на покупку билетов)
        
        // ❌ Скрываем только внутреннюю финансовую информацию группы:
        fanEvent.fee = nil        // Гонорар группы - приватная информация
        fanEvent.currency = nil   // Валюта гонорара - приватная информация
        
        // Скрываем приватные заметки
        fanEvent.notes = nil
        
        return fanEvent
    }
    
    /// Проверяет, может ли фанат видеть детали события
    func canFanViewEventDetails(_ event: Event) -> Bool {
        return isEventVisibleToFans(event)
    }
}
