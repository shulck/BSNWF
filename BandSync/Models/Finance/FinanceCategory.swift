// FinanceCategory.swift

import Foundation

enum FinanceCategory: String, Codable, CaseIterable, Identifiable {
    var id: String { rawValue }

    case logistics = "Logistics"
    case accommodation = "Accommodation"
    case food = "Food"
    case gear = "Equipment"
    case promo = "Promotion"
    case production = "Video/Photo Production"
    case other = "Other"

    case performance = "Performances"
    case merch = "Merchandise"
    case royalties = "Royalties"
    case sponsorship = "Sponsorship"
    case mediaProduction = "Media Production"
    
    var localizedTitle: String {
        switch self {
        case .logistics: return "categoryLogistics".localized
        case .accommodation: return "categoryAccommodation".localized
        case .food: return "categoryFood".localized
        case .gear: return "categoryGear".localized
        case .promo: return "categoryPromo".localized
        case .production: return "categoryProduction".localized
        case .other: return "categoryOther".localized
        case .performance: return "categoryPerformance".localized
        case .merch: return "categoryMerch".localized
        case .royalties: return "categoryRoyalties".localized
        case .sponsorship: return "categorySponsorship".localized
        case .mediaProduction: return "categoryMediaProduction".localized
        }
    }

    static func forType(_ type: FinanceType) -> [FinanceCategory] {
        switch type {
        case .income:
            return [.performance, .merch, .royalties, .sponsorship, .mediaProduction, .other]
        case .expense:
            return [.logistics, .accommodation, .food, .gear, .promo, .production, .other]
        }
    }
}
