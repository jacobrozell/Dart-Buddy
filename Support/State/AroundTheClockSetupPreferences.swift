import Foundation

/// Last-used Around the Clock setup chip values (restored on setup `onAppear`).
enum AroundTheClockSetupPreferences {
    private static let includeBullFinishKey = "aroundTheClockSetup.includeBullFinish"
    private static let resetPolicyKey = "aroundTheClockSetup.resetPolicy"

    static func load() -> (includeBullFinish: Bool, resetPolicy: AroundTheClockResetPolicy) {
        let defaults = UserDefaults.standard
        let bull = defaults.object(forKey: includeBullFinishKey) as? Bool ?? false
        let policyRaw = defaults.string(forKey: resetPolicyKey)
            ?? AroundTheClockResetPolicy.noReset.rawValue
        let policy = AroundTheClockResetPolicy(rawValue: policyRaw) ?? .noReset
        return (bull, policy)
    }

    static func save(includeBullFinish: Bool, resetPolicy: AroundTheClockResetPolicy) {
        let defaults = UserDefaults.standard
        defaults.set(includeBullFinish, forKey: includeBullFinishKey)
        defaults.set(resetPolicy.rawValue, forKey: resetPolicyKey)
    }

    static func clearStored(userDefaults: UserDefaults = .standard) {
        userDefaults.removeObject(forKey: includeBullFinishKey)
        userDefaults.removeObject(forKey: resetPolicyKey)
    }
}
