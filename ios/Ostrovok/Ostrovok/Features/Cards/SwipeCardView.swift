import SwiftUI

struct SwipeCardView: View {
    let offer: Offer
    var interactive: Bool
    let onLike: () -> Void
    let onNope: () -> Void
    let onOpen: () -> Void

    @State private var offset: CGSize = .zero
    private let threshold: CGFloat = 110

    var body: some View {
        card
            .offset(offset)
            .rotationEffect(.degrees(Double(offset.width / 18)))
            .gesture(drag)
            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: offset)
    }

    private var drag: some Gesture {
        DragGesture()
            .onChanged { value in
                guard interactive else { return }
                offset = value.translation
            }
            .onEnded { value in
                guard interactive else { return }
                if value.translation.width > threshold {
                    offset = CGSize(width: 480, height: value.translation.height)
                    onLike()
                } else if value.translation.width < -threshold {
                    offset = CGSize(width: -480, height: value.translation.height)
                    onNope()
                } else {
                    offset = .zero
                }
            }
    }

    private var card: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(hue: offer.imageHue, saturation: 0.35, brightness: 0.82),
                                Palette.forest
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay {
                        Image(systemName: offer.imageSymbol)
                            .font(.system(size: 72))
                            .foregroundStyle(.white.opacity(0.9))
                    }
                    .frame(height: 280)

                stamp

                Text(offer.kind.title.uppercased())
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.white.opacity(0.92))
                    .clipShape(Capsule())
                    .foregroundStyle(Palette.forest)
                    .padding(16)
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(offer.title)
                        .font(.title3.weight(.semibold))
                    Spacer()
                    Label(String(format: "%.1f", offer.rating), systemImage: "star.fill")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Palette.leaf)
                }
                Text("\(offer.city), \(offer.country)")
                    .foregroundStyle(Palette.muted)
                Text(offer.shortDescription)
                    .font(.subheadline)
                    .foregroundStyle(Palette.ink)
                    .lineLimit(3)
                HStack {
                    Text(offer.priceLabel)
                        .font(.headline)
                        .foregroundStyle(Palette.forest)
                    Spacer()
                    Button("Подробнее") { onOpen() }
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Palette.leaf)
                }
            }
            .padding(18)
            .background(Color.white)
        }
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: Palette.cardShadow, radius: 18, y: 10)
    }

    @ViewBuilder
    private var stamp: some View {
        let progress = min(abs(offset.width) / threshold, 1)
        if offset.width > 20 {
            Text("НРАВИТСЯ")
                .font(.headline.weight(.bold))
                .foregroundStyle(Palette.like)
                .padding(8)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Palette.like, lineWidth: 3))
                .rotationEffect(.degrees(-18))
                .opacity(progress)
                .padding(24)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        } else if offset.width < -20 {
            Text("МИМО")
                .font(.headline.weight(.bold))
                .foregroundStyle(Palette.nope)
                .padding(8)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Palette.nope, lineWidth: 3))
                .rotationEffect(.degrees(18))
                .opacity(progress)
                .padding(24)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
        }
    }
}
