import Foundation

// MARK: - Currency Support
enum Currency: String, CaseIterable, Identifiable {
    case usd = "USD"
    case eur = "EUR"
    case uah = "UAH"
    case gbp = "GBP"
    case cad = "CAD"
    case aud = "AUD"
    case chf = "CHF"
    case jpy = "JPY"
    case pln = "PLN"
    case czk = "CZK"
    case sek = "SEK"
    case nok = "NOK"
    case dkk = "DKK"
    
    var id: String { self.rawValue }
    
    var symbol: String {
        switch self {
        case .usd, .cad, .aud: return "$"
        case .eur: return "€"
        case .uah: return "₴"
        case .gbp: return "£"
        case .chf: return "₣"
        case .jpy: return "¥"
        case .pln: return "zł"
        case .czk: return "Kč"
        case .sek: return "kr"
        case .nok: return "kr"
        case .dkk: return "kr"
        }
    }
    
    var name: String {
        switch self {
        case .usd: return NSLocalizedString("US Dollar", comment: "US Dollar currency name")
        case .eur: return NSLocalizedString("Euro", comment: "Euro currency name")
        case .uah: return NSLocalizedString("Ukrainian Hryvnia", comment: "Ukrainian Hryvnia currency name")
        case .gbp: return NSLocalizedString("British Pound", comment: "British Pound currency name")
        case .cad: return NSLocalizedString("Canadian Dollar", comment: "Canadian Dollar currency name")
        case .aud: return NSLocalizedString("Australian Dollar", comment: "Australian Dollar currency name")
        case .chf: return NSLocalizedString("Swiss Franc", comment: "Swiss Franc currency name")
        case .jpy: return NSLocalizedString("Japanese Yen", comment: "Japanese Yen currency name")
        case .pln: return NSLocalizedString("Polish Złoty", comment: "Polish Złoty currency name")
        case .czk: return NSLocalizedString("Czech Koruna", comment: "Czech Koruna currency name")
        case .sek: return NSLocalizedString("Swedish Krona", comment: "Swedish Krona currency name")
        case .nok: return NSLocalizedString("Norwegian Krone", comment: "Norwegian Krone currency name")
        case .dkk: return NSLocalizedString("Danish Krone", comment: "Danish Krone currency name")
        }
    }
    
    var flag: String {
        switch self {
        case .usd: return "🇺🇸"
        case .eur: return "🇪🇺"
        case .uah: return "🇺🇦"
        case .gbp: return "🇬🇧"
        case .cad: return "🇨🇦"
        case .aud: return "🇦🇺"
        case .chf: return "🇨🇭"
        case .jpy: return "🇯🇵"
        case .pln: return "🇵🇱"
        case .czk: return "🇨🇿"
        case .sek: return "🇸🇪"
        case .nok: return "🇳🇴"
        case .dkk: return "🇩🇰"
        }
    }
    
    // MARK: - UserDefaults Support
    private static let userDefaultsKey = "selectedCurrency"
    
    /// Saves the selected currency to UserDefaults
    func save() {
        UserDefaults.standard.set(self.rawValue, forKey: Currency.userDefaultsKey)
    }
    
    /// Loads the saved currency from UserDefaults, returns USD if none saved
    static func loadSaved() -> Currency {
        let savedRawValue = UserDefaults.standard.string(forKey: userDefaultsKey)
        if let savedRawValue = savedRawValue,
           let savedCurrency = Currency(rawValue: savedRawValue) {
            return savedCurrency
        }
        return .usd // Default fallback
    }
}
