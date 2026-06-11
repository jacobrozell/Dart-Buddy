import Foundation

/// Last-used match-setup chip values stored in `UserDefaults`.
///
/// When adding a new game mode with setup preferences:
/// 1. Conform the preferences type to this protocol.
/// 2. Register it in `LocalDataResetInventory.setupPreferenceStores`.
protocol PersistedSetupPreferences {
    static func clearStored(userDefaults: UserDefaults)
}

extension CricketSetupPreferences: PersistedSetupPreferences {}
extension BaseballSetupPreferences: PersistedSetupPreferences {}
extension ShanghaiSetupPreferences: PersistedSetupPreferences {}
extension KillerSetupPreferences: PersistedSetupPreferences {}
