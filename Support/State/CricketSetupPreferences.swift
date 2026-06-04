import Foundation

/// Last-used Cricket setup chip values (restored on setup `onAppear`).
enum CricketSetupPreferences {
    private static let pointsEnabledKey = "cricketSetup.pointsEnabled"
    private static let scoringModeKey = "cricketSetup.scoringMode"

    static func load() -> (pointsEnabled: Bool, scoringMode: CricketScoringMode) {
        let defaults = UserDefaults.standard
        let points = defaults.object(forKey: pointsEnabledKey) as? Bool ?? true
        let modeRaw = defaults.string(forKey: scoringModeKey) ?? CricketScoringMode.standard.rawValue
        let mode = CricketScoringMode(rawValue: modeRaw) ?? .standard
        return (points, mode)
    }

    static func save(pointsEnabled: Bool, scoringMode: CricketScoringMode) {
        let defaults = UserDefaults.standard
        defaults.set(pointsEnabled, forKey: pointsEnabledKey)
        defaults.set(scoringMode.rawValue, forKey: scoringModeKey)
    }
}
