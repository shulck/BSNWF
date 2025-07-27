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
            "nettoumsatz", "bruttoumsatz", "girocard", "gesamt", "total",
            "zu zahlen", "summe", "betrag", "endpreis"
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
                                candidates.append((amount: amount, keyword: keyword + " (next line)", priority: priority - 1))
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
            "total", "sum", "amount", "due", "balance", "pay",
            "итого", "сумма", "к оплате", "betrag", "gesamt",
            "netto", "brutto", "endpreis", "zu zahlen"
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
            return lowercased.contains("date") ||
                   lowercased.contains("time") ||
                   lowercased.contains("receipt") ||
                   lowercased.contains("transaction") ||
                   lowercased.contains("purchase")
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
        if line.lowercased().contains("today") {
            return today
        }
        
        // If receipt contains "yesterday"
        if line.lowercased().contains("yesterday") {
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
                if line.contains("/") || line.contains("@") || line.contains("Tel:") ||
                   line.contains("Phone:") || line.contains("Address:") || line.contains("ID:") ||
                   line.lowercased().contains("receipt") ||
                   line.contains("www.") || line.contains("http") {
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
        let startMarkers = ["item", "description", "product", "quantity", "qty", "price"]
        let endMarkers = ["total", "subtotal", "sub-total", "amount", "balance", "due", "sum", "tax", "vat"]
        
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
                if lowercasedLine.contains("qty") || lowercasedLine.contains(" x ") ||
                   lowercasedLine.contains("$") || lowercasedLine.contains("€") ||
                   (lowercasedLine.contains("quantity") && lowercasedLine.contains("price")) {
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
            let blockedWords = ["receipt", "store", "date", "time", "total", "amount",
                              "payment", "cashier", "thank", "you", "discount", "tax",
                              "id", "address", "number", "phone", "welcome", "order"]
            
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
            "restaurant": .food,
            "cafe": .food,
            "pizza": .food,
            "sushi": .food,
            "food": .food,
            "grocery": .food,
            "supermarket": .food,
            "bread": .food,
            "milk": .food,
            "coffee": .food,
            "burger": .food,
            
            "taxi": .logistics,
            "metro": .logistics,
            "bus": .logistics,
            "train": .logistics,
            "subway": .logistics,
            "ticket": .logistics,
            "transit": .logistics,
            "gas": .logistics,
            "fuel": .logistics,
            "parking": .logistics,
            "uber": .logistics,
            "post": .logistics, // Added for Deutsche Post
            
            "hotel": .accommodation,
            "apartment": .accommodation,
            "room": .accommodation,
            "hostel": .accommodation,
            "lodging": .accommodation,
            "airbnb": .accommodation,
            
            "guitar": .gear,
            "equipment": .gear,
            "instrument": .gear,
            "mic": .gear,
            "microphone": .gear,
            "speaker": .gear,
            "amplifier": .gear,
            "cable": .gear,
            "strings": .gear,
            
            "ad": .promo,
            "promotion": .promo,
            "marketing": .promo,
            "flyer": .promo,
            "poster": .promo,
            "print": .promo,
            "design": .promo,
            "social": .promo
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
        return sortedCategories.first?.key.rawValue ?? "Other"
    }
}
