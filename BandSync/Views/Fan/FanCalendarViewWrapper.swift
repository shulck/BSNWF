import SwiftUI

struct FanCalendarViewWrapper: View {
    @State private var navigationPath = NavigationPath()
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            FanCalendarView()
                .navigationDestination(for: String.self) { eventId in
                    // ✅ Используем основной EventService.shared!
                    if let event = EventService.shared.events.first(where: { $0.id == eventId }) {
                        FanEventDetailView(fanEvent: event)
                    } else {
                        VStack {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.largeTitle)
                                .foregroundColor(.orange)
                                .padding()
                            
                            Text("Event not found")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            Text("This event may have been deleted or you don't have permission to view it.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        .padding()
                    }
                }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ResetFanCalendar"))) { _ in
            print("Fan calendar navigation reset")
            navigationPath = NavigationPath()
        }
    }
}

struct FanCalendarView: View {
    @StateObject private var eventService = EventService.shared  // ✅ Основной сервис!
    @State private var selectedDate = Date()
    @EnvironmentObject private var appState: AppState
    
    // ✅ Фильтрация событий для фанатов из основного сервиса
    private var fanVisibleEvents: [Event] {
        return eventService.events.filter { event in
            // 1. Приватные события НЕ видны фанатам
            if event.isPersonal {
                return false
            }
            
            // 2. Только определенные типы событий видны фанатам
            let fanVisibleTypes: [EventType] = [.concert, .festival, .birthday]
            return fanVisibleTypes.contains(event.type)
        }.sorted { $0.date < $1.date }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Calendar Section - используем отфильтрованные события
            let calendarView = CustomDatePicker(selectedDate: $selectedDate, events: fanVisibleEvents)
                .padding(.horizontal)
                .padding(.top)
                .padding(.bottom, 4)
                .background(Color(UIColor.systemBackground))
                .cornerRadius(16)
            
            calendarView
                .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                .padding([.horizontal, .top])

            Divider()

            // Header for selected date
            HStack {
                Text(formatDate(selectedDate))
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                let eventCount = eventsForSelectedDate().count
                if eventCount > 0 {
                    Text("\(eventCount) \(eventCountLabel(eventCount))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(12)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)

            // Events List
            if eventService.isLoading {
                VStack {
                    Spacer()
                    ProgressView("Loading events...")
                        .foregroundColor(.secondary)
                    Spacer()
                }
            } else if fanVisibleEvents.isEmpty {
                VStack {
                    Spacer()
                    
                    Image(systemName: "calendar.badge.exclamationmark")
                        .font(.system(size: 60))
                        .foregroundColor(.gray.opacity(0.6))
                    
                    Text("No Events Yet")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                        .padding(.top, 8)
                    
                    Text("Check back later for upcoming concerts and events!")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                    
                    Spacer()
                }
            } else {
                List {
                    ForEach(eventsForSelectedDate(), id: \.id) { event in
                        NavigationLink(value: event.id ?? "") {
                            FanEventRowView(event: event)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(UIColor.systemBackground))
                                        .shadow(color: Color.primary.opacity(0.06), radius: 4, x: 0, y: 2)
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .padding(.vertical, 4)
                    }
                }
                .listStyle(PlainListStyle())
                .padding(.top, 8)
            }
        }
        .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle("Events") // Заголовок для фанатов
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // ✅ ГЛАВНОЕ ИЗМЕНЕНИЕ: Сбрасываем дату на текущую при появлении вкладки
            resetToCurrentDate()
            loadEvents()
        }
        .refreshable {
            loadEvents()
        }
        // ✅ ДОБАВЛЯЕМ: Слушаем уведомления о переключении вкладок
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("FanCalendarTabSelected"))) { _ in
            resetToCurrentDate()
        }
    }

    // ✅ НОВЫЙ МЕТОД: Сброс к текущей дате
    private func resetToCurrentDate() {
        let now = Date()
        // Проверяем, отличается ли выбранная дата от текущей
        let calendar = Calendar.current
        if !calendar.isDate(selectedDate, inSameDayAs: now) {
            print("🔄 FanCalendarView: Resetting selected date to current date")
            selectedDate = now
        }
    }

    // ✅ Получаем события для выбранной даты из отфильтрованного списка
    private func eventsForSelectedDate() -> [Event] {
        let calendar = Calendar.current
        return fanVisibleEvents.filter { event in
            calendar.isDate(event.date, inSameDayAs: selectedDate)
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: date)
    }

    private func eventCountLabel(_ count: Int) -> String {
        let mod10 = count % 10
        let mod100 = count % 100
        if mod10 == 1 && mod100 != 11 {
            return "event"
        } else if mod10 >= 2 && mod10 <= 4 && (mod100 < 10 || mod100 >= 20) {
            return "events"
        } else {
            return "events"
        }
    }
    
    // ✅ Загружаем события через основной EventService!
    private func loadEvents() {
        guard let user = appState.user else {
            print("❌ FanCalendarView: No user found")
            return
        }
        
        // ✅ Для фанатов используем fanGroupId, для участников группы - groupId
        let groupId: String?
        if user.userType == .fan {
            groupId = user.fanGroupId
        } else {
            groupId = user.groupId
        }
        
        guard let groupId = groupId else {
            print("❌ FanCalendarView: No groupId or fanGroupId found for user type: \(user.userType)")
            return
        }
        
        print("🔄 FanCalendarView: Loading events for \(user.userType.rawValue) with groupId: \(groupId)")
        eventService.fetchEvents(for: groupId)  // ✅ Основной сервис загружает ВСЕ события
    }
}
