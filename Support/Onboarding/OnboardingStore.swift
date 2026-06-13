import Foundation

/// Persists whether the user has finished the first-launch app tour.
struct OnboardingStore: Sendable {
    static let completedKey = "onboarding_completed"
    static let experienceTierKey = "onboarding_experience_tier"
    static let legacyExperienceKey = "onboarding_darts_experience"
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

    var savedExperienceTier: BotDifficulty? {
        if let raw = userDefaults.string(forKey: Self.experienceTierKey),
           let tier = BotDifficulty(rawValue: raw) {
            return tier
        }
        guard let legacy = userDefaults.string(forKey: Self.legacyExperienceKey) else { return nil }
        switch legacy {
        case "beginner": return .easy
        case "experienced": return .medium
        default: return nil
        }
    }

    func markCompleted() {
        userDefaults.set(true, forKey: Self.completedKey)
    }

    func saveExperienceTier(_ tier: BotDifficulty) {
        userDefaults.set(tier.rawValue, forKey: Self.experienceTierKey)
    }

    func clearPersistedState() {
        userDefaults.removeObject(forKey: Self.completedKey)
        userDefaults.removeObject(forKey: Self.experienceTierKey)
        userDefaults.removeObject(forKey: Self.legacyExperienceKey)
    }
}

enum OnboardingPresentationMode: Sendable {
    case firstLaunch
    case replay
}
