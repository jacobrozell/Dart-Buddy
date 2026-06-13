import Foundation

/// Last-used Shanghai setup chip values (restored on setup `onAppear`).
/// Register in `LocalDataResetInventory.setupPreferenceStores` when adding modes.
enum ShanghaiSetupPreferences {
    private static let roundCountKey = "shanghaiSetup.roundCount"
    private static let bonusRuleKey = "shanghaiSetup.bonusRule"

    static func load(userDefaults: UserDefaults = .standard) -> (roundCount: Int, bonusRule: ShanghaiBonusRule) {
        let rounds = userDefaults.object(forKey: roundCountKey) as? Int ?? 20
        let bonusRaw = userDefaults.string(forKey: bonusRuleKey) ?? ShanghaiBonusRule.bonus150.rawValue
        let bonus = ShanghaiBonusRule(rawValue: bonusRaw) ?? .bonus150
        return (max(1, min(20, rounds)), bonus)
    }

    static func save(roundCount: Int, bonusRule: ShanghaiBonusRule, userDefaults: UserDefaults = .standard) {
        userDefaults.set(max(1, min(20, roundCount)), forKey: roundCountKey)
        userDefaults.set(bonusRule.rawValue, forKey: bonusRuleKey)
    }

    static func clearStored(userDefaults: UserDefaults = .standard) {
        userDefaults.removeObject(forKey: roundCountKey)
        userDefaults.removeObject(forKey: bonusRuleKey)
    }
}
