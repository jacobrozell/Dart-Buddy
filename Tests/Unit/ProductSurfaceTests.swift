import Testing
@testable import DartBuddy

@Suite("Product surface", .tags(.unit, .regression))
struct ProductSurfaceTests {
    private static let partyPackReleaseArguments = [ProductSurface.leanProductSurfaceLaunchArgument]
    /// TestFlight / App Store: no launch arguments.
    private static let testFlightArguments: [String] = []

    @Test("TestFlight launch uses party pack without launch arguments")
    func testFlightLaunchUsesPartyPackWithoutLaunchArguments() {
        let args = Self.testFlightArguments
        let config = ProductSurface.configuration(for: args)

        #expect(!ProductSurface.isFullProductSurfaceEnabled(arguments: args))
        #expect(config == .party1_1)
        #expect(!config.showsModesTab)
        #expect(!config.showsTrainingBots)
        #expect(!config.showsPlayerExport)
    }

    @Test("TestFlight reachability matches party pack allowlist exactly")
    func testFlightReachabilityMatchesAllowlistExactly() {
        let args = Self.testFlightArguments

        for entry in GameModeCatalog.all where entry.isAvailable {
            guard let matchType = entry.matchType else { continue }
            let reachable = ProductSurface.isMatchTypeReachable(matchType, arguments: args)
            let expected = ProductSurface.partyPack1_1CatalogIDs.contains(entry.id)
            #expect(reachable == expected, "Unexpected reachability for \(entry.id)")
        }
    }

    @Test("Default play setup picker lists exactly seven modes")
    func defaultPlaySetupPickerListsExactlySevenModes() {
        guard !ProductSurface.isFullProductSurfaceEnabled else { return }

        let sections = GameModeCatalog.playSetupPickerSections()
        let ids = Set(sections.flatMap(\.1).map(\.id))
        #expect(ids == ProductSurface.partyPack1_1CatalogIDs)
        #expect(sections.flatMap(\.1).count == 7)
        #expect(GameModeCatalog.playSetupPickerMoreComingCount(in: .standard, displayedCount: 2) == 0)
        #expect(GameModeCatalog.playSetupPickerMoreComingCount(in: .party, displayedCount: 3) == 0)
        #expect(GameModeCatalog.playSetupPickerMoreComingCount(in: .coop, displayedCount: 1) == 0)
        #expect(GameModeCatalog.playSetupPickerMoreComingCount(in: .practice, displayedCount: 1) == 0)
    }

    @Test("Release defaults expose party modes without Modes tab")
    func releaseDefaultsExposePartyPack() {
        let config = ProductSurface.configuration(for: Self.partyPackReleaseArguments)

        #expect(!config.showsModesTab)
        #expect(config.showsPartyModes)
        #expect(!config.showsCoopModes)
        #expect(!config.showsTrainingBots)
        #expect(config.showsCustomBots)
        #expect(!config.showsPlayerExport)
        #expect(config.showsAccessibilityMarketing)
        #expect(config.bundledLocaleCodes == ["en"])
    }

    @Test("Full product surface restores hidden areas")
    func fullSurfaceLaunchArgumentEnablesExtendedAreas() {
        let config = ProductSurface.configuration(for: [ProductSurface.fullProductSurfaceLaunchArgument])

        #expect(config.showsModesTab)
        #expect(config.showsPartyModes)
        #expect(config.showsCoopModes)
        #expect(config.showsTrainingBots)
        #expect(config.showsCustomBots)
        #expect(config.showsPlayerExport)
        #expect(config.showsAccessibilityMarketing)
        #expect(config.bundledLocaleCodes == ["en", "de", "es", "nl", "fr", "zh-Hans", "it"])
    }

    @Test("Release defaults expose X01, Cricket, party, and practice gameplay")
    func releaseMatchTypeReachability() {
        let args = Self.partyPackReleaseArguments

        #expect(ProductSurface.isMatchTypeReachable(.x01, arguments: args))
        #expect(ProductSurface.isMatchTypeReachable(.cricket, arguments: args))
        #expect(ProductSurface.isMatchTypeReachable(.baseball, arguments: args))
        #expect(ProductSurface.isMatchTypeReachable(.killer, arguments: args))
        #expect(ProductSurface.isMatchTypeReachable(.shanghai, arguments: args))
        #expect(ProductSurface.isMatchTypeReachable(.aroundTheClock, arguments: args))
        #expect(ProductSurface.isMatchTypeReachable(.raid, arguments: args))
        #expect(!ProductSurface.isMatchTypeReachable(.golf, arguments: args))
        #expect(!ProductSurface.isMatchTypeReachable(.fleet, arguments: args))
        #expect(!ProductSurface.isMatchTypeReachable(.aroundTheClock180, arguments: args))
        #expect(!ProductSurface.isMatchTypeReachable(.mickeyMouse, arguments: args))
        #expect(!ProductSurface.isMatchTypeReachable(.americanCricket, arguments: args))
    }

    @Test("Full product surface exposes shipped catalog modes")
    func fullSurfaceMatchTypeReachability() {
        let args = [ProductSurface.fullProductSurfaceLaunchArgument]

        for entry in GameModeCatalog.available {
            guard let matchType = entry.matchType else { continue }
            #expect(ProductSurface.isMatchTypeReachable(matchType, arguments: args))
        }
    }

    @Test("Party pack allowlist matches catalog IDs")
    func partyPackAllowlistMatchesCatalogIDs() {
        let args = Self.partyPackReleaseArguments
        let reachableIDs = Set(
            GameModeCatalog.all.compactMap { entry -> String? in
                guard let matchType = entry.matchType,
                      ProductSurface.isMatchTypeReachable(matchType, arguments: args) else {
                    return nil
                }
                return entry.id
            }
        )
        #expect(reachableIDs == ProductSurface.partyPack1_1CatalogIDs)
    }
}
