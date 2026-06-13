import Foundation

enum RaidSetupPreferences {
    private static let bossTierKey = "raidSetup.bossTier"
    private static let heroHeartsKey = "raidSetup.heroHearts"
    private static let enrageEnabledKey = "raidSetup.enrageEnabled"

    static func loadBossTier() -> RaidBossTier {
        let raw = UserDefaults.standard.string(forKey: bossTierKey) ?? RaidBossTier.standard.rawValue
        return RaidBossTier(rawValue: raw) ?? .standard
    }

    static func save(bossTier: RaidBossTier) {
        UserDefaults.standard.set(bossTier.rawValue, forKey: bossTierKey)
    }

    static func loadHeroHearts() -> Int {
        let value = UserDefaults.standard.integer(forKey: heroHeartsKey)
        return [3, 4, 5].contains(value) ? value : 3
    }

    static func save(heroHearts: Int) {
        UserDefaults.standard.set(heroHearts, forKey: heroHeartsKey)
    }

    static func loadEnrageEnabled() -> Bool {
        UserDefaults.standard.object(forKey: enrageEnabledKey) as? Bool ?? true
    }

    static func save(enrageEnabled: Bool) {
        UserDefaults.standard.set(enrageEnabled, forKey: enrageEnabledKey)
    }

    static func makeConfig() -> MatchConfigRaid {
        MatchConfigRaid(
            bossTier: loadBossTier(),
            heroHearts: loadHeroHearts(),
            enrageEnabled: loadEnrageEnabled()
        )
    }
}
