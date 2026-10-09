import Foundation
import Combine

/// Состояние приложения. Хранит онбординг, свайпы и колоду карточек.
/// Позже сюда же ляжет клиент к Go API, не ломая экраны.
@MainActor
final class AppSession: ObservableObject {
    @Published var preferences: UserPreferences
    @Published private(set) var swipes: [SwipeEvent]
    @Published private(set) var deck: [Offer]
    @Published private(set) var allOffers: [Offer]
    @Published private(set) var apiState: APIConnectionState = .local
    @Published var selectedTab: AppTab = .cards
    @Published var pendingAgentPrompt: String?

    private let engine = RecommendationEngine()
    private let api = APIClient()
    private let defaults = UserDefaults.standard
    private var refreshGeneration = 0

    private static let preferencesKey = "ostrovok.preferences"
    private static let swipesKey = "ostrovok.swipes"

    init(offers: [Offer] = Catalog.offers) {
        let defaults = UserDefaults.standard
        self.allOffers = offers
        self.preferences = Self.loadPreferences(defaults: defaults, key: Self.preferencesKey) ?? .empty
        self.swipes = Self.loadSwipes(defaults: defaults, key: Self.swipesKey)
        self.deck = []
        rebuildDeck()
    }

    var likedOffers: [Offer] {
        let ids = Set(swipes.filter(\.liked).map(\.offerId))
        return allOffers.filter { ids.contains($0.id) }
    }

    var seenIDs: Set<String> {
        Set(swipes.map(\.offerId))
    }

    func completeOnboarding(countries: [String], priorities: [String], skipped: Bool) {
        preferences.selectedCountryCodes = countries
        preferences.selectedPriorityIDs = priorities
        preferences.skippedOnboarding = skipped
        preferences.onboardingCompleted = true
        persist()
        rebuildDeck()
        scheduleRemoteRefresh()
    }

    func skipOnboarding() {
        completeOnboarding(countries: [], priorities: [], skipped: true)
    }

    func swipe(_ offer: Offer, liked: Bool) {
        let event = SwipeEvent(
            id: UUID(),
            offerId: offer.id,
            liked: liked,
            tags: offer.tags,
            budgetTier: offer.budgetTier,
            kind: offer.kind,
            countryCode: offer.countryCode
        )
        swipes.append(event)
        if deck.first?.id == offer.id {
            deck.removeFirst()
        } else {
            deck.removeAll { $0.id == offer.id }
        }
        persist()
        // Пересчитываем всю оставшуюся колоду после каждого жеста:
        // следующий экран уже учитывает только что поставленный лайк/дизлайк.
        rebuildDeck()
        scheduleRemoteRefresh()
    }

    func offer(id: String) -> Offer? {
        allOffers.first { $0.id == id }
    }

    func resetForTests() {
        refreshGeneration += 1
        preferences = .empty
        swipes = []
        apiState = .local
        persist()
        rebuildDeck()
        selectedTab = .cards
    }

    func openAgent(with prompt: String? = nil) {
        pendingAgentPrompt = prompt
        selectedTab = .agent
    }

    func refreshRecommendations() async {
        guard FeatureFlags.remoteAPIEnabled, preferences.onboardingCompleted else {
            apiState = .local
            return
        }

        refreshGeneration += 1
        let generation = refreshGeneration
        apiState = .connecting

        do {
            let remote = try await api.recommendations(
                preferences: preferences,
                swipes: swipes
            )
            guard generation == refreshGeneration else { return }
            mergeIntoCatalog(remote)
            deck = remote
            apiState = .online
        } catch {
            guard generation == refreshGeneration else { return }
            rebuildDeck()
            apiState = .offline(error.localizedDescription)
        }
    }

    func agentReply(to text: String) async -> ChatMessage {
        if FeatureFlags.remoteAPIEnabled {
            do {
                return try await api.agentReply(message: text, liked: likedOffers)
            } catch {
                apiState = .offline(error.localizedDescription)
            }
        }
        return AgentService().reply(to: text, liked: likedOffers)
    }

    private func rebuildDeck() {
        deck = engine.nextDeck(
            from: allOffers,
            excluding: seenIDs,
            preferences: preferences,
            swipes: swipes
        )
    }

    private func scheduleRemoteRefresh() {
        Task { await refreshRecommendations() }
    }

    private func mergeIntoCatalog(_ remote: [Offer]) {
        let remoteByID = Dictionary(uniqueKeysWithValues: remote.map { ($0.id, $0) })
        var merged = allOffers.map { remoteByID[$0.id] ?? $0 }
        let knownIDs = Set(merged.map(\.id))
        merged.append(contentsOf: remote.filter { !knownIDs.contains($0.id) })
        allOffers = merged
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(preferences) {
            defaults.set(data, forKey: Self.preferencesKey)
        }
        if let data = try? JSONEncoder().encode(swipes) {
            defaults.set(data, forKey: Self.swipesKey)
        }
    }

    private static func loadPreferences(defaults: UserDefaults, key: String) -> UserPreferences? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(UserPreferences.self, from: data)
    }

    private static func loadSwipes(defaults: UserDefaults, key: String) -> [SwipeEvent] {
        guard let data = defaults.data(forKey: key) else { return [] }
        return (try? JSONDecoder().decode([SwipeEvent].self, from: data)) ?? []
    }
}

enum AppTab: Hashable {
    case cards
    case agent
    case profile
}
