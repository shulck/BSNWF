import SwiftUI
import MapKit

struct FanLocationView: View {
    let event: Event
    @Environment(\.dismiss) private var dismiss
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
            VStack(spacing: 0) {
                // Map view
                Map(coordinateRegion: $region, annotationItems: [event]) { event in
                    MapAnnotation(coordinate: region.center) {
                        VStack {
                            Image(systemName: event.type.icon)
                                .font(.title2)
                                .foregroundColor(.white)
                                .padding(8)
                                .background(Color(hex: event.type.colorHex))
                                .clipShape(Circle())
                                .shadow(radius: 3)
                            
                            Text(event.title)
                                .font(.caption)
                                .fontWeight(.medium)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.white.opacity(0.9))
                                .cornerRadius(8)
                                .shadow(radius: 2)
                        }
                    }
                }
                .ignoresSafeArea(edges: .top)
                
                // Location details
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Event Location")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            if let location = event.location, !location.isEmpty {
                                Text(location)
                                    .font(.body)
                                    .foregroundColor(.secondary)
                            } else {
                                Text("Location not specified")
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                    .italic()
                            }
                        }
                        
                        Spacer()
                        
                        if let location = event.location, !location.isEmpty {
                            Button(action: openInMaps) {
                                Label("Directions", systemImage: "arrow.triangle.turn.up.right.diamond")
                                    .font(.subheadline)
                                    .foregroundColor(.purple)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(Color.purple.opacity(0.1))
                                    .cornerRadius(8)
                            }
                        }
                    }
                    
                    Divider()
                    
                    // Event details
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: event.type.icon)
                                .foregroundColor(Color(hex: event.type.colorHex))
                            Text(event.title)
                                .font(.headline)
                                .foregroundColor(.primary)
                        }
                        
                        HStack {
                            Image(systemName: "calendar")
                                .foregroundColor(.secondary)
                            Text(formatEventDate())
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Image(systemName: "tag")
                                .foregroundColor(.secondary)
                            Text(event.type.rawValue)
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
                .background(Color(UIColor.systemBackground))
            }
            .navigationTitle("Event Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(.purple)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if let location = event.location, !location.isEmpty {
                        Button(action: shareLocation) {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundColor(.purple)
                        }
                    }
                }
            }
        }
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
                    region = MKCoordinateRegion(
                        center: location.coordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                    )
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
            
            presentingVC.present(activityVC, animated: true)
        }
    }
}
