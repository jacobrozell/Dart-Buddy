import Foundation

enum RaidSetupPreferences {
    private static let bossTierKey = "raidSetup.bossTier"
    private static let heroHeartsKey = "raidSetup.heroHearts"
    private static let enrageEnabledKey = "raidSetup.enrageEnabled"

    static func loadBossTier(userDefaults: UserDefaults = .standard) -> RaidBossTier {
        let raw = userDefaults.string(forKey: bossTierKey) ?? RaidBossTier.standard.rawValue
        return RaidBossTier(rawValue: raw) ?? .standard
    }

    static func save(bossTier: RaidBossTier, userDefaults: UserDefaults = .standard) {
        userDefaults.set(bossTier.rawValue, forKey: bossTierKey)
    }

    static func loadHeroHearts(userDefaults: UserDefaults = .standard) -> Int {
        let value = userDefaults.integer(forKey: heroHeartsKey)
        return [3, 4, 5].contains(value) ? value : 3
    }

    static func save(heroHearts: Int, userDefaults: UserDefaults = .standard) {
        userDefaults.set(heroHearts, forKey: heroHeartsKey)
    }

    static func loadEnrageEnabled(userDefaults: UserDefaults = .standard) -> Bool {
        userDefaults.object(forKey: enrageEnabledKey) as? Bool ?? true
    }

    static func save(enrageEnabled: Bool, userDefaults: UserDefaults = .standard) {
        userDefaults.set(enrageEnabled, forKey: enrageEnabledKey)
    }

    static func makeConfig(userDefaults: UserDefaults = .standard) -> MatchConfigRaid {
        MatchConfigRaid(
            bossTier: loadBossTier(userDefaults: userDefaults),
            heroHearts: loadHeroHearts(userDefaults: userDefaults),
            enrageEnabled: loadEnrageEnabled(userDefaults: userDefaults)
        )
    }

    static func clearStored(userDefaults: UserDefaults = .standard) {
        userDefaults.removeObject(forKey: bossTierKey)
        userDefaults.removeObject(forKey: heroHeartsKey)
        userDefaults.removeObject(forKey: enrageEnabledKey)
    }
}
