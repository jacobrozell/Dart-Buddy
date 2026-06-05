import Foundation
import Testing
@testable import DartBuddy

private func d(_ multiplier: DartMultiplier, _ segment: Int) -> DartInput {
    DartInput(multiplier: multiplier, segment: .oneToTwenty(segment))
}

private func advanceToInning(_ targetInning: Int, state: BaseballState) throws -> BaseballState {
    var updated = state
    while updated.currentInning < targetInning, updated.isComplete == false {
        let segment = updated.currentInning
        updated = try BaseballEngine.submitTurn(
            state: updated,
            darts: [d(.single, segment)]
        ).updatedState
    }
    return updated
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func baseballInningThreeGLDExampleScoresSixRuns() throws {
    let players = [UUID(), UUID()]
    let config = MatchConfigBaseball()
    var state = try BaseballEngine.makeInitialState(config: config, playerIds: players)
    state = try advanceToInning(3, state: state)
    #expect(state.currentInning == 3)
    #expect(state.currentPlayerIndex == 0)

    state = try BaseballEngine.submitTurn(
        state: state,
        darts: [d(.single, 3), d(.double, 3), d(.triple, 3)]
    ).updatedState

    #expect(state.players[0].cumulativeRuns == 8)
    #expect(state.players[0].runsThisInning == 6)
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func baseballOffSegmentScoresZero() throws {
    let players = [UUID(), UUID()]
    let state = try BaseballEngine.makeInitialState(config: MatchConfigBaseball(), playerIds: players)

    let outcome = try BaseballEngine.submitTurn(
        state: state,
        darts: [d(.triple, 4), d(.triple, 5)]
    )

    #expect(outcome.event.runsThisVisit == 0)
    #expect(outcome.updatedState.players[0].cumulativeRuns == 0)
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func baseballThreePlayerInningRotation() throws {
    let players = [UUID(), UUID(), UUID()]
    var state = try BaseballEngine.makeInitialState(config: MatchConfigBaseball(inningCount: 9), playerIds: players)

    state = try BaseballEngine.submitTurn(state: state, darts: [d(.single, 1)]).updatedState
    #expect(state.currentPlayerIndex == 1)
    #expect(state.currentInning == 1)

    state = try BaseballEngine.submitTurn(state: state, darts: [d(.single, 1)]).updatedState
    #expect(state.currentPlayerIndex == 2)

    state = try BaseballEngine.submitTurn(state: state, darts: [d(.single, 1)]).updatedState
    #expect(state.currentPlayerIndex == 0)
    #expect(state.currentInning == 2)
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func baseballExtraInningsBreaksTie() throws {
    let p1 = UUID()
    let p2 = UUID()
    var state = try BaseballEngine.makeInitialState(
        config: MatchConfigBaseball(inningCount: 1, tieBreaker: .extraInnings),
        playerIds: [p1, p2]
    )

    state = try BaseballEngine.submitTurn(state: state, darts: [d(.single, 1)]).updatedState
    state = try BaseballEngine.submitTurn(state: state, darts: [d(.single, 1)]).updatedState
    #expect(state.isExtraInning)
    #expect(state.currentInning == 2)
    #expect(state.isComplete == false)

    state = try BaseballEngine.submitTurn(state: state, darts: [d(.single, 2)]).updatedState
    state = try BaseballEngine.submitTurn(state: state, darts: [DartInput(multiplier: .single, segment: .miss, isMiss: true)]).updatedState
    #expect(state.isComplete)
    #expect(state.winnerPlayerId == p1)
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func baseballBullPlayoffResolvesTie() throws {
    let p1 = UUID()
    let p2 = UUID()
    var state = try BaseballEngine.makeInitialState(
        config: MatchConfigBaseball(inningCount: 1, tieBreaker: .bullPlayoff),
        playerIds: [p1, p2]
    )

    state = try BaseballEngine.submitTurn(state: state, darts: [d(.single, 1)]).updatedState
    state = try BaseballEngine.submitTurn(state: state, darts: [d(.single, 1)]).updatedState
    #expect(state.phase == .bullPlayoff)

    state = try BaseballEngine.submitTurn(
        state: state,
        darts: [DartInput(multiplier: .single, segment: .outerBull)]
    ).updatedState
    state = try BaseballEngine.submitTurn(state: state, darts: []).updatedState
    #expect(state.winnerPlayerId == p1)
    #expect(state.isComplete)
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func baseballBullPlayoffContinuesWhenRoundTied() throws {
    let p1 = UUID()
    let p2 = UUID()
    var state = try BaseballEngine.makeInitialState(
        config: MatchConfigBaseball(inningCount: 1, tieBreaker: .bullPlayoff),
        playerIds: [p1, p2]
    )

    state = try BaseballEngine.submitTurn(state: state, darts: [d(.single, 1)]).updatedState
    state = try BaseballEngine.submitTurn(state: state, darts: [d(.single, 1)]).updatedState
    #expect(state.phase == .bullPlayoff)

    state = try BaseballEngine.submitTurn(
        state: state,
        darts: [DartInput(multiplier: .single, segment: .outerBull)]
    ).updatedState
    state = try BaseballEngine.submitTurn(
        state: state,
        darts: [DartInput(multiplier: .single, segment: .outerBull)]
    ).updatedState
    #expect(state.isComplete == false)
    #expect(state.playoffRound == 2)
    #expect(state.players[0].playoffRunsThisRound == 0)
    #expect(state.players[1].playoffRunsThisRound == 0)
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func baseballSeventhInningStretchGate() throws {
    let players = [UUID(), UUID()]
    let config = MatchConfigBaseball(inningCount: 7, seventhInningStretch: true)
    var state = try BaseballEngine.makeInitialState(config: config, playerIds: players)

    for _ in 0 ..< 12 {
        state = try BaseballEngine.submitTurn(state: state, darts: [d(.single, state.currentInning)]).updatedState
    }
    #expect(state.currentInning == 7)
    #expect(state.currentPlayerIndex == 0)

    let blocked = try BaseballEngine.submitTurn(state: state, darts: [d(.triple, 7)]).updatedState
    #expect(blocked.players[0].cumulativeRuns == 6)
    #expect(blocked.players[0].stretchGateOpen == false)

    let opened = try BaseballEngine.submitTurn(
        state: state,
        darts: [DartInput(multiplier: .single, segment: .outerBull), d(.triple, 7)]
    ).updatedState
    #expect(opened.players[0].stretchGateOpen)
    #expect(opened.players[0].cumulativeRuns == 9)
    #expect(opened.players[0].runsThisInning == 3)
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func baseballUndoViaReplayRestoresMidInning() throws {
    let players = [UUID(), UUID()]
    var state = try BaseballEngine.makeInitialState(config: MatchConfigBaseball(), playerIds: players)
    let first = try BaseballEngine.submitTurn(state: state, darts: [d(.single, 1)]).event
    state = try BaseballEngine.submitTurn(state: state, darts: [d(.double, 1)]).updatedState

    let replayed = try BaseballEngine.replay(config: MatchConfigBaseball(), playerIds: players, events: [first])
    #expect(replayed.players[0].cumulativeRuns == 1)
    #expect(replayed.currentPlayerIndex == 1)
}
