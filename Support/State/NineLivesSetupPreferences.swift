import Foundation

/// Last-used Nine Lives setup chip values (restored on setup `onAppear`).
enum NineLivesSetupPreferences {
    private static let startingLivesKey = "nineLivesSetup.startingLives"

    static func load() -> NineLivesStartingLives {
        let defaults = UserDefaults.standard
        let raw = defaults.string(forKey: startingLivesKey) ?? NineLivesStartingLives.nine.rawValue
        return NineLivesStartingLives(rawValue: raw) ?? .nine
    }

    static func save(startingLives: NineLivesStartingLives) {
        UserDefaults.standard.set(startingLives.rawValue, forKey: startingLivesKey)
    }

    static func clearStored(userDefaults: UserDefaults = .standard) {
        userDefaults.removeObject(forKey: startingLivesKey)
    }
}
