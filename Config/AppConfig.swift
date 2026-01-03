import Foundation

enum AppConfig {
    /// OpenAI API Key - reads from Info.plist (set via xcconfig or build settings)
    /// Falls back to UserDefaults if not set in build config
    static var openAIAPIKey: String {
        // First try Info.plist (from build settings)
        if let key = Bundle.main.object(forInfoDictionaryKey: "OPENAI_API_KEY") as? String,
           !key.isEmpty,
           key != "your-api-key-here",
           !key.hasPrefix("$(") {
            return key
        }

        // Fall back to UserDefaults (from Settings UI)
        return UserDefaults.standard.string(forKey: "openAIKey") ?? ""
    }

    /// Check if API key is configured
    static var isAPIKeyConfigured: Bool {
        !openAIAPIKey.isEmpty
    }
}
