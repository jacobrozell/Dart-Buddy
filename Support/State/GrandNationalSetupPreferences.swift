import Foundation

/// Last-used Grand National setup chip values (restored on setup `onAppear`).
enum GrandNationalSetupPreferences {
    private static let rulesetKey = "grandNationalSetup.ruleset"
    private static let lapsKey = "grandNationalSetup.laps"

    static func load() -> (ruleset: GrandNationalRuleset, laps: Int) {
        let defaults = UserDefaults.standard
        let rulesetRaw = defaults.string(forKey: rulesetKey) ?? GrandNationalRuleset.novice.rawValue
        let ruleset = GrandNationalRuleset(rawValue: rulesetRaw) ?? .novice
        let laps = defaults.object(forKey: lapsKey) as? Int ?? 2
        return (ruleset, max(1, min(10, laps)))
    }

    static func save(ruleset: GrandNationalRuleset, laps: Int) {
        let defaults = UserDefaults.standard
        defaults.set(ruleset.rawValue, forKey: rulesetKey)
        defaults.set(max(1, min(10, laps)), forKey: lapsKey)
    }

    static func clearStored(userDefaults: UserDefaults = .standard) {
        userDefaults.removeObject(forKey: rulesetKey)
        userDefaults.removeObject(forKey: lapsKey)
    }
}
