import Testing
@testable import DartBuddy

@Suite("Product surface", .tags(.unit, .regression))
struct ProductSurfaceTests {
    @Test("Lean 1.0 defaults hide extended surface")
    func leanDefaultsHideExtendedSurface() {
        guard !ProductSurface.isFullProductSurfaceEnabled else {
            Issue.record("Run without -enable_full_product_surface to assert lean defaults.")
            return
        }

        #expect(!ProductSurface.showsModesTab)
        #expect(!ProductSurface.showsPartyModes)
        #expect(!ProductSurface.showsTrainingBots)
        #expect(!ProductSurface.showsCustomBots)
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
}
