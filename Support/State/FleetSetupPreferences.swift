import Foundation

enum FleetSetupPreferences {
    private static let presetKey = "fleetSetup.preset"
    private static let shipCountKey = "fleetSetup.shipCount"
    private static let shipHealthKey = "fleetSetup.shipHealth"
    private static let bullAllowedKey = "fleetSetup.bullAllowed"
    private static let callModeKey = "fleetSetup.callMode"
    private static let sonarEnabledKey = "fleetSetup.sonarEnabled"
    private static let handoffEachTurnKey = "fleetSetup.handoffEachTurn"

    enum Preset: String, CaseIterable {
        case quick, standard, siege, bullseye

        var config: MatchConfigFleet {
            switch self {
            case .quick: .presetQuick()
            case .standard: .presetStandard()
            case .siege: .presetSiege()
            case .bullseye: .presetBullseye()
            }
        }

        var titleKey: String {
            "play.fleet.setup.preset.\(rawValue)"
        }
    }

    static func loadPreset() -> Preset {
        let raw = UserDefaults.standard.string(forKey: presetKey) ?? Preset.standard.rawValue
        return Preset(rawValue: raw) ?? .standard
    }

    static func save(preset: Preset) {
        UserDefaults.standard.set(preset.rawValue, forKey: presetKey)
        let config = preset.config
        save(shipCount: config.shipCount)
        save(shipHealth: config.shipHealth)
        save(bullAllowed: config.bullAllowed)
    }

    static func loadShipCount() -> FleetShipCount {
        let raw = UserDefaults.standard.integer(forKey: shipCountKey)
        return FleetShipCount(rawValue: raw == 0 ? 5 : raw) ?? .standard
    }

    static func save(shipCount: FleetShipCount) {
        UserDefaults.standard.set(shipCount.rawValue, forKey: shipCountKey)
    }

    static func loadShipHealth() -> FleetShipHealth {
        let raw = UserDefaults.standard.integer(forKey: shipHealthKey)
        return FleetShipHealth(rawValue: raw == 0 ? 3 : raw) ?? .armored
    }

    static func save(shipHealth: FleetShipHealth) {
        UserDefaults.standard.set(shipHealth.rawValue, forKey: shipHealthKey)
    }

    static func loadBullAllowed() -> Bool {
        UserDefaults.standard.object(forKey: bullAllowedKey) as? Bool ?? false
    }

    static func save(bullAllowed: Bool) {
        UserDefaults.standard.set(bullAllowed, forKey: bullAllowedKey)
    }

    static func loadCallMode() -> FleetCallMode {
        let raw = UserDefaults.standard.string(forKey: callModeKey) ?? FleetCallMode.strict.rawValue
        return FleetCallMode(rawValue: raw) ?? .strict
    }

    static func save(callMode: FleetCallMode) {
        UserDefaults.standard.set(callMode.rawValue, forKey: callModeKey)
    }

    static func loadSonarEnabled() -> Bool {
        UserDefaults.standard.object(forKey: sonarEnabledKey) as? Bool ?? true
    }

    static func save(sonarEnabled: Bool) {
        UserDefaults.standard.set(sonarEnabled, forKey: sonarEnabledKey)
    }

    static func loadHandoffEachTurn() -> Bool {
        UserDefaults.standard.object(forKey: handoffEachTurnKey) as? Bool ?? false
    }

    static func save(handoffEachTurn: Bool) {
        UserDefaults.standard.set(handoffEachTurn, forKey: handoffEachTurnKey)
    }

    static func buildConfig() -> MatchConfigFleet {
        MatchConfigFleet(
            shipCount: loadShipCount(),
            shipHealth: loadShipHealth(),
            bullAllowed: loadBullAllowed(),
            callMode: loadCallMode(),
            sonarEnabled: loadSonarEnabled(),
            handoffEachTurn: loadHandoffEachTurn()
        )
    }
}
