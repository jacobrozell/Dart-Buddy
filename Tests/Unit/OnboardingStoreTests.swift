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

    private func makeIsolatedDefaults() -> UserDefaults {
        UserDefaults(suiteName: "OnboardingStoreTests.\(UUID().uuidString)")!
    }
}
