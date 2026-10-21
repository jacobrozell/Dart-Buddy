import Foundation

/// Last-used Around the Clock setup chip values (restored on setup `onAppear`).
enum AroundTheClockSetupPreferences {
    private static let includeBullFinishKey = "aroundTheClockSetup.includeBullFinish"
    private static let resetPolicyKey = "aroundTheClockSetup.resetPolicy"

    static func load(userDefaults: UserDefaults = .standard) -> (includeBullFinish: Bool, resetPolicy: AroundTheClockResetPolicy) {
        let bull = userDefaults.object(forKey: includeBullFinishKey) as? Bool ?? false
        let policyRaw = userDefaults.string(forKey: resetPolicyKey)
            ?? AroundTheClockResetPolicy.noReset.rawValue
        let policy = AroundTheClockResetPolicy(rawValue: policyRaw) ?? .noReset
        return (bull, policy)
    }

    static func save(
        includeBullFinish: Bool,
        resetPolicy: AroundTheClockResetPolicy,
        userDefaults: UserDefaults = .standard
    ) {
        userDefaults.set(includeBullFinish, forKey: includeBullFinishKey)
        userDefaults.set(resetPolicy.rawValue, forKey: resetPolicyKey)
    }

    static func clearStored(userDefaults: UserDefaults = .standard) {
        userDefaults.removeObject(forKey: includeBullFinishKey)
        userDefaults.removeObject(forKey: resetPolicyKey)
    }
}
