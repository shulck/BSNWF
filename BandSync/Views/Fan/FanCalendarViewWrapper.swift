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
                        // Modern Error State
                        VStack(spacing: 24) {
                            ZStack {
                                Circle()
                                    .fill(Color.orange.opacity(0.15))
                                    .frame(width: 80, height: 80)
                                
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.system(size: 32, weight: .semibold))
                                    .foregroundColor(.orange)
                            }
                            
                            VStack(spacing: 12) {
                                Text("Event Not Found")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.primary)
                                
                                Text("This event may have been deleted or you don't have permission to view it.")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .lineLimit(nil)
                            }
                        }
                        .padding(.horizontal, 40)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color(UIColor.systemGroupedBackground))
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
    @Environment(\.colorScheme) private var colorScheme
    
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
            // Modern Calendar Section
            VStack(spacing: 16) {
                // Calendar Header
                HStack {
                    Text(formatMonthYear(selectedDate))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    // Today button
                    Button("Today") {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            selectedDate = Date()
                        }
                    }
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue.opacity(0.1))
                    .clipShape(Capsule())
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                
                // Calendar Widget
                CustomDatePicker(selectedDate: $selectedDate, events: fanVisibleEvents)
                    .padding(.horizontal, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(colorScheme == .dark ?
                                  Color(UIColor.secondarySystemGroupedBackground) :
                                  Color.white)
                            .shadow(
                                color: colorScheme == .dark ?
                                    Color.clear :
                                    Color.black.opacity(0.08),
                                radius: 12,
                                x: 0,
                                y: 4
                            )
                    )
                    .padding(.horizontal, 20)
            }
            .padding(.bottom, 16)

            // Selected Date Header
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(formatSelectedDate(selectedDate))
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        let eventCount = eventsForSelectedDate().count
                        if eventCount > 0 {
                            Text("\(eventCount) \(eventCountLabel(eventCount))")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        } else {
                            Text("No events")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    // Event count badge
                    let eventCount = eventsForSelectedDate().count
                    if eventCount > 0 {
                        ZStack {
                            Circle()
                                .fill(Color.blue.opacity(0.15))
                                .frame(width: 32, height: 32)
                            
                            Text("\(eventCount)")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.blue)
                        }
                    }
                }
                .padding(.horizontal, 20)
                
                Rectangle()
                    .fill(Color.secondary.opacity(0.2))
                    .frame(height: 1)
                    .padding(.horizontal, 20)
            }

            // Events List
            if eventService.isLoading {
                // Modern Loading State
                VStack(spacing: 20) {
                    Spacer()
                    
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.2)
                            .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                        
                        Text("Loading events...")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                
            } else if fanVisibleEvents.isEmpty {
                // Modern Empty State
                VStack(spacing: 24) {
                    Spacer()
                    
                    VStack(spacing: 20) {
                        ZStack {
                            Circle()
                                .fill(Color.gray.opacity(0.1))
                                .frame(width: 100, height: 100)
                            
                            Image(systemName: "calendar.badge.exclamationmark")
                                .font(.system(size: 40, weight: .medium))
                                .foregroundColor(.gray.opacity(0.6))
                        }
                        
                        VStack(spacing: 12) {
                            Text("No Events Yet")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            
                            Text("Check back later for upcoming concerts and events!")
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .lineLimit(nil)
                        }
                    }
                    .padding(.horizontal, 40)
                    
                    Spacer()
                }
                
            } else {
                // Modern Events List
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(eventsForSelectedDate(), id: \.id) { event in
                            NavigationLink(value: event.id ?? "") {
                                ModernFanEventRowView(event: event)
                                    .padding(.horizontal, 20)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.vertical, 16)
                }
            }
        }
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(UIColor.systemGroupedBackground),
                    Color(UIColor.systemGroupedBackground).opacity(0.8)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
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

    private func formatMonthYear(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }
    
    private func formatSelectedDate(_ date: Date) -> String {
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

// MARK: - Modern Fan Event Row View

struct ModernFanEventRowView: View {
    let event: Event
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack(spacing: 16) {
            // Event Icon with Time
            VStack(spacing: 6) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(hex: event.type.colorHex).opacity(0.15))
                        .frame(width: 56, height: 56)
                    
                    VStack(spacing: 2) {
                        Text(formatDay(event.date))
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(Color(hex: event.type.colorHex))
                        
                        Text(formatMonth(event.date))
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundColor(Color(hex: event.type.colorHex).opacity(0.8))
                    }
                }
                
                Text(formatTime(event.date))
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
            }
            
            // Event Details
            VStack(alignment: .leading, spacing: 8) {
                // Title and Status
                HStack {
                    Text(event.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                    
                    Spacer()
                    
                    // Special badge for birthday events
                    if event.type == .birthday {
                        HStack(spacing: 4) {
                            Text("🎉")
                                .font(.caption)
                            Text("Congratulate".localized)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.pink)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.pink.opacity(0.1))
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(Color.pink.opacity(0.2), lineWidth: 1)
                        )
                    }
                }
                
                // Type and Status Tags
                HStack(spacing: 8) {
                    // Event Type
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color(hex: event.type.colorHex))
                            .frame(width: 6, height: 6)
                        
                        Text(event.type.rawValue.localized)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(Color(hex: event.type.colorHex))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(hex: event.type.colorHex).opacity(0.1))
                    .clipShape(Capsule())
                    
                    // Status
                    HStack(spacing: 4) {
                        Circle()
                            .fill(event.status.color)
                            .frame(width: 6, height: 6)
                        
                        Text(event.status.rawValue.localized)
                            .font(.caption)
                            .foregroundColor(event.status.color)
                    }
                    
                    Spacer()
                }
                
                // Location for non-birthday events
                if event.type != .birthday, let location = event.location, !location.isEmpty {
                    HStack(spacing: 6) {
                        Image(systemName: "location.fill")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        Text(location)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
            }
            
            // Chevron
            Image(systemName: "chevron.right")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(colorScheme == .dark ?
                      Color(UIColor.secondarySystemGroupedBackground) :
                      Color.white)
                .shadow(
                    color: colorScheme == .dark ?
                        Color.clear :
                        Color.black.opacity(0.08),
                    radius: 8,
                    x: 0,
                    y: 2
                )
        )
    }
    
    private func formatDay(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
    
    private func formatMonth(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return formatter.string(from: date).uppercased()
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
