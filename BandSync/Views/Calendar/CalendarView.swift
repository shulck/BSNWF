import SwiftUI

struct CalendarViewWrapper: View {
    @State private var navigationPath = NavigationPath()
    @EnvironmentObject private var navigationManager: NavigationManager
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            CalendarView()
                .navigationDestination(for: String.self) { eventId in
                    if let event = EventService.shared.events.first(where: { $0.id == eventId }) {
                        EventDetailView(event: event)
                    } else {
                        Text(NSLocalizedString("Event not found", comment: "Event not found message"))
                            .foregroundColor(.secondary)
                    }
                }
        }
        .onAppear {
                    // ИСПРАВЛЕНИЕ: Отложенная инициализация сервисов
                    DispatchQueue.main.async {
                        _ = EventService.shared // Ленивая инициализация
                    }
                }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ResetTab0"))) { _ in
            print("Calendar navigation reset")
            navigationPath = NavigationPath()
        }
        .onReceive(navigationManager.$eventToOpen) { eventId in
            if let eventId = eventId, !eventId.isEmpty {
                print("Opening event from notification: \(eventId)")
                navigationPath.append(eventId)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("NavigateToEvent"))) { notification in
            guard let userInfo = notification.userInfo,
                  let eventId = userInfo["eventId"] as? String else { return }
            
            // Check if event is already loaded
            if EventService.shared.events.contains(where: { $0.id == eventId }) {
                navigationPath.append(eventId)
            } else {
                // Try to fetch the specific event first
                EventService.shared.fetchEventById(eventId) { event in
                    DispatchQueue.main.async {
                        if event != nil {
                            // If event exists, load all events for the group to ensure consistency
                            if let groupId = AppState.shared.user?.groupId {
                                EventService.shared.fetchEvents(for: groupId)
                            }
                            // Navigate after a brief delay to ensure the event is in the list
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                navigationPath.append(eventId)
                            }
                        }
                    }
                }
            }
        }
    }
}

struct CalendarView: View {
    @StateObject private var eventService = EventService.shared
    @State private var selectedDate = Date()
    @State private var showAddEvent = false

    var body: some View {
        VStack(spacing: 0) {
            // Calendar Section
            CustomDatePicker(selectedDate: $selectedDate, events: eventService.events)
                .padding(.horizontal)
                .padding(.top)
                .padding(.bottom, 4)
                .background(Color(UIColor.systemBackground))
                .cornerRadius(16)
                .shadow(color: Color.primary.opacity(0.05), radius: 8, x: 0, y: 4)
                .padding([.horizontal, .top])

            Divider()

            // Header for selected date
            HStack {
                Text(formatDate(selectedDate))
                    .font(.headline)
                Spacer()
                Text("\(eventsForSelectedDate().count) \(eventCountLabel(eventsForSelectedDate().count))")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            .padding(.top, 8)

            // Events List
            if eventsForSelectedDate().isEmpty {
                Spacer()
                Text(NSLocalizedString("No events for selected date", comment: "No events for selected date message"))
                    .foregroundColor(.secondary)
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(12)
                    .shadow(color: Color.primary.opacity(0.03), radius: 5, x: 0, y: 2)
                Spacer()
            } else {
                List {
                    ForEach(eventsForSelectedDate(), id: \.id) { event in
                        ZStack {
                            Color.clear
                            NavigationLink(destination: EventDetailView(event: event)) {
                                EventRowView(event: event)
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color(UIColor.systemBackground))
                                            .shadow(color: Color.primary.opacity(0.06), radius: 4, x: 0, y: 2)
                                    )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
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
        .navigationTitle(NSLocalizedString("Calendar", comment: "Calendar navigation title"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showAddEvent = true
                }) {
                    Image(systemName: "plus")
                        .font(.title2)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                }
            }
        }
        .onAppear {
            if let groupId = AppState.shared.user?.groupId {
                eventService.fetchEvents(for: groupId)
            }
        }
        .sheet(isPresented: $showAddEvent) {
            AddEventView(initialDate: selectedDate)
        }
    }

    private func eventsForSelectedDate() -> [Event] {
        let currentUserId = AppState.shared.user?.id
        
        return eventService.events.filter {
            let dateMatches = Calendar.current.isDate($0.date, inSameDayAs: selectedDate)
            let isAccessible = !$0.isPersonal || $0.createdBy == currentUserId
            
            return dateMatches && isAccessible
        }.sorted { $0.date < $1.date }
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
            return NSLocalizedString("event", comment: "Single event label")
        } else if mod10 >= 2 && mod10 <= 4 && (mod100 < 10 || mod100 >= 20) {
            return NSLocalizedString("events", comment: "Multiple events label")
        } else {
            return NSLocalizedString("events", comment: "Multiple events label")
        }
    }
}
