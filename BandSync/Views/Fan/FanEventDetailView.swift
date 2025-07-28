//
//  FanEventDetailView.swift
//  BandSync
//
//  Created by Claude on 28.07.2025.
//

import SwiftUI
import MapKit

struct FanEventDetailView: View {
    let event: Event
    @Environment(\.dismiss) private var dismiss
    @State private var showingLocationSheet = false
    
    // Форматируем событие для фанатов (убираем приватную информацию)
    private var fanEvent: Event {
        FanEventService.shared.formatEventForFans(event)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header Section
                fanEventHeaderSection
                
                // Main Content
                VStack(spacing: 16) {
                    // Location Section
                    if let location = fanEvent.location, !location.isEmpty {
                        fanLocationSection
                    }
                    
                    // Date and Time Section
                    fanDateTimeSection
                    
                    // Description Section (if available)
                    if let notes = fanEvent.notes, !notes.isEmpty {
                        fanDescriptionSection
                    }
                    
                    // Event Type Info
                    fanEventTypeSection
                }
                .padding(.horizontal)
                
                Spacer(minLength: 40)
            }
        }
        .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle("Event Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                // Share button for fans
                Button(action: shareEvent) {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundColor(.purple)
                }
            }
        }
        .sheet(isPresented: $showingLocationSheet) {
            FanLocationView(event: fanEvent)
        }
    }
    
    // MARK: - Fan Event Header Section
    
    private var fanEventHeaderSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Adaptive event title
            GeometryReader { geometry in
                Text(fanEvent.title)
                    .font(adaptiveTitleFont(for: geometry.size.width))
                    .fontWeight(.bold)
                    .foregroundColor(Color(hex: fanEvent.type.colorHex))
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                    .multilineTextAlignment(.leading)
            }
            .frame(minHeight: adaptiveTitleHeight())
            .padding(.bottom, 4)
            
            // Event type and status
            fanEventTypeAndStatusRow
            
            // Date label
            Label(formatDate(fanEvent.date), systemImage: "calendar")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal)
    }
    
    // MARK: - Fan Location Section
    
    private var fanLocationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Location")
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
                // Location name
                HStack {
                    Image(systemName: "location.fill")
                        .foregroundColor(.purple)
                    Text(fanEvent.location ?? "")
                        .font(.body)
                        .foregroundColor(.primary)
                    Spacer()
                }
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(12)
                
                // Action buttons for location
                HStack(spacing: 12) {
                    // Get directions button
                    Button(action: {
                        showLocationDirections(address: fanEvent.location ?? "", name: fanEvent.title)
                    }) {
                        Label("Get directions", systemImage: "arrow.triangle.turn.up.right.diamond")
                            .font(.subheadline)
                            .foregroundColor(.white)
                            .padding(.vertical, 10)
                            .padding(.horizontal, 16)
                            .background(Color.purple)
                            .cornerRadius(8)
                    }
                    
                    // Show on map button
                    Button(action: {
                        showingLocationSheet = true
                    }) {
                        Label("Show on map", systemImage: "map")
                            .font(.subheadline)
                            .foregroundColor(.purple)
                            .padding(.vertical, 10)
                            .padding(.horizontal, 16)
                            .background(Color.purple.opacity(0.1))
                            .cornerRadius(8)
                    }
                    
                    Spacer()
                }
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.primary.opacity(0.05), radius: 8, x: 0, y: 4)
    }
    
    // MARK: - Fan Date and Time Section
    
    private var fanDateTimeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Date & Time")
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(spacing: 8) {
                // Date
                HStack {
                    Image(systemName: "calendar")
                        .foregroundColor(.purple)
                    Text(formatLongDate(fanEvent.date))
                        .font(.body)
                        .foregroundColor(.primary)
                    Spacer()
                }
                
                // Time
                HStack {
                    Image(systemName: "clock")
                        .foregroundColor(.purple)
                    Text(formatTime(fanEvent.date))
                        .font(.body)
                        .foregroundColor(.primary)
                    Spacer()
                }
            }
            .padding()
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(12)
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.primary.opacity(0.05), radius: 8, x: 0, y: 4)
    }
    
    // MARK: - Fan Description Section
    
    private var fanDescriptionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("About this event")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text(fanEvent.notes ?? "")
                .font(.body)
                .foregroundColor(.secondary)
                .lineLimit(nil)
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(12)
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.primary.opacity(0.05), radius: 8, x: 0, y: 4)
    }
    
    // MARK: - Fan Event Type Section
    
    private var fanEventTypeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Event Information")
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(spacing: 8) {
                // Event type
                HStack {
                    Image(systemName: fanEvent.type.icon)
                        .foregroundColor(Color(hex: fanEvent.type.colorHex))
                    Text("Type: \(fanEvent.type.rawValue)")
                        .font(.body)
                        .foregroundColor(.primary)
                    Spacer()
                }
                
                // Event status
                HStack {
                    Image(systemName: "checkmark.circle")
                        .foregroundColor(fanEvent.status.color)
                    Text("Status: \(fanEvent.status.rawValue)")
                        .font(.body)
                        .foregroundColor(.primary)
                    Spacer()
                }
            }
            .padding()
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(12)
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.primary.opacity(0.05), radius: 8, x: 0, y: 4)
    }
    
    // MARK: - Helper Views and Functions
    
    private var fanEventTypeAndStatusRow: some View {
        HStack(spacing: 16) {
            Label(fanEvent.type.rawValue, systemImage: fanEvent.type.icon)
                .foregroundColor(Color(hex: fanEvent.type.colorHex))
                .font(.subheadline)
            
            Label(fanEvent.status.rawValue, systemImage: "checkmark.circle")
                .foregroundColor(fanEvent.status.color)
                .font(.subheadline)
        }
    }
    
    // MARK: - Adaptive Title Helpers
    
    private func adaptiveTitleFont(for width: CGFloat) -> Font {
        let titleLength = fanEvent.title.count
        
        if width > 600 {
            if titleLength > 30 {
                return .title2.bold()
            } else {
                return .largeTitle.bold()
            }
        } else if width > 390 {
            if titleLength > 25 {
                return .title3.bold()
            } else if titleLength > 15 {
                return .title2.bold()
            } else {
                return .title.bold()
            }
        } else if width > 350 {
            if titleLength > 20 {
                return .headline.bold()
            } else if titleLength > 12 {
                return .title3.bold()
            } else {
                return .title2.bold()
            }
        } else {
            if titleLength > 15 {
                return .subheadline.bold()
            } else if titleLength > 10 {
                return .headline.bold()
            } else {
                return .title3.bold()
            }
        }
    }
    
    private func adaptiveTitleHeight() -> CGFloat {
        let titleLength = fanEvent.title.count
        
        if titleLength > 30 {
            return 100
        } else if titleLength > 20 {
            return 70
        } else if titleLength > 10 {
            return 50
        } else {
            return 35
        }
    }
    
    // MARK: - Formatting Functions
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func formatLongDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter.string(from: date)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    // MARK: - Actions
    
    private func shareEvent() {
        let text = """
        🎵 \(fanEvent.title)
        📅 \(formatDate(fanEvent.date))
        📍 \(fanEvent.location ?? "TBA")
        🎤 \(fanEvent.type.rawValue)
        """
        
        let activityVC = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            // Find the top-most view controller
            var topController = rootViewController
            while let presented = topController.presentedViewController {
                topController = presented
            }
            
            // Present the activity controller
            topController.present(activityVC, animated: true)
        }
    }
    
    private func showLocationDirections(address: String, name: String) {
        let alert = UIAlertController(title: "Open in Maps", message: "Which application to use for navigation?", preferredStyle: .actionSheet)
        
        // Apple Maps
        alert.addAction(UIAlertAction(title: "Apple Maps", style: .default) { _ in
            let encodedAddress = address.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            if let url = URL(string: "http://maps.apple.com/?q=\(encodedAddress)"),
               UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            }
        })
        
        // Google Maps (if installed)
        if let url = URL(string: "comgooglemaps://"),
           UIApplication.shared.canOpenURL(url) {
            alert.addAction(UIAlertAction(title: "Google Maps", style: .default) { _ in
                let encodedAddress = address.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
                if let googleUrl = URL(string: "comgooglemaps://?q=\(encodedAddress)") {
                    UIApplication.shared.open(googleUrl)
                }
            })
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        // Present the alert
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            var topController = rootViewController
            while let presented = topController.presentedViewController {
                topController = presented
            }
            topController.present(alert, animated: true)
        }
    }
}

// MARK: - Fan Location View (для показа карты)

struct FanLocationView: View {
    let event: Event
    @Environment(\.dismiss) private var dismiss
    @State private var region: MKCoordinateRegion
    
    init(event: Event) {
        self.event = event
        // Default region (можно улучшить геокодированием адреса)
        self._region = State(initialValue: MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 50.0, longitude: 8.0), // Примерные координаты Европы
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        ))
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // Event info header
                VStack(alignment: .leading, spacing: 8) {
                    Text(event.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    if let location = event.location {
                        HStack {
                            Image(systemName: "location.fill")
                                .foregroundColor(.purple)
                            Text(location)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
                .background(Color(UIColor.systemBackground))
                
                // Map view
                Map(coordinateRegion: $region)
                    .ignoresSafeArea(edges: .bottom)
            }
            .navigationTitle("Event Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.purple)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Directions") {
                        if let location = event.location {
                            showLocationDirections(address: location, name: event.title)
                        }
                    }
                    .foregroundColor(.purple)
                }
            }
        }
    }
    
    private func showLocationDirections(address: String, name: String) {
        let encodedAddress = address.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        if let url = URL(string: "http://maps.apple.com/?q=\(encodedAddress)"),
           UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Extensions

// EventStatus уже имеет свойство color в Core/Enums/EventStatus.swift
// Никаких дополнительных extensions не нужно
