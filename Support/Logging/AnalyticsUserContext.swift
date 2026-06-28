import FirebaseAnalytics
import Foundation

/// Privacy-safe user properties for retention and product-health segmentation.
///
/// Values are coarse enums/booleans only — never player names, IDs, or notes.
@MainActor
public enum AnalyticsUserContext {
    public static func syncFromBootstrap(
        settings: SettingsSummary?,
        preferences: UserPreferencesStore
    ) {
        sync(
            settings: settings,
            preferences: preferences,
            onboardingComplete: isOnboardingComplete()
        )
    }

    public static func syncAfterSettingsApply(_ settings: SettingsSummary) {
        sync(settings: settings, preferences: nil, onboardingComplete: isOnboardingComplete())
    }

    public static func syncOnboardingCompleted(
        settings: SettingsSummary?,
        preferences: UserPreferencesStore
    ) {
        sync(settings: settings, preferences: preferences, onboardingComplete: true)
    }

    public static func userPropertyValues(
        settings: SettingsSummary?,
        preferences: UserPreferencesStore?,
        onboardingComplete: Bool
    ) -> [String: String] {
        var values: [String: String] = [
            "onboarding_complete": boolString(onboardingComplete),
            "app_locale": appLocaleCode(),
            "product_surface": ProductSurface.analyticsLabel
        ]

        if let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String, !buildNumber.isEmpty {
            values["build_number"] = buildNumber
        }

        if let settings {
            values["appearance_mode"] = settings.appearanceModeRaw
            values["haptics_enabled"] = boolString(settings.hapticsEnabled)
            values["sound_enabled"] = boolString(settings.soundEnabled)
            values["turn_caller_enabled"] = boolString(settings.turnTotalCallerEnabled)
            values["bot_stagger_enabled"] = boolString(settings.botStaggerEnabled)
            values["bot_dart_haptics_enabled"] = boolString(settings.botDartHapticsEnabled)
            values["dart_entry_default"] = DartEntryPresentation(
                rawValueOrDefault: settings.defaultDartEntryPresentationRaw
            ).rawValue
            values["default_match_type"] = settings.defaultMatchTypeRaw
        } else if let preferences {
            values["dart_entry_default"] = preferences.defaultDartEntryPresentation.rawValue
            values["haptics_enabled"] = boolString(preferences.feedback.hapticsEnabled)
            values["sound_enabled"] = boolString(preferences.feedback.soundEnabled)
            values["turn_caller_enabled"] = boolString(preferences.feedback.turnTotalCallerEnabled)
            values["bot_stagger_enabled"] = boolString(preferences.feedback.botStaggerEnabled)
            values["bot_dart_haptics_enabled"] = boolString(preferences.feedback.botDartHapticsEnabled)
        }

        return values
    }

    public static func sync(
        settings: SettingsSummary?,
        preferences: UserPreferencesStore?,
        onboardingComplete: Bool
    ) {
        guard FirebaseBootstrap.shouldConfigure, FirebaseBootstrap.isAnalyticsCollectionEnabled else { return }

        for (name, value) in userPropertyValues(
            settings: settings,
            preferences: preferences,
            onboardingComplete: onboardingComplete
        ) {
            Analytics.setUserProperty(value, forName: name)
        }
    }

    private static func isOnboardingComplete() -> Bool {
        !OnboardingStore.defaultIsEnabled
            || UserDefaults.standard.bool(forKey: OnboardingStore.completedKey)
    }

    private static func appLocaleCode() -> String {
        if let preferred = Bundle.main.preferredLocalizations.first, !preferred.isEmpty {
            return preferred
        }
        if let languageCode = Locale.current.language.languageCode?.identifier, !languageCode.isEmpty {
            return languageCode
        }
        return "unknown"
    }

    private static func boolString(_ value: Bool) -> String {
        value ? "true" : "false"
    }
}
