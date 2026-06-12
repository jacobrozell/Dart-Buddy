import Foundation

/// Last-used English Cricket setup chip values (restored on setup `onAppear`).
enum EnglishCricketSetupPreferences {
    private static let wicketsPerInningsKey = "englishCricketSetup.wicketsPerInnings"
    private static let endWhenTargetPassedKey = "englishCricketSetup.endWhenTargetPassed"

    static func load() -> (wicketsPerInnings: Int, endWhenTargetPassed: Bool) {
        let defaults = UserDefaults.standard
        let wickets = defaults.object(forKey: wicketsPerInningsKey) as? Int ?? 10
        let endEarly = defaults.object(forKey: endWhenTargetPassedKey) as? Bool ?? true
        return (max(1, wickets), endEarly)
    }

    static func save(wicketsPerInnings: Int, endWhenTargetPassed: Bool) {
        let defaults = UserDefaults.standard
        defaults.set(max(1, wicketsPerInnings), forKey: wicketsPerInningsKey)
        defaults.set(endWhenTargetPassed, forKey: endWhenTargetPassedKey)
    }

    static func clearStored(userDefaults: UserDefaults = .standard) {
        userDefaults.removeObject(forKey: wicketsPerInningsKey)
        userDefaults.removeObject(forKey: endWhenTargetPassedKey)
    }
}
