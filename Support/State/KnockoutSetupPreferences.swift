import Foundation

/// Last-used Knockout setup chip values (restored on setup `onAppear`).
enum KnockoutSetupPreferences {
    private static let strikesToEliminateKey = "knockoutSetup.strikesToEliminate"

    static func load() -> Int {
        let defaults = UserDefaults.standard
        let strikes = defaults.object(forKey: strikesToEliminateKey) as? Int ?? 3
        return max(1, min(5, strikes))
    }

    static func save(strikesToEliminate: Int) {
        UserDefaults.standard.set(max(1, min(5, strikesToEliminate)), forKey: strikesToEliminateKey)
    }

    static func clearStored(userDefaults: UserDefaults = .standard) {
        userDefaults.removeObject(forKey: strikesToEliminateKey)
    }
}
