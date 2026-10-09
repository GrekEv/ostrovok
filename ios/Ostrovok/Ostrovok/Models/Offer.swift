import Foundation

enum OfferKind: String, Codable, CaseIterable, Identifiable {
    case hotel
    case motel
    case hostel
    case tour
    case flight

    var id: String { rawValue }

    var title: String {
        switch self {
        case .hotel: return "Отель"
        case .motel: return "Мотель"
        case .hostel: return "Хостел"
        case .tour: return "Тур"
        case .flight: return "Перелёт"
        }
    }

    var symbol: String {
        switch self {
        case .hotel: return "building.2"
        case .motel: return "car"
        case .hostel: return "bed.double"
        case .tour: return "map"
        case .flight: return "airplane"
        }
    }
}

struct Offer: Identifiable, Hashable, Codable {
    let id: String
    let kind: OfferKind
    let title: String
    let city: String
    let country: String
    let countryCode: String
    let shortDescription: String
    let description: String
    let pricePerNight: Int
    let currency: String
    let rating: Double
    let reviewCount: Int
    let tags: [String]
    let amenities: [String]
    let imageSymbol: String
    let imageHue: Double
    let reviews: [Review]
    let budgetTier: BudgetTier

    var priceLabel: String {
        switch kind {
        case .flight:
            return "от \(formattedPrice) \(currency)"
        case .tour:
            return "\(formattedPrice) \(currency) / тур"
        default:
            return "\(formattedPrice) \(currency) / ночь"
        }
    }

    private var formattedPrice: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = " "
        return formatter.string(from: NSNumber(value: pricePerNight)) ?? "\(pricePerNight)"
    }
}

enum BudgetTier: String, Codable {
    case low
    case mid
    case high
}

struct Review: Identifiable, Hashable, Codable {
    let id: String
    let author: String
    let rating: Double
    let text: String
    let date: String
}
