import Foundation

struct PersistenceManager {
    private static let settingsKey = "TokenChallengeSettings"

    static func loadSettings() -> ChallengeSettings {
        guard let data = UserDefaults.standard.data(forKey: settingsKey),
              let settings = try? JSONDecoder().decode(ChallengeSettings.self, from: data)
        else {
            return .default
        }
        return settings
    }

    static func saveSettings(_ settings: ChallengeSettings) {
        guard let data = try? JSONEncoder().encode(settings) else { return }
        UserDefaults.standard.set(data, forKey: settingsKey)
    }
}
