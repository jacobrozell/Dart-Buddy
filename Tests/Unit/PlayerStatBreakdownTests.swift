import Foundation
import Testing
@testable import DartBuddy

@Suite("Player stat breakdown", .tags(.unit, .stats, .regression))
struct PlayerStatBreakdownTests {
    @Test
    func average3DartUsesThreeDartFormula() {
        var row = PlayerStatBreakdown(playerId: UUID(), name: "A", darts: 9, points: 180)
        #expect(row.average3Dart == 60)

        row.darts = 0
        #expect(row.average3Dart == 0)
    }

    @Test
    func winPercentTracksGamesAndWins() {
        var row = PlayerStatBreakdown(playerId: UUID(), name: "A", games: 4, wins: 1)
        #expect(row.winPercent == 25)

        row.games = 0
        #expect(row.winPercent == 0)
    }

    @Test
    func doubleAndTriplePercentsUseDartDenominator() {
        let row = PlayerStatBreakdown(
            playerId: UUID(),
            name: "A",
            darts: 10,
            doubles: 2,
            triples: 1
        )
        #expect(row.doublePercent == 20)
        #expect(row.triplePercent == 10)
    }

    @Test
    func marksPerRoundDividesCricketMarksByRounds() {
        var row = PlayerStatBreakdown(playerId: UUID(), name: "A", cricketMarks: 9, cricketRounds: 3)
        #expect(row.marksPerRound == 3)

        row.cricketRounds = 0
        #expect(row.marksPerRound == 0)
    }

    @Test
    func idMatchesPlayerId() {
        let playerId = UUID()
        let row = PlayerStatBreakdown(playerId: playerId, name: "A")
        #expect(row.id == playerId)
    }

    @Test
    func percentsReturnZeroWhenNoDartsRecorded() {
        let row = PlayerStatBreakdown(playerId: UUID(), name: "A")
        #expect(row.doublePercent == 0)
        #expect(row.triplePercent == 0)
    }
}
