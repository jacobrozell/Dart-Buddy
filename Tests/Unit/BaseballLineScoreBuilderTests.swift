import Foundation
import Testing
@testable import DartBuddy

@Test(.tags(.unit, .baseball, .history, .regression))
func baseballLineScoreOrdersPlayersByTurnOrder() {
    let p1 = UUID()
    let p2 = UUID()
    let p3 = UUID()
    let turns = [
        makeTurn(playerId: p2, inning: 1, runs: 2, turnIndex: 0),
        makeTurn(playerId: p3, inning: 1, runs: 1, turnIndex: 1),
        makeTurn(playerId: p1, inning: 1, runs: 3, turnIndex: 2)
    ]
    let score = BaseballLineScoreBuilder.build(
        turns: turns,
        participants: [
            (p1, "Alice", 0),
            (p2, "Bob", 1),
            (p3, "Sam", 2)
        ],
        scheduledInningCount: 9
    )

    #expect(score.rows.map(\.name) == ["Alice", "Bob", "Sam"])
    #expect(score.rows[0].runsByInning[1] == 3)
    #expect(score.rows[1].runsByInning[1] == 2)
    #expect(score.rows[2].total == 1)
}

@Test(.tags(.unit, .baseball, .history, .regression))
func baseballLineScoreIncludesExtraInningColumns() {
    let p1 = UUID()
    let p2 = UUID()
    let turns = [
        makeTurn(playerId: p1, inning: 9, runs: 1, turnIndex: 0),
        makeTurn(playerId: p2, inning: 9, runs: 1, turnIndex: 1),
        makeTurn(playerId: p1, inning: 10, runs: 2, turnIndex: 2),
        makeTurn(playerId: p2, inning: 10, runs: 0, turnIndex: 3)
    ]
    let score = BaseballLineScoreBuilder.build(
        turns: turns,
        participants: [(p1, "A", 0), (p2, "B", 1)],
        scheduledInningCount: 9
    )

    #expect(score.inningColumns.contains(10))
    #expect(score.rows[0].runsByInning[10] == 2)
    #expect(score.rows[0].total == 3)
}

@Test(.tags(.unit, .baseball, .history, .regression))
func baseballLineScoreOmitsBullPlayoffTurns() {
    let p1 = UUID()
    let p2 = UUID()
    var playoff = makeTurn(playerId: p1, inning: 9, runs: 2, turnIndex: 2)
    playoff = BaseballTurnEvent(
        payloadVersion: playoff.payloadVersion,
        id: playoff.id,
        playerId: playoff.playerId,
        turnIndex: playoff.turnIndex,
        inning: playoff.inning,
        phaseRaw: BaseballPhase.bullPlayoff.rawValue,
        legIndex: playoff.legIndex,
        runsThisVisit: 2,
        cumulativeRunsAfterTurn: 10,
        darts: playoff.darts,
        timestamp: playoff.timestamp
    )
    let score = BaseballLineScoreBuilder.build(
        turns: [
            makeTurn(playerId: p1, inning: 1, runs: 3, turnIndex: 0),
            makeTurn(playerId: p2, inning: 1, runs: 1, turnIndex: 1),
            playoff
        ],
        participants: [(p1, "A", 0), (p2, "B", 1)],
        scheduledInningCount: 9
    )

    #expect(score.playoffTurnCount == 1)
    #expect(score.rows[0].total == 3)
}

private func makeTurn(playerId: UUID, inning: Int, runs: Int, turnIndex: Int) -> BaseballTurnEvent {
    BaseballTurnEvent(
        payloadVersion: 1,
        id: UUID(),
        playerId: playerId,
        turnIndex: turnIndex,
        inning: inning,
        phaseRaw: BaseballPhase.innings.rawValue,
        legIndex: inning - 1,
        runsThisVisit: runs,
        cumulativeRunsAfterTurn: runs,
        darts: [],
        timestamp: Date()
    )
}
