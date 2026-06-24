import Foundation
import Testing
@testable import DartBuddy

// MARK: - Helpers

private func triple(_ n: Int) -> DartInput {
    DartInput(multiplier: .triple, segment: .oneToTwenty(n))
}

private func double(_ n: Int) -> DartInput {
    DartInput(multiplier: .double, segment: .oneToTwenty(n))
}

private func single(_ n: Int) -> DartInput {
    DartInput(multiplier: .single, segment: .oneToTwenty(n))
}

private func innerBull() -> DartInput {
    DartInput(multiplier: .double, segment: .innerBull)
}

private func outerBull() -> DartInput {
    DartInput(multiplier: .single, segment: .outerBull)
}

private func miss() -> DartInput {
    DartInput(multiplier: .single, segment: .miss, isMiss: true)
}

// MARK: - Setup

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func ticTacToeRequiresExactlyTwoPlayers() {
    #expect(throws: AppError.self) {
        _ = try TicTacToeEngine.makeInitialState(
            config: MatchConfigTicTacToe(),
            playerIds: [UUID()]
        )
    }
    #expect(throws: AppError.self) {
        _ = try TicTacToeEngine.makeInitialState(
            config: MatchConfigTicTacToe(),
            playerIds: [UUID(), UUID(), UUID()]
        )
    }
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func ticTacToeInitialStateAssignsXandO() throws {
    let a = UUID(); let b = UUID()
    let state = try TicTacToeEngine.makeInitialState(
        config: MatchConfigTicTacToe(),
        playerIds: [a, b]
    )
    #expect(state.players[0].side == .x)
    #expect(state.players[1].side == .o)
    #expect(state.grid.allSatisfy { $0 == nil })
    #expect(state.currentSide == .x)
}

// MARK: - Cell matching

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func ticTacToeCellTargetMatchesByMultiplier() {
    #expect(TicTacToeCellTarget.triple(20).matches(triple(20)))
    #expect(!TicTacToeCellTarget.triple(20).matches(single(20)))
    #expect(!TicTacToeCellTarget.triple(20).matches(triple(19)))
    #expect(TicTacToeCellTarget.anyBull.matches(innerBull()))
    #expect(TicTacToeCellTarget.anyBull.matches(outerBull()))
    #expect(TicTacToeCellTarget.innerBull.matches(innerBull()))
    #expect(!TicTacToeCellTarget.innerBull.matches(outerBull()))
    #expect(TicTacToeCellTarget.anySegment(14).matches(triple(14)))
    #expect(TicTacToeCellTarget.anySegment(14).matches(single(14)))
    #expect(!TicTacToeCellTarget.anySegment(14).matches(triple(13)))
    #expect(!TicTacToeCellTarget.single(20).matches(miss()))
}

// MARK: - Claiming

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func ticTacToeClaimsOpenCellOnMatch() throws {
    let state = try TicTacToeEngine.makeInitialState(
        config: MatchConfigTicTacToe(preset: .balanced),
        playerIds: [UUID(), UUID()]
    )
    // Balanced grid cell 0 is T20.
    let outcome = try TicTacToeEngine.submitTurn(
        state: state,
        darts: [triple(20), miss(), miss()]
    )
    #expect(outcome.event.claimsThisVisit == [TicTacToeClaim(cellIndex: 0, side: .x)])
    #expect(outcome.updatedState.grid[0] == .x)
    #expect(outcome.updatedState.currentSide == .o)
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func ticTacToeIgnoresClaimedCells() throws {
    var state = try TicTacToeEngine.makeInitialState(
        config: MatchConfigTicTacToe(preset: .balanced),
        playerIds: [UUID(), UUID()]
    )
    state.grid[0] = .o
    let outcome = try TicTacToeEngine.submitTurn(
        state: state,
        darts: [triple(20), miss(), miss()]
    )
    #expect(outcome.event.claimsThisVisit.isEmpty)
    #expect(outcome.updatedState.grid[0] == .o)
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func ticTacToeMultipleClaimsInOneVisit() throws {
    let state = try TicTacToeEngine.makeInitialState(
        config: MatchConfigTicTacToe(preset: .balanced),
        playerIds: [UUID(), UUID()]
    )
    // Cells: 0 T20, 5 T18, 6 D5.
    let outcome = try TicTacToeEngine.submitTurn(
        state: state,
        darts: [triple(20), triple(18), double(5)]
    )
    #expect(outcome.event.claimsThisVisit.count == 3)
    #expect(outcome.updatedState.grid[0] == .x)
    #expect(outcome.updatedState.grid[5] == .x)
    #expect(outcome.updatedState.grid[6] == .x)
    #expect(outcome.updatedState.isComplete == false)
}

// MARK: - Winning

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func ticTacToeTopRowWinEndsMatch() throws {
    // Custom grid with three trivially-hittable singles in the top row.
    let cells: [TicTacToeCellTarget] = [
        .anySegment(1), .anySegment(2), .anySegment(3),
        .anySegment(4), .anySegment(5), .anySegment(6),
        .anySegment(7), .anySegment(8), .anySegment(9),
    ]
    let a = UUID(); let b = UUID()
    var state = try TicTacToeEngine.makeInitialState(
        config: MatchConfigTicTacToe(cells: cells),
        playerIds: [a, b]
    )
    let first = try TicTacToeEngine.submitTurn(
        state: state,
        darts: [single(1), single(2), single(3)]
    )
    state = first.updatedState
    #expect(first.event.matchCompleted)
    #expect(first.event.winningLine == [0, 1, 2])
    #expect(state.winnerPlayerId == a)
    #expect(state.isComplete)
    #expect(state.isDraw == false)
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func ticTacToeDiagonalWin() throws {
    let cells: [TicTacToeCellTarget] = [
        .anySegment(1), .anySegment(2), .anySegment(3),
        .anySegment(4), .anySegment(5), .anySegment(6),
        .anySegment(7), .anySegment(8), .anySegment(9),
    ]
    let a = UUID(); let b = UUID()
    var state = try TicTacToeEngine.makeInitialState(
        config: MatchConfigTicTacToe(cells: cells),
        playerIds: [a, b]
    )
    // X claims 0; O claims 1; X claims 4; O claims 2; X claims 8 → diag win.
    state = try TicTacToeEngine.submitTurn(state: state, darts: [single(1)]).updatedState
    state = try TicTacToeEngine.submitTurn(state: state, darts: [single(2)]).updatedState
    state = try TicTacToeEngine.submitTurn(state: state, darts: [single(5)]).updatedState
    state = try TicTacToeEngine.submitTurn(state: state, darts: [single(3)]).updatedState
    let final = try TicTacToeEngine.submitTurn(state: state, darts: [single(9)])
    #expect(final.event.winningLine == [0, 4, 8])
    #expect(final.updatedState.winnerPlayerId == a)
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func ticTacToeRecordsDrawWhenGridFills() throws {
    let cells: [TicTacToeCellTarget] = [
        .anySegment(1), .anySegment(2), .anySegment(3),
        .anySegment(4), .anySegment(5), .anySegment(6),
        .anySegment(7), .anySegment(8), .anySegment(9),
    ]
    let a = UUID(); let b = UUID()
    var state = try TicTacToeEngine.makeInitialState(
        config: MatchConfigTicTacToe(cells: cells),
        playerIds: [a, b]
    )
    // Forced draw: X{0,2,3,7,8} vs O{1,4,5,6}.
    //   X O X
    //   X O O
    //   O X X
    let sequence: [Int] = [1, 2, 3, 5, 4, 6, 8, 7, 9]
    for value in sequence {
        state = try TicTacToeEngine.submitTurn(state: state, darts: [single(value)]).updatedState
    }
    #expect(state.isComplete)
    #expect(state.isDraw)
    #expect(state.winnerPlayerId == nil)
}

// MARK: - Replay

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func ticTacToeReplayReconstructsGrid() throws {
    let cells: [TicTacToeCellTarget] = [
        .anySegment(1), .anySegment(2), .anySegment(3),
        .anySegment(4), .anySegment(5), .anySegment(6),
        .anySegment(7), .anySegment(8), .anySegment(9),
    ]
    let a = UUID(); let b = UUID()
    var state = try TicTacToeEngine.makeInitialState(
        config: MatchConfigTicTacToe(cells: cells),
        playerIds: [a, b]
    )
    var events: [TicTacToeVisitEvent] = []
    let visits: [[DartInput]] = [
        [single(1), single(5), miss()],   // X claims 0 and 4
        [single(2), miss(), miss()],      // O claims 1
        [single(9)],                       // X claims 8 → diag win
    ]
    for visit in visits {
        let outcome = try TicTacToeEngine.submitTurn(state: state, darts: visit)
        state = outcome.updatedState
        events.append(outcome.event)
    }
    let replayed = try TicTacToeEngine.replay(
        config: MatchConfigTicTacToe(cells: cells),
        playerIds: [a, b],
        events: events
    )
    #expect(replayed.grid == state.grid)
    #expect(replayed.isComplete == state.isComplete)
    #expect(replayed.winnerPlayerId == state.winnerPlayerId)
    #expect(replayed.winningLine == state.winningLine)
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func ticTacToeSubmitAfterCompletionThrows() throws {
    var state = try TicTacToeEngine.makeInitialState(
        config: MatchConfigTicTacToe(),
        playerIds: [UUID(), UUID()]
    )
    state.isComplete = true
    #expect(throws: AppError.self) {
        _ = try TicTacToeEngine.submitTurn(state: state, darts: [miss()])
    }
}
