import Testing
@testable import DartBuddy

@Suite("Game mode catalog entries", .tags(.unit, .setupFlow, .regression))
struct GameModeCatalogEntryTests {
    @Test
    func shippedModesProducePendingSetupSelections() throws {
        let x01 = try #require(GameModeCatalog.entry(for: .x01))
        let cricket = try #require(GameModeCatalog.entry(for: .cricket))
        let baseball = try #require(GameModeCatalog.entry(for: .baseball))
        let killer = try #require(GameModeCatalog.entry(for: .killer))
        let shanghai = try #require(GameModeCatalog.entry(for: .shanghai))

        #expect(x01.pendingModeSelection == PendingModeSelection(
            setupCategory: .standard,
            mode: .x01,
            partyGame: nil,
            matchType: .x01
        ))
        #expect(cricket.pendingModeSelection == PendingModeSelection(
            setupCategory: .standard,
            mode: .cricket,
            partyGame: nil,
            matchType: .cricket
        ))
        if ProductSurface.showsPartyModes {
            #expect(baseball.pendingModeSelection == PendingModeSelection(
                setupCategory: .party,
                mode: nil,
                partyGame: .baseball,
                matchType: .baseball
            ))
            #expect(killer.pendingModeSelection == PendingModeSelection(
                setupCategory: .party,
                mode: nil,
                partyGame: .killer,
                matchType: .killer
            ))
            #expect(shanghai.pendingModeSelection == PendingModeSelection(
                setupCategory: .party,
                mode: nil,
                partyGame: .shanghai,
                matchType: .shanghai
            ))
        } else {
            #expect(baseball.pendingModeSelection == nil)
            #expect(killer.pendingModeSelection == nil)
            #expect(shanghai.pendingModeSelection == nil)
        }
    }

    @Test
    func plannedModesDoNotProducePendingSetupSelections() {
        for entry in GameModeCatalog.planned {
            #expect(entry.pendingModeSelection == nil)
        }
    }

    @Test
    func searchMatchesNameBlurbAndId() throws {
        let x01 = try #require(GameModeCatalog.entry(for: "standard.x01"))

        #expect(x01.matchesSearchQuery(""))
        #expect(x01.matchesSearchQuery("x01"))
        #expect(x01.matchesSearchQuery("501"))
        #expect(x01.matchesSearchQuery("standard.x01"))
        #expect(!x01.matchesSearchQuery("zzznomatch"))
    }

    @Test
    func shippedModesReuseMatchTypeAccentIcons() throws {
        for type in [MatchType.x01, .cricket, .baseball, .killer, .shanghai] {
            let entry = try #require(GameModeCatalog.entry(for: type))
            #expect(entry.iconSystemName == GameModeAccent.icon(for: type))
        }
    }

    @Test
    func searchIsCaseInsensitive() throws {
        let cricket = try #require(GameModeCatalog.entry(for: "standard.cricket"))
        #expect(cricket.matchesSearchQuery("CRICKET"))
        #expect(cricket.matchesSearchQuery("cricket"))
    }

    @Test
    func plannedModesUseSectionAccentFallback() {
        let plannedStandard = GameModeCatalog.planned.first { $0.section == .standard }
        let plannedParty = GameModeCatalog.planned.first { $0.section == .party }
        let plannedPractice = GameModeCatalog.planned.first { $0.section == .practice }
        #expect(plannedStandard != nil)
        #expect(plannedParty != nil)
        #expect(plannedPractice != nil)
    }

    @Test
    func soloModesUseSoloPlayerCountLabel() {
        let soloModes = GameModeCatalog.all.filter(\.isSolo)
        #expect(!soloModes.isEmpty)
        for entry in soloModes {
            #expect(entry.playerCountLabel == L10n.string("modes.playerCount.solo"))
        }
    }
}
