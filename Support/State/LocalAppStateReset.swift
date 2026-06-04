import Foundation

/// Clears non-SwiftData local state (UserDefaults) used by the app.
enum LocalAppStateReset {
    static let didResetNotification = Notification.Name("dartBuddy.localDataDidReset")

    static func clearAllPersistedAuxiliaryState(userDefaults: UserDefaults = .standard) {
        OnboardingStore(userDefaults: userDefaults).clearPersistedState()
        AppStoreUpdateChecker.clearPersistedState(userDefaults: userDefaults)
        CricketSetupPreferences.clearStored(userDefaults: userDefaults)
    }

    static func notifyDidReset() {
        NotificationCenter.default.post(name: didResetNotification, object: nil)
    }
}
