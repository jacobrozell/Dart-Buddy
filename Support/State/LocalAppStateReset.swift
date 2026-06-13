import Foundation

/// Clears non-SwiftData local state (UserDefaults) used by the app.
enum LocalAppStateReset {
    static let didResetNotification = Notification.Name("dartBuddy.localDataDidReset")

    static func clearAllPersistedAuxiliaryState(userDefaults: UserDefaults = .standard) {
        LocalDataResetInventory.clearAuxiliaryUserDefaults(userDefaults: userDefaults)
        for store in LocalDataResetInventory.setupPreferenceStores {
            store.clearStored(userDefaults: userDefaults)
        }
    }

    static func notifyDidReset() {
        NotificationCenter.default.post(name: didResetNotification, object: nil)
    }
}
