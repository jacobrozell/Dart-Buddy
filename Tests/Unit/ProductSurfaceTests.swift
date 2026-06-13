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
        #expect(ProductSurface.bundledLocaleCodes == ["en", "de", "es", "nl", "fr", "zh-Hans", "it"])
    }

    @Test("Lean 1.0 reachability keeps core and co-op modes, hides party")
    func leanMatchTypeReachability() {
        guard !ProductSurface.isFullProductSurfaceEnabled else { return }

        #expect(ProductSurface.isMatchTypeReachable(.x01))
        #expect(ProductSurface.isMatchTypeReachable(.cricket))
        #expect(ProductSurface.isMatchTypeReachable(.raid))
        #expect(ProductSurface.isMatchTypeReachable(.aroundTheClock))
        #expect(!ProductSurface.isMatchTypeReachable(.baseball))
        #expect(!ProductSurface.isMatchTypeReachable(.killer))
        #expect(!ProductSurface.isMatchTypeReachable(.golf))
    }

    @Test("Full product surface reachability includes every available catalog mode")
    func fullSurfaceMatchTypeReachability() {
        guard ProductSurface.isFullProductSurfaceEnabled else { return }

        for entry in GameModeCatalog.available {
            guard let matchType = entry.matchType else { continue }
            #expect(ProductSurface.isMatchTypeReachable(matchType))
        }
    }
}
