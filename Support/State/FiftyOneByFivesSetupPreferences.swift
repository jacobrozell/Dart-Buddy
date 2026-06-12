import Foundation

/// Last-used 51 By 5's setup chip values (restored on setup `onAppear`).
enum FiftyOneByFivesSetupPreferences {
    private static let targetPointsKey = "fiftyOneByFivesSetup.targetPoints"
    private static let mustFinishExactKey = "fiftyOneByFivesSetup.mustFinishExact"

    static func load() -> (targetPoints: Int, mustFinishExact: Bool) {
        let defaults = UserDefaults.standard
        let target = defaults.object(forKey: targetPointsKey) as? Int ?? 51
        let exact = defaults.bool(forKey: mustFinishExactKey)
        return (max(1, target), exact)
    }

    static func save(targetPoints: Int, mustFinishExact: Bool) {
        let defaults = UserDefaults.standard
        defaults.set(max(1, targetPoints), forKey: targetPointsKey)
        defaults.set(mustFinishExact, forKey: mustFinishExactKey)
    }

    static func clearStored(userDefaults: UserDefaults = .standard) {
        userDefaults.removeObject(forKey: targetPointsKey)
        userDefaults.removeObject(forKey: mustFinishExactKey)
    }
}
