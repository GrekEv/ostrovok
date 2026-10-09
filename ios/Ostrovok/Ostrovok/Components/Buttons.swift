import SwiftUI

struct PrimaryButton: View {
    let title: String
    var filled: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .foregroundStyle(filled ? Color.white : Palette.forest)
                .background(filled ? Palette.leaf : Palette.mint)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

struct Chip: View {
    let title: String
    let selected: Bool
    var emoji: String? = nil

    var body: some View {
        HStack(spacing: 6) {
            if let emoji {
                Text(emoji)
            }
            Text(title)
                .font(.subheadline.weight(.medium))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .foregroundStyle(selected ? Color.white : Palette.ink)
        .background(selected ? Palette.leaf : Color.white)
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(selected ? Palette.leaf : Palette.mint, lineWidth: 1)
        )
    }
}
