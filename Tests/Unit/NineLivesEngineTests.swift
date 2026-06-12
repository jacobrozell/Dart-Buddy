import Foundation
import Testing
@testable import DartBuddy

// MARK: - Helpers

private func hit(_ segment: Int) -> DartInput {
    DartInput(multiplier: .single, segment: .oneToTwenty(segment))
}

private func miss() -> DartInput {
    DartInput(multiplier: .single, segment: .miss, isMiss: true)
}

private func wrongSegment(_ segment: Int) -> DartInput {
    DartInput(multiplier: .single, segment: .oneToTwenty(segment))
}

// MARK: - Engine Tests

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func nineLivesAdvancesTargetOnFirstHit() throws {
    let players = [UUID(), UUID()]
    let state = try NineLivesEngine.makeInitialState(
        config: MatchConfigNineLives(),
        playerIds: players
    )
    #expect(state.players[0].targetIndex == 0)
    #expect(state.players[0].currentTarget == 1)

    let outcome = try NineLivesEngine.submitTurn(
        state: state,
        darts: [hit(1), miss(), miss()]
    )

    #expect(outcome.event.advanced == true)
    #expect(outcome.event.lifeLost == false)
    #expect(outcome.updatedState.players[0].targetIndex == 1)
    #expect(outcome.updatedState.players[0].lives == 9)
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func nineLivesLosesLifeOnNoAdvance() throws {
    let players = [UUID(), UUID()]
    let state = try NineLivesEngine.makeInitialState(
        config: MatchConfigNineLives(),
        playerIds: players
    )

    let outcome = try NineLivesEngine.submitTurn(
        state: state,
        darts: [miss(), miss(), miss()]
    )

    #expect(outcome.event.advanced == false)
    #expect(outcome.event.lifeLost == true)
    #expect(outcome.event.livesAfter == 8)
    #expect(outcome.updatedState.players[0].lives == 8)
    #expect(outcome.updatedState.players[0].targetIndex == 0)
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func nineLivesWrongSegmentDoesNotAdvance() throws {
    let players = [UUID(), UUID()]
    let state = try NineLivesEngine.makeInitialState(
        config: MatchConfigNineLives(),
        playerIds: players
    )
    // Targeting 1, but player throws at 2
    let outcome = try NineLivesEngine.submitTurn(
        state: state,
        darts: [wrongSegment(2), wrongSegment(3), miss()]
    )

    #expect(outcome.event.advanced == false)
    #expect(outcome.event.lifeLost == true)
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func nineLivesEliminatesPlayerAtZeroLives() throws {
    let p1 = UUID()
    let p2 = UUID()
    let config = MatchConfigNineLives(startingLives: .three)
    var state = try NineLivesEngine.makeInitialState(config: config, playerIds: [p1, p2])

    // Lose all 3 lives for p1
    for _ in 0 ..< 3 {
        guard !state.isComplete else { break }
        state = try NineLivesEngine.submitTurn(state: state, darts: [miss(), miss(), miss()]).updatedState
        guard !state.isComplete else { break }
        state = try NineLivesEngine.submitTurn(state: state, darts: [hit(1), miss(), miss()]).updatedState
    }

    let p1State = state.players.first { $0.playerId == p1 }
    #expect(p1State?.isEliminated == true)
    #expect(p1State?.lives == 0)
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func nineLivesLastStandingWins() throws {
    let winner = UUID()
    let loser = UUID()
    let config = MatchConfigNineLives(startingLives: .three)
    var state = try NineLivesEngine.makeInitialState(config: config, playerIds: [winner, loser])

    // loser starts second; eliminate winner's turns (they hit) and loser's turns (they miss)
    // We need loser to lose all 3 lives.
    // Round 1: winner hits, loser misses
    state = try NineLivesEngine.submitTurn(state: state, darts: [hit(1), miss(), miss()]).updatedState
    state = try NineLivesEngine.submitTurn(state: state, darts: [miss(), miss(), miss()]).updatedState
    // Round 2: winner hits, loser misses
    state = try NineLivesEngine.submitTurn(state: state, darts: [hit(2), miss(), miss()]).updatedState
    state = try NineLivesEngine.submitTurn(state: state, darts: [miss(), miss(), miss()]).updatedState
    // Round 3: winner hits, loser misses → loser eliminated → winner wins
    state = try NineLivesEngine.submitTurn(state: state, darts: [hit(3), miss(), miss()]).updatedState
    let outcome = try NineLivesEngine.submitTurn(state: state, darts: [miss(), miss(), miss()])

    #expect(outcome.event.eliminated == true)
    #expect(outcome.event.matchCompleted == true)
    #expect(outcome.updatedState.isComplete == true)
    #expect(outcome.updatedState.winnerPlayerId == winner)
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func nineLivesFirstToComplete20Wins() throws {
    let winner = UUID()
    let other1 = UUID()
    let other2 = UUID()
    let config = MatchConfigNineLives()
    var state = try NineLivesEngine.makeInitialState(config: config, playerIds: [winner, other1, other2])
    state.players[0].targetIndex = 19
    state.currentPlayerIndex = 0

    let outcome = try NineLivesEngine.submitTurn(
        state: state,
        darts: [hit(20), miss(), miss()]
    )

    #expect(outcome.event.matchCompleted == true)
    #expect(outcome.updatedState.isComplete == true)
    #expect(outcome.updatedState.winnerPlayerId == winner)
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func nineLivesThreeStartingLivesConfig() throws {
    let players = [UUID(), UUID()]
    let config = MatchConfigNineLives(startingLives: .three)
    let state = try NineLivesEngine.makeInitialState(config: config, playerIds: players)

    #expect(state.players[0].lives == 3)
    #expect(state.players[1].lives == 3)
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func nineLivesRequiresMinimumTwoPlayers() throws {
    #expect(throws: AppError.self) {
        try NineLivesEngine.makeInitialState(
            config: MatchConfigNineLives(),
            playerIds: [UUID()]
        )
    }
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func nineLivesRejectsTooManyDarts() throws {
    let players = [UUID(), UUID()]
    let state = try NineLivesEngine.makeInitialState(config: MatchConfigNineLives(), playerIds: players)

    #expect(throws: AppError.self) {
        try NineLivesEngine.submitTurn(
            state: state,
            darts: [hit(1), hit(1), hit(1), hit(1)]
        )
    }
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func nineLivesRejectsSubmitWhenComplete() throws {
    let p1 = UUID()
    let p2 = UUID()
    let config = MatchConfigNineLives(startingLives: .three)
    var state = try NineLivesEngine.makeInitialState(config: config, playerIds: [p1, p2])
    // Eliminate p2 by losing all 3 lives
    for _ in 0 ..< 3 {
        state = try NineLivesEngine.submitTurn(state: state, darts: [hit(1), miss(), miss()]).updatedState
        state = try NineLivesEngine.submitTurn(state: state, darts: [miss(), miss(), miss()]).updatedState
    }
    #expect(state.isComplete)
    #expect(throws: AppError.self) {
        try NineLivesEngine.submitTurn(state: state, darts: [hit(1), miss(), miss()])
    }
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func nineLivesOnlyFirstHitAdvances() throws {
    let players = [UUID(), UUID()]
    let state = try NineLivesEngine.makeInitialState(config: MatchConfigNineLives(), playerIds: players)

    // Three darts all on target 1 — should only advance once
    let outcome = try NineLivesEngine.submitTurn(
        state: state,
        darts: [hit(1), hit(1), hit(1)]
    )

    #expect(outcome.event.advanced == true)
    #expect(outcome.updatedState.players[0].targetIndex == 1)
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func nineLivesReplayRestoresState() throws {
    let p1 = UUID()
    let p2 = UUID()
    let config = MatchConfigNineLives()
    let initial = try NineLivesEngine.makeInitialState(config: config, playerIds: [p1, p2])

    let turn1 = try NineLivesEngine.submitTurn(state: initial, darts: [hit(1), miss(), miss()])
    let turn2 = try NineLivesEngine.submitTurn(
        state: turn1.updatedState,
        darts: [miss(), miss(), miss()]
    )

    let replayed = try NineLivesEngine.replay(
        config: config,
        playerIds: [p1, p2],
        events: [turn1.event, turn2.event]
    )

    let origState = turn2.updatedState
    #expect(replayed.players[0].targetIndex == origState.players[0].targetIndex)
    #expect(replayed.players[1].lives == origState.players[1].lives)
    #expect(replayed.turnIndex == origState.turnIndex)
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func nineLivesEliminatedPlayerSkippedInRotation() throws {
    let p1 = UUID()
    let p2 = UUID()
    let p3 = UUID()
    let config = MatchConfigNineLives(startingLives: .three)
    var state = try NineLivesEngine.makeInitialState(config: config, playerIds: [p1, p2, p3])

    // Eliminate p2 (second player) by having them miss 3 times
    // p1 hits, p2 misses, p3 hits (repeat 3 times)
    for _ in 0 ..< 3 {
        state = try NineLivesEngine.submitTurn(state: state, darts: [hit(1), miss(), miss()]).updatedState
        state = try NineLivesEngine.submitTurn(state: state, darts: [miss(), miss(), miss()]).updatedState
        state = try NineLivesEngine.submitTurn(state: state, darts: [hit(1), miss(), miss()]).updatedState
    }

    let p2State = state.players.first { $0.playerId == p2 }!
    #expect(p2State.isEliminated == true)

    // After p1 throws, turn should go to p3 (skipping eliminated p2)
    let p1Index = state.players.firstIndex { $0.playerId == p1 }!
    state.currentPlayerIndex = p1Index
    let outcome = try NineLivesEngine.submitTurn(state: state, darts: [miss(), miss(), miss()])

    let nextPlayerId = outcome.updatedState.players[outcome.updatedState.currentPlayerIndex].playerId
    #expect(nextPlayerId == p3)
}
