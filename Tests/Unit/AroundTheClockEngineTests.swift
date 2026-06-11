import Foundation
import Testing
@testable import DartBuddy

// MARK: - Helpers

private func hit(_ value: Int) -> DartInput {
    DartInput(multiplier: .single, segment: .oneToTwenty(value))
}

private func miss() -> DartInput {
    DartInput(multiplier: .single, segment: .miss, isMiss: true)
}

private let defaultConfig = MatchConfigAroundTheClock()

// MARK: - Engine tests

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func aroundTheClockInitialStateHasTargetIndexZero() throws {
    let players = [UUID(), UUID()]
    let state = try AroundTheClockEngine.makeInitialState(config: defaultConfig, playerIds: players)
    #expect(state.players[0].targetIndex == 0)
    #expect(state.players[1].targetIndex == 0)
    #expect(state.currentPlayerIndex == 0)
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func aroundTheClockSoloMatchAllowsOnePlayer() throws {
    let state = try AroundTheClockEngine.makeInitialState(config: defaultConfig, playerIds: [UUID()])
    #expect(state.players.count == 1)
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func aroundTheClockHitAdvancesTargetIndex() throws {
    let players = [UUID(), UUID()]
    let state = try AroundTheClockEngine.makeInitialState(config: defaultConfig, playerIds: players)
    let outcome = try AroundTheClockEngine.submitTurn(state: state, darts: [hit(1), miss(), miss()])
    #expect(outcome.event.targetBefore == 0)
    #expect(outcome.event.targetAfter == 1)
    #expect(outcome.updatedState.players[0].targetIndex == 1)
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func aroundTheClockMissDoesNotAdvanceTargetIndex() throws {
    let players = [UUID(), UUID()]
    let state = try AroundTheClockEngine.makeInitialState(config: defaultConfig, playerIds: players)
    let outcome = try AroundTheClockEngine.submitTurn(state: state, darts: [miss(), miss(), miss()])
    #expect(outcome.event.targetAfter == 0)
    #expect(outcome.updatedState.players[0].targetIndex == 0)
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func aroundTheClockWrongSegmentDoesNotAdvance() throws {
    let players = [UUID(), UUID()]
    let state = try AroundTheClockEngine.makeInitialState(config: defaultConfig, playerIds: players)
    // Aiming at 1, throws a 5
    let outcome = try AroundTheClockEngine.submitTurn(state: state, darts: [hit(5), hit(5), hit(5)])
    #expect(outcome.updatedState.players[0].targetIndex == 0)
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func aroundTheClockTurnRotatesPlayers() throws {
    let players = [UUID(), UUID()]
    var state = try AroundTheClockEngine.makeInitialState(config: defaultConfig, playerIds: players)
    state = try AroundTheClockEngine.submitTurn(state: state, darts: [miss(), miss(), miss()]).updatedState
    #expect(state.currentPlayerIndex == 1)
    state = try AroundTheClockEngine.submitTurn(state: state, darts: [miss(), miss(), miss()]).updatedState
    #expect(state.currentPlayerIndex == 0)
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func aroundTheClockFinishingAllTargetsWinsMatch() throws {
    let winner = UUID()
    let other = UUID()
    var state = try AroundTheClockEngine.makeInitialState(config: defaultConfig, playerIds: [winner, other])
    // Force player to target 19 so one more hit wins
    state.players[0].targetIndex = 19
    let outcome = try AroundTheClockEngine.submitTurn(state: state, darts: [hit(20), miss(), miss()])
    #expect(outcome.updatedState.isComplete)
    #expect(outcome.updatedState.winnerPlayerId == winner)
    #expect(outcome.event.matchCompleted)
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func aroundTheClockBullFinishRequiresBullAfter20() throws {
    let winner = UUID()
    var state = try AroundTheClockEngine.makeInitialState(
        config: MatchConfigAroundTheClock(includeBullFinish: true),
        playerIds: [winner, UUID()]
    )
    // Set to index 19 (target = 20)
    state.players[0].targetIndex = 19
    var outcome = try AroundTheClockEngine.submitTurn(state: state, darts: [hit(20), miss(), miss()])
    // After hitting 20, index should be 20 (aiming at bull), not complete
    #expect(!outcome.updatedState.isComplete)
    #expect(outcome.updatedState.players[0].targetIndex == 20)

    // Now hit the bull
    // Advance to the updated state and rotate back to player 0
    var s2 = outcome.updatedState
    // Skip player 1's turn
    s2 = try AroundTheClockEngine.submitTurn(state: s2, darts: [miss(), miss(), miss()]).updatedState
    // Player 0 throws bull
    let bullDart = DartInput(multiplier: .single, segment: .outerBull)
    let finalOutcome = try AroundTheClockEngine.submitTurn(state: s2, darts: [bullDart, miss(), miss()])
    #expect(finalOutcome.updatedState.isComplete)
    #expect(finalOutcome.updatedState.winnerPlayerId == winner)
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func aroundTheClockNoResetPolicyDoesNotReset() throws {
    let players = [UUID(), UUID()]
    var state = try AroundTheClockEngine.makeInitialState(
        config: MatchConfigAroundTheClock(resetPolicy: .noReset),
        playerIds: players
    )
    state.players[0].targetIndex = 5
    let outcome = try AroundTheClockEngine.submitTurn(state: state, darts: [miss(), miss(), miss()])
    #expect(outcome.updatedState.players[0].targetIndex == 5)
    #expect(!outcome.event.resetApplied)
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func aroundTheClockResetOnThreeMissesResetsOnAllMisses() throws {
    let players = [UUID(), UUID()]
    var state = try AroundTheClockEngine.makeInitialState(
        config: MatchConfigAroundTheClock(resetPolicy: .resetOnThreeMisses),
        playerIds: players
    )
    state.players[0].targetIndex = 5
    let outcome = try AroundTheClockEngine.submitTurn(state: state, darts: [miss(), miss(), miss()])
    #expect(outcome.updatedState.players[0].targetIndex == 0)
    #expect(outcome.event.resetApplied)
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func aroundTheClockResetOnThreeMissesDoesNotResetOnPartialHit() throws {
    let players = [UUID(), UUID()]
    var state = try AroundTheClockEngine.makeInitialState(
        config: MatchConfigAroundTheClock(resetPolicy: .resetOnThreeMisses),
        playerIds: players
    )
    state.players[0].targetIndex = 5
    // Hits on dart 1, two misses — index advances; reset not applied
    let outcome = try AroundTheClockEngine.submitTurn(state: state, darts: [hit(6), miss(), miss()])
    #expect(outcome.updatedState.players[0].targetIndex == 6)
    #expect(!outcome.event.resetApplied)
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func aroundTheClockResetEntireSequenceResetsOnAnyMiss() throws {
    let players = [UUID(), UUID()]
    var state = try AroundTheClockEngine.makeInitialState(
        config: MatchConfigAroundTheClock(resetPolicy: .resetEntireSequence),
        playerIds: players
    )
    state.players[0].targetIndex = 10
    // Misses target — entire sequence reset
    let outcome = try AroundTheClockEngine.submitTurn(state: state, darts: [miss(), miss(), miss()])
    #expect(outcome.updatedState.players[0].targetIndex == 0)
    #expect(outcome.event.resetApplied)
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func aroundTheClockRejectsTooManyDarts() throws {
    let players = [UUID(), UUID()]
    let state = try AroundTheClockEngine.makeInitialState(config: defaultConfig, playerIds: players)
    #expect(throws: AppError.self) {
        try AroundTheClockEngine.submitTurn(state: state, darts: [miss(), miss(), miss(), miss()])
    }
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func aroundTheClockRejectsSubmitAfterComplete() throws {
    let players = [UUID(), UUID()]
    var state = try AroundTheClockEngine.makeInitialState(config: defaultConfig, playerIds: players)
    state.players[0].targetIndex = 19
    state = try AroundTheClockEngine.submitTurn(state: state, darts: [hit(20), miss(), miss()]).updatedState
    #expect(state.isComplete)
    #expect(throws: AppError.self) {
        try AroundTheClockEngine.submitTurn(state: state, darts: [miss()])
    }
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func aroundTheClockReplayRestoresState() throws {
    let players = [UUID(), UUID()]
    let state = try AroundTheClockEngine.makeInitialState(config: defaultConfig, playerIds: players)
    let first = try AroundTheClockEngine.submitTurn(state: state, darts: [hit(1), miss(), miss()])
    let second = try AroundTheClockEngine.submitTurn(state: first.updatedState, darts: [hit(1), miss(), miss()])

    let replayed = try AroundTheClockEngine.replay(
        config: defaultConfig,
        playerIds: players,
        events: [first.event, second.event]
    )

    #expect(replayed.players[0].targetIndex == first.event.targetAfter)
    #expect(replayed.players[1].targetIndex == second.event.targetAfter)
}
