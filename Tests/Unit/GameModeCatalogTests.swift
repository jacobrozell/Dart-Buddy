import Testing
@testable import DartBuddy

@Suite("Game mode catalog", .tags(.unit, .setupFlow, .regression))
struct GameModeCatalogTests {
    @Test
    func catalogListsAllThirtyFourModes() {
        #expect(GameModeCatalog.all.count == 34)
    }

    @Test
    func everyEntryHasAStableUniqueIdentity() {
        let ids = GameModeCatalog.all.map(\.id)
        #expect(Set(ids).count == ids.count)
        #expect(ids.allSatisfy { !$0.isEmpty })
    }

    @Test
    func availableModesMatchCurrentProductSurface() {
        let available = GameModeCatalog.available
        let mappedTypes = Set(available.compactMap(\.matchType))

        #expect(available.allSatisfy { $0.isAvailable })
        #expect(mappedTypes == Set(available.compactMap(\.matchType)))

        if ProductSurface.showsPartyModes {
            #expect(mappedTypes.contains(.baseball))
            #expect(mappedTypes.contains(.golf))
        } else {
            #expect(!mappedTypes.contains(.baseball))
            #expect(!mappedTypes.contains(.golf))
        }

        for type in mappedTypes {
            #expect(GameModeCatalog.entry(for: type)?.matchType == type)
        }
    }

    @Test
    func plannedModesAreNotRoutable() {
        for entry in GameModeCatalog.planned {
            #expect(entry.matchType == nil, "Planned mode \(entry.id) must not claim a MatchType")
            #expect(entry.isAvailable == false)
        }
        #expect(GameModeCatalog.planned.count == 12)
    }

    @Test
    func standardAndPartySectionsShipModesToday() {
        #expect(!GameModeCatalog.entries(in: .standard).filter { $0.isAvailable }.isEmpty)
        #expect(!GameModeCatalog.entries(in: .party).filter { $0.isAvailable }.isEmpty)
        #expect(!GameModeCatalog.entries(in: .practice).filter { $0.isAvailable }.isEmpty)
    }

    @Test
    func comingSoonCountMatchesPlannedEntriesPerSection() {
        for section in GameModeSection.allCases {
            let planned = GameModeCatalog.entries(in: section).filter { !$0.isAvailable }.count
            #expect(GameModeCatalog.comingSoonCount(in: section) == planned)
        }
    }

    @Test
    func everyCatalogEntryHasLocalizedNameAndBlurb() {
        for entry in GameModeCatalog.all {
            #expect(!entry.localizedName.isEmpty)
            #expect(entry.localizedName != entry.nameKey)
            #expect(!entry.localizedBlurb.isEmpty)
            #expect(entry.localizedBlurb != entry.blurbKey)
        }
    }

    @Test
    func catalogPartitionsIntoFourSections() {
        let standard = GameModeCatalog.entries(in: .standard)
        let party = GameModeCatalog.entries(in: .party)
        let coop = GameModeCatalog.entries(in: .coop)
        let practice = GameModeCatalog.entries(in: .practice)

        #expect(standard.allSatisfy { $0.section == .standard })
        #expect(party.allSatisfy { $0.section == .party })
        #expect(coop.allSatisfy { $0.section == .coop })
        #expect(practice.allSatisfy { $0.section == .practice })
        #expect(standard.count + party.count + coop.count + practice.count == GameModeCatalog.all.count)
    }

    @Test
    func entryLookupByIdRoundTrips() {
        for entry in GameModeCatalog.all {
            #expect(GameModeCatalog.entry(for: entry.id) == entry)
        }
    }

    @Test
    func playSetupPickerShowsAllSectionsWhenPartyModesVisible() {
        guard ProductSurface.showsPartyModes else { return }

        let sections = GameModeCatalog.playSetupPickerSections()
        #expect(sections.map(\.0) == GameModeSection.allCases)
        #expect(sections.first { $0.0 == .practice }?.1.count == GameModeCatalog.entries(in: .practice).count)
        #expect(GameModeCatalog.playSetupPickerMoreComingCount(in: .practice, displayedCount: 0) == 0)
    }

    @Test
    func playSetupPickerShowsStandardModesOnlyWhenPartyHidden() {
        guard !ProductSurface.showsPartyModes else { return }

        let sections = GameModeCatalog.playSetupPickerSections()
        #expect(sections.count == 1)
        #expect(sections[0].0 == .standard)
        #expect(sections[0].1.map(\.id) == ["standard.x01", "standard.cricket"])
        #expect(GameModeCatalog.playSetupPickerMoreComingCount(in: .standard, displayedCount: 2) == 0)
        #expect(!sections.contains { $0.0 == .party })
        #expect(!sections.contains { $0.0 == .coop })
        #expect(!sections.contains { $0.0 == .practice })
    }

    @Test
    func selectableInPlaySetupMatchesPendingSelection() {
        for entry in GameModeCatalog.all {
            #expect(entry.isSelectableInPlaySetup == (entry.pendingModeSelection != nil))
        }
    }

    @Test
    func soloChallengeModesAreSinglePlayer() {
        let soloChallenges = GameModeCatalog.all.filter { $0.uiTemplate == .soloChallenge && $0.isAvailable }
        guard !soloChallenges.isEmpty else { return }
        for entry in soloChallenges {
            #expect(entry.isSolo)
            #expect(entry.section == .practice)
        }
    }
}
