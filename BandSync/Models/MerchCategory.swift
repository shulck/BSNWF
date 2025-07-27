import Foundation
import FirebaseFirestore

enum MerchCategory: String, Codable, CaseIterable, Identifiable {
    var id: String { rawValue }

    case clothing = "Clothing"
    case music = "Music"
    case accessory = "Accessories"
    case other = "Other"

    var icon: String {
        switch self {
        case .clothing: return "tshirt"
        case .music: return "music.note"
        case .accessory: return "bag"
        case .other: return "ellipsis.circle"
        }
    }
    
    var defaultSubcategories: [MerchSubcategory] {
        return MerchSubcategory.subcategories(for: self)
    }
    
    var needsSizes: Bool {
        return self == .clothing
    }
    
    var suggestedLowStockThreshold: Int {
        switch self {
        case .clothing: return 5
        case .music: return 10
        case .accessory: return 15
        case .other: return 3
        }
    }
}

struct MerchSizeStock: Codable {
    var S: Int = 0
    var M: Int = 0
    var L: Int = 0
    var XL: Int = 0
    var XXL: Int = 0

    init(S: Int = 0, M: Int = 0, L: Int = 0, XL: Int = 0, XXL: Int = 0) {
        self.S = S
        self.M = M
        self.L = L
        self.XL = XL
        self.XXL = XXL
    }

    var total: Int {
        return S + M + L + XL + XXL
    }

    func hasLowStock(threshold: Int, category: MerchCategory) -> Bool {
        if total >= 50 {
            return false
        }
        
        if category == .clothing {
            if (S > 0 && S <= threshold) ||
               (M > 0 && M <= threshold) ||
               (L > 0 && L <= threshold) ||
               (XL > 0 && XL <= threshold) ||
               (XXL > 0 && XXL <= threshold) {
                return true
            }
            
            if total == 0 {
                return true
            }
            
            return false
        } else {
            return total <= threshold
        }
    }
    
    var sizesInStock: [String] {
        var result: [String] = []
        
        if S > 0 { result.append("S") }
        if M > 0 { result.append("M") }
        if L > 0 { result.append("L") }
        if XL > 0 { result.append("XL") }
        if XXL > 0 { result.append("XXL") }
        
        return result
    }
    
    func sizesWithLowStock(threshold: Int) -> [String] {
        var result: [String] = []
        
        if S > 0 && S <= threshold { result.append("S") }
        if M > 0 && M <= threshold { result.append("M") }
        if L > 0 && L <= threshold { result.append("L") }
        if XL > 0 && XL <= threshold { result.append("XL") }
        if XXL > 0 && XXL <= threshold { result.append("XXL") }
        
        return result
    }
}

struct MerchItem: Identifiable, Codable {
    @DocumentID var id: String?

    var name: String
    var description: String
    var price: Double
    var category: MerchCategory
    var subcategory: MerchSubcategory?
    var stock: MerchSizeStock
    var groupId: String
    var lowStockThreshold: Int
    var sku: String?
    var cost: Double?
    var imageURL: String?
    var imageUrls: [String]?
    var updatedAt: Date?
    
    var imageBase64: [String]?
    
    init(
        id: String? = nil,
        name: String,
        description: String,
        price: Double,
        category: MerchCategory,
        subcategory: MerchSubcategory? = nil,
        stock: MerchSizeStock,
        groupId: String,
        lowStockThreshold: Int = 5,
        sku: String? = nil,
        cost: Double? = nil,
        imageURL: String? = nil,
        imageUrls: [String]? = nil,
        updatedAt: Date? = Date(),
        imageBase64: [String]? = nil
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.price = price
        self.category = category
        self.subcategory = subcategory
        self.stock = stock
        self.groupId = groupId
        self.lowStockThreshold = lowStockThreshold
        self.sku = sku
        self.cost = cost
        self.imageURL = imageURL
        self.imageUrls = imageUrls
        self.updatedAt = updatedAt
        self.imageBase64 = imageBase64
    }
    
    func generateSKU() -> String {
        let prefix = category.rawValue.prefix(2).uppercased()
        let nameComponent = name.filter { !$0.isWhitespace }.prefix(3).uppercased()
        let randomSuffix = String(format: "%04d", Int.random(in: 1000...9999))
        return "\(prefix)-\(nameComponent)-\(randomSuffix)"
    }
    
    var totalStock: Int {
        return stock.total
    }
    
    var isLowStock: Bool {
        return stock.hasLowStock(threshold: lowStockThreshold, category: category)
    }
    
    var sizesWithLowStock: [String] {
        return stock.sizesWithLowStock(threshold: lowStockThreshold)
    }
}
