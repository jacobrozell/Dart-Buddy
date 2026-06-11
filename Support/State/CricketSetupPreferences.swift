import Foundation

/// Last-used Cricket setup chip values (restored on setup `onAppear`).
/// Register in `LocalDataResetInventory.setupPreferenceStores` when adding modes.
enum CricketSetupPreferences {
    private static let pointsEnabledKey = "cricketSetup.pointsEnabled"
    private static let scoringModeKey = "cricketSetup.scoringMode"

    static func load(userDefaults: UserDefaults = .standard) -> (pointsEnabled: Bool, scoringMode: CricketScoringMode) {
        let points = userDefaults.object(forKey: pointsEnabledKey) as? Bool ?? true
        let modeRaw = userDefaults.string(forKey: scoringModeKey) ?? CricketScoringMode.standard.rawValue
        let mode = CricketScoringMode(rawValue: modeRaw) ?? .standard
        return (points, mode)
    }

    static func save(pointsEnabled: Bool, scoringMode: CricketScoringMode, userDefaults: UserDefaults = .standard) {
        userDefaults.set(pointsEnabled, forKey: pointsEnabledKey)
        userDefaults.set(scoringMode.rawValue, forKey: scoringModeKey)
    }

    static func clearStored(userDefaults: UserDefaults = .standard) {
        userDefaults.removeObject(forKey: pointsEnabledKey)
        userDefaults.removeObject(forKey: scoringModeKey)
    }
}
