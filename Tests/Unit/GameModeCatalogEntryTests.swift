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
            let mickeyMouse = try #require(GameModeCatalog.entry(for: .mickeyMouse))
            #expect(mickeyMouse.pendingModeSelection == PendingModeSelection(
                setupCategory: .standard,
                mode: nil,
                partyGame: nil,
                matchType: .mickeyMouse
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
        let plannedParty = GameModeCatalog.planned.first { $0.section == .party }
        let plannedPractice = GameModeCatalog.planned.first { $0.section == .practice }
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

    @Test
    func multiplayerCapableModesUseMinimumPlusLabel() throws {
        // X01 has a minimum of one player but is multiplayer-capable: it must read
        // "1+ players", not the solo "1 player" label.
        let x01 = try #require(GameModeCatalog.entry(for: .x01))
        #expect(x01.isSolo == false)
        #expect(x01.playerCountLabel == L10n.format("modes.playerCount.minimumFormat", 1))

        let cricket = try #require(GameModeCatalog.entry(for: .cricket))
        #expect(cricket.playerCountLabel == L10n.format("modes.playerCount.minimumFormat", 2))

        let killer = try #require(GameModeCatalog.entry(for: .killer))
        #expect(killer.playerCountLabel == L10n.format("modes.playerCount.minimumFormat", 3))
    }

    @Test
    func everyModeMinimumDoesNotExceedMaximum() {
        for entry in GameModeCatalog.all {
            #expect(entry.minimumPlayers <= entry.maximumPlayers)
            #expect(entry.minimumPlayers >= 1)
        }
    }

    @Test
    func onlySoloChallengeDrillsAreSinglePlayerCapped() {
        // The roster-skip fork is reserved for true solo drills (max one player).
        for entry in GameModeCatalog.all where entry.isSolo {
            #expect(entry.uiTemplate == .soloChallenge)
        }
    }

    @Test
    func rulesGuideAvailabilityMatchesCatalog() throws {
        let x01 = try #require(GameModeCatalog.entry(for: .x01))
        let americanCricket = try #require(GameModeCatalog.entry(for: .americanCricket))
        let golf = try #require(GameModeCatalog.entry(for: .golf))

        #expect(x01.hasRulesGuide)
        #expect(americanCricket.hasRulesGuide)
        #expect(golf.hasRulesGuide)
    }

    @Test
    func plannedCoopRaidIsShippedWithRulesGuide() throws {
        let raid = try #require(GameModeCatalog.entry(for: "coop.raid"))
        #expect(raid.matchType == .raid)
        #expect(raid.isAvailable)
        #expect(raid.hasRulesGuide)
        #expect(GameRulesCatalog.hasGuide(for: .raid))
    }

    @Test
    func otherPlannedCoopModesLackPreviewRulesGuides() throws {
        for id in ["coop.cerberus", "coop.theVault", "coop.clearTheBoard"] {
            let entry = try #require(GameModeCatalog.entry(for: id))
            #expect(!entry.hasRulesGuide)
        }
    }

    @Test
    func coopPlannedModesUseAmberSectionAccent() throws {
        for id in ["coop.raid", "coop.cerberus", "coop.theVault", "coop.clearTheBoard"] {
            let entry = try #require(GameModeCatalog.entry(for: id))
            #expect(entry.section == .coop)
            #expect(entry.accentColor == Brand.amber)
        }
    }
}
