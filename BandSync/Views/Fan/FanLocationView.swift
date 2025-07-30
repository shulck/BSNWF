import SwiftUI
import MapKit

struct FanLocationView: View {
    let event: Event
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var region: MKCoordinateRegion
    @State private var isSearching = false
    
    init(event: Event) {
        self.event = event
        // Default region (can be updated when location is geocoded)
        self._region = State(initialValue: MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        ))
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background Map
                Map(coordinateRegion: $region, annotationItems: [event]) { event in
                    MapAnnotation(coordinate: region.center) {
                        VStack(spacing: 8) {
                            // Modern map pin
                            ZStack {
                                Circle()
                                    .fill(Color(hex: event.type.colorHex))
                                    .frame(width: 50, height: 50)
                                    .shadow(color: Color(hex: event.type.colorHex).opacity(0.4), radius: 8, x: 0, y: 4)
                                
                                Image(systemName: event.type.icon)
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                            
                            // Event title badge
                            Text(event.title)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(.ultraThinMaterial)
                                        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                                )
                        }
                    }
                }
                .ignoresSafeArea()
                
                // Floating UI overlay
                VStack {
                    // Top bar with close and share buttons
                    HStack {
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                                .frame(width: 44, height: 44)
                                .background(.ultraThinMaterial)
                                .clipShape(Circle())
                                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                        }
                        
                        Spacer()
                        
                        if let location = event.location, !location.isEmpty {
                            Button(action: shareLocation) {
                                Image(systemName: "square.and.arrow.up")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                                    .frame(width: 44, height: 44)
                                    .background(.ultraThinMaterial)
                                    .clipShape(Circle())
                                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 60)
                    
                    Spacer()
                    
                    // Bottom card with event details
                    VStack(spacing: 0) {
                        // Handle bar
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.secondary.opacity(0.4))
                            .frame(width: 40, height: 6)
                            .padding(.top, 12)
                        
                        // Card content
                        VStack(spacing: 24) {
                            // Location header
                            VStack(spacing: 16) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 8) {
                                        HStack(spacing: 8) {
                                            Image(systemName: "location.fill")
                                                .font(.title3)
                                                .foregroundColor(.blue)
                                            
                                            Text("Event Location")
                                                .font(.title2)
                                                .fontWeight(.bold)
                                                .foregroundColor(.primary)
                                        }
                                        
                                        if let location = event.location, !location.isEmpty {
                                            Text(location)
                                                .font(.subheadline)
                                                .foregroundColor(.secondary)
                                                .lineLimit(nil)
                                        } else {
                                            Text("Location not specified")
                                                .font(.subheadline)
                                                .foregroundColor(.secondary)
                                                .italic()
                                        }
                                    }
                                    
                                    Spacer()
                                }
                                
                                // Get directions button
                                if let location = event.location, !location.isEmpty {
                                    Button(action: openInMaps) {
                                        HStack(spacing: 8) {
                                            Image(systemName: "arrow.triangle.turn.up.right.diamond.fill")
                                                .font(.system(size: 16, weight: .semibold))
                                            Text("Get Directions")
                                                .font(.headline)
                                                .fontWeight(.semibold)
                                        }
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 16)
                                        .background(
                                            LinearGradient(
                                                gradient: Gradient(colors: [.blue, .blue.opacity(0.8)]),
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .clipShape(RoundedRectangle(cornerRadius: 14))
                                        .shadow(color: .blue.opacity(0.3), radius: 12, x: 0, y: 6)
                                    }
                                }
                            }
                            
                            // Divider
                            Rectangle()
                                .fill(Color.secondary.opacity(0.2))
                                .frame(height: 1)
                            
                            // Event details section
                            VStack(spacing: 16) {
                                // Event title with icon
                                HStack(spacing: 12) {
                                    ZStack {
                                        Circle()
                                            .fill(Color(hex: event.type.colorHex).opacity(0.15))
                                            .frame(width: 40, height: 40)
                                        
                                        Image(systemName: event.type.icon)
                                            .font(.system(size: 18, weight: .semibold))
                                            .foregroundColor(Color(hex: event.type.colorHex))
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(event.title)
                                            .font(.headline)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.primary)
                                            .lineLimit(2)
                                        
                                        Text(event.type.rawValue)
                                            .font(.caption)
                                            .fontWeight(.medium)
                                            .foregroundColor(Color(hex: event.type.colorHex))
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 3)
                                            .background(Color(hex: event.type.colorHex).opacity(0.1))
                                            .clipShape(Capsule())
                                    }
                                    
                                    Spacer()
                                }
                                
                                // Date and time
                                HStack(spacing: 12) {
                                    Image(systemName: "calendar")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.blue)
                                        .frame(width: 24, height: 24)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Date & Time")
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.secondary)
                                            .textCase(.uppercase)
                                        
                                        Text(formatEventDate())
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .foregroundColor(.primary)
                                    }
                                    
                                    Spacer()
                                }
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                                .background(Color.blue.opacity(0.05))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 24)
                        .background(
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .fill(.ultraThinMaterial)
                                .shadow(color: .black.opacity(colorScheme == .dark ? 0.3 : 0.1), radius: 20, x: 0, y: -10)
                        )
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            geocodeLocation()
        }
    }
    
    // MARK: - Helper Methods
    
    private func formatEventDate() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: event.date)
    }
    
    private func geocodeLocation() {
        guard let locationString = event.location,
              !locationString.isEmpty else { return }
        
        isSearching = true
        let geocoder = CLGeocoder()
        
        geocoder.geocodeAddressString(locationString) { placemarks, error in
            DispatchQueue.main.async {
                isSearching = false
                
                if let placemark = placemarks?.first,
                   let location = placemark.location {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        region = MKCoordinateRegion(
                            center: location.coordinate,
                            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                        )
                    }
                }
            }
        }
    }
    
    private func openInMaps() {
        guard let location = event.location,
              !location.isEmpty else { return }
        
        let encodedLocation = location.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "http://maps.apple.com/?q=\(encodedLocation)"
        
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
    }
    
    private func shareLocation() {
        guard let location = event.location,
              !location.isEmpty else { return }
        
        let shareText = """
        📍 \(event.title)
        🗓 \(formatEventDate())
        📍 \(location)
        """
        
        let activityVC = UIActivityViewController(activityItems: [shareText], applicationActivities: nil)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootViewController = window.rootViewController {
            
            var presentingVC = rootViewController
            while let presentedVC = presentingVC.presentedViewController {
                presentingVC = presentedVC
            }
            
            // iPad support
            if let popover = activityVC.popoverPresentationController {
                popover.sourceView = window
                popover.sourceRect = CGRect(x: window.bounds.midX, y: window.bounds.midY, width: 0, height: 0)
                popover.permittedArrowDirections = []
            }
            
            presentingVC.present(activityVC, animated: true)
        }
    }
}
