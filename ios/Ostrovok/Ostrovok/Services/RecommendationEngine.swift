import Foundation

/// Локальный аналог будущего Go-сервиса рекомендаций.
/// Логика: онбординг задаёт стартовый профиль, свайпы усиливают или ослабляют теги, типы жилья и бюджет.
struct RecommendationEngine {
    func ranked(offers: [Offer], preferences: UserPreferences, swipes: [SwipeEvent]) -> [Offer] {
        let profile = buildProfile(preferences: preferences, swipes: swipes)

        return offers
            .map { offer in (offer, score(offer, profile: profile)) }
            .sorted { lhs, rhs in
                if lhs.1 == rhs.1 {
                    return lhs.0.rating > rhs.0.rating
                }
                return lhs.1 > rhs.1
            }
            .map(\.0)
    }

    func nextDeck(from offers: [Offer], excluding seenIDs: Set<String>, preferences: UserPreferences, swipes: [SwipeEvent]) -> [Offer] {
        ranked(offers: offers, preferences: preferences, swipes: swipes)
            .filter { !seenIDs.contains($0.id) }
    }

    private func buildProfile(preferences: UserPreferences, swipes: [SwipeEvent]) -> Profile {
        var tagWeight: [String: Double] = [:]
        var kindWeight: [OfferKind: Double] = [:]
        var budgetWeight: [BudgetTier: Double] = [:]
        var countryWeight: [String: Double] = [:]

        if preferences.skippedOnboarding || (preferences.selectedCountryCodes.isEmpty && preferences.selectedPriorityIDs.isEmpty) {
            // Универсальный профиль: середина бюджета, города и море, без крайностей.
            ["город", "комфорт", "море", "культура"].forEach { tagWeight[$0, default: 0] += 1.2 }
            budgetWeight[.mid, default: 0] += 2
            kindWeight[.hotel, default: 0] += 1
        } else {
            for code in preferences.selectedCountryCodes {
                countryWeight[code, default: 0] += 2.5
            }
            for id in preferences.selectedPriorityIDs {
                if let priority = Catalog.priorities.first(where: { $0.id == id }) {
                    for tag in priority.tags {
                        tagWeight[tag, default: 0] += 2
                    }
                }
            }
        }

        for swipe in swipes {
            let direction: Double = swipe.liked ? 1 : -1.4
            for tag in swipe.tags {
                tagWeight[tag, default: 0] += direction
            }
            kindWeight[swipe.kind, default: 0] += direction * 0.8
            budgetWeight[swipe.budgetTier, default: 0] += direction * 0.9
            countryWeight[swipe.countryCode, default: 0] += direction * 0.7
        }

        return Profile(
            tagWeight: tagWeight,
            kindWeight: kindWeight,
            budgetWeight: budgetWeight,
            countryWeight: countryWeight
        )
    }

    private func score(_ offer: Offer, profile: Profile) -> Double {
        var value = offer.rating
        for tag in offer.tags {
            value += profile.tagWeight[tag, default: 0]
        }
        value += profile.kindWeight[offer.kind, default: 0]
        value += profile.budgetWeight[offer.budgetTier, default: 0]
        value += profile.countryWeight[offer.countryCode, default: 0]
        return value
    }

    private struct Profile {
        let tagWeight: [String: Double]
        let kindWeight: [OfferKind: Double]
        let budgetWeight: [BudgetTier: Double]
        let countryWeight: [String: Double]
    }
}
