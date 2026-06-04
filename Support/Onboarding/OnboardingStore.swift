import Foundation

/// Persists whether the user has finished the first-launch app tour.
struct OnboardingStore: Sendable {
    static let completedKey = "onboarding_completed"
    static let skipLaunchArgument = "-skip_onboarding"

    let userDefaults: UserDefaults
    let isEnabled: Bool

    init(
        userDefaults: UserDefaults = .standard,
        isEnabled: Bool = OnboardingStore.defaultIsEnabled
    ) {
        self.userDefaults = userDefaults
        self.isEnabled = isEnabled
    }

    static var defaultIsEnabled: Bool {
        let arguments = ProcessInfo.processInfo.arguments
        return !arguments.contains(skipLaunchArgument) && !arguments.contains("-ui_test_reset")
    }

    var shouldPresentOnLaunch: Bool {
        isEnabled && !userDefaults.bool(forKey: Self.completedKey)
    }

    func markCompleted() {
        userDefaults.set(true, forKey: Self.completedKey)
    }

    func clearPersistedState() {
        userDefaults.removeObject(forKey: Self.completedKey)
    }
}

enum OnboardingPresentationMode: Sendable {
    case firstLaunch
    case replay
}
