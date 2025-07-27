//
//  EventMapPreview.swift
//  BandSync
//
//  Created by Oleksandr Kuziakin on 02.04.2025.
//

import SwiftUI
import MapKit

struct EventMapPreview: View {
    let event: Event
    
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var mapPoints: [EventMapPoint] = []
    @State private var isLoading = true
    
    var body: some View {
        ZStack {
            Map(position: $cameraPosition) {
                ForEach(mapPoints, id: \.id) { point in
                    Annotation(point.title, coordinate: point.coordinate) {
                        ZStack {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 20, height: 20)
                            Circle()
                                .stroke(Color.white, lineWidth: 2)
                                .frame(width: 20, height: 20)
                        }
                    }
                }
            }
            .mapStyle(.standard)
            
            if isLoading {
                ProgressView()
                    .padding(8)
                    .background(Color.white.opacity(0.8))
                    .cornerRadius(8)
            }
        }
        .onAppear {
            geocodeEventLocation()
        }
    }
    
    private func geocodeEventLocation() {
        isLoading = true
        
        guard let locationString = event.location, !locationString.isEmpty else {
            isLoading = false
            return
        }
        
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(locationString) { placemarks, error in
            if error != nil {
                isLoading = false
                return
            }
            
            guard let placemark = placemarks?.first, let location = placemark.location else {
                isLoading = false
                return
            }
            
            let coordinate = location.coordinate
            let name = placemark.name ?? "Venue"
            
            let newAnnotation = EventMapPoint(
                id: UUID().uuidString,
                title: name,
                coordinate: coordinate
            )
            
            DispatchQueue.main.async {
                cameraPosition = .region(MKCoordinateRegion(
                    center: coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
                ))
                mapPoints = [newAnnotation]
                isLoading = false
            }
        }
    }
    
    private func formatAddress(from placemark: CLPlacemark) -> String {
        var addressComponents: [String] = []
        
        if let subThoroughfare = placemark.subThoroughfare,
           let thoroughfare = placemark.thoroughfare {
            addressComponents.append("\(subThoroughfare) \(thoroughfare)")
        } else if let thoroughfare = placemark.thoroughfare {
            addressComponents.append(thoroughfare)
        }
        
        if let locality = placemark.locality {
            addressComponents.append(locality)
        }
        
        if let administrativeArea = placemark.administrativeArea {
            addressComponents.append(administrativeArea)
        }
        
        return addressComponents.isEmpty ? "Unknown address" : addressComponents.joined(separator: ", ")
    }
}
