import SwiftUI
import Testing
@testable import DartBuddy

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
        instantBotTurnsEnabled: false,
        defaultDartEntryPresentationRaw: "visualBoard",
        updatedAt: Date()
    )

    store.apply(settings)

    #expect(store.feedback.botStaggerEnabled == false)
    #expect(store.feedback.botDartHapticsEnabled == false)
    #expect(store.appearanceModeRaw == "dark")
    #expect(store.preferredColorScheme == .dark)
    #expect(store.defaultDartEntryPresentation == .visualBoard)
}
