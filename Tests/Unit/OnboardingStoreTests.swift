import Foundation
import Testing
@testable import DartBuddy

@Suite("Onboarding", .tags(.unit, .regression))
struct OnboardingStoreTests {
    @Test
    func shouldPresentOnLaunchWhenNotCompleted() {
        let defaults = makeIsolatedDefaults()
        let store = OnboardingStore(userDefaults: defaults, isEnabled: true)
        #expect(store.shouldPresentOnLaunch)
    }

    @Test
    func shouldNotPresentAfterMarkCompleted() {
        let defaults = makeIsolatedDefaults()
        let store = OnboardingStore(userDefaults: defaults, isEnabled: true)
        store.markCompleted()
        #expect(!store.shouldPresentOnLaunch)
    }

    @Test
    func shouldNotPresentWhenDisabled() {
        let defaults = makeIsolatedDefaults()
        let store = OnboardingStore(userDefaults: defaults, isEnabled: false)
        #expect(!store.shouldPresentOnLaunch)
    }

    @Test
    func clearPersistedStateResetsFlag() {
        let defaults = makeIsolatedDefaults()
        let store = OnboardingStore(userDefaults: defaults, isEnabled: true)
        store.markCompleted()
        store.clearPersistedState()
        #expect(store.shouldPresentOnLaunch)
    }

    @Test
    func saveAndLoadExperienceTier() {
        let defaults = makeIsolatedDefaults()
        let store = OnboardingStore(userDefaults: defaults, isEnabled: true)
        #expect(store.savedExperienceTier == nil)

        store.saveExperienceTier(.medium)
        #expect(store.savedExperienceTier == .medium)

        store.saveExperienceTier(.veryEasy)
        #expect(store.savedExperienceTier == .veryEasy)
    }

    @Test
    func clearPersistedStateRemovesExperienceTier() {
        let defaults = makeIsolatedDefaults()
        let store = OnboardingStore(userDefaults: defaults, isEnabled: true)
        store.saveExperienceTier(.easy)
        store.clearPersistedState()
        #expect(store.savedExperienceTier == nil)
    }

    @Test
    func legacyExperienceValueMigratesToTier() {
        let defaults = makeIsolatedDefaults()
        defaults.set("beginner", forKey: OnboardingStore.legacyExperienceKey)
        let store = OnboardingStore(userDefaults: defaults, isEnabled: true)
        #expect(store.savedExperienceTier == .easy)
    }

    private func makeIsolatedDefaults() -> UserDefaults {
        UserDefaults(suiteName: "OnboardingStoreTests.\(UUID().uuidString)")!
    }
}
