import Foundation

enum EventType: String, Codable, CaseIterable {
    case concert = "Concert"
    case festival = "Festival"
    case rehearsal = "Rehearsal"
    case meeting = "Meeting"
    case interview = "Interview"
    case photoshoot = "Photoshoot"
    case personal = "Personal"
    case birthday = "Birthday"
    case checkin = "Checkin"
    case checkout = "Checkout"
    case stay = "Stay"
    case other = "Other"
    
    var colorHex: String {
        switch self {
        case .concert: return "FF0000"
        case .festival: return "FF8C00"
        case .rehearsal: return "00FF00"
        case .meeting: return "0000FF"
        case .interview: return "8A2BE2"
        case .photoshoot: return "00FFFF"
        case .personal: return "FFD700"
        case .birthday: return "FF69B4"
        case .checkin: return "32CD32"
        case .checkout: return "32CD32"
        case .stay: return "32CD32"
        case .other: return "008B8B"
        }
    }
    
    var icon: String {
        switch self {
        case .concert: return "music.mic"
        case .festival: return "music.note.list"
        case .rehearsal: return "music.quarternote.3"
        case .meeting: return "person.3"
        case .interview: return "mic"
        case .photoshoot: return "camera"
        case .personal: return "person"
        case .birthday: return "gift"
        case .checkin: return "arrow.down.to.line"
        case .checkout: return "arrow.up.from.line"
        case .stay: return "bed.double"
        case .other: return "ellipsis.circle"
        }
    }
}

