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
        #expect(config.bundledLocaleCodes == ["en", "de"])
    }

    @Test("Smart 1.2 allowlist ships nine modes including Practice Pack")
    func smartAllowlistMatchesReleaseCatalog() {
        let args = Self.smartReleaseArguments

        #expect(ProductSurface.smart1_2ReleaseCatalogIDs.count == 9)
        #expect(ProductSurface.smart1_2ReleaseCatalogIDs.isSuperset(of: ProductSurface.partyPack1_1CatalogIDs))

        for entry in GameModeCatalog.available {
            guard let matchType = entry.matchType else { continue }
            let reachable = ProductSurface.isMatchTypeReachable(matchType, arguments: args)
            let expected = ProductSurface.smart1_2ReleaseCatalogIDs.contains(entry.id)
            #expect(reachable == expected, "Unexpected reachability for \(entry.id)")
        }
    }

    @Test("Practice Pack modes are reachable on smart 1.2")
    func practicePackModesReachable() {
        let args = Self.smartReleaseArguments

        #expect(ProductSurface.isMatchTypeReachable(.bobs27, arguments: args))
        #expect(ProductSurface.isMatchTypeReachable(.halveIt, arguments: args))
        #expect(ProductSurface.isMatchTypeReachable(.aroundTheClock, arguments: args))
        #expect(!ProductSurface.isMatchTypeReachable(.chaseTheDragon, arguments: args))
        #expect(!ProductSurface.isMatchTypeReachable(.aroundTheClock180, arguments: args))
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
