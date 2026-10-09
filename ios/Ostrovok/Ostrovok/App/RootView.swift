import SwiftUI

struct RootView: View {
    @EnvironmentObject private var session: AppSession

    var body: some View {
        Group {
            if FeatureFlags.authEnabled {
                AuthPlaceholderView()
            } else if !session.preferences.onboardingCompleted {
                OnboardingFlowView()
            } else {
                MainTabView()
            }
        }
        .tint(Palette.leaf)
        .background(Palette.foam.ignoresSafeArea())
        .task {
            await session.refreshRecommendations()
        }
    }
}
