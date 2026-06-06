import Testing
@testable import DartBuddy

@Suite("Party games", .tags(.unit, .setupFlow, .regression))
struct PartyGameTests {
    @Test
    func allPartyGamesAreAvailableToday() {
        for game in PartyGame.allCases {
            #expect(game.isAvailable)
        }
    }

    @Test
    func minimumPlayersMatchCatalogExpectations() {
        #expect(PartyGame.baseball.minimumPlayers == 2)
        #expect(PartyGame.shanghai.minimumPlayers == 2)
        #expect(PartyGame.killer.minimumPlayers == 3)
    }

    @Test
    func partyGamesMapToShippedCatalogEntries() throws {
        let mappings: [(PartyGame, MatchType)] = [
            (.baseball, .baseball),
            (.killer, .killer),
            (.shanghai, .shanghai)
        ]
        for (game, type) in mappings {
            let entry = try #require(GameModeCatalog.entry(for: type))
            #expect(entry.isAvailable)
            #expect(entry.pendingModeSelection?.partyGame == game)
            #expect(entry.pendingModeSelection?.setupCategory == .party)
        }
    }

    @Test
    func accessibilityIdentifiersAreStable() {
        #expect(PartyGame.baseball.accessibilityIdentifier == "setup_party_game_baseball")
        #expect(PartyGame.killer.accessibilityIdentifier == "setup_party_game_killer")
        #expect(PartyGame.shanghai.accessibilityIdentifier == "setup_party_game_shanghai")
    }

    @Test
    func titleAndSubtitleKeysResolve() {
        for game in PartyGame.allCases {
            #expect(!L10n.string(game.titleKey).isEmpty)
            #expect(!L10n.string(game.subtitleKey).isEmpty)
        }
    }
}
