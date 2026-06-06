import Testing
@testable import DartBuddy

@Suite("Game mode catalog", .tags(.unit, .setupFlow, .regression))
struct GameModeCatalogTests {
    @Test
    func catalogListsAllTwentyNineModes() {
        #expect(GameModeCatalog.all.count == 29)
    }

    @Test
    func everyEntryHasAStableUniqueIdentity() {
        let ids = GameModeCatalog.all.map(\.id)
        #expect(Set(ids).count == ids.count)
        #expect(ids.allSatisfy { !$0.isEmpty })
    }

    @Test
    func fiveShippedModesCoverEveryMatchType() {
        let shipped = GameModeCatalog.available
        #expect(shipped.count == 5)

        let mappedTypes = Set(shipped.compactMap(\.matchType))
        #expect(mappedTypes == [.x01, .cricket, .baseball, .killer, .shanghai])

        // Each shipped entry round-trips back through the MatchType lookup.
        for type in [MatchType.x01, .cricket, .baseball, .killer, .shanghai] {
            #expect(GameModeCatalog.entry(for: type)?.matchType == type)
        }
    }

    @Test
    func plannedModesAreNotRoutable() {
        for entry in GameModeCatalog.planned {
            #expect(entry.matchType == nil, "Planned mode \(entry.id) must not claim a MatchType")
            #expect(entry.isAvailable == false)
        }
        #expect(GameModeCatalog.planned.count == 24)
    }

    @Test
    func standardAndPartySectionsShipModesToday() {
        // Standard and Party each have shipped modes; Practice is intentionally
        // all-planned for now (the UI collapses fully-unavailable sections behind
        // a "coming soon" teaser rather than rendering a wall of disabled cards —
        // see docs/full-game-catalog-ui.md §3).
        #expect(!GameModeCatalog.entries(in: .standard).filter(\.isAvailable).isEmpty)
        #expect(!GameModeCatalog.entries(in: .party).filter(\.isAvailable).isEmpty)
        #expect(GameModeCatalog.entries(in: .practice).allSatisfy { !$0.isAvailable })
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
    func catalogPartitionsIntoThreeSections() {
        let standard = GameModeCatalog.entries(in: .standard)
        let party = GameModeCatalog.entries(in: .party)
        let practice = GameModeCatalog.entries(in: .practice)

        #expect(standard.allSatisfy { $0.section == .standard })
        #expect(party.allSatisfy { $0.section == .party })
        #expect(practice.allSatisfy { $0.section == .practice })
        #expect(standard.count + party.count + practice.count == GameModeCatalog.all.count)
    }

    @Test
    func entryLookupByIdRoundTrips() {
        for entry in GameModeCatalog.all {
            #expect(GameModeCatalog.entry(for: entry.id) == entry)
        }
    }

    @Test
    func soloChallengeModesAreSinglePlayer() {
        // Solo-challenge modes drive the roster-skip fork in setup, so they must
        // be playable alone.
        let soloChallenges = GameModeCatalog.all.filter { $0.uiTemplate == .soloChallenge }
        #expect(!soloChallenges.isEmpty)
        for entry in soloChallenges {
            #expect(entry.isSolo)
            #expect(entry.section == .practice)
        }
    }
}
