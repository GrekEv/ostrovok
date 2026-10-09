import SwiftUI

/// Точка входа. Авторизация отключена флагом FeatureFlags.authEnabled —
/// когда будем подключать Google / Apple / почту, меняем только этот флаг и экран AuthView.
@main
struct OstrovokApp: App {
    @StateObject private var session = AppSession()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(session)
                .preferredColorScheme(.light)
        }
    }
}
