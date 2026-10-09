import SwiftUI

struct OfferDetailView: View {
    let offer: Offer
    @EnvironmentObject private var session: AppSession
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    headerImage
                    VStack(alignment: .leading, spacing: 10) {
                        Text(offer.title)
                            .font(.title.weight(.semibold))
                        Text("\(offer.city), \(offer.country)")
                            .foregroundStyle(Palette.muted)
                        HStack {
                            Label(String(format: "%.1f", offer.rating), systemImage: "star.fill")
                            Text("· \(offer.reviewCount) отзывов")
                                .foregroundStyle(Palette.muted)
                        }
                        .foregroundStyle(Palette.leaf)

                        Text(offer.priceLabel)
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(Palette.forest)

                        Text(offer.description)
                            .foregroundStyle(Palette.ink)

                        tags
                        amenities
                        reviews
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
                }
            }
            .background(Palette.foam)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Закрыть") { dismiss() }
                }
            }
            .safeAreaInset(edge: .bottom) {
                HStack(spacing: 12) {
                    Button("Мимо") {
                        session.swipe(offer, liked: false)
                        dismiss()
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Palette.mint)
                    .foregroundStyle(Palette.forest)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                    Button("Нравится") {
                        session.swipe(offer, liked: true)
                        dismiss()
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Palette.leaf)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .padding(16)
                .background(Color.white)
            }
        }
    }

    private var headerImage: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(hue: offer.imageHue, saturation: 0.35, brightness: 0.82),
                    Palette.forest
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            Image(systemName: offer.imageSymbol)
                .font(.system(size: 80))
                .foregroundStyle(.white)
        }
        .frame(height: 220)
    }

    private var tags: some View {
        FlowTags(tags: offer.tags)
    }

    private var amenities: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Что входит")
                .font(.headline)
            ForEach(offer.amenities, id: \.self) { item in
                Label(item, systemImage: "checkmark.circle.fill")
                    .foregroundStyle(Palette.forest)
            }
        }
        .padding(.top, 8)
    }

    private var reviews: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Отзывы")
                .font(.headline)
                .padding(.top, 8)
            ForEach(offer.reviews) { review in
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(review.author)
                            .font(.subheadline.weight(.semibold))
                        Spacer()
                        Text(review.date)
                            .font(.caption)
                            .foregroundStyle(Palette.muted)
                    }
                    Label(String(format: "%.1f", review.rating), systemImage: "star.fill")
                        .font(.caption)
                        .foregroundStyle(Palette.leaf)
                    Text(review.text)
                        .font(.subheadline)
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        }
    }
}

struct FlowTags: View {
    let tags: [String]

    var body: some View {
        FlexibleTagWrap(tags: tags)
    }
}

private struct FlexibleTagWrap: View {
    let tags: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(rows, id: \.self) { row in
                HStack(spacing: 8) {
                    ForEach(row, id: \.self) { tag in
                        Text(tag)
                            .font(.caption.weight(.medium))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Palette.mint)
                            .foregroundStyle(Palette.forest)
                            .clipShape(Capsule())
                    }
                }
            }
        }
    }

    private var rows: [[String]] {
        var result: [[String]] = [[]]
        var width = 0
        for tag in tags {
            let estimated = tag.count * 8 + 28
            if width + estimated > 320, !result[result.count - 1].isEmpty {
                result.append([tag])
                width = estimated
            } else {
                result[result.count - 1].append(tag)
                width += estimated
            }
        }
        return result
    }
}
