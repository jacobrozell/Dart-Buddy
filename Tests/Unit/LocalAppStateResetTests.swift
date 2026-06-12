import Foundation
import Testing
@testable import DartBuddy

@Suite("Local app state reset", .tags(.unit, .regression))
struct LocalAppStateResetTests {
    @Test
    func clearAllPersistedAuxiliaryStateRemovesKnownKeys() {
        let defaults = makeIsolatedDefaults()
        OnboardingStore(userDefaults: defaults, isEnabled: true).markCompleted()
        defaults.set(BotDifficulty.easy.rawValue, forKey: OnboardingStore.experienceTierKey)
        defaults.set("9.9.9", forKey: "app_store_update_dismissed_version")
        defaults.set(false, forKey: "cricketSetup.pointsEnabled")
        defaults.set(CricketScoringMode.cutThroat.rawValue, forKey: "cricketSetup.scoringMode")
        KillerSetupPreferences.save(startingLives: 5, userDefaults: defaults)

        LocalAppStateReset.clearAllPersistedAuxiliaryState(userDefaults: defaults)

        #expect(!defaults.bool(forKey: OnboardingStore.completedKey))
        #expect(defaults.string(forKey: OnboardingStore.experienceTierKey) == nil)
        #expect(defaults.string(forKey: "app_store_update_dismissed_version") == nil)
        #expect(defaults.object(forKey: "cricketSetup.pointsEnabled") == nil)
        #expect(defaults.string(forKey: "cricketSetup.scoringMode") == nil)
        #expect(defaults.object(forKey: "killer.setup.startingLives") == nil)
    }

    private func makeIsolatedDefaults() -> UserDefaults {
        UserDefaults(suiteName: "LocalAppStateResetTests.\(UUID().uuidString)")!
    }
}
