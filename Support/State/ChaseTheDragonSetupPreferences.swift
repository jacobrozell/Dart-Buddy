import Foundation

/// Last-used Chase the Dragon setup chip values (restored on setup `onAppear`).
enum ChaseTheDragonSetupPreferences {
    private static let lapsKey = "chaseTheDragonSetup.laps"

    static func load() -> ChaseTheDragonLaps {
        let defaults = UserDefaults.standard
        let raw = defaults.integer(forKey: lapsKey)
        return ChaseTheDragonLaps(rawValue: raw) ?? .one
    }

    static func save(laps: ChaseTheDragonLaps) {
        UserDefaults.standard.set(laps.rawValue, forKey: lapsKey)
    }

    static func clearStored(userDefaults: UserDefaults = .standard) {
        userDefaults.removeObject(forKey: lapsKey)
    }
}
