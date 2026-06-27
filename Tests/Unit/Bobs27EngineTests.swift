import Foundation
import Testing
@testable import DartBuddy

// MARK: - Helpers

private func double(_ n: Int) -> DartInput {
    DartInput(multiplier: .double, segment: .oneToTwenty(n))
}

private func single(_ n: Int) -> DartInput {
    DartInput(multiplier: .single, segment: .oneToTwenty(n))
}

private func miss() -> DartInput {
    DartInput(multiplier: .single, segment: .miss, isMiss: true)
}

private func innerBull() -> DartInput {
    DartInput(multiplier: .double, segment: .innerBull)
}

private func outerBull() -> DartInput {
    DartInput(multiplier: .single, segment: .outerBull)
}

// MARK: - Setup

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func bobs27RequiresAtLeastOnePlayer() {
    #expect(throws: AppError.self) {
        _ = try Bobs27Engine.makeInitialState(config: MatchConfigBobs27(), playerIds: [])
    }
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func bobs27SupportsMultiplePlayers() throws {
    let state = try Bobs27Engine.makeInitialState(
        config: MatchConfigBobs27(),
        playerIds: [UUID(), UUID()]
    )
    #expect(state.players.count == 2)
    #expect(state.players.allSatisfy { $0.score == 27 })
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func bobs27InitialStateStartsAtTwentySevenOnDoubleOne() throws {
    let state = try Bobs27Engine.makeInitialState(
        config: MatchConfigBobs27(),
        playerIds: [UUID()]
    )
    #expect(state.players[0].score == 27)
    #expect(state.roundIndex == 0)
    #expect(state.currentTarget == .double(1))
    #expect(state.isComplete == false)
}

// MARK: - Hit / Miss math

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func bobs27HitOnTargetAddsHitCountTimesValue() throws {
    let state = try Bobs27Engine.makeInitialState(
        config: MatchConfigBobs27(),
        playerIds: [UUID()]
    )
    let outcome = try Bobs27Engine.submitTurn(
        state: state,
        darts: [double(1), double(1), miss()]
    )
    #expect(outcome.event.hitCount == 2)
    #expect(outcome.event.delta == 4)
    #expect(outcome.updatedState.players[0].score == 31)
    #expect(outcome.updatedState.roundIndex == 1)
    #expect(outcome.updatedState.currentTarget == .double(2))
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func bobs27MissAllSubtractsTargetValue() throws {
    let state = try Bobs27Engine.makeInitialState(
        config: MatchConfigBobs27(),
        playerIds: [UUID()]
    )
    let outcome = try Bobs27Engine.submitTurn(
        state: state,
        darts: [single(1), miss(), miss()]
    )
    #expect(outcome.event.hitCount == 0)
    #expect(outcome.event.delta == -2)
    #expect(outcome.updatedState.players[0].score == 25)
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func bobs27SingleHitDoesNotCountAsDoubleHit() throws {
    let state = try Bobs27Engine.makeInitialState(
        config: MatchConfigBobs27(),
        playerIds: [UUID()]
    )
    let outcome = try Bobs27Engine.submitTurn(
        state: state,
        darts: [single(1), single(1), single(1)]
    )
    #expect(outcome.event.hitCount == 0)
    #expect(outcome.event.delta == -2)
}

// MARK: - Bull round

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func bobs27BullRoundOnlyInnerBullCounts() throws {
    var state = try Bobs27Engine.makeInitialState(
        config: MatchConfigBobs27(),
        playerIds: [UUID()]
    )
    state.roundIndex = 20
    state.players[0].score = 100
    #expect(state.currentTarget == .bull)

    let outcome = try Bobs27Engine.submitTurn(
        state: state,
        darts: [innerBull(), outerBull(), miss()]
    )
    #expect(outcome.event.hitCount == 1)
    #expect(outcome.event.delta == 50)
    #expect(outcome.updatedState.players[0].score == 150)
    #expect(outcome.updatedState.isComplete == true)
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func bobs27BullRoundMissSubtractsBullPenalty() throws {
    var state = try Bobs27Engine.makeInitialState(
        config: MatchConfigBobs27(),
        playerIds: [UUID()]
    )
    state.roundIndex = 20
    state.players[0].score = 100
    let outcome = try Bobs27Engine.submitTurn(
        state: state,
        darts: [outerBull(), miss(), miss()]
    )
    #expect(outcome.event.delta == -27)
    #expect(outcome.updatedState.players[0].score == 73)
    #expect(outcome.updatedState.isComplete == true)
}

// MARK: - Bust / completion

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func bobs27BustOutWhenScoreHitsZero() throws {
    var state = try Bobs27Engine.makeInitialState(
        config: MatchConfigBobs27(),
        playerIds: [UUID()]
    )
    state.roundIndex = 4
    state.players[0].score = 10
    let outcome = try Bobs27Engine.submitTurn(
        state: state,
        darts: [miss(), miss(), miss()]
    )
    #expect(outcome.event.delta == -10)
    #expect(outcome.updatedState.players[0].score == 0)
    #expect(outcome.updatedState.players[0].bustOut == true)
    #expect(outcome.updatedState.isComplete == true)
    #expect(outcome.event.matchCompleted == true)
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func bobs27PerfectGameScoresFourteenThirtySeven() throws {
    var state = try Bobs27Engine.makeInitialState(
        config: MatchConfigBobs27(),
        playerIds: [UUID()]
    )
    for round in 0 ..< 20 {
        let n = round + 1
        let outcome = try Bobs27Engine.submitTurn(
            state: state,
            darts: [double(n), double(n), double(n)]
        )
        state = outcome.updatedState
    }
    let finalOutcome = try Bobs27Engine.submitTurn(
        state: state,
        darts: [innerBull(), innerBull(), innerBull()]
    )
    #expect(finalOutcome.updatedState.players[0].score == 1437)
    #expect(finalOutcome.updatedState.isComplete == true)
    #expect(finalOutcome.updatedState.players[0].bustOut == false)
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func bobs27SubmitAfterCompletionThrows() throws {
    var state = try Bobs27Engine.makeInitialState(
        config: MatchConfigBobs27(),
        playerIds: [UUID()]
    )
    state.isComplete = true
    #expect(throws: AppError.self) {
        _ = try Bobs27Engine.submitTurn(state: state, darts: [miss()])
    }
}

// MARK: - Replay

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func bobs27ReplayReconstructsTerminalState() throws {
    let playerId = UUID()
    let initial = try Bobs27Engine.makeInitialState(
        config: MatchConfigBobs27(),
        playerIds: [playerId]
    )
    var state = initial
    var events: [Bobs27RoundEvent] = []
    let visits: [[DartInput]] = [
        [double(1), miss(), miss()],
        [miss(), miss(), miss()],
        [double(3), double(3), double(3)],
    ]
    for visit in visits {
        let outcome = try Bobs27Engine.submitTurn(state: state, darts: visit)
        state = outcome.updatedState
        events.append(outcome.event)
    }
    let replayed = try Bobs27Engine.replay(
        config: MatchConfigBobs27(),
        playerIds: [playerId],
        events: events
    )
    #expect(replayed.players[0].score == state.players[0].score)
    #expect(replayed.roundIndex == state.roundIndex)
}
