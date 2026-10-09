import Foundation

struct TravelPriority: Identifiable, Hashable, Codable {
    let id: String
    let title: String
    let subtitle: String
    let symbol: String
    let tags: [String]
}

struct CountryOption: Identifiable, Hashable, Codable {
    let code: String
    let name: String
    let emoji: String

    var id: String { code }
}

struct SwipeEvent: Identifiable, Hashable, Codable {
    let id: UUID
    let offerId: String
    let liked: Bool
    let tags: [String]
    let budgetTier: BudgetTier
    let kind: OfferKind
    let countryCode: String
}

struct UserPreferences: Codable, Equatable {
    var selectedCountryCodes: [String]
    var selectedPriorityIDs: [String]
    var skippedOnboarding: Bool
    var onboardingCompleted: Bool

    static let empty = UserPreferences(
        selectedCountryCodes: [],
        selectedPriorityIDs: [],
        skippedOnboarding: false,
        onboardingCompleted: false
    )
}
