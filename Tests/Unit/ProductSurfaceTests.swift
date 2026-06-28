import Testing
@testable import DartBuddy

@Suite("Product surface", .tags(.unit, .regression))
struct ProductSurfaceTests {
    private static let smartReleaseArguments = [ProductSurface.leanProductSurfaceLaunchArgument]

    @Test("Smart 1.2 defaults expose training and export")
    func smartDefaultsExposeTrainingAndExport() {
        let args = Self.smartReleaseArguments
        let config = ProductSurface.configuration(for: args)

        #expect(!ProductSurface.isFullProductSurfaceEnabled(arguments: args))
        #expect(config == .smart1_2)
        #expect(!config.showsModesTab)
        #expect(config.showsPartyModes)
        #expect(!config.showsCoopModes)
        #expect(config.showsTrainingBots)
        #expect(config.showsCustomBots)
        #expect(config.showsPlayerExport)
        #expect(config.showsAccessibilityMarketing)
        #expect(config.bundledLocaleCodes == ["en", "de", "es", "nl", "fr"])
    }

    @Test("Smart 1.2 allowlist matches 1.1 gameplay modes")
    func smartAllowlistMatchesPartyPack() {
        let args = Self.smartReleaseArguments

        for entry in GameModeCatalog.available {
            guard let matchType = entry.matchType else { continue }
            let reachable = ProductSurface.isMatchTypeReachable(matchType, arguments: args)
            let expected = ProductSurface.partyPack1_1CatalogIDs.contains(entry.id)
            #expect(reachable == expected, "Unexpected reachability for \(entry.id)")
        }
    }

    @Test("Full product surface restores hidden areas")
    func fullSurfaceLaunchArgumentEnablesExtendedAreas() {
        let args = [ProductSurface.fullProductSurfaceLaunchArgument]
        let config = ProductSurface.configuration(for: args)

        #expect(ProductSurface.isFullProductSurfaceEnabled(arguments: args))
        #expect(config == .full)
        #expect(config.showsModesTab)
        #expect(config.showsPartyModes)
        #expect(config.showsCoopModes)
        #expect(config.showsTrainingBots)
        #expect(config.showsCustomBots)
        #expect(config.showsPlayerExport)
        #expect(config.showsAccessibilityMarketing)
        #expect(config.bundledLocaleCodes == ["en", "de", "es", "nl", "fr", "zh-Hans", "it"])
    }

    @Test("Full product surface exposes shipped catalog modes")
    func fullSurfaceMatchTypeReachability() {
        let args = [ProductSurface.fullProductSurfaceLaunchArgument]

        for entry in GameModeCatalog.available {
            guard let matchType = entry.matchType else { continue }
            #expect(ProductSurface.isMatchTypeReachable(matchType, arguments: args))
        }
    }
}
