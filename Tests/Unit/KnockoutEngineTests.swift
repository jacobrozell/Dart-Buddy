import Foundation
import Testing
@testable import DartBuddy

// MARK: - Helpers

private func miss() -> DartInput {
    DartInput(multiplier: .single, segment: .miss, isMiss: true)
}

private func single(_ value: Int) -> DartInput {
    DartInput(multiplier: .single, segment: .oneToTwenty(value))
}

private func triple(_ value: Int) -> DartInput {
    DartInput(multiplier: .triple, segment: .oneToTwenty(value))
}

private func visitOf(_ total: Int) -> [DartInput] {
    // Build a 3-dart visit that sums to `total`.
    // Use single-20 × n + remainder for simplicity.
    let twenties = min(total / 20, 3)
    let rem = total - twenties * 20
    var darts: [DartInput] = Array(repeating: single(20), count: twenties)
    if rem > 0, darts.count < 3 {
        darts.append(single(rem))
    }
    while darts.count < 3 {
        darts.append(miss())
    }
    return darts
}

// MARK: - Engine tests

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func knockoutRoundLeaderSetsHighNeverStrikes() throws {
    let p1 = UUID()
    let p2 = UUID()
    let state = try KnockoutEngine.makeInitialState(
        config: MatchConfigKnockout(),
        playerIds: [p1, p2]
    )

    // P1 is round leader — any total sets the high, never a strike.
    let outcome = try KnockoutEngine.submitTurn(state: state, darts: visitOf(40))

    #expect(outcome.event.beatHigh == true)
    #expect(outcome.event.strikeAwarded == false)
    #expect(outcome.event.highAfter == 40)
    #expect(outcome.updatedState.currentHigh == 40)
    #expect(outcome.updatedState.players[0].strikes == 0)
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func knockoutSecondPlayerBeatsHighNoStrike() throws {
    let players = [UUID(), UUID()]
    var state = try KnockoutEngine.makeInitialState(
        config: MatchConfigKnockout(),
        playerIds: players
    )
    state = try KnockoutEngine.submitTurn(state: state, darts: visitOf(40)).updatedState

    // P2 beats 40 with 60.
    let outcome = try KnockoutEngine.submitTurn(state: state, darts: visitOf(60))

    #expect(outcome.event.beatHigh == true)
    #expect(outcome.event.strikeAwarded == false)
    #expect(outcome.event.highAfter == 60)
    #expect(outcome.updatedState.players[1].strikes == 0)
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func knockoutTiedHighDoesNotBeat() throws {
    let players = [UUID(), UUID()]
    var state = try KnockoutEngine.makeInitialState(
        config: MatchConfigKnockout(),
        playerIds: players
    )
    state = try KnockoutEngine.submitTurn(state: state, darts: visitOf(40)).updatedState

    // P2 ties exactly — must EXCEED, so tie => strike.
    let outcome = try KnockoutEngine.submitTurn(state: state, darts: visitOf(40))

    #expect(outcome.event.beatHigh == false)
    #expect(outcome.event.strikeAwarded == true)
    #expect(outcome.updatedState.players[1].strikes == 1)
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func knockoutMissedHighAwardsStrike() throws {
    let players = [UUID(), UUID()]
    var state = try KnockoutEngine.makeInitialState(
        config: MatchConfigKnockout(),
        playerIds: players
    )
    state = try KnockoutEngine.submitTurn(state: state, darts: visitOf(60)).updatedState

    // P2 scores lower than 60.
    let outcome = try KnockoutEngine.submitTurn(state: state, darts: visitOf(20))

    #expect(outcome.event.strikeAwarded == true)
    #expect(outcome.updatedState.players[1].strikes == 1)
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func knockoutThreeStrikesEliminatesPlayer() throws {
    let p1 = UUID()
    let p2 = UUID()
    let p3 = UUID()
    var state = try KnockoutEngine.makeInitialState(
        config: MatchConfigKnockout(strikesToEliminate: 3),
        playerIds: [p1, p2, p3]
    )

    // Round 1: p1 sets high 60, p2 and p3 miss.
    state = try KnockoutEngine.submitTurn(state: state, darts: visitOf(60)).updatedState
    state = try KnockoutEngine.submitTurn(state: state, darts: visitOf(20)).updatedState
    state = try KnockoutEngine.submitTurn(state: state, darts: visitOf(20)).updatedState
    // Round 2: p1 sets high, p2 and p3 miss again.
    state = try KnockoutEngine.submitTurn(state: state, darts: visitOf(60)).updatedState
    state = try KnockoutEngine.submitTurn(state: state, darts: visitOf(20)).updatedState
    state = try KnockoutEngine.submitTurn(state: state, darts: visitOf(20)).updatedState
    // Round 3: p1 sets high, p2 and p3 miss for third strike.
    state = try KnockoutEngine.submitTurn(state: state, darts: visitOf(60)).updatedState
    state = try KnockoutEngine.submitTurn(state: state, darts: visitOf(20)).updatedState
    let outcome = try KnockoutEngine.submitTurn(state: state, darts: visitOf(20))

    let p2State = outcome.updatedState.players.first { $0.playerId == p2 }
    let p3State = outcome.updatedState.players.first { $0.playerId == p3 }
    #expect(p2State?.strikes == 3)
    #expect(p2State?.isEliminated == true)
    #expect(p3State?.strikes == 3)
    #expect(p3State?.isEliminated == true)
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func knockoutLastSurvivorWins() throws {
    let p1 = UUID()
    let p2 = UUID()
    var state = try KnockoutEngine.makeInitialState(
        config: MatchConfigKnockout(strikesToEliminate: 1),
        playerIds: [p1, p2]
    )

    // P1 sets high, P2 fails — gets 1 strike, eliminated immediately with strikesToEliminate=1.
    state = try KnockoutEngine.submitTurn(state: state, darts: visitOf(60)).updatedState
    let outcome = try KnockoutEngine.submitTurn(state: state, darts: visitOf(10))

    #expect(outcome.updatedState.isComplete)
    #expect(outcome.updatedState.winnerPlayerId == p1)
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func knockoutHighResetsAfterRound() throws {
    let players = [UUID(), UUID()]
    var state = try KnockoutEngine.makeInitialState(
        config: MatchConfigKnockout(resetHighEachRound: true),
        playerIds: players
    )

    // Round 1: P1 sets high 80.
    state = try KnockoutEngine.submitTurn(state: state, darts: visitOf(60)).updatedState
    // P2 beats 60 with 80.
    state = try KnockoutEngine.submitTurn(state: state, darts: visitOf(80)).updatedState

    // Round 2 starts: high should reset to 0.
    #expect(state.currentHigh == 0)
    #expect(state.currentRound == 2)
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func knockoutReplayRestoresState() throws {
    let players = [UUID(), UUID()]
    let config = MatchConfigKnockout()
    var state = try KnockoutEngine.makeInitialState(config: config, playerIds: players)

    let t1 = try KnockoutEngine.submitTurn(state: state, darts: visitOf(40))
    state = t1.updatedState
    let t2 = try KnockoutEngine.submitTurn(state: state, darts: visitOf(20))

    let replayed = try KnockoutEngine.replay(
        config: config,
        playerIds: players,
        events: [t1.event, t2.event]
    )

    #expect(replayed.players[1].strikes == t2.updatedState.players[1].strikes)
    #expect(replayed.currentHigh == t2.updatedState.currentHigh)
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func knockoutCompletedMatchRejectsSubmit() throws {
    let p1 = UUID()
    let p2 = UUID()
    var state = try KnockoutEngine.makeInitialState(
        config: MatchConfigKnockout(strikesToEliminate: 1),
        playerIds: [p1, p2]
    )
    state = try KnockoutEngine.submitTurn(state: state, darts: visitOf(60)).updatedState
    state = try KnockoutEngine.submitTurn(state: state, darts: visitOf(10)).updatedState
    #expect(state.isComplete)

    #expect(throws: AppError.self) {
        _ = try KnockoutEngine.submitTurn(state: state, darts: visitOf(20))
    }
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func knockoutMinimumTwoPlayersRequired() throws {
    #expect(throws: AppError.self) {
        _ = try KnockoutEngine.makeInitialState(config: MatchConfigKnockout(), playerIds: [UUID()])
    }
}

@Test(.tags(.unit, .match, .offline, .regression))
func knockoutTooManyDartsRejected() throws {
    let players = [UUID(), UUID()]
    let state = try KnockoutEngine.makeInitialState(config: MatchConfigKnockout(), playerIds: players)

    let fourDarts = [single(20), single(20), single(20), single(20)]
    #expect(throws: AppError.self) {
        _ = try KnockoutEngine.submitTurn(state: state, darts: fourDarts)
    }
}

@Test(.tags(.unit, .match, .offline, .regression))
func knockoutZeroStrikesToEliminateRejected() throws {
    #expect(throws: (any Error).self) {
        _ = try KnockoutEngine.makeInitialState(
            config: MatchConfigKnockout(strikesToEliminate: 0),
            playerIds: [UUID(), UUID()]
        )
    }
}
