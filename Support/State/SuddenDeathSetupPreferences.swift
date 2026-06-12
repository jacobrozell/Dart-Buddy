import Foundation

/// Last-used Sudden Death setup chip values (restored on setup `onAppear`).
enum SuddenDeathSetupPreferences {
    private static let eliminateAllTiedKey = "suddenDeathSetup.eliminateAllTied"
    private static let visitsPerRoundKey = "suddenDeathSetup.visitsPerRound"

    static func load() -> (eliminateAllTied: Bool, visitsPerRound: Int) {
        let defaults = UserDefaults.standard
        let eliminateAllTied = defaults.object(forKey: eliminateAllTiedKey) as? Bool ?? true
        let visitsPerRound = defaults.object(forKey: visitsPerRoundKey) as? Int ?? 1
        return (eliminateAllTied, max(1, min(2, visitsPerRound)))
    }

    static func save(eliminateAllTied: Bool, visitsPerRound: Int) {
        let defaults = UserDefaults.standard
        defaults.set(eliminateAllTied, forKey: eliminateAllTiedKey)
        defaults.set(max(1, min(2, visitsPerRound)), forKey: visitsPerRoundKey)
    }

    static func clearStored(userDefaults: UserDefaults = .standard) {
        userDefaults.removeObject(forKey: eliminateAllTiedKey)
        userDefaults.removeObject(forKey: visitsPerRoundKey)
    }
}
