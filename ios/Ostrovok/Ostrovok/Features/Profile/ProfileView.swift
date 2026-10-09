import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var session: AppSession

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing: 16) {
                        OstrovokMascot(mood: .smile, size: 64)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Гость Островка")
                                .font(.headline)
                            Text(FeatureFlags.authEnabled ? "Аккаунт" : "Тестовый вход без регистрации")
                                .font(.footnote)
                                .foregroundStyle(Palette.muted)
                        }
                    }
                    .padding(.vertical, 6)
                    .listRowBackground(Color.white)
                }

                Section("Рекомендации") {
                    if session.preferences.skippedOnboarding {
                        Text("Онбординг пропущен — показывали универсальные карточки, дальше учимся на свайпах.")
                    } else {
                        Text(countryLine)
                        Text(priorityLine)
                    }
                    Text("Лайков: \(session.likedOffers.count)  ·  всего свайпов: \(session.swipes.count)")
                }
                .listRowBackground(Color.white)

                Section("Подключение") {
                    Label(session.apiState.title, systemImage: apiSymbol)
                        .foregroundStyle(apiColor)
                    if case let .offline(reason) = session.apiState {
                        Text(reason)
                            .font(.footnote)
                            .foregroundStyle(Palette.muted)
                        Button("Повторить подключение") {
                            Task { await session.refreshRecommendations() }
                        }
                    }
                }
                .listRowBackground(Color.white)

                if !session.likedOffers.isEmpty {
                    Section("Отложенные и понравившиеся") {
                        ForEach(session.likedOffers) { offer in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(offer.title)
                                    .font(.headline)
                                Text("\(offer.kind.title) · \(offer.city)")
                                    .font(.footnote)
                                    .foregroundStyle(Palette.muted)
                            }
                        }
                    }
                    .listRowBackground(Color.white)
                }

                Section {
                    Button("Открыть агента") {
                        session.openAgent()
                    }
                    Button("Сбросить онбординг и свайпы", role: .destructive) {
                        session.resetForTests()
                    }
                }
                .listRowBackground(Color.white)
            }
            .scrollContentBackground(.hidden)
            .background(Palette.foam)
            .navigationTitle("Кабинет")
        }
    }

    private var countryLine: String {
        let names = Catalog.countries
            .filter { session.preferences.selectedCountryCodes.contains($0.code) }
            .map(\.name)
        return names.isEmpty ? "Страны не выбраны" : "Страны: \(names.joined(separator: ", "))"
    }

    private var priorityLine: String {
        let names = Catalog.priorities
            .filter { session.preferences.selectedPriorityIDs.contains($0.id) }
            .map(\.title)
        return names.isEmpty ? "Приоритеты не выбраны" : "Важно: \(names.joined(separator: ", "))"
    }

    private var apiSymbol: String {
        switch session.apiState {
        case .online: return "checkmark.circle.fill"
        case .connecting: return "arrow.triangle.2.circlepath"
        case .local: return "iphone"
        case .offline: return "wifi.slash"
        }
    }

    private var apiColor: Color {
        switch session.apiState {
        case .online: return Palette.leaf
        case .offline: return Palette.nope
        case .connecting, .local: return Palette.muted
        }
    }
}
