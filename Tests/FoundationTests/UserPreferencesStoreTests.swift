import SwiftUI
import Testing
@testable import DartsScoreboard

@MainActor
@Test(.tags(.unit, .settings, .regression))
func userPreferencesStoreAppliesBotPacingFromSettings() {
    let store = UserPreferencesStore()
    let settings = SettingsSummary(
        id: UUID(),
        appearanceModeRaw: "dark",
        hapticsEnabled: true,
        soundEnabled: true,
        turnTotalCallerEnabled: false,
        defaultMatchTypeRaw: "x01",
        defaultX01StartScore: 501,
        defaultCheckoutModeRaw: "doubleOut",
        defaultCheckInModeRaw: "straightIn",
        defaultLegFormatRaw: "firstTo",
        defaultLegsToWin: 3,
        defaultSetsEnabled: false,
        botStaggerEnabled: false,
        botDartHapticsEnabled: false,
        updatedAt: Date()
    )

    store.apply(settings)

    #expect(store.feedback.botStaggerEnabled == false)
    #expect(store.feedback.botDartHapticsEnabled == false)
    #expect(store.appearanceModeRaw == "dark")
    #expect(store.preferredColorScheme == .dark)
}
