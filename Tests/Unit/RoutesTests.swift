import Foundation
import Testing
@testable import DartBuddy

@Suite("Play routes", .tags(.unit, .navigation, .regression))
struct RoutesTests {
    @Test
    func matchTypeMapsToPlayRoute() {
        let matchId = UUID()

        #expect(MatchType.x01.playRoute(matchId: matchId) == .x01Match(matchId: matchId))
        #expect(MatchType.cricket.playRoute(matchId: matchId) == .cricketMatch(matchId: matchId))
        #expect(MatchType.baseball.playRoute(matchId: matchId) == .baseballMatch(matchId: matchId))
        #expect(MatchType.killer.playRoute(matchId: matchId) == .killerMatch(matchId: matchId))
        #expect(MatchType.shanghai.playRoute(matchId: matchId) == .shanghaiMatch(matchId: matchId))
    }

    @Test
    func playRoutesWithSameMatchIdAreEqual() {
        let matchId = UUID()
        #expect(PlayRoute.x01Match(matchId: matchId) == PlayRoute.x01Match(matchId: matchId))
        #expect(PlayRoute.matchSummary(matchId: matchId) == PlayRoute.matchSummary(matchId: matchId))
        #expect(PlayRoute.historyDetail(matchId: matchId) == PlayRoute.historyDetail(matchId: matchId))
    }

    @Test
    func playRoutesWithDifferentMatchIdsAreNotEqual() {
        #expect(PlayRoute.x01Match(matchId: UUID()) != PlayRoute.x01Match(matchId: UUID()))
    }

    @Test
    func staticPlayRoutesAreHashable() {
        let routes: Set<PlayRoute> = [.setup]
        #expect(routes.contains(.setup))
    }

    @Test
    func nestedRoutesStoreIdentifiers() {
        let matchId = UUID()
        let playerId = UUID()

        #expect(HistoryRoute.detail(matchId: matchId) == HistoryRoute.detail(matchId: matchId))
        #expect(PlayersRoute.detail(playerId: playerId) == PlayersRoute.detail(playerId: playerId))
        #expect(PlayersRoute.edit(playerId: nil) == PlayersRoute.edit(playerId: nil))
        #expect(SettingsRoute.root == SettingsRoute.root)
    }
}
