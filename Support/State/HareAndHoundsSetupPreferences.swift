import Foundation

/// Last-used Hare and Hounds setup chip values (restored on setup `onAppear`).
enum HareAndHoundsSetupPreferences {
    private static let houndStartKey = "hareAndHoundsSetup.houndStart"

    static func load() -> HoundStartPosition {
        let defaults = UserDefaults.standard
        let raw = defaults.string(forKey: houndStartKey) ?? HoundStartPosition.segment5.rawValue
        return HoundStartPosition(rawValue: raw) ?? .segment5
    }

    static func save(houndStart: HoundStartPosition) {
        UserDefaults.standard.set(houndStart.rawValue, forKey: houndStartKey)
    }

    static func clearStored(userDefaults: UserDefaults = .standard) {
        userDefaults.removeObject(forKey: houndStartKey)
    }
}
