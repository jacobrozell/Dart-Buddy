import Testing
@testable import DartBuddy

@Suite("Product surface", .tags(.unit, .regression))
struct ProductSurfaceTests {
    @Test("Lean 1.0 defaults hide extended product areas")
    func leanDefaultsHideExtendedAreas() {
        guard !ProductSurface.isFullProductSurfaceEnabled else {
            return
        }

        #expect(!ProductSurface.showsModesTab)
        #expect(!ProductSurface.showsPartyModes)
        #expect(!ProductSurface.showsTrainingBots)
        #expect(ProductSurface.showsCustomBots)
        #expect(!ProductSurface.showsPlayerExport)
        #expect(ProductSurface.bundledLocaleCodes == ["en"])
    }

    @Test("Full product surface restores hidden areas")
    func fullSurfaceLaunchArgumentEnablesExtendedAreas() {
        guard ProductSurface.isFullProductSurfaceEnabled else {
            return
        }

        #expect(ProductSurface.showsModesTab)
        #expect(ProductSurface.showsPartyModes)
        #expect(ProductSurface.showsTrainingBots)
        #expect(ProductSurface.showsCustomBots)
        #expect(ProductSurface.showsPlayerExport)
        #expect(ProductSurface.bundledLocaleCodes == ["en", "de", "es", "nl"])
    }

    @Test("Match type reachability includes all shipped modes on dev")
    func matchTypeReachability() {
        for matchType in [MatchType.x01, .cricket, .baseball, .killer, .shanghai, .golf, .aroundTheClock] {
            #expect(ProductSurface.isMatchTypeReachable(matchType))
        }
    }
}
