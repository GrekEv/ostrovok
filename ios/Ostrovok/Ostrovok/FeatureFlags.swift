import Foundation

/// Переключатели для тестовых сборок.
/// authEnabled = false: пользователь сразу попадает в онбординг / главную.
enum FeatureFlags {
    static let authEnabled = false
    /// Для симулятора API доступен на этом компьютере по 127.0.0.1.
    /// На реальном iPhone задайте OSTROVOK_API_URL в Scheme → Environment Variables.
    static let remoteAPIEnabled = true
    static let defaultAPIURL = "http://127.0.0.1:8080"
}
