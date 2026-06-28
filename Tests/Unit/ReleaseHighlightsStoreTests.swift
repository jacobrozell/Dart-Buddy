import Foundation
import Testing
@testable import DartBuddy

@Suite("Release highlights", .tags(.unit, .regression))
struct ReleaseHighlightsStoreTests {
    @Test("Release highlights suppressed on smart1_2 store surface")
    func currentHighlightNilOnSmart12Surface() {
        let storeArgs: [String] = []
        let leanArgs = [ProductSurface.leanProductSurfaceLaunchArgument]
        let fullArgs = [ProductSurface.fullProductSurfaceLaunchArgument]

        #expect(ReleaseHighlights.current(arguments: storeArgs) == nil)
        #expect(ReleaseHighlights.current(arguments: leanArgs) == nil)
        #expect(ReleaseHighlights.current(arguments: fullArgs) == nil)
    }

    @Test("Store presents once per highlight version")
    func shouldPresentOncePerVersion() {
        let defaults = makeIsolatedDefaults()
        let store = ReleaseHighlightsStore(userDefaults: defaults)
        let highlight = ReleaseHighlight.partyPack1_1

        #expect(store.shouldPresent(highlight: highlight))
        store.markDismissed(version: highlight.version)
        #expect(!store.shouldPresent(highlight: highlight))
    }

    @Test("Skip launch argument disables presentation")
    func skipLaunchArgumentDisablesPresentation() {
        let defaults = makeIsolatedDefaults()
        let store = ReleaseHighlightsStore(
            userDefaults: defaults,
            isEnabled: false
        )
        let highlight = ReleaseHighlight.partyPack1_1

        #expect(!store.shouldPresent(highlight: highlight))
    }

    @Test("Clear persisted state removes dismissal")
    func clearPersistedStateRemovesDismissal() {
        let defaults = makeIsolatedDefaults()
        let store = ReleaseHighlightsStore(userDefaults: defaults)
        let highlight = ReleaseHighlight.partyPack1_1

        store.markDismissed(version: highlight.version)
        ReleaseHighlightsStore.clearPersistedState(userDefaults: defaults)

        #expect(ReleaseHighlightsStore(userDefaults: defaults).shouldPresent(highlight: highlight))
    }

    private func makeIsolatedDefaults() -> UserDefaults {
        UserDefaults(suiteName: "ReleaseHighlightsStoreTests.\(UUID().uuidString)")!
    }
}
