import Foundation
import Testing
@testable import DartBuddy

// MARK: - Helpers

private func atcDart(_ value: Int) -> DartInput {
    DartInput(multiplier: .single, segment: .oneToTwenty(value))
}

private func atcMiss() -> DartInput {
    DartInput(multiplier: .single, segment: .miss, isMiss: true)
}

@MainActor
private func makeAroundTheClockViewModel(
    participantCount: Int = 2,
    includeBullFinish: Bool = false,
    resetPolicy: AroundTheClockResetPolicy = .noReset,
    preTurns: [[DartInput]] = []
) throws -> (vm: AroundTheClockMatchViewModel, store: ActiveMatchStore) {
    let ids = (0 ..< participantCount).map { _ in UUID() }
    let participants = ids.enumerated().map { index, id in
        MatchParticipant(playerId: id, displayNameAtMatchStart: "P\(index + 1)", turnOrder: index)
    }
    var session = try MatchLifecycleService.createMatch(
        type: .aroundTheClock,
        config: .aroundTheClock(MatchConfigAroundTheClock(
            includeBullFinish: includeBullFinish,
            resetPolicy: resetPolicy
        )),
        participants: participants
    )
    for darts in preTurns {
        session = try MatchLifecycleService.submitAroundTheClockTurn(session: session, darts: darts)
    }
    let store = ActiveMatchStore()
    store.save(session)
    let vm = AroundTheClockMatchViewModel(
        matchId: session.runtime.matchId,
        store: store,
        logger: DefaultAppLogger(minimumLevel: .fault, sink: TestNoopLogSink()),
        matchRepository: FakeMatchRepositoryBuilder.matchViewModel(completedType: .aroundTheClock),
        statsRepository: FakeStatsRepository(),
        feedbackPreferences: {
            let prefs = FeedbackPreferences()
            prefs.botStaggerEnabled = false
            return prefs
        }()
    )
    return (vm, store)
}

// MARK: - Tests

@MainActor
@Test(.tags(.integration, .match, .regression))
func aroundTheClockViewModelInitialTargetIsOne() async throws {
    let (vm, _) = try makeAroundTheClockViewModel()
    #expect(vm.currentTarget == 1)
    #expect(vm.lockedSegment == 1)
}

@MainActor
@Test(.tags(.integration, .match, .regression))
func aroundTheClockViewModelLockedSegmentAdvancesDuringVisitEntry() async throws {
    let (vm, _) = try makeAroundTheClockViewModel()
    vm.enteredDarts = [atcDart(1)]
    #expect(vm.currentTarget == 2)
    #expect(vm.lockedSegment == 2)

    vm.enteredDarts = [atcDart(1), atcDart(2)]
    #expect(vm.currentTarget == 3)
    #expect(vm.lockedSegment == 3)
}

@MainActor
@Test(.tags(.integration, .match, .regression))
func aroundTheClockViewModelUndoLastDartRestoresLockedSegment() async throws {
    let (vm, _) = try makeAroundTheClockViewModel()
    vm.enteredDarts = [atcDart(1), atcDart(2)]
    #expect(vm.lockedSegment == 3)

    await vm.undoLastDart()
    #expect(vm.enteredDarts.count == 1)
    #expect(vm.currentTarget == 2)
    #expect(vm.lockedSegment == 2)

    await vm.undoLastDart()
    #expect(vm.enteredDarts.isEmpty)
    #expect(vm.currentTarget == 1)
    #expect(vm.lockedSegment == 1)
}

@MainActor
@Test(.tags(.integration, .match, .critical, .regression))
func aroundTheClockViewModelMultipleHitsInOneTurnAdvanceTarget() async throws {
    let (vm, _) = try makeAroundTheClockViewModel()
    vm.enteredDarts = [atcDart(1), atcDart(2), atcDart(3)]

    await vm.submitTurn()

    #expect(vm.state == .readyTurn || vm.state == .targetAdvancedFeedback)
    #expect(vm.aroundTheClockState?.players[0].targetIndex == 3)
    #expect(vm.enteredDarts.isEmpty)
}

@MainActor
@Test(.tags(.integration, .match, .regression))
func aroundTheClockViewModelRequiresThreeDartsBeforeSubmit() async throws {
    let (vm, _) = try makeAroundTheClockViewModel()
    vm.enteredDarts = [atcDart(1), atcMiss()]
    #expect(vm.canSubmit == false)
}

@MainActor
@Test(.tags(.integration, .match, .critical, .regression))
func aroundTheClockViewModelHitAdvancesTarget() async throws {
    let (vm, _) = try makeAroundTheClockViewModel()
    vm.enteredDarts = [atcDart(1), atcMiss(), atcMiss()]

    await vm.submitTurn()

    #expect(vm.state == .readyTurn || vm.state == .targetAdvancedFeedback)
    #expect(vm.aroundTheClockState?.players[0].targetIndex == 1)
    #expect(vm.enteredDarts.isEmpty)
}

@MainActor
@Test(.tags(.integration, .match, .regression))
func aroundTheClockViewModelHeaderTextContainsTarget() async throws {
    let (vm, _) = try makeAroundTheClockViewModel()
    #expect(vm.headerText.contains("1"))
    #expect(vm.headerAccessibilityLabel.contains(L10n.string("play.aroundTheClock.navTitle")))
}

@MainActor
@Test(.tags(.integration, .match, .regression))
func aroundTheClockViewModelProgressRowsMatchPlayerCount() async throws {
    let (vm, _) = try makeAroundTheClockViewModel(participantCount: 3)
    #expect(vm.progressRows.count == 3)
}

@MainActor
@Test(.tags(.integration, .match, .critical, .regression))
func aroundTheClockViewModelCompletionSetsMatchCompleted() async throws {
    let p1 = UUID()
    let participants = [
        MatchParticipant(playerId: p1, displayNameAtMatchStart: "P1", turnOrder: 0),
        MatchParticipant(playerId: UUID(), displayNameAtMatchStart: "P2", turnOrder: 1)
    ]
    // Pre-set player 0 to targetIndex 19 via preTurns isn't possible without cheating state,
    // so we use a fresh session and manually advance state via the engine.
    var session = try MatchLifecycleService.createMatch(
        type: .aroundTheClock,
        config: .aroundTheClock(MatchConfigAroundTheClock()),
        participants: participants
    )
    // Manually replace state with one where player 0 is on target 19 (hitting 20 wins).
    // We do this by submitting enough turns (19 hits for P1, skip P2 each time).
    // That's 19 rounds — instead just build it synthetically.
    // In real app this would take real plays; for the test we submit 19 successful p1 darts
    // with p2 missing each round.
    for i in 1 ... 19 {
        session = try MatchLifecycleService.submitAroundTheClockTurn(
            session: session,
            darts: [DartInput(multiplier: .single, segment: .oneToTwenty(i)), atcMiss(), atcMiss()]
        )
        // P2 misses
        session = try MatchLifecycleService.submitAroundTheClockTurn(
            session: session,
            darts: [atcMiss(), atcMiss(), atcMiss()]
        )
    }
    let store = ActiveMatchStore()
    store.save(session)
    let vm = AroundTheClockMatchViewModel(
        matchId: session.runtime.matchId,
        store: store,
        logger: DefaultAppLogger(minimumLevel: .fault, sink: TestNoopLogSink()),
        matchRepository: FakeMatchRepositoryBuilder.matchViewModel(completedType: .aroundTheClock),
        statsRepository: FakeStatsRepository(),
        feedbackPreferences: {
            let prefs = FeedbackPreferences()
            prefs.botStaggerEnabled = false
            return prefs
        }()
    )

    vm.enteredDarts = [DartInput(multiplier: .single, segment: .oneToTwenty(20)), atcMiss(), atcMiss()]
    await vm.submitTurn()

    #expect(vm.state == .matchCompleted)
    #expect(vm.aroundTheClockState?.isComplete == true)
    #expect(store.completedSessions().count == 1)
}

@MainActor
@Test(.tags(.integration, .match, .regression))
func aroundTheClockViewModelRehydratesSessionFromSnapshotWhenStoreEmpty() async throws {
    let ids = [UUID(), UUID()]
    var session = try MatchLifecycleService.createMatch(
        type: .aroundTheClock,
        config: .aroundTheClock(MatchConfigAroundTheClock()),
        participants: ids.enumerated().map { index, id in
            MatchParticipant(playerId: id, displayNameAtMatchStart: "P\(index + 1)", turnOrder: index)
        }
    )
    session = try MatchLifecycleService.submitAroundTheClockTurn(
        session: session,
        darts: [atcDart(1), atcMiss(), atcMiss()]
    )
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
            eventTypeRaw: "aroundTheClockTurn",
            eventPayload: try CodablePayloadCoder.encode(envelope),
            createdAt: envelope.timestamp
        )
    }
    let store = ActiveMatchStore()
    let vm = AroundTheClockMatchViewModel(
        matchId: matchId,
        store: store,
        logger: DefaultAppLogger(minimumLevel: .fault, sink: TestNoopLogSink()),
        matchRepository: FakeMatchRepositoryBuilder.rehydrating(snapshot: snapshotSummary, completedType: .aroundTheClock),
        statsRepository: FakeStatsRepository(events: eventSummaries),
        feedbackPreferences: FeedbackPreferences()
    )

    #expect(vm.session == nil)
    await vm.onAppear()

    #expect(vm.session?.events.count == 1)
    #expect(store.session(for: matchId) != nil)
}
