import Testing
@testable import DartBuddy

@Suite("Product surface", .tags(.unit, .regression))
struct ProductSurfaceTests {
    @Test("Release defaults expose party modes without Modes tab")
    func releaseDefaultsExposePartyPack() {
        guard !ProductSurface.isFullProductSurfaceEnabled else {
            return
        }

        #expect(!ProductSurface.showsModesTab)
        #expect(ProductSurface.showsPartyModes)
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
        #expect(ProductSurface.bundledLocaleCodes == ["en", "de", "es", "nl", "fr", "zh-Hans", "it"])
    }

    @Test("Release defaults expose X01, Cricket, and party gameplay")
    func releaseMatchTypeReachability() {
        guard !ProductSurface.isFullProductSurfaceEnabled else {
            return
        }

        #expect(ProductSurface.isMatchTypeReachable(.x01))
        #expect(ProductSurface.isMatchTypeReachable(.cricket))
        #expect(ProductSurface.isMatchTypeReachable(.baseball))
        #expect(ProductSurface.isMatchTypeReachable(.killer))
        #expect(ProductSurface.isMatchTypeReachable(.shanghai))
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

        for entry in GameModeCatalog.available {
            guard let matchType = entry.matchType else { continue }
            #expect(ProductSurface.isMatchTypeReachable(matchType))
        }
    }
}
