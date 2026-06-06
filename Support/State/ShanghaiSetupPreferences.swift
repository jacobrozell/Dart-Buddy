import Foundation

/// Last-used Shanghai setup chip values (restored on setup `onAppear`).
enum ShanghaiSetupPreferences {
    private static let roundCountKey = "shanghaiSetup.roundCount"
    private static let bonusRuleKey = "shanghaiSetup.bonusRule"

    static func load() -> (roundCount: Int, bonusRule: ShanghaiBonusRule) {
        let defaults = UserDefaults.standard
        let rounds = defaults.object(forKey: roundCountKey) as? Int ?? 20
        let bonusRaw = defaults.string(forKey: bonusRuleKey) ?? ShanghaiBonusRule.bonus150.rawValue
        let bonus = ShanghaiBonusRule(rawValue: bonusRaw) ?? .bonus150
        return (max(1, min(20, rounds)), bonus)
    }

    static func save(roundCount: Int, bonusRule: ShanghaiBonusRule) {
        let defaults = UserDefaults.standard
        defaults.set(max(1, min(20, roundCount)), forKey: roundCountKey)
        defaults.set(bonusRule.rawValue, forKey: bonusRuleKey)
    }

    static func clearStored(userDefaults: UserDefaults = .standard) {
        userDefaults.removeObject(forKey: roundCountKey)
        userDefaults.removeObject(forKey: bonusRuleKey)
    }
}
