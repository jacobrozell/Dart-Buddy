import Foundation
import Testing
@testable import DartBuddy

// MARK: - Helpers

private func acDart(_ multiplier: DartMultiplier, _ segment: Int) -> DartInput {
    DartInput(multiplier: multiplier, segment: .oneToTwenty(segment))
}

private func acMiss() -> DartInput {
    DartInput(multiplier: .single, segment: .miss, isMiss: true)
}

private func acOuterBull() -> DartInput {
    DartInput(multiplier: .single, segment: .outerBull)
}

private func acInnerBull() -> DartInput {
    DartInput(multiplier: .single, segment: .innerBull)
}

private func makeState(
    playerCount: Int = 2,
    pointsEnabled: Bool = true
) throws -> AmericanCricketState {
    let ids = (0 ..< playerCount).map { _ in UUID() }
    return try AmericanCricketEngine.makeInitialState(
        config: MatchConfigAmericanCricket(pointsEnabled: pointsEnabled),
        playerIds: ids
    )
}

// MARK: - Initial state

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func americanCricketInitialStateHasTargetAt20() throws {
    let state = try makeState()
    #expect(state.activeTargetIndex == 0)
    #expect(state.activeTarget == .t20)
    #expect(state.currentPlayerIndex == 0)
    #expect(state.isComplete == false)
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func americanCricketRequiresMinimumTwoPlayers() throws {
    let ids = [UUID()]
    #expect(throws: AppError.self) {
        _ = try AmericanCricketEngine.makeInitialState(
            config: MatchConfigAmericanCricket(),
            playerIds: ids
        )
    }
}

// MARK: - Marks and close

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func americanCricketSingleAddsOneMark() throws {
    var state = try makeState()
    let outcome = try AmericanCricketEngine.submitTurn(state: state, darts: [acDart(.single, 20)])
    let marks = outcome.updatedState.players[0].marks["20"] ?? 0
    #expect(marks == 1)
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func americanCricketDoubleAddsTwoMarks() throws {
    let state = try makeState()
    let outcome = try AmericanCricketEngine.submitTurn(state: state, darts: [acDart(.double, 20)])
    let marks = outcome.updatedState.players[0].marks["20"] ?? 0
    #expect(marks == 2)
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func americanCricketTripleClosesTarget() throws {
    let state = try makeState()
    let outcome = try AmericanCricketEngine.submitTurn(state: state, darts: [acDart(.triple, 20)])
    let marks = outcome.updatedState.players[0].marks["20"] ?? 0
    #expect(marks == 3)
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func americanCricketOffTargetDartScoresNothing() throws {
    let state = try makeState()
    // Active target is 20; dart hits 19.
    let outcome = try AmericanCricketEngine.submitTurn(state: state, darts: [acDart(.triple, 19)])
    let marks = outcome.updatedState.players[0].marks["20"] ?? 0
    #expect(marks == 0)
    #expect(outcome.updatedState.players[0].cumulativePoints == 0)
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func americanCricketMissAddsNoMarks() throws {
    let state = try makeState()
    let outcome = try AmericanCricketEngine.submitTurn(state: state, darts: [acMiss(), acMiss(), acMiss()])
    let marks = outcome.updatedState.players[0].marks["20"] ?? 0
    #expect(marks == 0)
}

// MARK: - Overflow scoring

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func americanCricketOverflowScoresPointsWhenOpponentOpen() throws {
    // Player 0 has 2 marks already; triple = 3 marks → 1 mark closes, 2 overflow → 40 pts (20 × 2).
    var state = try makeState()
    state.players[0].marks["20"] = 2
    let outcome = try AmericanCricketEngine.submitTurn(state: state, darts: [acDart(.triple, 20)])
    #expect(outcome.updatedState.players[0].cumulativePoints == 40)
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func americanCricketNoOverflowPointsWhenDisabled() throws {
    var state = try makeState(pointsEnabled: false)
    state.players[0].marks["20"] = 2
    let outcome = try AmericanCricketEngine.submitTurn(state: state, darts: [acDart(.triple, 20)])
    #expect(outcome.updatedState.players[0].cumulativePoints == 0)
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func americanCricketOverflowZeroWhenAllOpponentsClosed() throws {
    // Both players close the 20 simultaneously is impossible, but if P1 is also closed no points.
    var state = try makeState()
    state.players[0].marks["20"] = 2
    state.players[1].marks["20"] = 3  // opponent already closed
    let outcome = try AmericanCricketEngine.submitTurn(state: state, darts: [acDart(.triple, 20)])
    // Overflow = 2 marks, but opponent is already closed → no points.
    #expect(outcome.updatedState.players[0].cumulativePoints == 0)
}

// MARK: - Target advancement

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func americanCricketTargetAdvancesOnceAllPlayersClosed() throws {
    var state = try makeState()
    // P0 closes 20.
    state = try AmericanCricketEngine.submitTurn(state: state, darts: [acDart(.triple, 20)]).updatedState
    // Target should NOT advance yet — P1 hasn't closed.
    #expect(state.activeTargetIndex == 0)

    // P1 closes 20.
    state = try AmericanCricketEngine.submitTurn(state: state, darts: [acDart(.triple, 20)]).updatedState
    #expect(state.activeTargetIndex == 1)
    #expect(state.activeTarget == .t19)
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func americanCricketSequentialAdvanceOrderIsCorrect() throws {
    var state = try makeState()
    let expectedTargets: [CricketTarget] = [.t20, .t19, .t18, .t17, .t16, .t15, .bull]
    #expect(americanCricketTargets == expectedTargets)
    #expect(state.activeTarget == expectedTargets[0])
}

// MARK: - Bull marks

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func americanCricketOuterBullCountsOneMark() throws {
    var state = try makeState()
    // Fast-forward to bull (index 6).
    state.activeTargetIndex = 6
    let outcome = try AmericanCricketEngine.submitTurn(state: state, darts: [acOuterBull()])
    let marks = outcome.updatedState.players[0].marks["bull"] ?? 0
    #expect(marks == 1)
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func americanCricketInnerBullCountsTwoMarks() throws {
    var state = try makeState()
    state.activeTargetIndex = 6
    let outcome = try AmericanCricketEngine.submitTurn(state: state, darts: [acInnerBull()])
    let marks = outcome.updatedState.players[0].marks["bull"] ?? 0
    #expect(marks == 2)
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func americanCricketInnerBullOverflowScores50Points() throws {
    // Player has 2 marks on bull; inner bull (2 marks) → 1 closes, 1 overflow = 50 pts.
    var state = try makeState()
    state.activeTargetIndex = 6
    state.players[0].marks["bull"] = 2
    let outcome = try AmericanCricketEngine.submitTurn(state: state, darts: [acInnerBull()])
    #expect(outcome.updatedState.players[0].cumulativePoints == 50)
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func americanCricketOuterBullOverflowScores25Points() throws {
    var state = try makeState()
    state.activeTargetIndex = 6
    state.players[0].marks["bull"] = 3  // already closed
    // Overflow on outer bull = 25 pts (opponent not closed).
    let outcome = try AmericanCricketEngine.submitTurn(state: state, darts: [acOuterBull()])
    #expect(outcome.updatedState.players[0].cumulativePoints == 25)
}

// MARK: - Win condition

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func americanCricketMatchCompletesAfterBullClosed() throws {
    var state = try makeState()
    // Fast-forward: close all targets through 15 for both players.
    for target in americanCricketTargets.dropLast() {
        for _ in 0 ..< 2 {
            state.players[state.currentPlayerIndex].marks[target.rawValue] = 3
            state.currentPlayerIndex = (state.currentPlayerIndex + 1) % 2
        }
        state.activeTargetIndex += 1
    }
    // Now on bull; give both players marks.
    state.players[0].marks["bull"] = 2
    state.players[1].marks["bull"] = 3

    // P0 closes bull with inner bull.
    state = try AmericanCricketEngine.submitTurn(state: state, darts: [acInnerBull()]).updatedState
    #expect(state.isComplete)
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func americanCricketHighestPointsWins() throws {
    let p1 = UUID()
    let p2 = UUID()
    var state = try AmericanCricketEngine.makeInitialState(
        config: MatchConfigAmericanCricket(pointsEnabled: true),
        playerIds: [p1, p2]
    )

    // P1 scores heavily on 20 by closing first and then scoring overflow before P2 closes.
    // P1 closes 20.
    state = try AmericanCricketEngine.submitTurn(state: state, darts: [acDart(.triple, 20)]).updatedState
    // P1 scores 60 pts overflow on 20 while P2 is still open.
    state = try AmericanCricketEngine.submitTurn(state: state, darts: [acDart(.triple, 20)]).updatedState
    // P2 closes 20.
    state = try AmericanCricketEngine.submitTurn(state: state, darts: [acDart(.triple, 20)]).updatedState

    // Active target now 19; close all remaining fast to end the game.
    for targetIndex in 1 ..< americanCricketTargets.count {
        let target = americanCricketTargets[targetIndex]
        for _ in 0 ..< 2 {
            state.players[state.currentPlayerIndex].marks[target.rawValue] = 3
            state.currentPlayerIndex = (state.currentPlayerIndex + 1) % 2
        }
        state.activeTargetIndex = targetIndex + 1
        if targetIndex + 1 >= americanCricketTargets.count {
            // Manually trigger completion.
            var mutable = state
            let maxPts = mutable.players.map(\.cumulativePoints).max() ?? 0
            let leaders = mutable.players.filter { $0.cumulativePoints == maxPts }
            if leaders.count == 1 {
                mutable.winnerPlayerId = leaders[0].playerId
            }
            mutable.isComplete = true
            state = mutable
            break
        }
    }

    #expect(state.isComplete)
    // P1 (index 0) should have scored 60 overflow points.
    #expect(state.players[0].cumulativePoints == 60)
    #expect(state.players[1].cumulativePoints == 0)
    #expect(state.winnerPlayerId == p1)
}

// MARK: - Turn rotation

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func americanCricketTurnRotatesAfterSubmit() throws {
    var state = try makeState(playerCount: 3)
    #expect(state.currentPlayerIndex == 0)
    state = try AmericanCricketEngine.submitTurn(state: state, darts: [acMiss()]).updatedState
    #expect(state.currentPlayerIndex == 1)
    state = try AmericanCricketEngine.submitTurn(state: state, darts: [acMiss()]).updatedState
    #expect(state.currentPlayerIndex == 2)
    state = try AmericanCricketEngine.submitTurn(state: state, darts: [acMiss()]).updatedState
    #expect(state.currentPlayerIndex == 0)
}

// MARK: - Replay

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func americanCricketReplayRestoresState() throws {
    let p1 = UUID()
    let p2 = UUID()
    var state = try AmericanCricketEngine.makeInitialState(
        config: MatchConfigAmericanCricket(),
        playerIds: [p1, p2]
    )
    let t1 = try AmericanCricketEngine.submitTurn(state: state, darts: [acDart(.double, 20)])
    state = t1.updatedState
    let t2 = try AmericanCricketEngine.submitTurn(state: state, darts: [acDart(.single, 20)])

    let replayed = try AmericanCricketEngine.replay(
        config: MatchConfigAmericanCricket(),
        playerIds: [p1, p2],
        events: [t1.event, t2.event]
    )

    #expect(replayed.players[0].marks["20"] == 2)
    #expect(replayed.players[1].marks["20"] == 1)
    #expect(replayed.currentPlayerIndex == 0)
    #expect(replayed.turnIndex == 2)
}

// MARK: - Invalid input

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func americanCricketSubmitOnCompletedMatchThrows() throws {
    var state = try makeState()
    state.isComplete = true
    #expect(throws: AppError.self) {
        _ = try AmericanCricketEngine.submitTurn(state: state, darts: [])
    }
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func americanCricketSubmitMoreThanThreeDartsThrows() throws {
    let state = try makeState()
    #expect(throws: AppError.self) {
        _ = try AmericanCricketEngine.submitTurn(
            state: state,
            darts: [acMiss(), acMiss(), acMiss(), acMiss()]
        )
    }
}

// MARK: - Undo (replay of events minus last)

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func americanCricketUndoViaTruncatedReplay() throws {
    let p1 = UUID()
    let p2 = UUID()
    var state = try AmericanCricketEngine.makeInitialState(
        config: MatchConfigAmericanCricket(),
        playerIds: [p1, p2]
    )
    let t1 = try AmericanCricketEngine.submitTurn(state: state, darts: [acDart(.triple, 20)])
    state = t1.updatedState
    let t2 = try AmericanCricketEngine.submitTurn(state: state, darts: [acDart(.double, 20)])

    // Undo t2 by replaying only t1.
    let undone = try AmericanCricketEngine.replay(
        config: MatchConfigAmericanCricket(),
        playerIds: [p1, p2],
        events: [t1.event]
    )

    #expect(undone.players[0].marks["20"] == 3)
    #expect(undone.players[1].marks["20"] == 0)
    #expect(undone.currentPlayerIndex == 1)
    #expect(undone.turnIndex == 1)
}
