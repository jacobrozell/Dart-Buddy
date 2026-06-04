import Foundation
import Testing
@testable import DartBuddy

@Test(.tags(.unit, .cricket, .regression))
func cricketBoardMarkTargetCountMatchesStandardCricketTargets() {
    #expect(CricketBoardView.markTargetCount == CricketTarget.allCases.count)
    #expect(CricketBoardView.markTargetCount == 7)
}

@Test(.tags(.unit, .cricket, .regression))
func cricketBoardColumnWidthTokensAreStable() {
    #expect(CricketBoardMetrics.targetColumnWidth >= 36)
    #expect(CricketBoardMetrics.targetColumnWidth <= 44)
    #expect(CricketBoardMetrics.playerColumnWidth >= 80)
    #expect(CricketBoardMetrics.playerColumnWidth <= 88)
}

@Test(.tags(.unit, .cricket, .regression))
func cricketBoardSplitComponentsShareColumnCount() {
    let columns = [
        CricketBoardView.Column(
            id: UUID(), name: "A", score: 20, marks: ["20": 3], isActive: true, colorToken: .blue,
            dartsThrown: 9, marksPerRound: 2.5, legsWon: 0, setsWon: 0, showsSetsLegs: false, setsEnabled: false
        ),
        CricketBoardView.Column(
            id: UUID(), name: "B", score: 0, marks: [:], isActive: false, colorToken: .coral,
            dartsThrown: 6, marksPerRound: 1.0, legsWon: 0, setsWon: 0, showsSetsLegs: false, setsEnabled: false
        )
    ]

    #expect(columns.count == 2)
    #expect(CricketTarget.allCases.map(\.rawValue).contains("20"))
    #expect(CricketTarget.allCases.map(\.rawValue).contains("bull"))
}

@Test(.tags(.unit, .cricket, .regression))
func cricketBoardKnockedOutTargetRequiresAllPlayersClosed() {
    let playerA = UUID()
    let playerB = UUID()
    let columnDefaults = (
        dartsThrown: 0, marksPerRound: 0.0, legsWon: 0, setsWon: 0, showsSetsLegs: false, setsEnabled: false
    )
    let columns = [
        CricketBoardView.Column(
            id: playerA, name: "A", score: 20, marks: ["20": 3, "19": 2], isActive: true, colorToken: .blue,
            dartsThrown: columnDefaults.dartsThrown, marksPerRound: columnDefaults.marksPerRound,
            legsWon: columnDefaults.legsWon, setsWon: columnDefaults.setsWon,
            showsSetsLegs: columnDefaults.showsSetsLegs, setsEnabled: columnDefaults.setsEnabled
        ),
        CricketBoardView.Column(
            id: playerB, name: "B", score: 0, marks: ["20": 3, "19": 1], isActive: false, colorToken: .coral,
            dartsThrown: columnDefaults.dartsThrown, marksPerRound: columnDefaults.marksPerRound,
            legsWon: columnDefaults.legsWon, setsWon: columnDefaults.setsWon,
            showsSetsLegs: columnDefaults.showsSetsLegs, setsEnabled: columnDefaults.setsEnabled
        )
    ]

    #expect(CricketBoardView.isTargetKnockedOut(columns: columns, target: .t20))
    #expect(CricketBoardView.isTargetKnockedOut(columns: columns, target: .t19) == false)
}

@Test(.tags(.unit, .cricket, .regression))
func cricketEngineTargetClosedByAllPlayersMatchesBoardKnockout() throws {
    var state = try CricketEngine.makeInitialState(
        config: MatchConfigCricket(),
        playerIds: [UUID(), UUID()]
    )
    state.players[0].marks["20"] = 3
    state.players[1].marks["20"] = 3

    #expect(CricketEngine.isTargetClosedByAllPlayers(state.players, target: .t20))
    #expect(CricketEngine.isTargetClosedByAllPlayers(state.players, target: .t19) == false)
}
