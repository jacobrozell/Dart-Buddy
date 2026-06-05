import Foundation

enum KillerSetupPreferences {
    private static let livesKey = "killer.setup.startingLives"

    static func load() -> Int {
        let stored = UserDefaults.standard.integer(forKey: livesKey)
        return stored == 0 ? 3 : min(5, max(3, stored))
    }

    static func save(startingLives: Int) {
        UserDefaults.standard.set(min(5, max(3, startingLives)), forKey: livesKey)
    }
}
