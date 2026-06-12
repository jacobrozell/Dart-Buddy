import Foundation
import Testing
@testable import DartBuddy

// MARK: - Helpers

private func d(_ multiplier: DartMultiplier, _ segment: Int) -> DartInput {
    DartInput(multiplier: multiplier, segment: .oneToTwenty(segment))
}

private func miss() -> DartInput {
    DartInput(multiplier: .single, segment: .miss, isMiss: true)
}

private func outerBull() -> DartInput {
    DartInput(multiplier: .single, segment: .outerBull)
}

private func innerBull() -> DartInput {
    DartInput(multiplier: .single, segment: .innerBull)
}

// MARK: - Mark math

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func mickeyMouseSingleAddsOneMark() throws {
    let players = [UUID(), UUID()]
    let state = try MickeyMouseEngine.makeInitialState(config: MatchConfigMickeyMouse(), playerIds: players)

    let outcome = try MickeyMouseEngine.submitTurn(state: state, darts: [d(.single, 20)])

    // Player 0 should have 1 mark on target index 0 (= 20).
    #expect(outcome.updatedState.players[0].marksByTarget[0] == 1)
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func mickeyMouseDoubleAddsTwoMarks() throws {
    let players = [UUID(), UUID()]
    let state = try MickeyMouseEngine.makeInitialState(config: MatchConfigMickeyMouse(), playerIds: players)

    let outcome = try MickeyMouseEngine.submitTurn(state: state, darts: [d(.double, 20)])

    #expect(outcome.updatedState.players[0].marksByTarget[0] == 2)
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func mickeyMouseTripleClosesTarget() throws {
    let players = [UUID(), UUID()]
    let state = try MickeyMouseEngine.makeInitialState(config: MatchConfigMickeyMouse(), playerIds: players)

    let outcome = try MickeyMouseEngine.submitTurn(state: state, darts: [d(.triple, 20)])

    #expect(outcome.updatedState.players[0].marksByTarget[0] == 3)
    // A triple closes the target for P0 → target advances to 19 (index 1).
    #expect(outcome.updatedState.currentTargetIndex == 1)
    #expect(outcome.event.advancedTarget == true)
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func mickeyMouseOffTargetScoresZeroMarks() throws {
    let players = [UUID(), UUID()]
    let state = try MickeyMouseEngine.makeInitialState(config: MatchConfigMickeyMouse(), playerIds: players)

    // Throw at 19 while active target is 20.
    let outcome = try MickeyMouseEngine.submitTurn(state: state, darts: [d(.triple, 19)])

    #expect(outcome.updatedState.players[0].marksByTarget[0] == 0)
    #expect(outcome.updatedState.currentTargetIndex == 0)
    #expect(outcome.event.advancedTarget == false)
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func mickeyMouseMissScoresZeroMarks() throws {
    let players = [UUID(), UUID()]
    let state = try MickeyMouseEngine.makeInitialState(config: MatchConfigMickeyMouse(), playerIds: players)

    let outcome = try MickeyMouseEngine.submitTurn(state: state, darts: [miss(), miss(), miss()])

    #expect(outcome.updatedState.players[0].marksByTarget[0] == 0)
    #expect(outcome.updatedState.currentTargetIndex == 0)
}

// MARK: - Target advance

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func mickeyMouseTargetAdvancesWhenAnyPlayerCloses() throws {
    let p1 = UUID(), p2 = UUID()
    var state = try MickeyMouseEngine.makeInitialState(config: MatchConfigMickeyMouse(), playerIds: [p1, p2])

    // P2 closes the target with 3 singles → active target advances to index 1.
    // First P1 throws (no marks):
    state = try MickeyMouseEngine.submitTurn(state: state, darts: [d(.single, 19)]).updatedState
    // P2 closes with a triple:
    let outcome = try MickeyMouseEngine.submitTurn(state: state, darts: [d(.triple, 20)])

    #expect(outcome.updatedState.currentTargetIndex == 1)
    #expect(outcome.event.advancedTarget == true)
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func mickeyMouseTargetAdvanceIsGlobalAllPlayers() throws {
    let p1 = UUID(), p2 = UUID()
    var state = try MickeyMouseEngine.makeInitialState(config: MatchConfigMickeyMouse(), playerIds: [p1, p2])

    // P1 closes target 20 with a triple, advancing to 19.
    state = try MickeyMouseEngine.submitTurn(state: state, darts: [d(.triple, 20)]).updatedState
    // Both players should be on target index 1 now.
    #expect(state.currentTargetIndex == 1)

    // P2 now plays; they should be aiming at 19 too.
    let outcome = try MickeyMouseEngine.submitTurn(state: state, darts: [d(.single, 19)])
    #expect(outcome.updatedState.players[1].marksByTarget[1] == 1)
}

// MARK: - Player rotation

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func mickeyMousePlayerRotatesAfterTurn() throws {
    let players = [UUID(), UUID(), UUID()]
    var state = try MickeyMouseEngine.makeInitialState(config: MatchConfigMickeyMouse(), playerIds: players)

    #expect(state.currentPlayerIndex == 0)

    state = try MickeyMouseEngine.submitTurn(state: state, darts: [miss()]).updatedState
    #expect(state.currentPlayerIndex == 1)

    state = try MickeyMouseEngine.submitTurn(state: state, darts: [miss()]).updatedState
    #expect(state.currentPlayerIndex == 2)

    state = try MickeyMouseEngine.submitTurn(state: state, darts: [miss()]).updatedState
    #expect(state.currentPlayerIndex == 0)
}

// MARK: - Bull marks

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func mickeyMouseOuterBullAddsOneMarkOnBullTarget() throws {
    let players = [UUID(), UUID()]
    // Fast-forward to bull target (index 9) by replaying 9 advances via triples.
    var state = try MickeyMouseEngine.makeInitialState(config: MatchConfigMickeyMouse(), playerIds: players)

    let numberedTargets: [Int] = [20, 19, 18, 17, 16, 15, 14, 13, 12]
    for value in numberedTargets {
        // P1 closes with a triple:
        state = try MickeyMouseEngine.submitTurn(state: state, darts: [d(.triple, value)]).updatedState
        // P2 passes:
        state = try MickeyMouseEngine.submitTurn(state: state, darts: [miss()]).updatedState
    }

    #expect(state.currentTargetIndex == MickeyMouseEngine.bullTargetIndex)

    // Outer bull = 1 mark.
    let outcome = try MickeyMouseEngine.submitTurn(state: state, darts: [outerBull()])
    #expect(outcome.updatedState.players[0].marksByTarget[MickeyMouseEngine.bullTargetIndex] == 1)
    #expect(outcome.event.advancedTarget == false)
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func mickeyMouseInnerBullAddsTwoMarksOnBullTarget() throws {
    let players = [UUID(), UUID()]
    var state = try MickeyMouseEngine.makeInitialState(config: MatchConfigMickeyMouse(), playerIds: players)

    let numberedTargets: [Int] = [20, 19, 18, 17, 16, 15, 14, 13, 12]
    for value in numberedTargets {
        state = try MickeyMouseEngine.submitTurn(state: state, darts: [d(.triple, value)]).updatedState
        state = try MickeyMouseEngine.submitTurn(state: state, darts: [miss()]).updatedState
    }

    #expect(state.currentTargetIndex == MickeyMouseEngine.bullTargetIndex)

    let outcome = try MickeyMouseEngine.submitTurn(state: state, darts: [innerBull()])
    #expect(outcome.updatedState.players[0].marksByTarget[MickeyMouseEngine.bullTargetIndex] == 2)
}

// MARK: - Win condition

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func mickeyMouseFirstToCloseBullWins() throws {
    let winner = UUID()
    let other = UUID()
    var state = try MickeyMouseEngine.makeInitialState(config: MatchConfigMickeyMouse(), playerIds: [winner, other])

    // Advance to bull by having winner close each number with a triple.
    let numberedTargets: [Int] = [20, 19, 18, 17, 16, 15, 14, 13, 12]
    for value in numberedTargets {
        state = try MickeyMouseEngine.submitTurn(state: state, darts: [d(.triple, value)]).updatedState
        state = try MickeyMouseEngine.submitTurn(state: state, darts: [miss()]).updatedState
    }

    #expect(state.currentTargetIndex == MickeyMouseEngine.bullTargetIndex)

    // Winner closes bull with inner bull + outer bull (= 3 marks).
    state = try MickeyMouseEngine.submitTurn(state: state, darts: [innerBull(), innerBull()]).updatedState

    #expect(state.isComplete)
    #expect(state.winnerPlayerId == winner)
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func mickeyMouseGameNotCompletedUntilBullClosed() throws {
    let players = [UUID(), UUID()]
    var state = try MickeyMouseEngine.makeInitialState(config: MatchConfigMickeyMouse(), playerIds: players)

    // Close 20→12 but not bull.
    let numberedTargets: [Int] = [20, 19, 18, 17, 16, 15, 14, 13, 12]
    for value in numberedTargets {
        state = try MickeyMouseEngine.submitTurn(state: state, darts: [d(.triple, value)]).updatedState
        state = try MickeyMouseEngine.submitTurn(state: state, darts: [miss()]).updatedState
    }

    #expect(!state.isComplete)
    #expect(state.winnerPlayerId == nil)
}

// MARK: - Error throwing

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func mickeyMouseThrowsOnCompletedGame() throws {
    let p1 = UUID()
    let p2 = UUID()
    var state = try MickeyMouseEngine.makeInitialState(config: MatchConfigMickeyMouse(), playerIds: [p1, p2])

    let numberedTargets: [Int] = [20, 19, 18, 17, 16, 15, 14, 13, 12]
    for value in numberedTargets {
        state = try MickeyMouseEngine.submitTurn(state: state, darts: [d(.triple, value)]).updatedState
        state = try MickeyMouseEngine.submitTurn(state: state, darts: [miss()]).updatedState
    }
    state = try MickeyMouseEngine.submitTurn(state: state, darts: [innerBull(), innerBull()]).updatedState

    #expect(state.isComplete)
    #expect(throws: (any Error).self) {
        _ = try MickeyMouseEngine.submitTurn(state: state, darts: [miss()])
    }
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func mickeyMouseThrowsOnTooManyDarts() throws {
    let players = [UUID(), UUID()]
    let state = try MickeyMouseEngine.makeInitialState(config: MatchConfigMickeyMouse(), playerIds: players)

    #expect(throws: (any Error).self) {
        _ = try MickeyMouseEngine.submitTurn(state: state, darts: [miss(), miss(), miss(), miss()])
    }
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func mickeyMouseThrowsOnTooFewPlayers() throws {
    #expect(throws: (any Error).self) {
        _ = try MickeyMouseEngine.makeInitialState(config: MatchConfigMickeyMouse(), playerIds: [UUID()])
    }
}

// MARK: - Replay

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func mickeyMouseReplayRestoresState() throws {
    let p1 = UUID()
    let p2 = UUID()
    let config = MatchConfigMickeyMouse()
    var state = try MickeyMouseEngine.makeInitialState(config: config, playerIds: [p1, p2])

    let first = try MickeyMouseEngine.submitTurn(state: state, darts: [d(.single, 20), d(.single, 20)])
    state = first.updatedState
    let second = try MickeyMouseEngine.submitTurn(state: state, darts: [d(.double, 20)])

    let replayed = try MickeyMouseEngine.replay(
        config: config,
        playerIds: [p1, p2],
        events: [first.event, second.event]
    )

    #expect(replayed.players[0].marksByTarget[0] == first.updatedState.players[0].marksByTarget[0])
    #expect(replayed.players[1].marksByTarget[0] == second.updatedState.players[1].marksByTarget[0])
    #expect(replayed.currentPlayerIndex == second.updatedState.currentPlayerIndex)
    #expect(replayed.currentTargetIndex == second.updatedState.currentTargetIndex)
}

// MARK: - Undo semantics (replay of events minus last)

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func mickeyMouseUndoRestoresPreviousState() throws {
    let p1 = UUID()
    let p2 = UUID()
    let config = MatchConfigMickeyMouse()
    var state = try MickeyMouseEngine.makeInitialState(config: config, playerIds: [p1, p2])

    let first = try MickeyMouseEngine.submitTurn(state: state, darts: [d(.double, 20)])
    state = first.updatedState
    let second = try MickeyMouseEngine.submitTurn(state: state, darts: [d(.single, 20)])

    // "Undo" second turn by replaying only the first event.
    let afterUndo = try MickeyMouseEngine.replay(
        config: config,
        playerIds: [p1, p2],
        events: [first.event]
    )

    // Should match state after first event.
    #expect(afterUndo.players[0].marksByTarget[0] == first.updatedState.players[0].marksByTarget[0])
    #expect(afterUndo.currentPlayerIndex == first.updatedState.currentPlayerIndex)
}

// MARK: - Target sequence

@Test(.tags(.unit, .match, .offline, .regression))
func mickeyMouseTargetSequenceIsCorrect() {
    let expected: [MickeyMouseTarget] = [
        .number(20), .number(19), .number(18), .number(17), .number(16),
        .number(15), .number(14), .number(13), .number(12), .bull
    ]
    #expect(MickeyMouseEngine.targets == expected)
    #expect(MickeyMouseEngine.bullTargetIndex == 9)
}
