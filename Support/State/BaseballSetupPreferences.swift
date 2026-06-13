import Foundation

/// Last-used Baseball setup chip values (restored on setup `onAppear`).
/// Register in `LocalDataResetInventory.setupPreferenceStores` when adding modes.
enum BaseballSetupPreferences {
    private static let inningCountKey = "baseballSetup.inningCount"
    private static let tieBreakerKey = "baseballSetup.tieBreaker"
    private static let stretchKey = "baseballSetup.seventhInningStretch"

    static func load(userDefaults: UserDefaults = .standard) -> (inningCount: Int, tieBreaker: BaseballTieBreaker, seventhInningStretch: Bool) {
        let innings = userDefaults.object(forKey: inningCountKey) as? Int ?? 9
        let tieRaw = userDefaults.string(forKey: tieBreakerKey) ?? BaseballTieBreaker.extraInnings.rawValue
        let tie = BaseballTieBreaker(rawValue: tieRaw) ?? .extraInnings
        let stretch = userDefaults.object(forKey: stretchKey) as? Bool ?? false
        return (max(1, innings), tie, stretch)
    }

    static func save(
        inningCount: Int,
        tieBreaker: BaseballTieBreaker,
        seventhInningStretch: Bool,
        userDefaults: UserDefaults = .standard
    ) {
        userDefaults.set(max(1, inningCount), forKey: inningCountKey)
        userDefaults.set(tieBreaker.rawValue, forKey: tieBreakerKey)
        userDefaults.set(seventhInningStretch, forKey: stretchKey)
    }

    static func clearStored(userDefaults: UserDefaults = .standard) {
        userDefaults.removeObject(forKey: inningCountKey)
        userDefaults.removeObject(forKey: tieBreakerKey)
        userDefaults.removeObject(forKey: stretchKey)
    }
}
