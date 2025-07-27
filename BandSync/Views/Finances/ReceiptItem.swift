//
//  ReceiptItem.swift
//  BandSync
//
//  Created by Oleksandr Kuziakin on 02.04.2025.
//

import Foundation

/// Model for representing an item (product/service) from a receipt
struct ReceiptItem: Identifiable, Equatable {
    let id = UUID()
    var name: String
    var quantity: Double
    var price: Double
    var totalPrice: Double
    
    init(name: String, quantity: Double = 1.0, price: Double = 0.0, totalPrice: Double? = nil) {
        self.name = name
        self.quantity = quantity
        self.price = price
        self.totalPrice = totalPrice ?? (price * quantity)
    }
    
    static func == (lhs: ReceiptItem, rhs: ReceiptItem) -> Bool {
        return lhs.id == rhs.id
    }
}

/// Extension for receipt analysis
extension ReceiptAnalyzer {
    /// Convert item lines to structured ReceiptItem objects
    static func extractReceiptItems(from lines: [String]) -> [ReceiptItem] {
        var receiptItems: [ReceiptItem] = []
        
        // Look for lines that may contain items with price
        let itemRegex = try? NSRegularExpression(pattern: "(.*?)\\s+([0-9]+[.,]?[0-9]*)\\s*[xX]?\\s*([0-9]+[.,]?[0-9]*)?\\s*([0-9]+[.,]?[0-9]*)", options: [])
        
        for line in lines {
            if let regex = itemRegex,
               let match = regex.firstMatch(in: line, options: [], range: NSRange(location: 0, length: line.count)) {
                
                let nsLine = line as NSString
                
                // Item name is usually in the first group
                let nameRange = match.range(at: 1)
                let name = nameRange.location != NSNotFound ? nsLine.substring(with: nameRange).trimmingCharacters(in: .whitespacesAndNewlines) : ""
                
                // Other groups may contain quantity, unit price and total amount
                var quantity: Double = 1.0
                var price: Double = 0.0
                var totalPrice: Double = 0.0
                
                // Try to extract numbers from corresponding groups
                if match.numberOfRanges > 2 {
                    let group2Range = match.range(at: 2)
                    if group2Range.location != NSNotFound {
                        let valueStr = nsLine.substring(with: group2Range).replacingOccurrences(of: ",", with: ".")
                        if let value = Double(valueStr) {
                            totalPrice = value  // By default assume this is total amount
                        }
                    }
                }
                
                if match.numberOfRanges > 3 {
                    let group3Range = match.range(at: 3)
                    if group3Range.location != NSNotFound {
                        let valueStr = nsLine.substring(with: group3Range).replacingOccurrences(of: ",", with: ".")
                        if let value = Double(valueStr) {
                            quantity = value
                        }
                    }
                }
                
                if match.numberOfRanges > 4 {
                    let group4Range = match.range(at: 4)
                    if group4Range.location != NSNotFound {
                        let valueStr = nsLine.substring(with: group4Range).replacingOccurrences(of: ",", with: ".")
                        if let value = Double(valueStr) {
                            price = totalPrice  // Previous value was probably unit price
                            totalPrice = value  // And this is total amount
                        }
                    }
                }
                
                // If there's at least item name, add element
                if !name.isEmpty {
                    let item = ReceiptItem(name: name, quantity: quantity, price: price, totalPrice: totalPrice)
                    receiptItems.append(item)
                }
            } else {
                // If regex didn't work but line may contain item, add it as is
                let words = line.components(separatedBy: " ")
                if words.count >= 1 && !line.contains("total") && !line.contains("subtotal") {
                    let item = ReceiptItem(name: line)
                    receiptItems.append(item)
                }
            }
        }
        
        return receiptItems
    }
}
