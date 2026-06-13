import Foundation
import Testing
@testable import DartBuddy

@Suite("Local data reset inventory", .tags(.unit, .settings, .regression))
struct LocalDataResetInventoryTests {
    @Test
    func swiftDataInventoryMatchesReleaseSchema() {
        LocalDataResetInventory.assertSwiftDataInventoryMatchesReleaseSchema()
        #expect(
            LocalDataResetInventory.swiftDataDeleters.count
                == SchemaLock.release_1_0_0Schema.models.count
        )
    }

    @Test
    func setupPreferenceInventoryListsEveryImplementedModeStore() {
        #expect(LocalDataResetInventory.setupPreferenceStores.count == 4)
        let names = Set(LocalDataResetInventory.setupPreferenceStores.map { String(describing: $0) })
        #expect(names.contains("CricketSetupPreferences"))
        #expect(names.contains("BaseballSetupPreferences"))
        #expect(names.contains("ShanghaiSetupPreferences"))
        #expect(names.contains("KillerSetupPreferences"))
    }

    @Test
    func clearAllPersistedAuxiliaryStateRemovesEveryRegisteredStore() {
        let defaults = makeIsolatedDefaults()

        OnboardingStore(userDefaults: defaults, isEnabled: true).markCompleted()
        defaults.set(BotDifficulty.easy.rawValue, forKey: OnboardingStore.experienceTierKey)
        defaults.set("9.9.9", forKey: "app_store_update_dismissed_version")

        BaseballSetupPreferences.save(
            inningCount: 7,
            tieBreaker: .bullPlayoff,
            seventhInningStretch: true,
            userDefaults: defaults
        )
        ShanghaiSetupPreferences.save(
            roundCount: 12,
            bonusRule: .instantWin,
            userDefaults: defaults
        )
        CricketSetupPreferences.save(
            pointsEnabled: false,
            scoringMode: .cutThroat,
            userDefaults: defaults
        )
        KillerSetupPreferences.save(startingLives: 5, userDefaults: defaults)

        LocalAppStateReset.clearAllPersistedAuxiliaryState(userDefaults: defaults)

        #expect(!defaults.bool(forKey: OnboardingStore.completedKey))
        #expect(defaults.string(forKey: OnboardingStore.experienceTierKey) == nil)
        #expect(defaults.string(forKey: "app_store_update_dismissed_version") == nil)

        let baseball = BaseballSetupPreferences.load(userDefaults: defaults)
        #expect(baseball.inningCount == 9)
        #expect(baseball.tieBreaker == .extraInnings)
        #expect(baseball.seventhInningStretch == false)

        let shanghai = ShanghaiSetupPreferences.load(userDefaults: defaults)
        #expect(shanghai.roundCount == 20)
        #expect(shanghai.bonusRule == .bonus150)

        let cricket = CricketSetupPreferences.load(userDefaults: defaults)
        #expect(cricket.pointsEnabled == true)
        #expect(cricket.scoringMode == .standard)

        #expect(KillerSetupPreferences.load(userDefaults: defaults) == 3)
    }

    private func makeIsolatedDefaults() -> UserDefaults {
        UserDefaults(suiteName: "LocalDataResetInventoryTests.\(UUID().uuidString)")!
    }
}
