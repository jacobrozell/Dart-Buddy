import Foundation

/// Last-used 180 Around the Clock setup chip values (restored on setup `onAppear`).
enum AroundTheClock180SetupPreferences {
    private static let parScoreKey = "aroundTheClock180Setup.parScore"
    private static let parScoreEnabledKey = "aroundTheClock180Setup.parScoreEnabled"

    static func load() -> (parScore: Int, parScoreEnabled: Bool) {
        let defaults = UserDefaults.standard
        let score = defaults.object(forKey: parScoreKey) as? Int ?? 60
        let enabled = defaults.object(forKey: parScoreEnabledKey) as? Bool ?? false
        return (max(0, min(180, score)), enabled)
    }

    static func save(parScore: Int, parScoreEnabled: Bool, userDefaults: UserDefaults = .standard) {
        userDefaults.set(max(0, min(180, parScore)), forKey: parScoreKey)
        userDefaults.set(parScoreEnabled, forKey: parScoreEnabledKey)
    }

    static func clearStored(userDefaults: UserDefaults = .standard) {
        userDefaults.removeObject(forKey: parScoreKey)
        userDefaults.removeObject(forKey: parScoreEnabledKey)
    }
}
