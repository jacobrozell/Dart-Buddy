import Foundation
import Testing
@testable import DartBuddy

// MARK: - Helpers

private func treble(_ number: Int) -> DartInput {
    DartInput(multiplier: .triple, segment: .oneToTwenty(number))
}

private func single(_ number: Int) -> DartInput {
    DartInput(multiplier: .single, segment: .oneToTwenty(number))
}

private func double(_ number: Int) -> DartInput {
    DartInput(multiplier: .double, segment: .oneToTwenty(number))
}

private var outerBull: DartInput {
    DartInput(multiplier: .single, segment: .outerBull)
}

private var innerBull: DartInput {
    DartInput(multiplier: .single, segment: .innerBull)
}

private var miss: DartInput {
    DartInput(multiplier: .single, segment: .miss, isMiss: true)
}

// MARK: - Initial state

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func chaseTheDragonInitialStateHasStepZero() throws {
    let players = [UUID(), UUID()]
    let state = try ChaseTheDragonEngine.makeInitialState(
        config: MatchConfigChaseTheDragon(),
        playerIds: players
    )
    #expect(state.players[0].stepIndex == 0)
    #expect(state.players[1].stepIndex == 0)
    #expect(state.isComplete == false)
    #expect(state.currentPlayerIndex == 0)
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func chaseTheDragonRequiresAtLeastOnePlayer() throws {
    #expect(throws: (any Error).self) {
        try ChaseTheDragonEngine.makeInitialState(
            config: MatchConfigChaseTheDragon(),
            playerIds: []
        )
    }
}

// MARK: - Treble validation

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func chaseTheDragonTrebleAdvancesStep() throws {
    let player = UUID()
    let state = try ChaseTheDragonEngine.makeInitialState(
        config: MatchConfigChaseTheDragon(),
        playerIds: [player]
    )
    let outcome = try ChaseTheDragonEngine.submitTurn(
        state: state,
        darts: [treble(10), miss, miss]
    )
    #expect(outcome.updatedState.players[0].stepIndex == 1)
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func chaseTheDragonSingleOnTrebleStepDoesNotAdvance() throws {
    let player = UUID()
    let state = try ChaseTheDragonEngine.makeInitialState(
        config: MatchConfigChaseTheDragon(),
        playerIds: [player]
    )
    let outcome = try ChaseTheDragonEngine.submitTurn(
        state: state,
        darts: [single(10), single(10), single(10)]
    )
    #expect(outcome.updatedState.players[0].stepIndex == 0)
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func chaseTheDragonDoubleOnTrebleStepDoesNotAdvance() throws {
    let player = UUID()
    let state = try ChaseTheDragonEngine.makeInitialState(
        config: MatchConfigChaseTheDragon(),
        playerIds: [player]
    )
    let outcome = try ChaseTheDragonEngine.submitTurn(
        state: state,
        darts: [double(10), double(10), double(10)]
    )
    #expect(outcome.updatedState.players[0].stepIndex == 0)
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func chaseTheDragonWrongNumberDoesNotAdvance() throws {
    let player = UUID()
    let state = try ChaseTheDragonEngine.makeInitialState(
        config: MatchConfigChaseTheDragon(),
        playerIds: [player]
    )
    let outcome = try ChaseTheDragonEngine.submitTurn(
        state: state,
        darts: [treble(11), treble(12), treble(13)]
    )
    // Step 0 is T10; none of these advance.
    #expect(outcome.updatedState.players[0].stepIndex == 0)
}

// MARK: - Bull steps

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func chaseTheDragonOuterBullAdvancesAtStep11() throws {
    // Advance through T10–T20 first (steps 0–10), then check outer bull at step 11.
    let player = UUID()
    var state = try ChaseTheDragonEngine.makeInitialState(
        config: MatchConfigChaseTheDragon(),
        playerIds: [player]
    )
    // Fast-forward through treble 10–20.
    for n in 10 ... 20 {
        state = try ChaseTheDragonEngine.submitTurn(state: state, darts: [treble(n)]).updatedState
    }
    #expect(state.players[0].stepIndex == 11) // Outer bull step.

    let outcome = try ChaseTheDragonEngine.submitTurn(state: state, darts: [outerBull])
    #expect(outcome.updatedState.players[0].stepIndex == 12) // Inner bull step.
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func chaseTheDragonInnerBullAdvancesAtStep12() throws {
    let player = UUID()
    var state = try ChaseTheDragonEngine.makeInitialState(
        config: MatchConfigChaseTheDragon(),
        playerIds: [player]
    )
    for n in 10 ... 20 {
        state = try ChaseTheDragonEngine.submitTurn(state: state, darts: [treble(n)]).updatedState
    }
    state = try ChaseTheDragonEngine.submitTurn(state: state, darts: [outerBull]).updatedState
    #expect(state.players[0].stepIndex == 12)
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func chaseTheDragonOuterBullDoesNotQualifyForInnerBullStep() throws {
    let player = UUID()
    var state = try ChaseTheDragonEngine.makeInitialState(
        config: MatchConfigChaseTheDragon(),
        playerIds: [player]
    )
    for n in 10 ... 20 {
        state = try ChaseTheDragonEngine.submitTurn(state: state, darts: [treble(n)]).updatedState
    }
    state = try ChaseTheDragonEngine.submitTurn(state: state, darts: [outerBull]).updatedState
    // Now on inner bull step — outer bull should NOT advance.
    let outcome = try ChaseTheDragonEngine.submitTurn(state: state, darts: [outerBull, outerBull, outerBull])
    #expect(outcome.updatedState.players[0].stepIndex == 12)
    #expect(outcome.updatedState.isComplete == false)
}

// MARK: - Win condition (1 lap)

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func chaseTheDragonSingleLapCompletionWins() throws {
    let winner = UUID()
    var state = try ChaseTheDragonEngine.makeInitialState(
        config: MatchConfigChaseTheDragon(laps: .one),
        playerIds: [winner]
    )
    for n in 10 ... 20 {
        state = try ChaseTheDragonEngine.submitTurn(state: state, darts: [treble(n)]).updatedState
    }
    state = try ChaseTheDragonEngine.submitTurn(state: state, darts: [outerBull]).updatedState
    let outcome = try ChaseTheDragonEngine.submitTurn(state: state, darts: [innerBull])
    #expect(outcome.updatedState.isComplete)
    #expect(outcome.updatedState.winnerPlayerId == winner)
}

// MARK: - Multi-lap

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func chaseTheDragonThreeLapDoesNotCompleteAfterOneLap() throws {
    let player = UUID()
    var state = try ChaseTheDragonEngine.makeInitialState(
        config: MatchConfigChaseTheDragon(laps: .three),
        playerIds: [player]
    )
    for n in 10 ... 20 {
        state = try ChaseTheDragonEngine.submitTurn(state: state, darts: [treble(n)]).updatedState
    }
    state = try ChaseTheDragonEngine.submitTurn(state: state, darts: [outerBull]).updatedState
    state = try ChaseTheDragonEngine.submitTurn(state: state, darts: [innerBull]).updatedState

    // Completing lap 1 of 3 resets stepIndex and increments lapsCompleted — game still in progress.
    #expect(state.isComplete == false)
    #expect(state.players[0].lapsCompleted == 1)
    #expect(state.players[0].stepIndex == 0)
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func chaseTheDragonThreeLapCompletionWins() throws {
    let player = UUID()
    var state = try ChaseTheDragonEngine.makeInitialState(
        config: MatchConfigChaseTheDragon(laps: .three),
        playerIds: [player]
    )
    for _ in 0 ..< 3 {
        for n in 10 ... 20 {
            state = try ChaseTheDragonEngine.submitTurn(state: state, darts: [treble(n)]).updatedState
        }
        state = try ChaseTheDragonEngine.submitTurn(state: state, darts: [outerBull]).updatedState
        if state.isComplete { break }
        state = try ChaseTheDragonEngine.submitTurn(state: state, darts: [innerBull]).updatedState
    }
    #expect(state.isComplete)
    #expect(state.winnerPlayerId == player)
}

// MARK: - Turn rotation

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func chaseTheDragonPlayerRotationAdvancesCorrectly() throws {
    let p1 = UUID()
    let p2 = UUID()
    var state = try ChaseTheDragonEngine.makeInitialState(
        config: MatchConfigChaseTheDragon(),
        playerIds: [p1, p2]
    )
    #expect(state.currentPlayerIndex == 0)

    state = try ChaseTheDragonEngine.submitTurn(state: state, darts: [miss, miss, miss]).updatedState
    #expect(state.currentPlayerIndex == 1)

    state = try ChaseTheDragonEngine.submitTurn(state: state, darts: [miss, miss, miss]).updatedState
    #expect(state.currentPlayerIndex == 0)
}

// MARK: - Multi-step visits

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func chaseTheDragonMultipleQualifyingHitsAdvancePerVisit() throws {
    let player = UUID()
    let state = try ChaseTheDragonEngine.makeInitialState(
        config: MatchConfigChaseTheDragon(),
        playerIds: [player]
    )
    let outcome = try ChaseTheDragonEngine.submitTurn(
        state: state,
        darts: [treble(10), treble(11), treble(12)]
    )
    #expect(outcome.updatedState.players[0].stepIndex == 3)
}

// MARK: - Max dart validation

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func chaseTheDragonRejectsMoreThanThreeDarts() throws {
    let player = UUID()
    let state = try ChaseTheDragonEngine.makeInitialState(
        config: MatchConfigChaseTheDragon(),
        playerIds: [player]
    )
    #expect(throws: (any Error).self) {
        try ChaseTheDragonEngine.submitTurn(
            state: state,
            darts: [treble(10), miss, miss, miss]
        )
    }
}

// MARK: - Completed match guard

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func chaseTheDragonRejectsSubmitWhenComplete() throws {
    let player = UUID()
    var state = try ChaseTheDragonEngine.makeInitialState(
        config: MatchConfigChaseTheDragon(laps: .one),
        playerIds: [player]
    )
    for n in 10 ... 20 {
        state = try ChaseTheDragonEngine.submitTurn(state: state, darts: [treble(n)]).updatedState
    }
    state = try ChaseTheDragonEngine.submitTurn(state: state, darts: [outerBull]).updatedState
    state = try ChaseTheDragonEngine.submitTurn(state: state, darts: [innerBull]).updatedState
    #expect(state.isComplete)

    #expect(throws: (any Error).self) {
        try ChaseTheDragonEngine.submitTurn(state: state, darts: [treble(10)])
    }
}

// MARK: - Event record

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func chaseTheDragonTurnEventRecordsStepBeforeAndAfter() throws {
    let player = UUID()
    let state = try ChaseTheDragonEngine.makeInitialState(
        config: MatchConfigChaseTheDragon(),
        playerIds: [player]
    )
    let outcome = try ChaseTheDragonEngine.submitTurn(
        state: state,
        darts: [treble(10), miss, miss]
    )
    #expect(outcome.event.stepBefore == 0)
    #expect(outcome.event.stepAfter == 1)
}

// MARK: - Replay round-trip

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func chaseTheDragonReplayRestoresState() throws {
    let players = [UUID(), UUID()]
    let config = MatchConfigChaseTheDragon()
    var state = try ChaseTheDragonEngine.makeInitialState(config: config, playerIds: players)

    let first = try ChaseTheDragonEngine.submitTurn(state: state, darts: [treble(10)])
    state = first.updatedState
    let second = try ChaseTheDragonEngine.submitTurn(state: state, darts: [miss, miss, miss])

    let replayed = try ChaseTheDragonEngine.replay(
        config: config,
        playerIds: players,
        events: [first.event, second.event]
    )
    #expect(replayed.players[0].stepIndex == first.updatedState.players[0].stepIndex)
    #expect(replayed.players[1].stepIndex == second.updatedState.players[1].stepIndex)
    #expect(replayed.currentPlayerIndex == second.updatedState.currentPlayerIndex)
}

// MARK: - Sequence length

@Test(.tags(.unit, .match, .offline, .regression))
func chaseTheDragonSequenceHas13Steps() {
    #expect(ChaseTheDragonEngine.dragonSequence.count == 13)
    #expect(ChaseTheDragonEngine.stepsPerLap == 13)
}

@Test(.tags(.unit, .match, .offline, .regression))
func chaseTheDragonSequenceStartsAtTen() {
    guard case let .treble(n) = ChaseTheDragonEngine.dragonSequence[0] else {
        Issue.record("First step should be treble(10)")
        return
    }
    #expect(n == 10)
}

@Test(.tags(.unit, .match, .offline, .regression))
func chaseTheDragonSequenceEndsWithBulls() {
    let last = ChaseTheDragonEngine.dragonSequence.last
    let penultimate = ChaseTheDragonEngine.dragonSequence[ChaseTheDragonEngine.dragonSequence.count - 2]
    #expect(last == .innerBull)
    #expect(penultimate == .outerBull)
}
