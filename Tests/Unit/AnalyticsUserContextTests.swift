import Foundation
import Testing
@testable import DartBuddy

@Suite("Analytics user context", .tags(.unit, .logging, .regression))
@MainActor
struct AnalyticsUserContextTests {
    @Test
    func userPropertyValuesIncludeSettingsAndOnboardingFlags() {
        let settings = SettingsSummary(
            id: UUID(),
            appearanceModeRaw: "dark",
            hapticsEnabled: true,
            soundEnabled: false,
            turnTotalCallerEnabled: true,
            defaultMatchTypeRaw: MatchType.cricket.rawValue,
            defaultX01StartScore: 501,
            defaultCheckoutModeRaw: "doubleOut",
            defaultCheckInModeRaw: "straightIn",
            defaultLegFormatRaw: "bestOf",
            defaultLegsToWin: 3,
            defaultSetsEnabled: false,
            botStaggerEnabled: true,
            botDartHapticsEnabled: false,
            instantBotTurnsEnabled: false,
            defaultDartEntryPresentationRaw: DartEntryPresentation.visualBoard.rawValue,
            updatedAt: Date()
        )

        let values = AnalyticsUserContext.userPropertyValues(
            settings: settings,
            preferences: nil,
            onboardingComplete: true
        )

        #expect(values["onboarding_complete"] == "true")
        #expect(values["appearance_mode"] == "dark")
        #expect(values["haptics_enabled"] == "true")
        #expect(values["sound_enabled"] == "false")
        #expect(values["turn_caller_enabled"] == "true")
        #expect(values["dart_entry_default"] == "visualBoard")
        #expect(values["default_match_type"] == MatchType.cricket.rawValue)
        #expect(values["product_surface"] == ProductSurface.analyticsLabel)
        #expect(values["app_locale"]?.isEmpty == false)
        #expect(values["build_number"]?.isEmpty == false)
    }

    @Test
    func userPropertyValuesFallBackToPreferencesWhenSettingsMissing() {
        let preferences = UserPreferencesStore()
        preferences.apply(
            SettingsSummary(
                id: UUID(),
                appearanceModeRaw: "system",
                hapticsEnabled: false,
                soundEnabled: true,
                turnTotalCallerEnabled: false,
                defaultMatchTypeRaw: MatchType.x01.rawValue,
                defaultX01StartScore: 501,
                defaultCheckoutModeRaw: "doubleOut",
                defaultCheckInModeRaw: "straightIn",
                defaultLegFormatRaw: "bestOf",
                defaultLegsToWin: 1,
                defaultSetsEnabled: false,
                botStaggerEnabled: false,
                botDartHapticsEnabled: true,
                instantBotTurnsEnabled: false,
                defaultDartEntryPresentationRaw: DartEntryPresentation.numberPad.rawValue,
                updatedAt: Date()
            )
        )

        let values = AnalyticsUserContext.userPropertyValues(
            settings: nil,
            preferences: preferences,
            onboardingComplete: false
        )

        #expect(values["onboarding_complete"] == "false")
        #expect(values["haptics_enabled"] == "false")
        #expect(values["sound_enabled"] == "true")
        #expect(values["dart_entry_default"] == "numberPad")
    }
}
