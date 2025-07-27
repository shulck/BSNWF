import Foundation

extension String {
    var localized: String {
        return NSLocalizedString(self, comment: "")
    }
    
    // Ukrainian pluralization for "song" (пісня)
    static func ukrainianSongsPlural(count: Int) -> String {
        let languageCode: String
        if #available(iOS 16, *) {
            languageCode = Locale.current.language.languageCode?.identifier ?? "en"
        } else {
            languageCode = Locale.current.languageCode ?? "en"
        }
        
        if languageCode == "uk" {
            if count == 1 {
                return "пісня"
            } else if count >= 2 && count <= 4 {
                return "пісні"
            } else {
                return "пісень"
            }
        } else {
            // For other languages, use the standard localized string
            return NSLocalizedString("songs", comment: "")
        }
    }
}
