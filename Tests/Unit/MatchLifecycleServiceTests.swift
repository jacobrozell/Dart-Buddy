import Foundation
import Testing
@testable import DartBuddy

@Test(.tags(.unit, .match, .regression, .offline))
func lifecycleCreateMatchPreservesExplicitMatchId() throws {
    let matchId = UUID()
    let session = try MatchLifecycleService.createMatch(
        matchId: matchId,
        type: .x01,
        config: .x01(MatchConfigX01(startScore: 301, legsToWin: 1, setsEnabled: false, setsToWin: nil, checkoutMode: .singleOut)),
        participants: [
            MatchParticipant(playerId: UUID(), displayNameAtMatchStart: "Solo", turnOrder: 0)
        ]
    )
    #expect(session.runtime.matchId == matchId)
}

@Test(.tags(.unit, .match, .regression, .offline))
func lifecycleCreateMatchRejectsSingleParticipantCricket() {
    #expect(throws: (any Error).self) {
        _ = try MatchLifecycleService.createMatch(
            type: .cricket,
            config: .cricket(MatchConfigCricket()),
            participants: [
                MatchParticipant(playerId: UUID(), displayNameAtMatchStart: "Only", turnOrder: 0)
            ]
        )
    }
}

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
func lifecycleUndoLastDartReopensVisitWithRemainingDarts() throws {
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

    let darts = [
        DartInput(multiplier: .triple, segment: .oneToTwenty(20)),
        DartInput(multiplier: .triple, segment: .oneToTwenty(20)),
        DartInput(multiplier: .triple, segment: .oneToTwenty(20))
    ]
    session = try MatchLifecycleService.submitX01Turn(session: session, enteredTotal: nil, darts: darts)

    let result = try MatchLifecycleService.undoLastDart(session: session)

    #expect(session.runtime.eventCount == 1)
    #expect(result.session.runtime.eventCount == 0)
    #expect(result.restoredDarts.count == 2)
    #expect(result.restoredDarts.allSatisfy { $0.multiplier == .triple && $0.segment == .oneToTwenty(20) })
    #expect(result.session.runtime.x01State?.players[0].remainingScore == 301)
    #expect(result.session.runtime.x01State?.currentPlayerIndex == 0)
}

@Test(.tags(.unit, .match, .critical, .regression, .offline))
func lifecycleUndoLastDartRemovesSingleDartTurnEntirely() throws {
    let player1 = UUID()
    let player2 = UUID()
    let participants = [
        MatchParticipant(playerId: player1, displayNameAtMatchStart: "P1", turnOrder: 0),
        MatchParticipant(playerId: player2, displayNameAtMatchStart: "P2", turnOrder: 1)
    ]
    var session = try MatchLifecycleService.createMatch(
        type: .cricket,
        config: .cricket(MatchConfigCricket()),
        participants: participants
    )
    session = try MatchLifecycleService.submitCricketTurn(
        session: session,
        darts: [DartInput(multiplier: .triple, segment: .oneToTwenty(20))]
    )

    let result = try MatchLifecycleService.undoLastDart(session: session)

    #expect(result.session.runtime.eventCount == 0)
    #expect(result.restoredDarts.isEmpty)
    #expect(result.session.runtime.cricketState?.players[0].marks["20"] == 0)
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

@Test(.tags(.unit, .match, .regression, .offline))
func lifecycleAbandonMarksInProgressMatchAbandoned() throws {
    let participants = [
        MatchParticipant(playerId: UUID(), displayNameAtMatchStart: "P1", turnOrder: 0),
        MatchParticipant(playerId: UUID(), displayNameAtMatchStart: "P2", turnOrder: 1)
    ]
    var session = try MatchLifecycleService.createMatch(
        type: .x01,
        config: .x01(MatchConfigX01(startScore: 301, legsToWin: 1, setsEnabled: false, setsToWin: nil, checkoutMode: .singleOut)),
        participants: participants
    )
    session = try MatchLifecycleService.submitX01Turn(session: session, enteredTotal: 100, darts: nil)

    let when = Date(timeIntervalSince1970: 99)
    let abandoned = try MatchLifecycleService.abandon(session: session, timestamp: when)

    #expect(abandoned.runtime.status == .abandoned)
    #expect(abandoned.runtime.endedAt == when)
    #expect(abandoned.runtime.currentTurnPlayerId == nil)
    // Event history is preserved so the match can still be inspected.
    #expect(abandoned.runtime.eventCount == session.runtime.eventCount)
}

@Test(.tags(.unit, .match, .regression, .offline))
func lifecycleAbandonLeavesCompletedMatchUntouched() throws {
    let participants = [
        MatchParticipant(playerId: UUID(), displayNameAtMatchStart: "P1", turnOrder: 0),
        MatchParticipant(playerId: UUID(), displayNameAtMatchStart: "P2", turnOrder: 1)
    ]
    var session = try MatchLifecycleService.createMatch(
        type: .x01,
        config: .x01(MatchConfigX01(startScore: 301, legsToWin: 1, setsEnabled: false, setsToWin: nil, checkoutMode: .singleOut)),
        participants: participants
    )
    session = try MatchLifecycleService.submitX01Turn(session: session, enteredTotal: 180, darts: nil)
    session = try MatchLifecycleService.submitX01Turn(session: session, enteredTotal: 0, darts: nil)
    session = try MatchLifecycleService.submitX01Turn(session: session, enteredTotal: 121, darts: nil)
    #expect(session.runtime.status == .completed)

    let unchanged = try MatchLifecycleService.abandon(session: session)

    #expect(unchanged.runtime.status == .completed)
    #expect(unchanged.runtime.winnerPlayerId == session.runtime.winnerPlayerId)
}

@Test(.tags(.unit, .match, .cricket, .critical, .regression, .offline))
func lifecycleResumePreservesCricketInnerBull() throws {
    // Regression: resuming a cricket match from a snapshot + tail events must
    // replay an inner bull (2 marks) faithfully rather than collapsing it to
    // an outer bull (1 mark), which previously changed marks after resume.
    let player1 = UUID()
    let player2 = UUID()
    let participants = [
        MatchParticipant(playerId: player1, displayNameAtMatchStart: "P1", turnOrder: 0),
        MatchParticipant(playerId: player2, displayNameAtMatchStart: "P2", turnOrder: 1)
    ]
    func d(_ value: Int) -> DartInput { DartInput(multiplier: .single, segment: .oneToTwenty(value)) }
    let inner = DartInput(multiplier: .single, segment: .innerBull)

    var session = try MatchLifecycleService.createMatch(
        type: .cricket,
        config: .cricket(MatchConfigCricket()),
        participants: participants
    )
    // Three turns to force a snapshot at eventCount == 3.
    session = try MatchLifecycleService.submitCricketTurn(session: session, darts: [d(20)], timestamp: Date(timeIntervalSince1970: 10))
    session = try MatchLifecycleService.submitCricketTurn(session: session, darts: [d(20)], timestamp: Date(timeIntervalSince1970: 20))
    session = try MatchLifecycleService.submitCricketTurn(session: session, darts: [d(19)], timestamp: Date(timeIntervalSince1970: 30))
    let snapshot = session.latestSnapshot

    // Tail turns (after the snapshot) include the inner-bull close.
    session = try MatchLifecycleService.submitCricketTurn(session: session, darts: [d(19)], timestamp: Date(timeIntervalSince1970: 40))
    session = try MatchLifecycleService.submitCricketTurn(session: session, darts: [inner, inner], timestamp: Date(timeIntervalSince1970: 50))
    let expectedState = session.runtime.cricketState
    #expect(expectedState?.players[0].marks["bull"] == 3)

    let tailEvents = session.events.filter { $0.eventIndex >= snapshot.eventCount }
    let resumed = try MatchLifecycleService.rehydrate(snapshot: snapshot, tailEvents: tailEvents)

    #expect(resumed.runtime.cricketState == expectedState)
    #expect(resumed.runtime.cricketState?.players[0].marks["bull"] == 3)
}

@Test(.tags(.unit, .match, .cricket, .critical, .regression, .offline))
func lifecycleResumeThreePlayerCricketMidBoard() throws {
    let participants = cricketParticipants(count: 3, names: ["P1", "P2", "P3"])
    var session = try MatchLifecycleService.createMatch(
        type: .cricket,
        config: .cricket(MatchConfigCricket()),
        participants: participants
    )

    session = try MatchLifecycleService.submitCricketTurn(session: session, darts: [CricketTestDarts.triple(20)], timestamp: Date(timeIntervalSince1970: 10))
    session = try MatchLifecycleService.submitCricketTurn(session: session, darts: [CricketTestDarts.single(20)], timestamp: Date(timeIntervalSince1970: 20))
    session = try MatchLifecycleService.submitCricketTurn(session: session, darts: [CricketTestDarts.single(19)], timestamp: Date(timeIntervalSince1970: 30))
    let snapshot = session.latestSnapshot

    session = try MatchLifecycleService.submitCricketTurn(session: session, darts: [CricketTestDarts.triple(19)], timestamp: Date(timeIntervalSince1970: 40))
    session = try MatchLifecycleService.submitCricketTurn(session: session, darts: [CricketTestDarts.miss()], timestamp: Date(timeIntervalSince1970: 50))
    session = try MatchLifecycleService.submitCricketTurn(session: session, darts: [CricketTestDarts.single(18)], timestamp: Date(timeIntervalSince1970: 60))
    let expectedState = session.runtime.cricketState
    #expect(expectedState?.currentPlayerIndex == 0)
    #expect(expectedState?.players[0].marks["20"] == 3)
    #expect(expectedState?.players[1].marks["20"] == 1)

    let tailEvents = session.events.filter { $0.eventIndex >= snapshot.eventCount }
    let resumed = try MatchLifecycleService.rehydrate(snapshot: snapshot, tailEvents: tailEvents)

    #expect(resumed.runtime.cricketState == expectedState)
    #expect(resumed.runtime.cricketState?.currentPlayerIndex == 0)
}

@Test(.tags(.unit, .match, .critical, .regression, .offline))
func lifecycleForfeitMarksInProgressMatchForfeited() throws {
    let player1 = UUID()
    let player2 = UUID()
    var session = try MatchLifecycleService.createMatch(
        type: .x01,
        config: .x01(MatchConfigX01(startScore: 301, legsToWin: 1, setsEnabled: false, setsToWin: nil, checkoutMode: .singleOut)),
        participants: [
            MatchParticipant(playerId: player1, displayNameAtMatchStart: "P1", turnOrder: 0),
            MatchParticipant(playerId: player2, displayNameAtMatchStart: "P2", turnOrder: 1)
        ]
    )
    session = try MatchLifecycleService.submitX01Turn(session: session, enteredTotal: 60, darts: nil)
    let when = Date(timeIntervalSince1970: 200)
    let forfeited = try MatchLifecycleService.forfeit(
        session: session,
        forfeitingPlayerId: player1,
        winnerPlayerId: player2,
        timestamp: when
    )
    #expect(forfeited.runtime.status == .forfeited)
    #expect(forfeited.runtime.endedAt == when)
    #expect(forfeited.runtime.winnerPlayerId == player2)
    #expect(forfeited.runtime.forfeitedByPlayerId == player1)
    #expect(forfeited.runtime.eventCount == 1)
}

@Test(.tags(.unit, .match, .regression, .offline))
func lifecycleForfeitRequiresAtLeastOneEvent() throws {
    let player1 = UUID()
    let player2 = UUID()
    let session = try MatchLifecycleService.createMatch(
        type: .x01,
        config: .x01(MatchConfigX01(startScore: 301, legsToWin: 1, setsEnabled: false, setsToWin: nil, checkoutMode: .singleOut)),
        participants: [
            MatchParticipant(playerId: player1, displayNameAtMatchStart: "P1", turnOrder: 0),
            MatchParticipant(playerId: player2, displayNameAtMatchStart: "P2", turnOrder: 1)
        ]
    )
    #expect(throws: (any Error).self) {
        _ = try MatchLifecycleService.forfeit(session: session, forfeitingPlayerId: player1, winnerPlayerId: player2)
    }
}

@Test(.tags(.unit, .match, .regression, .offline))
func lifecycleForfeitSoloX01AllowsNilWinner() throws {
    let solo = UUID()
    var session = try MatchLifecycleService.createMatch(
        type: .x01,
        config: .x01(MatchConfigX01(startScore: 301, legsToWin: 1, setsEnabled: false, setsToWin: nil, checkoutMode: .singleOut)),
        participants: [MatchParticipant(playerId: solo, displayNameAtMatchStart: "Solo", turnOrder: 0)]
    )
    session = try MatchLifecycleService.submitX01Turn(session: session, enteredTotal: 60, darts: nil)
    let forfeited = try MatchLifecycleService.forfeit(session: session, forfeitingPlayerId: solo, winnerPlayerId: nil)
    #expect(forfeited.runtime.status == .forfeited)
    #expect(forfeited.runtime.winnerPlayerId == nil)
}
