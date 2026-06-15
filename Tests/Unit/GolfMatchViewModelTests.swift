import Foundation
import Testing
@testable import DartBuddy

private func golfDart(_ multiplier: DartMultiplier, _ segment: Int) -> DartInput {
    DartInput(multiplier: multiplier, segment: .oneToTwenty(segment))
}

private func missDart() -> DartInput {
    DartInput(multiplier: .single, segment: .miss, isMiss: true)
}

@MainActor
private func makeGolfViewModel(
    participantCount: Int = 2,
    courseLength: GolfCourseLength = .nine,
    preTurns: [(darts: [DartInput], endedEarly: Bool)] = []
) throws -> (vm: GolfMatchViewModel, store: ActiveMatchStore) {
    let ids = (0 ..< participantCount).map { _ in UUID() }
    let participants = ids.enumerated().map { index, id in
        MatchParticipant(playerId: id, displayNameAtMatchStart: "P\(index + 1)", turnOrder: index)
    }
    var session = try MatchLifecycleService.createMatch(
        type: .golf,
        config: .golf(MatchConfigGolf(courseLength: courseLength)),
        participants: participants
    )
    for turn in preTurns {
        let input = GolfTurnInput(darts: turn.darts, endedEarly: turn.endedEarly)
        session = try MatchLifecycleService.submitGolfTurn(session: session, input: input)
    }
    let store = ActiveMatchStore()
    store.save(session)
    let vm = GolfMatchViewModel(
        matchId: session.runtime.matchId,
        store: store,
        logger: DefaultAppLogger(minimumLevel: .fault, sink: TestNoopLogSink()),
        matchRepository: FakeMatchRepositoryBuilder.matchViewModel(completedType: .golf),
        statsRepository: FakeStatsRepository(),
        feedbackPreferences: {
            let prefs = FeedbackPreferences()
            prefs.botStaggerEnabled = false
            return prefs
        }()
    )
    return (vm, store)
}

// MARK: - Entry validation

@MainActor
@Test(.tags(.integration, .match, .regression))
func golfViewModelLockedSegmentMatchesCurrentHole() async throws {
    let (vm, _) = try makeGolfViewModel()

    #expect(vm.lockedSegment == 1)
    #expect(vm.golfState?.currentHole == 1)
}

@MainActor
@Test(.tags(.integration, .match, .regression))
func golfViewModelCannotSubmitWithNoDarts() async throws {
    let (vm, _) = try makeGolfViewModel()

    #expect(vm.canSubmitFull == false)
    #expect(vm.canSubmitEarly == false)
}

@MainActor
@Test(.tags(.integration, .match, .regression))
func golfViewModelCanSubmitEarlyWithOneDart() async throws {
    let (vm, _) = try makeGolfViewModel()
    vm.enteredDarts = [golfDart(.double, 1)]

    #expect(vm.canSubmitEarly == true)
    #expect(vm.canSubmitFull == false)
}

@MainActor
@Test(.tags(.integration, .match, .regression))
func golfViewModelCanSubmitFullWithThreeDarts() async throws {
    let (vm, _) = try makeGolfViewModel()
    vm.enteredDarts = [golfDart(.single, 1), golfDart(.single, 1), golfDart(.single, 1)]

    #expect(vm.canSubmitFull == true)
    #expect(vm.canSubmitEarly == false)
}

// MARK: - Submission

@MainActor
@Test(.tags(.integration, .match, .critical, .regression))
func golfViewModelHumanSubmitUpdatesStrokes() async throws {
    let (vm, _) = try makeGolfViewModel()
    vm.enteredDarts = [golfDart(.double, 1)]

    await vm.submitTurn(endedEarly: true)

    #expect(vm.state == .holeCompleteFeedback || vm.state == .readyTurn)
    #expect(vm.golfState?.players[0].strokesByHole[1] == 1)
    #expect(vm.enteredDarts.isEmpty)
}

@MainActor
@Test(.tags(.integration, .match, .critical, .regression))
func golfViewModelThreeDartSubmitRecordsLastDart() async throws {
    let (vm, _) = try makeGolfViewModel()
    // First dart hits double (1), last dart is miss (5) — last dart must win
    vm.enteredDarts = [golfDart(.double, 1), golfDart(.single, 1), missDart()]

    await vm.submitTurn(endedEarly: false)

    #expect(vm.golfState?.players[0].strokesByHole[1] == 5)
}

// MARK: - Header text

@MainActor
@Test(.tags(.integration, .match, .regression))
func golfViewModelHeaderTextIncludesHoleAndCourse() async throws {
    let (vm, _) = try makeGolfViewModel(courseLength: .nine)

    #expect(vm.headerText.contains("1"))
    #expect(vm.headerText.contains("9"))
}

// MARK: - Scorecard rows

@MainActor
@Test(.tags(.integration, .match, .regression))
func golfViewModelScorecardRowsMatchParticipantCount() async throws {
    let (vm, _) = try makeGolfViewModel(participantCount: 3)

    #expect(vm.scorecardRows.count == 3)
}

@MainActor
@Test(.tags(.integration, .match, .regression))
func golfViewModelScorecardRowActivePlayerIsMarked() async throws {
    let (vm, _) = try makeGolfViewModel()

    let activeRows = vm.scorecardRows.filter(\.isActive)
    #expect(activeRows.count == 1)
}

@MainActor
@Test(.tags(.integration, .match, .regression))
func golfViewModelHoleCompleteFeedbackUsesRecordedStrokesNotNextHole() async throws {
    let (vm, _) = try makeGolfViewModel()
    // Player 1 completes hole 1 with a double (1 stroke).
    vm.enteredDarts = [golfDart(.double, 1)]
    await vm.submitTurn(endedEarly: true)

    // Player 2 is up on hole 1; after they finish, the course advances to hole 2.
    vm.enteredDarts = [golfDart(.triple, 1)]
    await vm.submitTurn(endedEarly: true)

    #expect(vm.golfState?.currentHole == 2)
    #expect(vm.holeCompleteFeedback == nil)
    #expect(vm.golfState?.players[1].strokesByHole[1] == 2)
}

@MainActor
@Test(.tags(.integration, .match, .regression))
func golfViewModelCurrentStrokePreviewUsesLockedHoleSegment() async throws {
    let (vm, _) = try makeGolfViewModel(
        preTurns: [(darts: [golfDart(.double, 1)], endedEarly: true)]
    )
    vm.enteredDarts = [golfDart(.triple, 1)]

    #expect(vm.lockedSegment == 1)
    #expect(vm.currentStrokePreview == 2)
}

@MainActor
@Test(.tags(.integration, .match, .regression))
func golfViewModelScorecardRowIncludesHoleStrokes() async throws {
    let (vm, _) = try makeGolfViewModel()
    vm.enteredDarts = [golfDart(.double, 1)]
    await vm.submitTurn(endedEarly: true)

    let row = try #require(vm.scorecardRows.first)
    #expect(row.holeStrokes[0] == 1)
    #expect(row.runningTotal == 1)
}

// MARK: - Match completion

@MainActor
@Test(.tags(.integration, .match, .critical, .regression))
func golfViewModelMatchCompletesAfterAllHoles() async throws {
    let (vm, store) = try makeGolfViewModel(courseLength: .nine)

    // Simulate all 9 holes for both players by pre-populating turns then one more via VM
    // Pre-load 8 holes (16 turns), then final two turns via VM
    var preTurns: [(darts: [DartInput], endedEarly: Bool)] = []
    for hole in 1 ... 8 {
        preTurns.append((darts: [golfDart(.double, hole)], endedEarly: false))
        preTurns.append((darts: [missDart()], endedEarly: false))
    }
    let (vm2, store2) = try makeGolfViewModel(courseLength: .nine, preTurns: preTurns)

    // Hole 9 — p1
    vm2.enteredDarts = [golfDart(.double, 9)]
    await vm2.submitTurn(endedEarly: true)

    // Hole 9 — p2
    vm2.enteredDarts = [missDart()]
    await vm2.submitTurn(endedEarly: false)

    _ = store2  // suppress unused warning
    _ = vm      // suppress unused warning
    _ = store   // suppress unused warning

    #expect(vm2.state == .matchCompleted || vm2.golfState?.isComplete == true)
}

// MARK: - Rehydration from snapshot

@MainActor
@Test(.tags(.integration, .match, .regression))
func golfViewModelRehydratesSessionFromSnapshotWhenStoreEmpty() async throws {
    let ids = [UUID(), UUID()]
    var session = try MatchLifecycleService.createMatch(
        type: .golf,
        config: .golf(MatchConfigGolf(courseLength: .nine)),
        participants: ids.enumerated().map { index, id in
            MatchParticipant(playerId: id, displayNameAtMatchStart: "P\(index + 1)", turnOrder: index)
        }
    )
    let input = GolfTurnInput(darts: [golfDart(.double, 1)], endedEarly: true)
    session = try MatchLifecycleService.submitGolfTurn(session: session, input: input)
    let matchId = session.runtime.matchId
    let snapshot = session.latestSnapshot
    let snapshotSummary = MatchSnapshotSummary(
        id: UUID(),
        matchId: matchId,
        snapshotVersion: snapshot.payloadVersion,
        snapshotPayload: snapshot.payload,
        updatedAt: Date()
    )
    let eventSummaries = try session.events.map { envelope in
        MatchEventSummary(
            id: UUID(),
            matchId: matchId,
            eventIndex: envelope.eventIndex,
            eventTypeRaw: "golfTurn",
            eventPayload: try CodablePayloadCoder.encode(envelope),
            createdAt: envelope.timestamp
        )
    }
    let store = ActiveMatchStore()
    let vm = GolfMatchViewModel(
        matchId: matchId,
        store: store,
        logger: DefaultAppLogger(minimumLevel: .fault, sink: TestNoopLogSink()),
        matchRepository: FakeMatchRepositoryBuilder.rehydrating(snapshot: snapshotSummary, completedType: .golf),
        statsRepository: FakeStatsRepository(events: eventSummaries),
        feedbackPreferences: FeedbackPreferences()
    )

    #expect(vm.session == nil)
    await vm.onAppear()

    #expect(vm.session?.events.count == 1)
    #expect(vm.golfState?.players[0].strokesByHole[1] == 1)
    #expect(store.session(for: matchId) != nil)
}

// MARK: - Undo last dart

@MainActor
@Test(.tags(.integration, .match, .regression))
func golfViewModelUndoLastDartRemovesFromEnteredDarts() async throws {
    let (vm, _) = try makeGolfViewModel()
    vm.enteredDarts = [golfDart(.double, 1), golfDart(.single, 1)]

    await vm.undoLastDart()

    #expect(vm.enteredDarts.count == 1)
}
