import SwiftUI

struct CountrySelectionView: View {
    @Binding var selection: Set<String>
    let onContinue: () -> Void

    private let columns = [GridItem(.adaptive(minimum: 150), spacing: 10)]

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            header
            ScrollView {
                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(Catalog.countries) { country in
                        Button {
                            if selection.contains(country.code) {
                                selection.remove(country.code)
                            } else {
                                selection.insert(country.code)
                            }
                        } label: {
                            Chip(
                                title: country.name,
                                selected: selection.contains(country.code),
                                emoji: country.emoji
                            )
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 24)
            }
            PrimaryButton(title: continueTitle, action: onContinue)
                .padding(.horizontal, 24)
                .padding(.bottom, 28)
        }
    }

    private var continueTitle: String {
        selection.isEmpty ? "Дальше без стран" : "Дальше"
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                OstrovokMascot(mood: .wink, size: 72)
                Text("Куда хотели бы поехать? Можно несколько стран — или ни одной.")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Palette.ink)
                    .padding(.top, 8)
            }
        }
        .padding(.horizontal, 24)
    }
}
