import Foundation

/// Last-used American Cricket setup chip values (restored on setup `onAppear`).
enum AmericanCricketSetupPreferences {
    private static let pointsEnabledKey = "americanCricketSetup.pointsEnabled"

    static func load() -> Bool {
        let defaults = UserDefaults.standard
        // Default is true; only returns false when the key has been explicitly set to false.
        if let stored = defaults.object(forKey: pointsEnabledKey) as? Bool {
            return stored
        }
        return true
    }

    static func save(pointsEnabled: Bool) {
        UserDefaults.standard.set(pointsEnabled, forKey: pointsEnabledKey)
    }

    static func clearStored(userDefaults: UserDefaults = .standard) {
        userDefaults.removeObject(forKey: pointsEnabledKey)
    }
}
