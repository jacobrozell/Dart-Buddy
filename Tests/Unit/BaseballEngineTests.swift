import Foundation
import Testing
@testable import DartBuddy

private func d(_ multiplier: DartMultiplier, _ segment: Int) -> DartInput {
    DartInput(multiplier: multiplier, segment: .oneToTwenty(segment))
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func baseballInningThreeGLDExampleScoresSixRuns() throws {
    let players = [UUID(), UUID()]
    let config = MatchConfigBaseball()
    var state = try BaseballEngine.makeInitialState(config: config, playerIds: players)

    state = try BaseballEngine.submitTurn(
        state: state,
        darts: [d(.single, 3), d(.double, 3), d(.triple, 3)]
    ).updatedState

    #expect(state.players[0].cumulativeRuns == 6)
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
    state = try BaseballEngine.submitTurn(state: state, darts: [d(.double, 1)]).updatedState
    #expect(state.isExtraInning)
    #expect(state.currentInning == 2)
    #expect(state.isComplete == false)

    state = try BaseballEngine.submitTurn(state: state, darts: [d(.single, 2)]).updatedState
    state = try BaseballEngine.submitTurn(state: state, darts: [d(.single, 2)]).updatedState
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
func baseballSeventhInningStretchGate() throws {
    let players = [UUID(), UUID()]
    let config = MatchConfigBaseball(inningCount: 7, seventhInningStretch: true)
    var state = try BaseballEngine.makeInitialState(config: config, playerIds: players)

    for _ in 0 ..< 12 {
        state = try BaseballEngine.submitTurn(state: state, darts: [d(.single, state.currentInning)]).updatedState
    }
    #expect(state.currentInning == 7)

    let blocked = try BaseballEngine.submitTurn(state: state, darts: [d(.triple, 7)]).updatedState
    #expect(blocked.players[0].cumulativeRuns == 3)

    let opened = try BaseballEngine.submitTurn(
        state: blocked,
        darts: [DartInput(multiplier: .single, segment: .outerBull), d(.triple, 7)]
    ).updatedState
    #expect(opened.players[0].stretchGateOpen)
    #expect(opened.players[0].cumulativeRuns == 6)
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

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func baseballLifecycleCreateSubmitSnapshot() throws {
    let p1 = UUID()
    let p2 = UUID()
    let participants = [
        MatchParticipant(playerId: p1, displayNameAtMatchStart: "P1", turnOrder: 0),
        MatchParticipant(playerId: p2, displayNameAtMatchStart: "P2", turnOrder: 1)
    ]
    var session = try MatchLifecycleService.createMatch(
        type: .baseball,
        config: .baseball(MatchConfigBaseball()),
        participants: participants
    )

    session = try MatchLifecycleService.submitBaseballTurn(session: session, darts: [d(.single, 1)])
    session = try MatchLifecycleService.submitBaseballTurn(session: session, darts: [d(.double, 1)])

    #expect(session.runtime.eventCount == 2)
    #expect(session.runtime.baseballState?.players[0].cumulativeRuns == 1)
    #expect(session.runtime.baseballState?.players[1].cumulativeRuns == 2)
    #expect(session.runtime.currentLegIndex == 0)

    let undone = try MatchLifecycleService.undoLastTurn(session: session)
    #expect(undone.runtime.eventCount == 1)
    #expect(undone.runtime.baseballState?.players[1].cumulativeRuns == 0)
}
