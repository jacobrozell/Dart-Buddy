import Foundation

/// Last-used Killer setup chip values (restored on setup `onAppear`).
/// Register in `LocalDataResetInventory.setupPreferenceStores` when adding modes.
enum KillerSetupPreferences {
    private static let livesKey = "killer.setup.startingLives"

    static func load(userDefaults: UserDefaults = .standard) -> Int {
        let stored = userDefaults.integer(forKey: livesKey)
        return stored == 0 ? 3 : min(5, max(3, stored))
    }

    static func save(startingLives: Int, userDefaults: UserDefaults = .standard) {
        userDefaults.set(min(5, max(3, startingLives)), forKey: livesKey)
    }

    static func clearStored(userDefaults: UserDefaults = .standard) {
        userDefaults.removeObject(forKey: livesKey)
    }
}
