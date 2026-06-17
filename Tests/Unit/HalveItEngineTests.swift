import Foundation
import Testing
@testable import DartBuddy

// MARK: - Helpers

private func single(_ n: Int) -> DartInput {
    DartInput(multiplier: .single, segment: .oneToTwenty(n))
}

private func double(_ n: Int) -> DartInput {
    DartInput(multiplier: .double, segment: .oneToTwenty(n))
}

private func triple(_ n: Int) -> DartInput {
    DartInput(multiplier: .triple, segment: .oneToTwenty(n))
}

private func miss() -> DartInput {
    DartInput(multiplier: .single, segment: .miss, isMiss: true)
}

// MARK: - Setup

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func halveItRejectsEmptyRoster() {
    #expect(throws: AppError.self) {
        _ = try HalveItEngine.makeInitialState(
            config: MatchConfigHalveIt(),
            playerIds: []
        )
    }
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func halveItStartsAtConfiguredScoreOnFirstTarget() throws {
    let state = try HalveItEngine.makeInitialState(
        config: MatchConfigHalveIt(),
        playerIds: [UUID()]
    )
    #expect(state.players[0].total == 301)
    #expect(state.currentTarget == 20)
    #expect(state.roundIndex == 0)
}

// MARK: - Hit math

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func halveItHitsSumAcrossMultipliersOnTarget() throws {
    let state = try HalveItEngine.makeInitialState(
        config: MatchConfigHalveIt(),
        playerIds: [UUID()]
    )
    // Round 0 = 20. T20 + D20 + S20 = 60 + 40 + 20 = 120.
    let outcome = try HalveItEngine.submitTurn(
        state: state,
        darts: [triple(20), double(20), single(20)]
    )
    #expect(outcome.event.visitScore == 120)
    #expect(outcome.event.halved == false)
    #expect(outcome.updatedState.players[0].total == 421)
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func halveItDartsOffTargetDoNotScore() throws {
    let state = try HalveItEngine.makeInitialState(
        config: MatchConfigHalveIt(),
        playerIds: [UUID()]
    )
    // Targeting 20; throws land on 19 (off-target) + miss.
    let outcome = try HalveItEngine.submitTurn(
        state: state,
        darts: [single(19), triple(19), miss()]
    )
    #expect(outcome.event.visitScore == 0)
    #expect(outcome.event.halved == true)
    #expect(outcome.updatedState.players[0].total == 150)  // 301 / 2
}

// MARK: - Halving rounds down

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func halveItHalveUsesIntegerDivision() throws {
    var state = try HalveItEngine.makeInitialState(
        config: MatchConfigHalveIt(),
        playerIds: [UUID()]
    )
    state.players[0].total = 51
    let outcome = try HalveItEngine.submitTurn(
        state: state,
        darts: [miss(), miss(), miss()]
    )
    #expect(outcome.updatedState.players[0].total == 25)
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func halveItOneHitPreventsHalve() throws {
    let state = try HalveItEngine.makeInitialState(
        config: MatchConfigHalveIt(),
        playerIds: [UUID()]
    )
    let outcome = try HalveItEngine.submitTurn(
        state: state,
        darts: [single(20), miss(), miss()]
    )
    #expect(outcome.event.visitScore == 20)
    #expect(outcome.event.halved == false)
    #expect(outcome.updatedState.players[0].total == 321)
}

// MARK: - Multi-round + multiplayer

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func halveItAdvancesRoundOnlyAfterAllPlayersThrow() throws {
    let a = UUID()
    let b = UUID()
    var state = try HalveItEngine.makeInitialState(
        config: MatchConfigHalveIt(),
        playerIds: [a, b]
    )
    state = try HalveItEngine.submitTurn(
        state: state,
        darts: [single(20)]
    ).updatedState
    #expect(state.roundIndex == 0)
    #expect(state.currentPlayerIndex == 1)
    #expect(state.currentTarget == 20)

    state = try HalveItEngine.submitTurn(
        state: state,
        darts: [single(20)]
    ).updatedState
    #expect(state.roundIndex == 1)
    #expect(state.currentPlayerIndex == 0)
    #expect(state.currentTarget == 19)
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func halveItCompletesAfterFinalRound() throws {
    let player = UUID()
    var state = try HalveItEngine.makeInitialState(
        config: MatchConfigHalveIt(),
        playerIds: [player]
    )
    for target in [20, 19, 18, 17, 16, 15] {
        let outcome = try HalveItEngine.submitTurn(
            state: state,
            darts: [single(target)]
        )
        state = outcome.updatedState
        if target == 15 {
            #expect(outcome.event.matchCompleted == true)
        }
    }
    #expect(state.isComplete == true)
    #expect(state.winnerPlayerId == player)
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func halveItPicksHigherTotalAsWinner() throws {
    let a = UUID()
    let b = UUID()
    var state = try HalveItEngine.makeInitialState(
        config: MatchConfigHalveIt(),
        playerIds: [a, b]
    )
    for _ in 0 ..< 6 {
        // a hits the target; b misses entirely.
        let aOutcome = try HalveItEngine.submitTurn(
            state: state,
            darts: [single(state.currentTarget ?? 20)]
        )
        state = aOutcome.updatedState
        let bOutcome = try HalveItEngine.submitTurn(
            state: state,
            darts: [miss(), miss(), miss()]
        )
        state = bOutcome.updatedState
    }
    #expect(state.isComplete == true)
    #expect(state.winnerPlayerId == a)
    #expect(state.players[0].total > state.players[1].total)
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func halveItSubmitAfterCompletionThrows() throws {
    var state = try HalveItEngine.makeInitialState(
        config: MatchConfigHalveIt(),
        playerIds: [UUID()]
    )
    state.isComplete = true
    #expect(throws: AppError.self) {
        _ = try HalveItEngine.submitTurn(state: state, darts: [miss()])
    }
}

// MARK: - Replay

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func halveItReplayReconstructsRunningTotals() throws {
    let player = UUID()
    var state = try HalveItEngine.makeInitialState(
        config: MatchConfigHalveIt(),
        playerIds: [player]
    )
    var events: [HalveItRoundEvent] = []
    let visits: [[DartInput]] = [
        [triple(20), single(20), miss()],   // +80 → 381
        [miss(), miss(), miss()],            // halve → 190
        [single(18), miss(), miss()],        // +18 → 208
    ]
    for visit in visits {
        let outcome = try HalveItEngine.submitTurn(state: state, darts: visit)
        state = outcome.updatedState
        events.append(outcome.event)
    }
    let replayed = try HalveItEngine.replay(
        config: MatchConfigHalveIt(),
        playerIds: [player],
        events: events
    )
    #expect(replayed.players[0].total == state.players[0].total)
    #expect(replayed.roundIndex == state.roundIndex)
}
