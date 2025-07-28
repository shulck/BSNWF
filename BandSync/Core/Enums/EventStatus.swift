
import Foundation
import SwiftUI

enum EventStatus: String, Codable, CaseIterable, Identifiable {
    case booked = "Booked"
    case confirmed = "Confirmed"
    case cancelled = "Cancelled"
    case postponed = "Postponed"
    case pending = "Pending"

    var id: String { rawValue }
    
    // Add color property
    var color: Color {
        switch self {
        case .booked:
            return .red
        case .confirmed:
            return .green
        case .cancelled:
            return .gray
        case .postponed:
            return .orange
        case .pending:
            return .blue
        }
    }
    
    // For UIKit compatibility, if needed
    var uiColor: UIColor {
        switch self {
        case .booked:
            return UIColor.systemRed
        case .confirmed:
            return UIColor.systemGreen
        case .cancelled:
            return UIColor.systemGray
        case .postponed:
            return UIColor.systemOrange
        case .pending:
            return UIColor.systemBlue
        }
    }
    
    // Hex value for integration with existing color system, if needed
    var colorHex: String {
        switch self {
        case .booked:
            return "#FF3B30" // Standard iOS red color
        case .confirmed:
            return "#34C759" // Standard iOS green color
        case .cancelled:
            return "#8E8E93" // Standard iOS gray color
        case .postponed:
            return "#FF9500" // Standard iOS orange color
        case .pending:
            return "#007AFF" // Standard iOS blue color
        }
    }
}
