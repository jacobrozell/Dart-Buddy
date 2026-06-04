import Foundation

/// Last-used Baseball setup chip values (restored on setup `onAppear`).
enum BaseballSetupPreferences {
    private static let inningCountKey = "baseballSetup.inningCount"
    private static let tieBreakerKey = "baseballSetup.tieBreaker"
    private static let stretchKey = "baseballSetup.seventhInningStretch"

    static func load() -> (inningCount: Int, tieBreaker: BaseballTieBreaker, seventhInningStretch: Bool) {
        let defaults = UserDefaults.standard
        let innings = defaults.object(forKey: inningCountKey) as? Int ?? 9
        let tieRaw = defaults.string(forKey: tieBreakerKey) ?? BaseballTieBreaker.extraInnings.rawValue
        let tie = BaseballTieBreaker(rawValue: tieRaw) ?? .extraInnings
        let stretch = defaults.object(forKey: stretchKey) as? Bool ?? false
        return (max(1, innings), tie, stretch)
    }

    static func save(inningCount: Int, tieBreaker: BaseballTieBreaker, seventhInningStretch: Bool) {
        let defaults = UserDefaults.standard
        defaults.set(max(1, inningCount), forKey: inningCountKey)
        defaults.set(tieBreaker.rawValue, forKey: tieBreakerKey)
        defaults.set(seventhInningStretch, forKey: stretchKey)
    }

    static func clearStored(userDefaults: UserDefaults = .standard) {
        userDefaults.removeObject(forKey: inningCountKey)
        userDefaults.removeObject(forKey: tieBreakerKey)
        userDefaults.removeObject(forKey: stretchKey)
    }
}
