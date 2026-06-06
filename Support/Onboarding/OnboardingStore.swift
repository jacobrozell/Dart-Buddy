import Foundation

enum OnboardingExperience: String, Sendable {
    case experienced
    case beginner
}

/// Persists whether the user has finished the first-launch app tour.
struct OnboardingStore: Sendable {
    static let completedKey = "onboarding_completed"
    static let experienceKey = "onboarding_darts_experience"
    static let skipLaunchArgument = "-skip_onboarding"
    static let uiTestOnboardingLaunchArgument = "-ui_test_onboarding"

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
        if arguments.contains(uiTestOnboardingLaunchArgument) {
            return true
        }
        return !arguments.contains(skipLaunchArgument) && !arguments.contains("-ui_test_reset")
    }

    var shouldPresentOnLaunch: Bool {
        isEnabled && !userDefaults.bool(forKey: Self.completedKey)
    }

    var savedExperience: OnboardingExperience? {
        guard let raw = userDefaults.string(forKey: Self.experienceKey) else { return nil }
        return OnboardingExperience(rawValue: raw)
    }

    func markCompleted() {
        userDefaults.set(true, forKey: Self.completedKey)
    }

    func saveExperience(_ experience: OnboardingExperience) {
        userDefaults.set(experience.rawValue, forKey: Self.experienceKey)
    }

    func clearPersistedState() {
        userDefaults.removeObject(forKey: Self.completedKey)
        userDefaults.removeObject(forKey: Self.experienceKey)
    }
}

enum OnboardingPresentationMode: Sendable {
    case firstLaunch
    case replay
}
