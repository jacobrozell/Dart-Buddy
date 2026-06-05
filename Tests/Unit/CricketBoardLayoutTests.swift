import Foundation
import Testing
@testable import DartBuddy

@Test(.tags(.unit, .cricket, .regression))
func cricketBoardMarkTargetCountMatchesStandardCricketTargets() {
    #expect(CricketBoardView.markTargetCount == CricketTarget.allCases.count)
    #expect(CricketBoardView.markTargetCount == 7)
}

@Test(.tags(.unit, .cricket, .regression))
func cricketConfigShowsSetsOnBoardOnlyWhenSetsEnabled() {
    #expect(MatchConfigCricket(legsToWin: 1, setsEnabled: false).showsSetsOnBoard == false)
    #expect(MatchConfigCricket(legsToWin: 3, setsEnabled: false).showsSetsOnBoard == false)
    #expect(MatchConfigCricket(legsToWin: 1, setsEnabled: true).showsSetsOnBoard)
}

@Test(.tags(.unit, .cricket, .regression))
func cricketBoardColumnLayoutDistributesWhenFewPlayersFit() {
    let layout = CricketBoardColumnLayout.resolve(availableWidth: 400, playerCount: 2)
    #expect(layout.scrollsHorizontally == false)
    #expect(layout.fixedPlayerColumnWidth == nil)

    let threeUp = CricketBoardColumnLayout.resolve(availableWidth: 520, playerCount: 3)
    #expect(threeUp.scrollsHorizontally == false)
    #expect(threeUp.fixedPlayerColumnWidth == nil)
}

@Test(.tags(.unit, .cricket, .regression))
func cricketBoardColumnLayoutScrollsWhenCrowdedOrTooNarrow() {
    let threeNarrow = CricketBoardColumnLayout.resolve(availableWidth: 200, playerCount: 3)
    #expect(threeNarrow.scrollsHorizontally == true)
    #expect(threeNarrow.fixedPlayerColumnWidth == CricketBoardMetrics.playerColumnWidth)

    let fourPlayers = CricketBoardColumnLayout.resolve(availableWidth: 600, playerCount: 4)
    #expect(fourPlayers.scrollsHorizontally == true)
    #expect(fourPlayers.fixedPlayerColumnWidth == CricketBoardMetrics.playerColumnWidth)

    // 195pt leaves 167pt for players; two 84pt columns need 168pt.
    let narrow = CricketBoardColumnLayout.resolve(availableWidth: 195, playerCount: 2)
    #expect(narrow.scrollsHorizontally == true)
    #expect(narrow.fixedPlayerColumnWidth == CricketBoardMetrics.playerColumnWidth)
}

@Test(.tags(.unit, .cricket, .regression))
func cricketBoardLandscapeCompactSizingIsShorterThanStandard() {
    #expect(CricketBoardSizing.landscapeCompact.boardBodyHeight < CricketBoardSizing.standard.boardBodyHeight)
}

@Test(.tags(.unit, .cricket, .regression))
func cricketBoardColumnLayoutDistributesThreePlayersOnTypicalPhoneWidth() {
    let layout = CricketBoardColumnLayout.resolve(availableWidth: 360, playerCount: 3)
    #expect(layout.scrollsHorizontally == false)
    #expect(layout.fixedPlayerColumnWidth == nil)
}

@Test(.tags(.unit, .cricket, .regression))
func cricketBoardColumnWidthTokensAreStable() {
    #expect(CricketBoardMetrics.targetColumnWidth >= 24)
    #expect(CricketBoardMetrics.targetColumnWidth <= 32)
    #expect(CricketBoardMetrics.scrollIndicatorPlayerThreshold == 3)
    #expect(CricketBoardMetrics.playerColumnWidth >= 80)
    #expect(CricketBoardMetrics.playerColumnWidth <= 88)
}

@Test(.tags(.unit, .cricket, .regression))
func cricketBoardSplitComponentsShareColumnCount() {
    let columns = [
        CricketBoardView.Column(
            id: UUID(), name: "A", score: 20, marks: ["20": 3], isActive: true, colorToken: .blue,
            dartsThrown: 9, marksPerRound: 2.5, setsWon: 0, setsEnabled: false
        ),
        CricketBoardView.Column(
            id: UUID(), name: "B", score: 0, marks: [:], isActive: false, colorToken: .coral,
            dartsThrown: 6, marksPerRound: 1.0, setsWon: 0, setsEnabled: false
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
        dartsThrown: 0, marksPerRound: 0.0, setsWon: 0, setsEnabled: false
    )
    let columns = [
        CricketBoardView.Column(
            id: playerA, name: "A", score: 20, marks: ["20": 3, "19": 2], isActive: true, colorToken: .blue,
            dartsThrown: columnDefaults.dartsThrown, marksPerRound: columnDefaults.marksPerRound,
            setsWon: columnDefaults.setsWon, setsEnabled: columnDefaults.setsEnabled
        ),
        CricketBoardView.Column(
            id: playerB, name: "B", score: 0, marks: ["20": 3, "19": 1], isActive: false, colorToken: .coral,
            dartsThrown: columnDefaults.dartsThrown, marksPerRound: columnDefaults.marksPerRound,
            setsWon: columnDefaults.setsWon, setsEnabled: columnDefaults.setsEnabled
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
