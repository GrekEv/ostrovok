import SwiftUI

/// Маскот турагента Островок: маленький остров с пальмой и глазами.
struct OstrovokMascot: View {
    var mood: Mood = .smile
    var size: CGFloat = 160

    enum Mood {
        case smile
        case wink
        case think
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(Palette.mint)
                .frame(width: size * 1.15, height: size * 1.15)

            island
            palm
            face
        }
        .frame(width: size * 1.2, height: size * 1.2)
        .accessibilityLabel("Островок, ваш турагент")
    }

    private var island: some View {
        Ellipse()
            .fill(Palette.leaf)
            .frame(width: size * 0.78, height: size * 0.28)
            .offset(y: size * 0.18)
            .shadow(color: Palette.forest.opacity(0.2), radius: 8, y: 6)
    }

    private var palm: some View {
        ZStack {
            Capsule()
                .fill(Color(red: 0.62, green: 0.42, blue: 0.22))
                .frame(width: size * 0.06, height: size * 0.38)
                .rotationEffect(.degrees(-8))
                .offset(x: -size * 0.02, y: -size * 0.08)

            ForEach(0..<5, id: \.self) { index in
                Capsule()
                    .fill(Palette.forest)
                    .frame(width: size * 0.28, height: size * 0.08)
                    .rotationEffect(.degrees(Double(index) * 36 - 70))
                    .offset(x: size * 0.08, y: -size * 0.28)
            }
        }
    }

    private var face: some View {
        HStack(spacing: size * 0.12) {
            eye(closed: mood == .wink)
            eye(closed: false)
        }
        .offset(y: size * 0.16)
        .overlay(alignment: .bottom) {
            Capsule()
                .fill(Palette.forest.opacity(mood == .think ? 0.4 : 0.9))
                .frame(width: size * 0.16, height: size * 0.035)
                .offset(y: size * 0.08)
        }
    }

    private func eye(closed: Bool) -> some View {
        Group {
            if closed {
                Capsule()
                    .fill(Palette.ink)
                    .frame(width: size * 0.08, height: size * 0.012)
            } else {
                Circle()
                    .fill(Color.white)
                    .frame(width: size * 0.09, height: size * 0.09)
                    .overlay(
                        Circle()
                            .fill(Palette.ink)
                            .frame(width: size * 0.045, height: size * 0.045)
                    )
            }
        }
    }
}
