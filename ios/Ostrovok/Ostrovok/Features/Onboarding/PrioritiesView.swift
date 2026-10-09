import SwiftUI

struct PrioritiesView: View {
    @Binding var selection: Set<String>
    let onContinue: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top, spacing: 12) {
                OstrovokMascot(mood: .think, size: 72)
                Text("Что для вас важно в путешествии?")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Palette.ink)
                    .padding(.top, 10)
            }
            .padding(.horizontal, 24)

            ScrollView {
                VStack(spacing: 10) {
                    ForEach(Catalog.priorities) { item in
                        Button {
                            if selection.contains(item.id) {
                                selection.remove(item.id)
                            } else {
                                selection.insert(item.id)
                            }
                        } label: {
                            priorityRow(item)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 24)
            }

            PrimaryButton(
                title: selection.isEmpty ? "К универсальным предложениям" : "К карточкам",
                action: onContinue
            )
            .padding(.horizontal, 24)
            .padding(.bottom, 28)
        }
    }

    private func priorityRow(_ item: TravelPriority) -> some View {
        let selected = selection.contains(item.id)
        return HStack(spacing: 14) {
            Image(systemName: item.symbol)
                .font(.title3)
                .foregroundStyle(selected ? Color.white : Palette.leaf)
                .frame(width: 36)
            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(.headline)
                Text(item.subtitle)
                    .font(.footnote)
                    .foregroundStyle(selected ? Color.white.opacity(0.85) : Palette.muted)
            }
            Spacer()
        }
        .padding(16)
        .foregroundStyle(selected ? Color.white : Palette.ink)
        .background(selected ? Palette.leaf : Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Palette.mint, lineWidth: selected ? 0 : 1)
        )
    }
}
