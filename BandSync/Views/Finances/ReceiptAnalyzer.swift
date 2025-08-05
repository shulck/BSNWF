// ReceiptAnalyzer.swift

import Foundation
import NaturalLanguage
import Vision

class ReceiptAnalyzer {
    
    struct ReceiptData {
        var amount: Double?
        var date: Date?
        var merchantName: String?
        var category: String?
        var items: [String]
        
        init(amount: Double? = nil, date: Date? = nil, merchantName: String? = nil, category: String? = nil, items: [String] = []) {
            self.amount = amount
            self.date = date
            self.merchantName = merchantName
            self.category = category
            self.items = items
        }
    }
    
    static func analyze(text: String) -> ReceiptData {
        let lines = text.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        // Enhanced TOTAL amount extraction
        let amount = extractTotalAmountV2(from: lines, fullText: text)
        let date = extractDate(from: lines)
        let merchantName = extractMerchantName(from: lines)
        let items = extractItems(from: lines)
        let category = determineCategory(items: items, merchantName: merchantName)
        
        return ReceiptData(
            amount: amount,
            date: date,
            merchantName: merchantName,
            category: category,
            items: items
        )
    }
    
    // New method for finding TOTAL amount
    private static func extractTotalAmountV2(from lines: [String], fullText: String) -> Double? {
        // 1. Special logic for Deutsche Post
        if fullText.lowercased().contains("deutsche post") {
            return extractDeutschePostTotalAmount(from: lines, fullText: fullText)
        }
        
        // 2. General logic for other receipts
        return extractTotalAmountGeneral(from: lines)
    }
    
    // Enhanced logic for Deutsche Post - looks for TOTAL amount
    private static func extractDeutschePostTotalAmount(from lines: [String], fullText: String) -> Double? {
        // Keywords for total amounts in Deutsche Post
        let totalKeywords = [
            NSLocalizedString("nettoumsatz", comment: "Net revenue keyword for receipt analysis"),
            NSLocalizedString("bruttoumsatz", comment: "Gross revenue keyword for receipt analysis"), 
            NSLocalizedString("girocard", comment: "Girocard payment keyword for receipt analysis"),
            NSLocalizedString("gesamt", comment: "Total keyword for receipt analysis"),
            NSLocalizedString("total", comment: "Total keyword for receipt analysis"),
            NSLocalizedString("zu zahlen", comment: "Amount to pay keyword for receipt analysis"),
            NSLocalizedString("summe", comment: "Sum keyword for receipt analysis"),
            NSLocalizedString("betrag", comment: "Amount keyword for receipt analysis"),
            NSLocalizedString("endpreis", comment: "Final price keyword for receipt analysis")
        ]
        
        var candidates: [(amount: Double, keyword: String, priority: Int)] = []
        
        // 1. Look for amounts near keywords for total
        for line in lines {
            let lowercasedLine = line.lowercased()
            
            // Check each keyword
            for keyword in totalKeywords {
                if lowercasedLine.contains(keyword) {
                    // Priority for different keywords
                    var priority = 0
                    switch keyword {
                    case "nettoumsatz": priority = 10 // Highest priority
                    case "bruttoumsatz": priority = 9
                    case "girocard": priority = 8
                    case "gesamt", "total": priority = 7
                    case "zu zahlen": priority = 6
                    default: priority = 5
                    }
                    
                    // Look for numbers in this line
                    if let amounts = extractAllAmountsFromLine(line) {
                        for amount in amounts {
                            candidates.append((amount: amount, keyword: keyword, priority: priority))
                        }
                    }
                    
                    // Also check next line
                    if let nextLineIndex = lines.firstIndex(of: line),
                       nextLineIndex + 1 < lines.count {
                        let nextLine = lines[nextLineIndex + 1]
                        if let amounts = extractAllAmountsFromLine(nextLine) {
                            for amount in amounts {
                                candidates.append((amount: amount, keyword: keyword + NSLocalizedString(" (next line)", comment: "Indicator that amount was found on next line"), priority: priority - 1))
                            }
                        }
                    }
                }
            }
        }
        
        // 2. If nothing found by keywords, look for largest reasonable amount
        if candidates.isEmpty {
            var allAmounts: [Double] = []
            
            for line in lines {
                if let amounts = extractAllAmountsFromLine(line) {
                    allAmounts.append(contentsOf: amounts)
                }
            }
            
            // Filter reasonable amounts and take the largest
            let reasonableAmounts = allAmounts.filter { $0 >= 1.0 && $0 <= 1000.0 }
            if let maxAmount = reasonableAmounts.max() {
                return maxAmount
            }
        }
        
        // 3. Choose best candidate by priority
        let sortedCandidates = candidates.sorted {
            if $0.priority != $1.priority {
                return $0.priority > $1.priority
            }
            return $0.amount > $1.amount // When priority is equal - higher amount
        }
        
        if let best = sortedCandidates.first {
            return best.amount
        }
        
        return nil
    }
    
    // General logic for finding total amounts
    private static func extractTotalAmountGeneral(from lines: [String]) -> Double? {
        // Keywords for total amounts
        let totalKeywords = [
            NSLocalizedString("total", comment: "Total keyword for receipt analysis"),
            NSLocalizedString("sum", comment: "Sum keyword for receipt analysis"),
            NSLocalizedString("amount", comment: "Amount keyword for receipt analysis"),
            NSLocalizedString("due", comment: "Due keyword for receipt analysis"),
            NSLocalizedString("balance", comment: "Balance keyword for receipt analysis"),
            NSLocalizedString("pay", comment: "Pay keyword for receipt analysis"),
            NSLocalizedString("итого", comment: "Total keyword in Russian for receipt analysis"),
            NSLocalizedString("сумма", comment: "Sum keyword in Russian for receipt analysis"),
            NSLocalizedString("к оплате", comment: "To pay keyword in Russian for receipt analysis"),
            NSLocalizedString("betrag", comment: "Amount keyword in German for receipt analysis"),
            NSLocalizedString("gesamt", comment: "Total keyword in German for receipt analysis"),
            NSLocalizedString("netto", comment: "Net keyword in German for receipt analysis"),
            NSLocalizedString("brutto", comment: "Gross keyword in German for receipt analysis"),
            NSLocalizedString("endpreis", comment: "Final price keyword in German for receipt analysis"),
            NSLocalizedString("zu zahlen", comment: "To pay keyword in German for receipt analysis")
        ]
        
        var candidates: [(amount: Double, priority: Int)] = []
        
        // Look for amounts near keywords
        for (index, line) in lines.enumerated() {
            let lowercasedLine = line.lowercased()
            
            var priority = 0
            
            // High priority for keywords
            for keyword in totalKeywords {
                if lowercasedLine.contains(keyword) {
                    priority += 10
                    break
                }
            }
            
            // Medium priority for lines at end of receipt
            if index >= lines.count - 5 {
                priority += 5
            }
            
            // Bonus for currency symbols
            if lowercasedLine.contains("€") || lowercasedLine.contains("eur") || lowercasedLine.contains("$") {
                priority += 3
            }
            
            if let amounts = extractAllAmountsFromLine(line) {
                for amount in amounts {
                    candidates.append((amount: amount, priority: priority))
                }
            }
        }
        
        // Sort by priority and choose best
        let sortedCandidates = candidates.sorted {
            if $0.priority != $1.priority {
                return $0.priority > $1.priority
            }
            return $0.amount > $1.amount
        }
        
        if let best = sortedCandidates.first {
            return best.amount
        }
        
        return nil
    }
    
    // Helper method - extracts ALL amounts from a line
    private static func extractAllAmountsFromLine(_ line: String) -> [Double]? {
        let patterns = [
            "([€$£]?)\\s*(\\d{1,4}[.,]\\d{2})\\s*([€$£]?)", // With currency symbols
            "(\\d{1,4}[.,]\\d{2})", // Regular numbers
        ]
        
        var amounts: [Double] = []
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
                let range = NSRange(location: 0, length: line.count)
                let matches = regex.matches(in: line, options: [], range: range)
                
                for match in matches {
                    let matchString = (line as NSString).substring(with: match.range)
                    let cleanedString = matchString.replacingOccurrences(of: "[€$£]", with: "", options: .regularExpression)
                        .replacingOccurrences(of: ",", with: ".")
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    if let amount = Double(cleanedString), amount > 0.01 && amount < 10000 {
                        amounts.append(amount)
                    }
                }
            }
        }
        
        return amounts.isEmpty ? nil : amounts
    }
    
    // Other methods remain unchanged
    private static func extractDate(from lines: [String]) -> Date? {
        // Look for lines that may contain date
        let possibleDateLines = lines.filter { line in
            let lowercased = line.lowercased()
            return lowercased.contains(NSLocalizedString("date", comment: "Date keyword for receipt analysis").lowercased()) ||
                   lowercased.contains(NSLocalizedString("time", comment: "Time keyword for receipt analysis").lowercased()) ||
                   lowercased.contains(NSLocalizedString("receipt", comment: "Receipt keyword for receipt analysis").lowercased()) ||
                   lowercased.contains(NSLocalizedString("transaction", comment: "Transaction keyword for receipt analysis").lowercased()) ||
                   lowercased.contains(NSLocalizedString("purchase", comment: "Purchase keyword for receipt analysis").lowercased()) ||
                   lowercased.contains("datum") || // German
                   lowercased.contains("zeit") || // German
                   lowercased.contains("дата") || // Russian
                   lowercased.contains("время") || // Russian
                   lowercased.contains("покупка") // Russian
        }
        
        // Date formats that might be in the receipt
        let dateFormatters: [DateFormatter] = [
            createDateFormatter(format: "MM/dd/yyyy"),
            createDateFormatter(format: "MM/dd/yy"),
            createDateFormatter(format: "dd/MM/yyyy"),
            createDateFormatter(format: "dd/MM/yy"),
            createDateFormatter(format: "yyyy-MM-dd"),
            createDateFormatter(format: "MM-dd-yyyy"),
            createDateFormatter(format: "dd-MM-yyyy"),
            createDateFormatter(format: "MM.dd.yyyy"),
            createDateFormatter(format: "dd.MM.yyyy"),
            createDateFormatter(format: "MMM dd, yyyy"),
            createDateFormatter(format: "MMMM dd, yyyy"),
            createDateFormatter(format: "MM/dd/yyyy HH:mm"),
            createDateFormatter(format: "MM/dd/yy HH:mm"),
            createDateFormatter(format: "dd.MM.yy")
        ]
        
        // Improved regex for dates
        let dateRegex = try? NSRegularExpression(pattern: "(\\d{1,2}[./-]\\d{1,2}[./-]\\d{2,4})|(\\d{4}[./-]\\d{1,2}[./-]\\d{1,2})", options: [])
        
        // First check specific lines
        for line in possibleDateLines {
            if let date = extractDateValue(from: line, using: dateRegex, formatters: dateFormatters) {
                return date
            }
        }
        
        // If not found, check all lines
        for line in lines {
            if let date = extractDateValue(from: line, using: dateRegex, formatters: dateFormatters) {
                return date
            }
        }
        
        // If all else fails, use today's date
        return Date()
    }
    
    private static func createDateFormatter(format: String) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        formatter.locale = Locale(identifier: "en_US")
        return formatter
    }
    
    private static func extractDateValue(from line: String, using regex: NSRegularExpression?, formatters: [DateFormatter]) -> Date? {
        guard let regex = regex else { return nil }
        
        let nsString = line as NSString
        let range = NSRange(location: 0, length: nsString.length)
        
        // Find all matches with regex
        let matches = regex.matches(in: line, options: [], range: range)
        
        for match in matches {
            let matchedString = nsString.substring(with: match.range)
            
            // Try different formats
            for formatter in formatters {
                if let date = formatter.date(from: matchedString) {
                    return date
                }
            }
        }
        
        // Try to find today's or yesterday's date
        let today = Date()
        let calendar = Calendar.current
        
        // If receipt contains "today"
        if line.lowercased().contains(NSLocalizedString("today", comment: "Today keyword for receipt analysis").lowercased()) ||
           line.lowercased().contains("heute") || // German
           line.lowercased().contains("сегодня") { // Russian
            return today
        }
        
        // If receipt contains "yesterday"
        if line.lowercased().contains(NSLocalizedString("yesterday", comment: "Yesterday keyword for receipt analysis").lowercased()) ||
           line.lowercased().contains("gestern") || // German
           line.lowercased().contains("вчера") { // Russian
            return calendar.date(byAdding: .day, value: -1, to: today)
        }
        
        return nil
    }
    
    private static func extractMerchantName(from lines: [String]) -> String? {
        // Usually merchant name is at the beginning of the receipt
        if !lines.isEmpty {
            // Take first few lines and look for the longest one
            let topLines = Array(lines.prefix(5))
            var merchantName: String?
            var maxLength = 0
            
            for line in topLines {
                // Ignore lines that look like date or address
                if line.contains("/") || line.contains("@") || 
                   line.contains(NSLocalizedString("Tel:", comment: "Telephone prefix for receipt analysis")) ||
                   line.contains(NSLocalizedString("Phone:", comment: "Phone prefix for receipt analysis")) || 
                   line.contains(NSLocalizedString("Address:", comment: "Address prefix for receipt analysis")) || 
                   line.contains("ID:") ||
                   line.lowercased().contains(NSLocalizedString("receipt", comment: "Receipt keyword for merchant name analysis").lowercased()) ||
                   line.contains("www.") || line.contains("http") ||
                   line.contains("Telefon:") || // German
                   line.contains("Adresse:") || // German
                   line.contains("Тел:") || // Russian
                   line.contains("Адрес:") { // Russian
                    continue
                }
                
                if line.count > maxLength {
                    maxLength = line.count
                    merchantName = line
                }
            }
            
            return merchantName
        }
        
        return nil
    }
    
    private static func extractItems(from lines: [String]) -> [String] {
        var items: [String] = []
        var isItemSection = false
        
        // Markers for beginning and end of items section
        let startMarkers = [
            NSLocalizedString("item", comment: "Item keyword for receipt analysis").lowercased(),
            NSLocalizedString("description", comment: "Description keyword for receipt analysis").lowercased(),
            NSLocalizedString("product", comment: "Product keyword for receipt analysis").lowercased(),
            NSLocalizedString("quantity", comment: "Quantity keyword for receipt analysis").lowercased(),
            NSLocalizedString("qty", comment: "Quantity abbreviation for receipt analysis").lowercased(),
            NSLocalizedString("price", comment: "Price keyword for receipt analysis").lowercased(),
            "artikel", "beschreibung", "produkt", "menge", "preis", // German
            "товар", "описание", "продукт", "количество", "цена" // Russian
        ]
        let endMarkers = [
            NSLocalizedString("total", comment: "Total keyword for items section end").lowercased(),
            NSLocalizedString("subtotal", comment: "Subtotal keyword for items section end").lowercased(),
            NSLocalizedString("sub-total", comment: "Sub-total keyword for items section end").lowercased(),
            NSLocalizedString("amount", comment: "Amount keyword for items section end").lowercased(),
            NSLocalizedString("balance", comment: "Balance keyword for items section end").lowercased(),
            NSLocalizedString("due", comment: "Due keyword for items section end").lowercased(),
            NSLocalizedString("sum", comment: "Sum keyword for items section end").lowercased(),
            NSLocalizedString("tax", comment: "Tax keyword for items section end").lowercased(),
            NSLocalizedString("vat", comment: "VAT keyword for items section end").lowercased(),
            "gesamt", "zwischensumme", "betrag", "steuer", "mwst", // German
            "итого", "промежуточная сумма", "сумма", "налог", "ндс" // Russian
        ]
        
        for line in lines {
            let lowercasedLine = line.lowercased()
            
            // Check for start of items section
            if !isItemSection {
                let isStart = startMarkers.contains { lowercasedLine.contains($0) }
                if isStart {
                    isItemSection = true
                    continue
                }
            }
            
            // Check for end of items section
            if isItemSection {
                let isEnd = endMarkers.contains { lowercasedLine.contains($0) }
                if isEnd {
                    break
                }
                
                // Ignore lines with quantity, price etc.
                if lowercasedLine.contains(NSLocalizedString("qty", comment: "Quantity abbreviation for filtering").lowercased()) || 
                   lowercasedLine.contains(" x ") ||
                   lowercasedLine.contains("$") || lowercasedLine.contains("€") ||
                   (lowercasedLine.contains(NSLocalizedString("quantity", comment: "Quantity keyword for filtering").lowercased()) && 
                    lowercasedLine.contains(NSLocalizedString("price", comment: "Price keyword for filtering").lowercased())) ||
                   lowercasedLine.contains("menge") || // German
                   lowercasedLine.contains("preis") || // German
                   lowercasedLine.contains("количество") || // Russian
                   lowercasedLine.contains("цена") { // Russian
                    continue
                }
                
                // Add line as item if it's not empty and long enough
                if !line.isEmpty && line.count > 3 {
                    items.append(line)
                }
            }
        }
        
        // If no items found through markers, try heuristic approach
        if items.isEmpty {
            // Look for lines that look like items (don't contain special words)
            let blockedWords = [
                NSLocalizedString("receipt", comment: "Receipt keyword for item filtering").lowercased(),
                NSLocalizedString("store", comment: "Store keyword for item filtering").lowercased(),
                NSLocalizedString("date", comment: "Date keyword for item filtering").lowercased(),
                NSLocalizedString("time", comment: "Time keyword for item filtering").lowercased(),
                NSLocalizedString("total", comment: "Total keyword for item filtering").lowercased(),
                NSLocalizedString("amount", comment: "Amount keyword for item filtering").lowercased(),
                NSLocalizedString("payment", comment: "Payment keyword for item filtering").lowercased(),
                NSLocalizedString("cashier", comment: "Cashier keyword for item filtering").lowercased(),
                NSLocalizedString("thank", comment: "Thank keyword for item filtering").lowercased(),
                NSLocalizedString("you", comment: "You keyword for item filtering").lowercased(),
                NSLocalizedString("discount", comment: "Discount keyword for item filtering").lowercased(),
                NSLocalizedString("tax", comment: "Tax keyword for item filtering").lowercased(),
                "id", "address", "number", "phone", "welcome", "order",
                // German
                "geschäft", "laden", "datum", "zeit", "gesamt", "betrag", 
                "zahlung", "kassierer", "danke", "rabatt", "steuer",
                "willkommen", "bestellung",
                // Russian
                "магазин", "дата", "время", "итого", "сумма", "платеж",
                "кассир", "спасибо", "скидка", "налог", "добро пожаловать", "заказ"
            ]
            
            for line in lines {
                let lowercasedLine = line.lowercased()
                let containsBlockedWord = blockedWords.contains { lowercasedLine.contains($0) }
                
                if !containsBlockedWord && !line.isEmpty && line.count > 3 {
                    items.append(line)
                }
            }
        }
        
        return items
    }
    
    private static func determineCategory(items: [String], merchantName: String?) -> String? {
        // Map keywords to FinanceCategory values
        let categoryKeywords: [String: FinanceCategory] = [
            // Food category
            NSLocalizedString("restaurant", comment: "Restaurant keyword for category detection").lowercased(): .food,
            NSLocalizedString("cafe", comment: "Cafe keyword for category detection").lowercased(): .food,
            NSLocalizedString("pizza", comment: "Pizza keyword for category detection").lowercased(): .food,
            NSLocalizedString("sushi", comment: "Sushi keyword for category detection").lowercased(): .food,
            NSLocalizedString("food", comment: "Food keyword for category detection").lowercased(): .food,
            NSLocalizedString("grocery", comment: "Grocery keyword for category detection").lowercased(): .food,
            NSLocalizedString("supermarket", comment: "Supermarket keyword for category detection").lowercased(): .food,
            NSLocalizedString("bread", comment: "Bread keyword for category detection").lowercased(): .food,
            NSLocalizedString("milk", comment: "Milk keyword for category detection").lowercased(): .food,
            NSLocalizedString("coffee", comment: "Coffee keyword for category detection").lowercased(): .food,
            NSLocalizedString("burger", comment: "Burger keyword for category detection").lowercased(): .food,
            // German food keywords
            "restaurant": .food, "kaffee": .food, "bäckerei": .food, "supermarkt": .food,
            "essen": .food, "getränk": .food, "brot": .food, "milch": .food,
            // Russian food keywords
            "ресторан": .food, "кафе": .food, "пицца": .food, "еда": .food,
            "продукты": .food, "супермаркет": .food, "хлеб": .food, "молоко": .food,
            "кофе": .food, "бургер": .food,
            
            // Logistics category
            NSLocalizedString("taxi", comment: "Taxi keyword for category detection").lowercased(): .logistics,
            NSLocalizedString("metro", comment: "Metro keyword for category detection").lowercased(): .logistics,
            NSLocalizedString("bus", comment: "Bus keyword for category detection").lowercased(): .logistics,
            NSLocalizedString("train", comment: "Train keyword for category detection").lowercased(): .logistics,
            NSLocalizedString("subway", comment: "Subway keyword for category detection").lowercased(): .logistics,
            NSLocalizedString("ticket", comment: "Ticket keyword for category detection").lowercased(): .logistics,
            NSLocalizedString("transit", comment: "Transit keyword for category detection").lowercased(): .logistics,
            NSLocalizedString("gas", comment: "Gas keyword for category detection").lowercased(): .logistics,
            NSLocalizedString("fuel", comment: "Fuel keyword for category detection").lowercased(): .logistics,
            NSLocalizedString("parking", comment: "Parking keyword for category detection").lowercased(): .logistics,
            NSLocalizedString("uber", comment: "Uber keyword for category detection").lowercased(): .logistics,
            NSLocalizedString("post", comment: "Post keyword for category detection").lowercased(): .logistics,
            // German logistics keywords
            "taxi": .logistics, "u-bahn": .logistics, "bahn": .logistics, "zug": .logistics,
            "ticket": .logistics, "benzin": .logistics, "tanken": .logistics, "parken": .logistics,
            "post": .logistics, "transport": .logistics,
            // Russian logistics keywords
            "такси": .logistics, "метро": .logistics, "автобус": .logistics, "поезд": .logistics,
            "билет": .logistics, "транспорт": .logistics, "бензин": .logistics, "топливо": .logistics,
            "парковка": .logistics, "почта": .logistics,
            
            // Accommodation category
            NSLocalizedString("hotel", comment: "Hotel keyword for category detection").lowercased(): .accommodation,
            NSLocalizedString("apartment", comment: "Apartment keyword for category detection").lowercased(): .accommodation,
            NSLocalizedString("room", comment: "Room keyword for category detection").lowercased(): .accommodation,
            NSLocalizedString("hostel", comment: "Hostel keyword for category detection").lowercased(): .accommodation,
            NSLocalizedString("lodging", comment: "Lodging keyword for category detection").lowercased(): .accommodation,
            NSLocalizedString("airbnb", comment: "Airbnb keyword for category detection").lowercased(): .accommodation,
            // German accommodation keywords
            "hotel": .accommodation, "wohnung": .accommodation, "zimmer": .accommodation,
            "unterkunft": .accommodation, "pension": .accommodation,
            // Russian accommodation keywords
            "отель": .accommodation, "гостиница": .accommodation, "квартира": .accommodation,
            "комната": .accommodation, "хостел": .accommodation, "жилье": .accommodation,
            
            // Equipment/Gear category
            NSLocalizedString("guitar", comment: "Guitar keyword for category detection").lowercased(): .gear,
            NSLocalizedString("equipment", comment: "Equipment keyword for category detection").lowercased(): .gear,
            NSLocalizedString("instrument", comment: "Instrument keyword for category detection").lowercased(): .gear,
            NSLocalizedString("mic", comment: "Mic keyword for category detection").lowercased(): .gear,
            NSLocalizedString("microphone", comment: "Microphone keyword for category detection").lowercased(): .gear,
            NSLocalizedString("speaker", comment: "Speaker keyword for category detection").lowercased(): .gear,
            NSLocalizedString("amplifier", comment: "Amplifier keyword for category detection").lowercased(): .gear,
            NSLocalizedString("cable", comment: "Cable keyword for category detection").lowercased(): .gear,
            NSLocalizedString("strings", comment: "Strings keyword for category detection").lowercased(): .gear,
            // German equipment keywords
            "gitarre": .gear, "ausrüstung": .gear, "instrument": .gear, "mikrofon": .gear,
            "lautsprecher": .gear, "verstärker": .gear, "kabel": .gear, "saiten": .gear,
            // Russian equipment keywords
            "гитара": .gear, "оборудование": .gear, "инструмент": .gear, "микрофон": .gear,
            "динамик": .gear, "усилитель": .gear, "кабель": .gear, "струны": .gear,
            
            // Promotion category
            NSLocalizedString("ad", comment: "Ad keyword for category detection").lowercased(): .promo,
            NSLocalizedString("promotion", comment: "Promotion keyword for category detection").lowercased(): .promo,
            NSLocalizedString("marketing", comment: "Marketing keyword for category detection").lowercased(): .promo,
            NSLocalizedString("flyer", comment: "Flyer keyword for category detection").lowercased(): .promo,
            NSLocalizedString("poster", comment: "Poster keyword for category detection").lowercased(): .promo,
            NSLocalizedString("print", comment: "Print keyword for category detection").lowercased(): .promo,
            NSLocalizedString("design", comment: "Design keyword for category detection").lowercased(): .promo,
            NSLocalizedString("social", comment: "Social keyword for category detection").lowercased(): .promo,
            // German promotion keywords
            "werbung": .promo, "marketing": .promo, "flyer": .promo, "plakat": .promo,
            "druck": .promo, "design": .promo, "sozial": .promo,
            // Russian promotion keywords
            "реклама": .promo, "маркетинг": .promo, "листовка": .promo, "плакат": .promo,
            "печать": .promo, "дизайн": .promo, "социальный": .promo
        ]
        
        // Count matches for each category
        var categoryMatches: [FinanceCategory: Int] = [:]
        
        // Check merchant name
        if let merchant = merchantName?.lowercased() {
            for (keyword, category) in categoryKeywords {
                if merchant.contains(keyword) {
                    categoryMatches[category, default: 0] += 3 // Merchant name has higher weight
                }
            }
        }
        
        // Check items
        for item in items {
            let lowercasedItem = item.lowercased()
            for (keyword, category) in categoryKeywords {
                if lowercasedItem.contains(keyword) {
                    categoryMatches[category, default: 0] += 1
                }
            }
        }
        
        // Find best matching category
        let sortedCategories = categoryMatches.sorted { $0.value > $1.value }
        return sortedCategories.first?.key.rawValue ?? NSLocalizedString("Other", comment: "Default category when no match found in receipt analysis")
    }
}
