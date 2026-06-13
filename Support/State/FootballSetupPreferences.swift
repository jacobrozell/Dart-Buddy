import Foundation

/// Last-used Football setup chip values (restored on setup `onAppear`).
enum FootballSetupPreferences {
    private static let goalsToWinKey = "footballSetup.goalsToWin"
    private static let kickoffModeKey = "footballSetup.kickoffMode"

    static func load() -> (goalsToWin: Int, kickoffMode: FootballKickoffMode) {
        let defaults = UserDefaults.standard
        let goals = defaults.object(forKey: goalsToWinKey) as? Int ?? 10
        let kickoffRaw = defaults.string(forKey: kickoffModeKey) ?? FootballKickoffMode.singleBull.rawValue
        let kickoff = FootballKickoffMode(rawValue: kickoffRaw) ?? .singleBull
        return (max(1, min(50, goals)), kickoff)
    }

    static func save(goalsToWin: Int, kickoffMode: FootballKickoffMode) {
        let defaults = UserDefaults.standard
        defaults.set(max(1, min(50, goalsToWin)), forKey: goalsToWinKey)
        defaults.set(kickoffMode.rawValue, forKey: kickoffModeKey)
    }

    static func clearStored(userDefaults: UserDefaults = .standard) {
        userDefaults.removeObject(forKey: goalsToWinKey)
        userDefaults.removeObject(forKey: kickoffModeKey)
    }
}
