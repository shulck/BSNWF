//
//  FanCalendarView.swift
//  BandSync
//
//  Created by Claude on 28.07.2025.
//

import SwiftUI

struct FanCalendarViewWrapper: View {
    @State private var navigationPath = NavigationPath()
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            FanCalendarView()
                .navigationDestination(for: String.self) { eventId in
                    if let event = FanEventService.shared.getEvent(by: eventId) {
                        FanEventDetailView(event: event)
                    } else {
                        Text("Event not found")
                            .foregroundColor(.secondary)
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
    @StateObject private var fanEventService = FanEventService.shared
    @State private var selectedDate = Date()
    @EnvironmentObject private var appState: AppState

    var body: some View {
        VStack(spacing: 0) {
            // Calendar Section - используем оригинальный CustomDatePicker
            CustomDatePicker(selectedDate: $selectedDate, events: fanEventService.fanEvents)
                .padding(.horizontal)
                .padding(.top)
                .padding(.bottom, 4)
                .background(Color(UIColor.systemBackground))
                .cornerRadius(16)
                .shadow(color: Color.purple.opacity(0.1), radius: 8, x: 0, y: 4) // Фиолетовая тема для фанатов
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
                        .foregroundColor(.purple) // Фиолетовая тема
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(Color.purple.opacity(0.1))
                        .cornerRadius(12)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)

            // Events List
            if fanEventService.isLoading {
                VStack {
                    Spacer()
                    ProgressView("Loading events...")
                        .foregroundColor(.purple)
                    Spacer()
                }
            } else if let errorMessage = fanEventService.errorMessage {
                VStack {
                    Spacer()
                    Text("Error: \(errorMessage)")
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding()
                    Button("Retry") {
                        loadEvents()
                    }
                    .foregroundColor(.purple)
                    Spacer()
                }
            } else {
                List {
                    let events = eventsForSelectedDate()
                    if events.isEmpty {
                        // Empty state for fans
                        VStack(spacing: 16) {
                            Image(systemName: "calendar.badge.exclamationmark")
                                .font(.system(size: 50))
                                .foregroundColor(.purple.opacity(0.6))
                            
                            Text("No events on this date")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Text("Check other dates to see upcoming concerts, festivals, and celebrations!")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                    } else {
                        // ✅ Используем тот же стиль что и в основном календаре
                        ForEach(events, id: \.id) { event in
                            ZStack {
                                Color.clear
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
                            }
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                            .padding(.vertical, 4)
                        }
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
            loadEvents()
        }
        .refreshable {
            loadEvents()
        }
    }

    private func eventsForSelectedDate() -> [Event] {
        return fanEventService.getEvents(for: selectedDate)
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
    
    private func loadEvents() {
        guard let user = appState.user,
              let groupId = user.fanGroupId else {
            print("❌ FanCalendarView: No fan group ID found")
            return
        }
        
        fanEventService.loadPublicEvents(for: groupId)
    }
}

// MARK: - Fan Event Row View (точная копия оригинального EventRowView)

struct FanEventRowView: View {
    let event: Event
    
    var body: some View {
        HStack {
            Rectangle()
                .fill(Color(hex: event.type.color)) // ✅ Используем .color как в оригинале (возвращает строку)
                .frame(width: 4)
                .cornerRadius(2)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(event.title)
                        .font(.headline)
                    
                    Spacer()
                    
                    // Event rating on the right side of the title
                    if let rating = event.rating {
                        HStack(spacing: 1) {
                            ForEach(1...5, id: \.self) { star in
                                Image(systemName: star <= rating ? "star.fill" : "star")
                                    .foregroundColor(star <= rating ? .yellow : .gray.opacity(0.3))
                                    .font(.caption2)
                            }
                        }
                    }
                }
                
                HStack {
                    Text(event.type.rawValue.localized)
                        .font(.caption)
                        .padding(3)
                        .padding(.horizontal, 3)
                        .background(Color(hex: event.type.color).opacity(0.2)) // ✅ Используем .color
                        .cornerRadius(4)
                    
                    Text(event.status.rawValue.localized)
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Spacer()
                    
                    Text(formatTime(event.date))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if let location = event.location, !location.isEmpty {
                    Text(location)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .lineLimit(1)
                }
            }
            .padding(.leading, 8)
        }
        .padding(.vertical, 4)
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
