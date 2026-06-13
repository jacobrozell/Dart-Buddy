import Foundation
import Testing
@testable import DartBuddy

// MARK: - Helpers

private func makeConfig(
    seed: UInt64 = 42,
    targetCount: Int = 6
) -> MatchConfigMulligan {
    var rng = SeededRandomNumberGenerator(seed: seed)
    let sequence = MulliganEngine.generateSequence(count: targetCount, rng: &rng)
    return MatchConfigMulligan(
        targetCount: targetCount,
        rngSeed: seed,
        targetSequence: sequence
    )
}

private func miss() -> DartInput {
    DartInput(multiplier: .single, segment: .miss, isMiss: true)
}

private func hit(_ n: Int, _ multiplier: DartMultiplier = .single) -> DartInput {
    DartInput(multiplier: multiplier, segment: .oneToTwenty(n))
}

private func bullSingle() -> DartInput {
    DartInput(multiplier: .single, segment: .outerBull)
}

private func bullDouble() -> DartInput {
    DartInput(multiplier: .single, segment: .innerBull)
}

// MARK: - Seed determinism

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func mulliganSeedProducesDeterministicSequence() throws {
    let config1 = makeConfig(seed: 12345)
    let config2 = makeConfig(seed: 12345)
    #expect(config1.targetSequence == config2.targetSequence)
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func mulliganDifferentSeedsDifferentSequences() throws {
    let config1 = makeConfig(seed: 1)
    let config2 = makeConfig(seed: 2)
    // With overwhelming probability two different seeds produce different sequences
    // (collision chance is negligible for test purposes)
    #expect(config1.targetSequence != config2.targetSequence)
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func mulliganSequenceHasSixDistinctNumbersPlusBull() throws {
    let config = makeConfig(seed: 7, targetCount: 6)
    // Exactly targetCount + 1 entries (numbers + bull)
    #expect(config.targetSequence.count == 7)
    #expect(config.targetSequence.last == .bull)
    // All number segments are distinct
    let numbers = config.targetSequence.dropLast().compactMap { segment -> Int? in
        if case let .number(n) = segment { return n }
        return nil
    }
    #expect(Set(numbers).count == 6)
    // All in range 1–20
    #expect(numbers.allSatisfy { (1 ... 20).contains($0) })
}

// MARK: - Initial state

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func mulliganMakeInitialStateRequiresTwoPlayers() throws {
    let config = makeConfig()
    #expect(throws: AppError.self) {
        try MulliganEngine.makeInitialState(config: config, playerIds: [UUID()])
    }
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func mulliganMakeInitialStateStartsAtTargetZero() throws {
    let config = makeConfig()
    let state = try MulliganEngine.makeInitialState(config: config, playerIds: [UUID(), UUID()])
    #expect(state.currentTargetIndex == 0)
    #expect(state.currentPlayerIndex == 0)
    #expect(state.isComplete == false)
    #expect(state.winnerPlayerId == nil)
    #expect(state.players.allSatisfy { $0.marksOnActiveTarget == 0 })
}

// MARK: - Mark accumulation

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func mulliganSingleHitAddsOneMark() throws {
    let config = makeConfig(seed: 42)
    var state = try MulliganEngine.makeInitialState(config: config, playerIds: [UUID(), UUID()])
    guard case let .number(firstTarget) = config.targetSequence[0] else {
        Issue.record("First target should be a number")
        return
    }
    let outcome = try MulliganEngine.submitTurn(
        state: state,
        darts: [hit(firstTarget, .single), miss(), miss()]
    )
    #expect(outcome.updatedState.currentTargetIndex == 0)
    // Player 0 threw first; after turn player index advances to 1
    // Player 0's marks should be 1
    #expect(outcome.event.darts[0].marksAdded == 1)
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func mulliganTripleHitClosesTargetImmediately() throws {
    let config = makeConfig(seed: 42)
    var state = try MulliganEngine.makeInitialState(config: config, playerIds: [UUID(), UUID()])
    guard case let .number(firstTarget) = config.targetSequence[0] else {
        Issue.record("First target should be a number")
        return
    }
    let outcome = try MulliganEngine.submitTurn(
        state: state,
        darts: [hit(firstTarget, .triple), miss(), miss()]
    )
    // Target advanced (player closed it with 3 marks in one dart)
    #expect(outcome.updatedState.currentTargetIndex == 1)
    // All players' marks reset to 0 on the new target
    #expect(outcome.updatedState.players.allSatisfy { $0.marksOnActiveTarget == 0 })
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func mulliganWrongSegmentScoresNoMarks() throws {
    let config = makeConfig(seed: 42)
    let state = try MulliganEngine.makeInitialState(config: config, playerIds: [UUID(), UUID()])
    // Hit a target that is not the active one
    let outcome = try MulliganEngine.submitTurn(
        state: state,
        darts: [miss(), miss(), miss()]
    )
    #expect(outcome.event.darts.allSatisfy { $0.marksAdded == 0 })
    #expect(outcome.updatedState.currentTargetIndex == 0)
}

// MARK: - Shared target advancement

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func mulliganClosureAdvancesTargetForAllPlayers() throws {
    let config = makeConfig(seed: 42)
    let p1 = UUID()
    let p2 = UUID()
    var state = try MulliganEngine.makeInitialState(config: config, playerIds: [p1, p2])
    guard case let .number(firstTarget) = config.targetSequence[0] else {
        Issue.record("First target should be a number")
        return
    }

    // Player 0: 3-mark close
    state = try MulliganEngine.submitTurn(
        state: state,
        darts: [hit(firstTarget, .triple), miss(), miss()]
    ).updatedState

    #expect(state.currentTargetIndex == 1)
    #expect(state.players.allSatisfy { $0.marksOnActiveTarget == 0 })
}

// MARK: - Bull win condition

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func mulliganBullClosureWinsMatch() throws {
    // Build a config with only 1 drawn number so bull is reached quickly
    var rng = SeededRandomNumberGenerator(seed: 99)
    let sequence = MulliganEngine.generateSequence(count: 1, rng: &rng)
    let config = MatchConfigMulligan(targetCount: 1, rngSeed: 99, targetSequence: sequence)
    let winner = UUID()
    var state = try MulliganEngine.makeInitialState(config: config, playerIds: [winner, UUID()])

    // Close first number target
    guard case let .number(n) = sequence[0] else {
        Issue.record("First element should be a number")
        return
    }
    state = try MulliganEngine.submitTurn(
        state: state,
        darts: [hit(n, .triple), miss(), miss()]
    ).updatedState
    #expect(state.currentTargetIndex == 1)
    #expect(state.currentTarget == .bull)

    // P1 turn: close bull with inner bull (2 marks) + outer bull (1 mark)
    state = try MulliganEngine.submitTurn(
        state: state,
        darts: [bullDouble(), bullSingle(), miss()]
    ).updatedState
    #expect(state.isComplete)
    #expect(state.winnerPlayerId == state.players[1].playerId)
}

// MARK: - Completed match guard

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func mulliganSubmitTurnThrowsWhenMatchComplete() throws {
    var rng = SeededRandomNumberGenerator(seed: 1)
    let sequence = MulliganEngine.generateSequence(count: 1, rng: &rng)
    let config = MatchConfigMulligan(targetCount: 1, rngSeed: 1, targetSequence: sequence)
    var state = try MulliganEngine.makeInitialState(config: config, playerIds: [UUID(), UUID()])

    guard case let .number(n) = sequence[0] else {
        Issue.record("First element should be a number")
        return
    }
    state = try MulliganEngine.submitTurn(
        state: state,
        darts: [hit(n, .triple), miss(), miss()]
    ).updatedState
    // Now on bull
    state = try MulliganEngine.submitTurn(
        state: state,
        darts: [bullDouble(), bullSingle(), miss()]
    ).updatedState
    #expect(state.isComplete)

    #expect(throws: AppError.self) {
        try MulliganEngine.submitTurn(state: state, darts: [miss(), miss(), miss()])
    }
}

// MARK: - Replay round-trip

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func mulliganReplayRestoresState() throws {
    let config = makeConfig(seed: 77)
    let ids = [UUID(), UUID()]
    var state = try MulliganEngine.makeInitialState(config: config, playerIds: ids)

    let e1 = try MulliganEngine.submitTurn(state: state, darts: [miss(), miss(), miss()])
    state = e1.updatedState
    let e2 = try MulliganEngine.submitTurn(state: state, darts: [miss(), miss(), miss()])

    let replayed = try MulliganEngine.replay(
        config: config,
        playerIds: ids,
        events: [e1.event, e2.event]
    )

    #expect(replayed.currentTargetIndex == e2.updatedState.currentTargetIndex)
    #expect(replayed.currentPlayerIndex == e2.updatedState.currentPlayerIndex)
    #expect(replayed.isComplete == false)
}

// MARK: - Undo semantics (replay minus last event)

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func mulliganUndoByDroppingLastEvent() throws {
    let config = makeConfig(seed: 55)
    let ids = [UUID(), UUID()]
    var state = try MulliganEngine.makeInitialState(config: config, playerIds: ids)

    let e1 = try MulliganEngine.submitTurn(state: state, darts: [miss(), miss(), miss()])
    state = e1.updatedState
    let e2 = try MulliganEngine.submitTurn(state: state, darts: [miss(), miss(), miss()])

    // Undo = replay without e2
    let afterUndo = try MulliganEngine.replay(config: config, playerIds: ids, events: [e1.event])

    #expect(afterUndo.turnIndex == e1.updatedState.turnIndex)
    #expect(afterUndo.currentPlayerIndex == e1.updatedState.currentPlayerIndex)
}

// MARK: - Max-darts guard

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func mulliganSubmitTurnRejectsFourDarts() throws {
    let config = makeConfig()
    let state = try MulliganEngine.makeInitialState(config: config, playerIds: [UUID(), UUID()])

    #expect(throws: AppError.self) {
        try MulliganEngine.submitTurn(
            state: state,
            darts: [miss(), miss(), miss(), miss()]
        )
    }
}
