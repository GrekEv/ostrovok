import SwiftUI

/// Заглушка. Экран появится, когда включим FeatureFlags.authEnabled.
struct AuthPlaceholderView: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("Вход")
                .font(.largeTitle.weight(.semibold))
            Text("Google, Apple ID и почта подключим после тестов основного потока.")
                .multilineTextAlignment(.center)
                .foregroundStyle(Palette.muted)
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Palette.foam)
    }
}
