import SwiftUI
import MapKit
import UIKit

class NavigationService {
    static let shared = NavigationService()
    
    private init() {}
    
    // MARK: - Helper Methods
    
    private func getRootViewController() -> UIViewController? {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return nil
        }
        return window.rootViewController
    }
    
    private func getScreenBounds() -> CGRect {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return UIScreen.main.bounds
        }
        return window.bounds
    }
    
    func navigateToAddress(_ address: String, name: String) {
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(address) { placemarks, error in
            guard let placemark = placemarks?.first, let location = placemark.location else {
                self.openAppleMapsDirectly(address: address)
                return
            }
            
            self.showMapSelectionDialog(coordinate: location.coordinate, name: name)
        }
    }
    
    private func showMapSelectionDialog(coordinate: CLLocationCoordinate2D, name: String) {
        let alert = UIAlertController(
            title: "Select application".localized,
            message: "Which application to use for navigation?".localized,
            preferredStyle: .actionSheet
        )
        
        alert.addAction(UIAlertAction(title: "Apple Maps".localized, style: .default) { _ in
            self.openInAppleMaps(coordinate: coordinate, name: name)
        })
        
        alert.addAction(UIAlertAction(title: "Google Maps".localized, style: .default) { _ in
            self.openInGoogleMaps(coordinate: coordinate, name: name)
        })
        
        alert.addAction(UIAlertAction(title: "Cancel".localized, style: .cancel))
        
        if let popover = alert.popoverPresentationController {
            popover.sourceView = getRootViewController()?.view
            let screenBounds = getScreenBounds()
            popover.sourceRect = CGRect(
                x: screenBounds.width / 2,
                y: screenBounds.height / 2,
                width: 0,
                height: 0
            )
            popover.permittedArrowDirections = []
        }
        
        DispatchQueue.main.async {
            guard let rootViewController = self.getRootViewController() else {
                return
            }
            
            var topController = rootViewController
            while let presentedController = topController.presentedViewController {
                topController = presentedController
            }
            
            topController.present(alert, animated: true)
        }
    }
    
    private func isGoogleMapsInstalled() -> Bool {
        guard URL(string: "comgooglemaps://") != nil else {
            return false
        }
        
        return true
    }
    
    private func openAppleMapsDirectly(address: String) {
        let encodedAddress = address.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let appleURL = URL(string: "http://maps.apple.com/?daddr=\(encodedAddress)&dirflg=d")!
        
        if UIApplication.shared.canOpenURL(appleURL) {
            UIApplication.shared.open(appleURL)
        }
    }
    
    private func openInAppleMaps(coordinate: CLLocationCoordinate2D, name: String) {
        let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: coordinate))
        mapItem.name = name
        mapItem.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving])
    }
    
    private func openInGoogleMaps(coordinate: CLLocationCoordinate2D, name: String) {
        let encodedName = name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        
        let safariURLString = "https://www.google.com/maps/dir/?api=1&destination=\(coordinate.latitude),\(coordinate.longitude)&travelmode=driving"
        
        let googleMapsURLString = "comgooglemaps://?daddr=\(coordinate.latitude),\(coordinate.longitude)&directionsmode=driving&q=\(encodedName)"
        
        if let googleMapsURL = URL(string: googleMapsURLString), UIApplication.shared.canOpenURL(googleMapsURL) {
            UIApplication.shared.open(googleMapsURL)
        } else if let safariURL = URL(string: safariURLString) {
            UIApplication.shared.open(safariURL)
        }
    }
    
    func navigateToCoordinate(_ coordinate: CLLocationCoordinate2D, name: String) {
        showMapSelectionDialog(coordinate: coordinate, name: name)
    }
}

struct NavigationServiceHost: UIViewControllerRepresentable {
    let perform: (UIViewController) -> Void
    
    func makeUIViewController(context: Context) -> UIViewController {
        return UIViewController()
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        perform(uiViewController)
    }
}
