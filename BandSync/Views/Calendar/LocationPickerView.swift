//
//  LocationPickerView.swift
//  BandSync
//
//  Created by Oleksandr Kuziakin on 31.03.2025.
//

import SwiftUI
import MapKit

struct LocationPickerView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var selectedLocation: LocationDetails?
    
    @State private var searchText = ""
    @State private var searchResults: [LocationDetails] = []
    @State private var isSearching = false
    
    // Updated to use MapCameraPosition for iOS 17+
    @State private var cameraPosition = MapCameraPosition.region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 50.450001, longitude: 30.523333),
            span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        )
    )
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search bar
                searchBar
                
                if isSearching {
                    loadingView
                } else if !searchResults.isEmpty && !searchText.isEmpty {
                    searchResultsList
                } else {
                    mapView
                }
            }
            .navigationTitle(NSLocalizedString("Select Location", comment: "Navigation title for location picker"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(NSLocalizedString("Cancel", comment: "Cancel button in location picker")) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(NSLocalizedString("Done", comment: "Done button in location picker")) {
                        dismiss()
                    }
                    .disabled(selectedLocation == nil)
                }
            }
            .onAppear {
                requestUserLocation()
            }
        }
    }
    
    // MARK: - UI Components
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField(NSLocalizedString("Search for a place", comment: "Search placeholder in location picker"), text: $searchText)
                .textFieldStyle(PlainTextFieldStyle())
                .onChange(of: searchText) { _, newValue in
                    searchLocations(query: newValue)
                }
            
            if !searchText.isEmpty {
                Button(action: {
                    searchText = ""
                    searchResults = []
                    isSearching = false
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .padding()
    }
    
    private var loadingView: some View {
        VStack {
            ProgressView()
            Text(NSLocalizedString("searching", comment: "Searching progress text"))
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var searchResultsList: some View {
        List(searchResults) { location in
            Button(action: {
                selectLocation(location)
            }) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(location.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(location.address)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
        }
        .listStyle(PlainListStyle())
    }
    
    private var mapView: some View {
        VStack {
            // Updated Map with iOS 17+ MapContentBuilder
            Map(position: $cameraPosition) {
                // Add annotations for search results
                ForEach(searchResults) { location in
                    Annotation(location.name, coordinate: location.coordinate) {
                        Image(systemName: "mappin.circle")
                            .foregroundColor(.blue)
                            .font(.title2)
                            .background(Circle().fill(Color.white).scaleEffect(0.8))
                    }
                }
                
                // Add annotation for selected location
                if let selected = selectedLocation {
                    Annotation(selected.name, coordinate: selected.coordinate) {
                        Image(systemName: "mappin.circle.fill")
                            .foregroundColor(.red)
                            .font(.title2)
                            .background(Circle().fill(Color.white).scaleEffect(0.8))
                    }
                }
            }
            .frame(maxHeight: .infinity)
            
            // Selected location card or instructions
            if let selected = selectedLocation {
                selectedLocationCard(selected)
            } else {
                mapInstructions
            }
        }
    }
    
    private func selectedLocationCard(_ location: LocationDetails) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(location.name)
                        .font(.headline)
                    
                    Text(location.address)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                Button(NSLocalizedString("Clear", comment: "Clear selected location button")) {
                    selectedLocation = nil
                }
                .foregroundColor(.red)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        .padding()
    }
    
    private var mapInstructions: some View {
        VStack(spacing: 8) {
            Text(NSLocalizedString("Search for a location above", comment: "Map instructions text"))
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        .padding()
    }
    
    // MARK: - Helper Methods
    
    private func searchLocations(query: String) {
        if query.isEmpty {
            searchResults = []
            isSearching = false
            return
        }
        
        if query.count < 2 {
            return
        }
        
        isSearching = true
        
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        
        // Extract region from camera position
        // For now, use a default region since extracting from MapCameraPosition can be complex
        // You can set this to your preferred search region
        request.region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 50.450001, longitude: 30.523333),
            span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
        )
        
        let search = MKLocalSearch(request: request)
        search.start { response, error in
            DispatchQueue.main.async {
                self.isSearching = false
                
                if let error = error {
                    print("Search error: \(error.localizedDescription)")
                    return
                }
                
                guard let response = response else {
                    print("No search response")
                    return
                }
                
                self.searchResults = response.mapItems.compactMap { item in
                    guard let name = item.name else { return nil }
                    
                    let coordinate = item.placemark.coordinate
                    let address = self.formatAddress(from: item.placemark)
                    
                    return LocationDetails(
                        id: UUID().uuidString,
                        name: name,
                        address: address,
                        coordinate: coordinate
                    )
                }
                
                // Show results on map
                if !self.searchResults.isEmpty {
                    self.focusMapOnResults()
                }
            }
        }
    }
    
    private func selectLocation(_ location: LocationDetails) {
        selectedLocation = location
        searchText = ""
        searchResults = []
        
        // Center map on selected location
        withAnimation {
            cameraPosition = .region(
                MKCoordinateRegion(
                    center: location.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                )
            )
        }
    }
    
    private func focusMapOnResults() {
        guard !searchResults.isEmpty else { return }
        
        let coordinates = searchResults.map { $0.coordinate }
        
        if coordinates.count == 1 {
            withAnimation {
                cameraPosition = .region(
                    MKCoordinateRegion(
                        center: coordinates[0],
                        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                    )
                )
            }
            return
        }
        
        let minLat = coordinates.map { $0.latitude }.min() ?? 0
        let maxLat = coordinates.map { $0.latitude }.max() ?? 0
        let minLon = coordinates.map { $0.longitude }.min() ?? 0
        let maxLon = coordinates.map { $0.longitude }.max() ?? 0
        
        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )
        
        let span = MKCoordinateSpan(
            latitudeDelta: max((maxLat - minLat) * 1.3, 0.01),
            longitudeDelta: max((maxLon - minLon) * 1.3, 0.01)
        )
        
        withAnimation {
            cameraPosition = .region(MKCoordinateRegion(center: center, span: span))
        }
    }
    
    private func requestUserLocation() {
        let locationManager = CLLocationManager()
        
        switch locationManager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            if let userLocation = locationManager.location {
                DispatchQueue.main.async {
                    self.cameraPosition = .region(
                        MKCoordinateRegion(
                            center: userLocation.coordinate,
                            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                        )
                    )
                }
            }
            
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
            
        default:
            break
        }
    }
    
    private func formatAddress(from placemark: CLPlacemark) -> String {
        var addressComponents: [String] = []
        
        if let subThoroughfare = placemark.subThoroughfare {
            addressComponents.append(subThoroughfare)
        }
        
        if let thoroughfare = placemark.thoroughfare {
            addressComponents.append(thoroughfare)
        }
        
        if let locality = placemark.locality {
            addressComponents.append(locality)
        }
        
        if let administrativeArea = placemark.administrativeArea {
            addressComponents.append(administrativeArea)
        }
        
        if let country = placemark.country {
            addressComponents.append(country)
        }
        
        return addressComponents.isEmpty ? NSLocalizedString("Unknown address", comment: "Unknown address fallback text") : addressComponents.joined(separator: ", ")
    }
}

// MARK: - LocationDetails Model

struct LocationDetails: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let address: String
    let coordinate: CLLocationCoordinate2D
    
    enum CodingKeys: String, CodingKey {
        case id, name, address, latitude, longitude
    }
    
    init(id: String, name: String, address: String, coordinate: CLLocationCoordinate2D) {
        self.id = id
        self.name = name
        self.address = address
        self.coordinate = coordinate
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        address = try container.decode(String.self, forKey: .address)
        let latitude = try container.decode(Double.self, forKey: .latitude)
        let longitude = try container.decode(Double.self, forKey: .longitude)
        coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(address, forKey: .address)
        try container.encode(coordinate.latitude, forKey: .latitude)
        try container.encode(coordinate.longitude, forKey: .longitude)
    }
    
    static func == (lhs: LocationDetails, rhs: LocationDetails) -> Bool {
        return lhs.id == rhs.id
    }
}
