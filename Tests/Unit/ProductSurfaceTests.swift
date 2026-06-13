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
        #expect(!ProductSurface.showsCoopModes)
        #expect(!ProductSurface.showsTrainingBots)
        #expect(ProductSurface.showsCustomBots)
        #expect(!ProductSurface.showsPlayerExport)
        #expect(ProductSurface.showsAccessibilityMarketing)
        #expect(ProductSurface.bundledLocaleCodes == ["en"])
    }

    @Test("Full product surface restores hidden areas")
    func fullSurfaceLaunchArgumentEnablesExtendedAreas() {
        guard ProductSurface.isFullProductSurfaceEnabled else {
            return
        }

        #expect(ProductSurface.showsModesTab)
        #expect(ProductSurface.showsPartyModes)
        #expect(ProductSurface.showsCoopModes)
        #expect(ProductSurface.showsTrainingBots)
        #expect(ProductSurface.showsCustomBots)
        #expect(ProductSurface.showsPlayerExport)
        #expect(ProductSurface.showsAccessibilityMarketing)
        #expect(ProductSurface.bundledLocaleCodes == ["en", "de", "es", "nl"])
    }

    @Test("Lean 1.0 only exposes X01 and Cricket gameplay")
    func leanMatchTypeReachability() {
        guard !ProductSurface.isFullProductSurfaceEnabled else {
            return
        }

        #expect(ProductSurface.isMatchTypeReachable(.x01))
        #expect(ProductSurface.isMatchTypeReachable(.cricket))
        #expect(!ProductSurface.isMatchTypeReachable(.baseball))
        #expect(!ProductSurface.isMatchTypeReachable(.killer))
        #expect(!ProductSurface.isMatchTypeReachable(.shanghai))
        #expect(!ProductSurface.isMatchTypeReachable(.golf))
        #expect(!ProductSurface.isMatchTypeReachable(.fleet))
        #expect(!ProductSurface.isMatchTypeReachable(.raid))
        #expect(!ProductSurface.isMatchTypeReachable(.aroundTheClock))
    }

    @Test("Full product surface exposes shipped catalog modes")
    func fullSurfaceMatchTypeReachability() {
        guard ProductSurface.isFullProductSurfaceEnabled else {
            return
        }

        for matchType in [MatchType.x01, .cricket, .baseball, .killer, .shanghai, .golf, .aroundTheClock, .fleet, .raid] {
            #expect(ProductSurface.isMatchTypeReachable(matchType))
        }
    }
}
