import Foundation

/// Черновик ответов агента. Позже заменим вызовом Go API / LLM.
struct AgentService {
    func opening(likedCount: Int) -> ChatMessage {
        let text: String
        if likedCount == 0 {
            text = "Я Островок. Помогу подобрать жильё, тур или перелёт, отложить бронь или соединить с менеджером. Можно свайпать карточки — чем больше лайков, тем точнее подбор."
        } else {
            text = "У вас уже \(likedCount) сохранённых вариантов. Могу сравнить их, забронировать, отложить или позвать менеджера."
        }
        return ChatMessage(
            isFromUser: false,
            text: text,
            quickReplies: ["Подобрать", "Забронировать", "Отложить бронь", "Менеджер"]
        )
    }

    func reply(to text: String, liked: [Offer]) -> ChatMessage {
        let intent = detectIntent(text)
        let names = liked.prefix(3).map(\.title).joined(separator: ", ")

        switch intent {
        case .matching:
            let body = liked.isEmpty
                ? "Свайпните вправо карточки, которые откликаются. Я соберу подборку по бюджету и тегам. Пока могу показать универсальные варианты: городские отели среднего бюджета и море."
                : "По вашим лайкам ближе всего: \(names). Если свайпали море вправо и хостелы влево — усилю пляж и комфорт, уберу самый дешёвый шум."
            return ChatMessage(isFromUser: false, text: body, quickReplies: ["Забронировать", "Отложить бронь", "Менеджер"])
        case .booking:
            let body = liked.first.map { offer in
                "Могу начать бронь «\(offer.title)» — \(offer.city), \(offer.priceLabel). На тестах оплата ещё не подключена: зафиксирую заявку и отдам менеджеру."
            } ?? "Добавьте хотя бы один вариант вправо — тогда будет что бронировать. Или напишите город и даты."
            return ChatMessage(isFromUser: false, text: body, quickReplies: ["Менеджер", "Отложить бронь", "Подобрать"])
        case .delayedBooking:
            return ChatMessage(
                isFromUser: false,
                text: "Отложенная бронь: сохраню выбранные карточки и напомню, когда цены или даты станут лучше. Напишите даты «с — по» и город.",
                quickReplies: ["Забронировать", "Менеджер"]
            )
        case .manager:
            return ChatMessage(
                isFromUser: false,
                text: "Соединяю с живым менеджером. Он видит ваши лайки и приоритеты. На тестах это очередь: ответ в рабочее время, обычно до 15 минут.",
                quickReplies: ["Подобрать", "Забронировать"]
            )
        case .general:
            return ChatMessage(
                isFromUser: false,
                text: "Могу подобрать, забронировать, отложить или позвать менеджера. Коротко напишите: куда, когда, с кем и бюджет.",
                quickReplies: ["Подобрать", "Забронировать", "Отложить бронь", "Менеджер"]
            )
        }
    }

    private func detectIntent(_ text: String) -> AgentIntent {
        let value = text.lowercased()
        if value.contains("менедж") { return .manager }
        if value.contains("отлож") || value.contains("потом") { return .delayedBooking }
        if value.contains("брон") { return .booking }
        if value.contains("подобр") || value.contains("вариант") || value.contains("найд") { return .matching }
        return .general
    }
}

enum APIConnectionState: Equatable {
    case local
    case connecting
    case online
    case offline(String)

    var title: String {
        switch self {
        case .local: return "Локальный каталог"
        case .connecting: return "Подключение к API…"
        case .online: return "API подключён"
        case .offline: return "Офлайн-режим"
        }
    }
}

struct APIClient {
    private let baseURL: URL
    private let session: URLSession

    init(
        baseURL: URL = APIClient.configuredBaseURL,
        session: URLSession = .shared
    ) {
        self.baseURL = baseURL
        self.session = session
    }

    static var configuredBaseURL: URL {
        let configured = ProcessInfo.processInfo.environment["OSTROVOK_API_URL"]
            ?? FeatureFlags.defaultAPIURL
        return URL(string: configured) ?? URL(string: FeatureFlags.defaultAPIURL)!
    }

    func recommendations(
        preferences: UserPreferences,
        swipes: [SwipeEvent]
    ) async throws -> [Offer] {
        let body = RecommendationRequest(
            countryCodes: preferences.selectedCountryCodes,
            priorityIDs: preferences.selectedPriorityIDs,
            skipped: preferences.skippedOnboarding,
            swipes: swipes
        )
        let remote: [RemoteOffer] = try await post(
            path: "/v1/recommendations",
            body: body
        )
        return remote.map(\.offer)
    }

    func agentReply(message: String, liked: [Offer]) async throws -> ChatMessage {
        let body = AgentRequest(message: message, liked: liked)
        let reply: AgentReply = try await post(path: "/v1/agent/chat", body: body)
        return ChatMessage(
            isFromUser: false,
            text: reply.text,
            quickReplies: reply.quickReplies
        )
    }

    private func post<Body: Encodable, Response: Decodable>(
        path: String,
        body: Body
    ) async throws -> Response {
        guard let url = URL(string: path, relativeTo: baseURL) else {
            throw APIError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 8
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        guard (200..<300).contains(http.statusCode) else {
            let serverError = try? JSONDecoder().decode(ServerError.self, from: data)
            throw APIError.server(
                status: http.statusCode,
                message: serverError?.error ?? "Неизвестная ошибка"
            )
        }
        return try JSONDecoder().decode(Response.self, from: data)
    }
}

private struct RecommendationRequest: Encodable {
    let countryCodes: [String]
    let priorityIDs: [String]
    let skipped: Bool
    let swipes: [SwipeEvent]
}

private struct AgentRequest: Encodable {
    let message: String
    let liked: [Offer]
}

private struct AgentReply: Decodable {
    let text: String
    let quickReplies: [String]
}

private struct ServerError: Decodable {
    let error: String
}

private struct RemoteOffer: Decodable {
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
    let tags: [String]?
    let amenities: [String]?
    let imageSymbol: String?
    let imageHue: Double?
    let reviews: [Review]?
    let budgetTier: BudgetTier

    var offer: Offer {
        Offer(
            id: id,
            kind: kind,
            title: title,
            city: city,
            country: country,
            countryCode: countryCode,
            shortDescription: shortDescription,
            description: description,
            pricePerNight: pricePerNight,
            currency: currency,
            rating: rating,
            reviewCount: reviewCount,
            tags: tags ?? [],
            amenities: amenities ?? [],
            imageSymbol: imageSymbol.flatMap { $0.isEmpty ? nil : $0 } ?? kind.symbol,
            imageHue: imageHue.map { $0 > 0 ? $0 : 0.38 } ?? 0.38,
            reviews: reviews ?? [],
            budgetTier: budgetTier
        )
    }
}

private enum APIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case server(status: Int, message: String)

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Неверный адрес API"
        case .invalidResponse: return "Сервер вернул некорректный ответ"
        case let .server(status, message): return "HTTP \(status): \(message)"
        }
    }
}
