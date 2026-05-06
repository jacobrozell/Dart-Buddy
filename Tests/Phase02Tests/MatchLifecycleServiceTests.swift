import Foundation
import Testing
@testable import DartsScoreboard

@Test(.tags(.unit, .match, .critical, .regression, .offline))
func lifecycleUndoRevertsLastTurnDeterministically() throws {
    let player1 = UUID()
    let player2 = UUID()
    let participants = [
        MatchParticipant(playerId: player1, displayNameAtMatchStart: "P1", turnOrder: 0),
        MatchParticipant(playerId: player2, displayNameAtMatchStart: "P2", turnOrder: 1)
    ]
    var session = try MatchLifecycleService.createMatch(
        type: .x01,
        config: .x01(MatchConfigX01(startScore: 301, legsToWin: 1, setsEnabled: false, setsToWin: nil, checkoutMode: .singleOut)),
        participants: participants
    )

    session = try MatchLifecycleService.submitX01Turn(session: session, enteredTotal: 100, darts: nil)
    session = try MatchLifecycleService.submitX01Turn(session: session, enteredTotal: 60, darts: nil)
    let beforeUndoEventCount = session.runtime.eventCount

    let undone = try MatchLifecycleService.undoLastTurn(session: session)

    #expect(beforeUndoEventCount == 2)
    #expect(undone.runtime.eventCount == 1)
    #expect(undone.runtime.x01State?.players[0].remainingScore == 201)
    #expect(undone.runtime.x01State?.players[1].remainingScore == 301)
}

@Test(.tags(.unit, .match, .critical, .regression, .offline))
func lifecycleResumeFromSnapshotPlusTailEventsIsDeterministic() throws {
    let player1 = UUID()
    let player2 = UUID()
    let participants = [
        MatchParticipant(playerId: player1, displayNameAtMatchStart: "P1", turnOrder: 0),
        MatchParticipant(playerId: player2, displayNameAtMatchStart: "P2", turnOrder: 1)
    ]
    var session = try MatchLifecycleService.createMatch(
        type: .x01,
        config: .x01(MatchConfigX01(startScore: 301, legsToWin: 1, setsEnabled: false, setsToWin: nil, checkoutMode: .singleOut)),
        participants: participants
    )

    session = try MatchLifecycleService.submitX01Turn(session: session, enteredTotal: 60, darts: nil, timestamp: Date(timeIntervalSince1970: 10))
    session = try MatchLifecycleService.submitX01Turn(session: session, enteredTotal: 45, darts: nil, timestamp: Date(timeIntervalSince1970: 20))
    session = try MatchLifecycleService.submitX01Turn(session: session, enteredTotal: 41, darts: nil, timestamp: Date(timeIntervalSince1970: 30))
    let snapshot = session.latestSnapshot

    session = try MatchLifecycleService.submitX01Turn(session: session, enteredTotal: 26, darts: nil, timestamp: Date(timeIntervalSince1970: 40))
    session = try MatchLifecycleService.submitX01Turn(session: session, enteredTotal: 20, darts: nil, timestamp: Date(timeIntervalSince1970: 50))
    let expectedState = session.runtime.x01State

    let tailEvents = session.events.filter { $0.eventIndex >= snapshot.eventCount }
    let resumed = try MatchLifecycleService.rehydrate(snapshot: snapshot, tailEvents: tailEvents)

    #expect(resumed.runtime.x01State == expectedState)
    #expect(resumed.runtime.eventCount == session.runtime.eventCount)
}
