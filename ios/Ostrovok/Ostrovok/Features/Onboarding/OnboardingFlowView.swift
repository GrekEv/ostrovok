import SwiftUI

struct OnboardingFlowView: View {
    @EnvironmentObject private var session: AppSession
    @State private var step: Step = .welcome
    @State private var countries: Set<String> = []
    @State private var priorities: Set<String> = []

    private enum Step {
        case welcome
        case countries
        case priorities
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                if step != .welcome {
                    Button("Назад") {
                        withAnimation(.easeInOut) {
                            step = step == .priorities ? .countries : .welcome
                        }
                    }
                    .foregroundStyle(Palette.forest)
                }
                Spacer()
                Button("Пропустить") {
                    session.skipOnboarding()
                }
                .foregroundStyle(Palette.muted)
            }
            .padding(.horizontal, 24)
            .padding(.top, 12)

            Group {
                switch step {
                case .welcome:
                    WelcomeStepView {
                        withAnimation { step = .countries }
                    }
                case .countries:
                    CountrySelectionView(selection: $countries) {
                        withAnimation { step = .priorities }
                    }
                case .priorities:
                    PrioritiesView(selection: $priorities) {
                        session.completeOnboarding(
                            countries: Array(countries),
                            priorities: Array(priorities),
                            skipped: false
                        )
                    }
                }
            }
            .transition(.opacity.combined(with: .move(edge: .trailing)))
        }
        .background(Palette.foam.ignoresSafeArea())
    }
}

struct WelcomeStepView: View {
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 28) {
            Spacer()
            OstrovokMascot(mood: .smile, size: 180)
            VStack(spacing: 10) {
                Text("Я Островок")
                    .font(.largeTitle.weight(.semibold))
                    .foregroundStyle(Palette.ink)
                Text("Помогу выбрать отель, хостел, тур или перелёт. Сначала расскажите, куда тянет — потом соберём карточки.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Palette.muted)
                    .padding(.horizontal, 12)
            }
            Spacer()
            PrimaryButton(title: "Выбрать страны", action: onContinue)
                .padding(.horizontal, 24)
                .padding(.bottom, 28)
        }
    }
}
