import Foundation
import Testing
@testable import DartBuddy

private func d(_ multiplier: DartMultiplier, _ segment: Int) -> DartInput {
    DartInput(multiplier: multiplier, segment: .oneToTwenty(segment))
}

@Test(.tags(.unit, .match, .baseball, .critical, .offline, .regression))
func baseballLifecycleCreateSubmitSnapshotAndUndo() throws {
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

    let undone = try MatchLifecycleService.undoLastTurn(session: session)
    #expect(undone.runtime.eventCount == 1)
    #expect(undone.runtime.baseballState?.players[1].cumulativeRuns == 0)
}

@Test(.tags(.unit, .match, .baseball, .critical, .offline, .regression))
func baseballLifecycleReplayMatchesSubmittedTurns() throws {
    let players = [UUID(), UUID()]
    var session = try MatchLifecycleService.createMatch(
        type: .baseball,
        config: .baseball(MatchConfigBaseball(inningCount: 1)),
        participants: [
            MatchParticipant(playerId: players[0], displayNameAtMatchStart: "A", turnOrder: 0),
            MatchParticipant(playerId: players[1], displayNameAtMatchStart: "B", turnOrder: 1)
        ]
    )
    session = try MatchLifecycleService.submitBaseballTurn(session: session, darts: [d(.single, 1)])
    session = try MatchLifecycleService.submitBaseballTurn(session: session, darts: [d(.double, 1)])

    let events = session.events.compactMap { envelope -> BaseballTurnEvent? in
        if case let .baseballTurn(turn) = envelope.payload { return turn }
        return nil
    }
    let replayed = try BaseballEngine.replay(
        config: MatchConfigBaseball(inningCount: 1),
        playerIds: players,
        events: events
    )

    #expect(replayed.players[0].cumulativeRuns == 1)
    #expect(replayed.players[1].cumulativeRuns == 2)
    #expect(replayed.isComplete)
}

@Test(.tags(.unit, .match, .baseball, .critical, .offline, .regression))
func baseballLifecycleUndoAcrossInningBoundary() throws {
    let players = [UUID(), UUID()]
    var session = try MatchLifecycleService.createMatch(
        type: .baseball,
        config: .baseball(MatchConfigBaseball(inningCount: 2)),
        participants: [
            MatchParticipant(playerId: players[0], displayNameAtMatchStart: "A", turnOrder: 0),
            MatchParticipant(playerId: players[1], displayNameAtMatchStart: "B", turnOrder: 1)
        ]
    )
    session = try MatchLifecycleService.submitBaseballTurn(session: session, darts: [d(.single, 1)])
    session = try MatchLifecycleService.submitBaseballTurn(session: session, darts: [d(.single, 1)])
    #expect(session.runtime.baseballState?.currentInning == 2)

    session = try MatchLifecycleService.submitBaseballTurn(session: session, darts: [d(.triple, 2)])
    let undone = try MatchLifecycleService.undoLastTurn(session: session)

    #expect(undone.runtime.baseballState?.currentInning == 2)
    #expect(undone.runtime.baseballState?.currentPlayerIndex == 0)
    #expect(undone.runtime.baseballState?.players[0].cumulativeRuns == 1)
}
