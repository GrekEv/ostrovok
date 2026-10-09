import SwiftUI

struct CardsFeedView: View {
    @EnvironmentObject private var session: AppSession
    @State private var detailOffer: Offer?

    var body: some View {
        NavigationStack {
            ZStack {
                Palette.foam.ignoresSafeArea()
                if session.deck.isEmpty {
                    emptyState
                } else {
                    stack
                }
            }
            .navigationTitle("Островок")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Palette.foam, for: .navigationBar)
            .sheet(item: $detailOffer) { offer in
                OfferDetailView(offer: offer)
            }
        }
    }

    private var stack: some View {
        VStack(spacing: 16) {
            Text(session.preferences.skippedOnboarding
                 ? "Универсальные варианты. Свайпайте — подбор станет точнее."
                 : "Под вас. Вправо — нравится, влево — мимо.")
                .font(.subheadline)
                .foregroundStyle(Palette.muted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)
                .padding(.top, 8)

            ZStack {
                ForEach(Array(session.deck.prefix(3).enumerated().reversed()), id: \.element.id) { index, offer in
                    let isTop = index == 0
                    SwipeCardView(
                        offer: offer,
                        interactive: isTop,
                        onLike: { session.swipe(offer, liked: true) },
                        onNope: { session.swipe(offer, liked: false) },
                        onOpen: { detailOffer = offer }
                    )
                    .scaleEffect(isTop ? 1 : 1 - CGFloat(index) * 0.04)
                    .offset(y: CGFloat(index) * 10)
                    .allowsHitTesting(isTop)
                }
            }
            .padding(.horizontal, 20)
            .frame(maxHeight: .infinity)

            HStack(spacing: 28) {
                roundAction("xmark", color: Palette.nope) {
                    if let offer = session.deck.first {
                        session.swipe(offer, liked: false)
                    }
                }
                roundAction("heart.fill", color: Palette.like) {
                    if let offer = session.deck.first {
                        session.swipe(offer, liked: true)
                    }
                }
            }
            .padding(.bottom, 12)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            OstrovokMascot(mood: .wink, size: 120)
            Text("Карточки на сегодня закончились")
                .font(.title3.weight(.semibold))
            Text("Откройте агента — он соберёт бронь по лайкам или позовёт менеджера.")
                .foregroundStyle(Palette.muted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            PrimaryButton(title: "К агенту") {
                session.openAgent(with: "Подобрать")
            }
            .padding(.horizontal, 40)
        }
    }

    private func roundAction(_ symbol: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.title2.weight(.semibold))
                .foregroundStyle(color)
                .frame(width: 64, height: 64)
                .background(Color.white)
                .clipShape(Circle())
                .shadow(color: Palette.cardShadow, radius: 10, y: 4)
        }
        .buttonStyle(.plain)
    }
}
