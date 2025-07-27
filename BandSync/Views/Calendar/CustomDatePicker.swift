//
//  CustomDatePicker.swift
//  BandSync
//

import SwiftUI

// Helper structure for highlighting dates with events
struct DateHighlighter: View {
    let date: Date
    let events: [Event]
    let isSelected: Bool
    let isToday: Bool
    
    var body: some View {
        Circle()
            .fill(backgroundColorForDate())
            .frame(width: 30, height: 30)
            .overlay(
                // Add border for selection or multiple event types
                Circle()
                    .stroke(borderColorForDate(), lineWidth: borderWidthForDate())
                    .frame(width: 30, height: 30)
            )
    }
    
    // Get background color based on event type and selection state
    private func backgroundColorForDate() -> Color {
        let eventsForThisDate = eventsForDate()
        
        if !eventsForThisDate.isEmpty {
            // Date with events - use primary event type color
            if let primaryEventType = eventsForThisDate.first?.type {
                // If selected, make it more saturated, otherwise use opacity
                return isSelected ?
                    Color(hex: primaryEventType.colorHex) :
                    Color(hex: primaryEventType.colorHex).opacity(0.8)
            }
        } else if isSelected {
            // Selected date without events - blue
            return Color.blue
        } else if isToday {
            // Today without events - transparent with blue border
            return Color.clear
        }
        
        // Regular date without events
        return Color.clear
    }
    
    // Get border color for mixed events, selection, or today's date
    private func borderColorForDate() -> Color {
        let eventsForThisDate = eventsForDate()
        
        if isSelected && !eventsForThisDate.isEmpty {
            // Selected date with events - white border for emphasis
            return Color.white
        } else if hasMixedEvents() && !isSelected {
            // Multiple different event types - show secondary color as border
            if eventsForThisDate.count > 1,
               let secondaryEventType = eventsForThisDate.dropFirst().first?.type {
                return Color(hex: secondaryEventType.colorHex)
            }
        } else if isSelected && eventsForThisDate.isEmpty {
            // Selected date without events - white border on blue background
            return Color.white
        } else if isToday && !isSelected && eventsForThisDate.isEmpty {
            // Today's date without events
            return Color.blue
        }
        
        return Color.clear
    }
    
    // Get border width based on state
    private func borderWidthForDate() -> CGFloat {
        let eventsForThisDate = eventsForDate()
        
        if isSelected {
            return 2.5 // Thicker border for selected dates
        } else if hasMixedEvents() {
            return 2 // Border for mixed events
        } else if isToday && eventsForThisDate.isEmpty {
            return 1.2 // Thin border for today
        }
        
        return 0
    }
    
    // Check if there are multiple different event types on this date
    private func hasMixedEvents() -> Bool {
        let eventTypes = Set(eventsForDate().map { $0.type })
        return eventTypes.count > 1
    }
    
    // Get the list of events for the given date
    private func eventsForDate() -> [Event] {
        return events.filter {
            Calendar.current.isDate($0.date, inSameDayAs: date)
        }
    }
}

struct CustomDatePicker: View {
    @Binding var selectedDate: Date
    let events: [Event]
    
    // Current month and year
    @State private var currentMonth = 0
    @State private var currentYear = 0
    
    var body: some View {
        VStack(spacing: 14) {
            // Header with month and year
            HStack {
                Button {
                    withAnimation(.smooth(duration: 0.3)) {
                        currentMonth -= 1
                        if currentMonth < 0 {
                            currentMonth = 11
                            currentYear -= 1
                        }
                        // Check if we returned to current month and select today's date
                        checkAndSelectTodayIfCurrentMonth()
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.title3)
                }
                
                Spacer()
                
                // Display current month and year
                Text(monthYearText())
                    .font(.title3.bold())
                    .animation(.smooth(duration: 0.3), value: currentMonth)
                    .animation(.smooth(duration: 0.3), value: currentYear)
                
                Spacer()
                
                Button {
                    withAnimation(.smooth(duration: 0.3)) {
                        currentMonth += 1
                        if currentMonth > 11 {
                            currentMonth = 0
                            currentYear += 1
                        }
                        // Check if we returned to current month and select today's date
                        checkAndSelectTodayIfCurrentMonth()
                    }
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.title3)
                }
            }
            .padding(.horizontal)
            
            // Days of the week
            HStack(spacing: 0) {
                ForEach(daysOfWeek(), id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                }
            }
            
            let columns = Array(repeating: GridItem(.flexible()), count: 7)
            
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(extractDates()) { dateValue in
                    // Date cell
                    VStack {
                        if dateValue.day != -1 {
                            // If the date belongs to the current month
                            Button {
                                selectedDate = dateValue.date
                            } label: {
                                ZStack {
                                    // Background highlighting based on events
                                    DateHighlighter(
                                        date: dateValue.date,
                                        events: events,
                                        isSelected: Calendar.current.isDate(dateValue.date, inSameDayAs: selectedDate),
                                        isToday: Calendar.current.isDateInToday(dateValue.date)
                                    )
                                    
                                    // Day number
                                    Text("\(dateValue.day)")
                                        .font(.system(size: 14))
                                        .fontWeight(Calendar.current.isDate(dateValue.date, inSameDayAs: selectedDate) ? .bold : .regular)
                                        .foregroundColor(textColorForDate(dateValue.date))
                                }
                            }
                            .gesture(
                                DragGesture()
                                    .onEnded { value in
                                        if value.translation.width > 5 {
                                            // Right swipe - previous month
                                            withAnimation(.smooth(duration: 0.3)) {
                                                currentMonth -= 1
                                                if currentMonth < 0 {
                                                    currentMonth = 11
                                                    currentYear -= 1
                                                }
                                            }
                                        } else if value.translation.width < -5 {
                                            // Left swipe - next month
                                            withAnimation(.smooth(duration: 0.3)) {
                                                currentMonth += 1
                                                if currentMonth > 11 {
                                                    currentMonth = 0
                                                    currentYear += 1
                                                }
                                            }
                                        }
                                    }
                            )
                        }
                    }
                    .frame(height: 38)
                }
            }
            .gesture(
                DragGesture()
                    .onEnded { value in
                        if value.translation.width > 5 {
                            // Right swipe - previous month
                            withAnimation(.smooth(duration: 0.3)) {
                                currentMonth -= 1
                                if currentMonth < 0 {
                                    currentMonth = 11
                                    currentYear -= 1
                                }
                                // Check if we returned to current month and select today's date
                                checkAndSelectTodayIfCurrentMonth()
                            }
                        } else if value.translation.width < -5 {
                            // Left swipe - next month
                            withAnimation(.smooth(duration: 0.3)) {
                                currentMonth += 1
                                if currentMonth > 11 {
                                    currentMonth = 0
                                    currentYear += 1
                                }
                                // Check if we returned to current month and select today's date
                                checkAndSelectTodayIfCurrentMonth()
                            }
                        }
                    }
            )
            
            Spacer()
        }
        .onAppear {
            // Initialize the current month and year
            let calendar = Calendar.current
            currentMonth = calendar.component(.month, from: selectedDate) - 1 // 0-based
            currentYear = calendar.component(.year, from: selectedDate)
        }
        .onChange(of: currentMonth) { _, _ in
            // When month changes, check if we're back to current month
            checkAndSelectTodayIfCurrentMonth()
        }
        .onChange(of: currentYear) { _, _ in
            // When year changes, check if we're back to current month
            checkAndSelectTodayIfCurrentMonth()
        }
    }
    
    // Check if we're viewing the current month and select today's date
    private func checkAndSelectTodayIfCurrentMonth() {
        let today = Date()
        let calendar = Calendar.current
        let todayMonth = calendar.component(.month, from: today) - 1 // 0-based
        let todayYear = calendar.component(.year, from: today)
        
        // If we're viewing the current month and year, select today's date
        if currentMonth == todayMonth && currentYear == todayYear {
            selectedDate = today
        }
    }
    
    // Get text color based on date state
    private func textColorForDate(_ date: Date) -> Color {
        let eventsForThisDate = events.filter { Calendar.current.isDate($0.date, inSameDayAs: date) }
        let isSelectedDate = Calendar.current.isDate(date, inSameDayAs: selectedDate)
        
        if !eventsForThisDate.isEmpty {
            // Date with events - always white text for better contrast
            return .white
        } else if isSelectedDate {
            // Selected date without events - white text on blue background
            return .white
        } else if Calendar.current.isDateInToday(date) {
            // Today's date without events - blue text
            return .blue
        } else {
            // Regular date - primary color
            return .primary
        }
    }
    
    // Get the name of the month and year
    private func monthYearText() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "LLLL yyyy" // Full month name and year
        
        // Create a date for the first day of the selected month
        let calendar = Calendar.current
        let date = calendar.date(from: DateComponents(year: currentYear, month: currentMonth + 1, day: 1)) ?? Date()
        
        return dateFormatter.string(from: date)
    }
    
    // Get abbreviated names of the days of the week
    private func daysOfWeek() -> [String] {
        var days = Calendar.current.shortWeekdaySymbols
        let sunday = days.removeFirst()
        days.append(sunday)
        return days
    }

    
    // Extract dates of the current month
    private func extractDates() -> [DateValue] {
        var dateValues = [DateValue]()
        
        let calendar = Calendar.current
        
        // Get the date for the first day of the selected month
        guard let firstDayOfMonth = calendar.date(from: DateComponents(year: currentYear, month: currentMonth + 1, day: 1)) else {
            return dateValues
        }
        
        // Get the number of days in the month
        let range = calendar.range(of: .day, in: .month, for: firstDayOfMonth)!
        
        // Get the weekday of the first day of the month (0 = Sunday, 1 = Monday, etc.)
        var firstWeekday = calendar.component(.weekday, from: firstDayOfMonth) - 1
        if firstWeekday == 0 { firstWeekday = 7 } // Move Sunday to the end
        
        // Add empty cells for the days of the previous month
        for _ in 0..<firstWeekday-1 {
            dateValues.append(DateValue(day: -1, date: Date()))
        }
        
        // Add days of the current month
        for day in 1...range.count {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstDayOfMonth) {
                dateValues.append(DateValue(day: day, date: date))
            }
        }
        
        return dateValues
    }
}

// Helper structure for representing a date in the calendar
struct DateValue: Identifiable {
    let id = UUID().uuidString
    let day: Int
    let date: Date
}

// Extension for converting a Hex string to Color
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        
        // Ensure values are valid and not NaN
        let red = Double(r) / 255.0
        let green = Double(g) / 255.0
        let blue = Double(b) / 255.0
        let alpha = Double(a) / 255.0
        
        self.init(
            .sRGB,
            red: red.isNaN ? 0.0 : red,
            green: green.isNaN ? 0.0 : green,
            blue: blue.isNaN ? 0.0 : blue,
            opacity: alpha.isNaN ? 1.0 : alpha
        )
    }
}
