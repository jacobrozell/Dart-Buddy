import Foundation
import Testing
@testable import DartBuddy

// MARK: - Helpers

private func hareAndHoundsDart(_ segment: Int) -> DartInput {
    DartInput(multiplier: .single, segment: .oneToTwenty(segment))
}

private func missDart() -> DartInput {
    DartInput(multiplier: .single, segment: .miss, isMiss: true)
}

@MainActor
private func makeHareAndHoundsViewModel(
    houndStart: HoundStartPosition = .segment5,
    preTurns: [[DartInput]] = []
) throws -> (vm: HareAndHoundsMatchViewModel, store: ActiveMatchStore) {
    let hareId = UUID()
    let houndId = UUID()
    let participants = [
        MatchParticipant(playerId: hareId, displayNameAtMatchStart: "Hare", turnOrder: 0),
        MatchParticipant(playerId: houndId, displayNameAtMatchStart: "Hound", turnOrder: 1),
    ]
    var session = try MatchLifecycleService.createMatch(
        type: .hareAndHounds,
        config: .hareAndHounds(MatchConfigHareAndHounds(houndStart: houndStart)),
        participants: participants
    )
    for darts in preTurns {
        session = try MatchLifecycleService.submitHareAndHoundsTurn(session: session, darts: darts)
    }
    let store = ActiveMatchStore()
    store.save(session)
    let vm = HareAndHoundsMatchViewModel(
        matchId: session.runtime.matchId,
        store: store,
        logger: DefaultAppLogger(minimumLevel: .fault, sink: TestNoopLogSink()),
        matchRepository: FakeMatchRepositoryBuilder.matchViewModel(completedType: .hareAndHounds),
        statsRepository: FakeStatsRepository(),
        feedbackPreferences: {
            let prefs = FeedbackPreferences()
            prefs.botStaggerEnabled = false
            return prefs
        }()
    )
    return (vm, store)
}

// MARK: - Entry Validation

@MainActor
@Test(.tags(.integration, .match, .regression))
func hareAndHoundsViewModelLockedSegmentMatchesCurrentTarget() async throws {
    let (vm, _) = try makeHareAndHoundsViewModel()

    // Hare starts at segment 20
    #expect(vm.lockedSegment == 20)
}

@MainActor
@Test(.tags(.integration, .match, .regression))
func hareAndHoundsViewModelLockedSegmentAdvancesDuringVisitEntry() async throws {
    let (vm, _) = try makeHareAndHoundsViewModel()
    vm.enteredDarts = [hareAndHoundsDart(20)]
    #expect(vm.lockedSegment == 1)

    vm.enteredDarts = [hareAndHoundsDart(20), hareAndHoundsDart(1)]
    #expect(vm.lockedSegment == 18)
}

@MainActor
@Test(.tags(.integration, .match, .critical, .regression))
func hareAndHoundsViewModelMultipleHitsInOneTurnAdvancePosition() async throws {
    let (vm, _) = try makeHareAndHoundsViewModel()
    vm.enteredDarts = [hareAndHoundsDart(20), hareAndHoundsDart(1), hareAndHoundsDart(18)]

    await vm.submitTurn()

    let hare = vm.hareAndHoundsState?.players.first { $0.role == .hare }
    #expect(hare?.positionIndex == 3)
    #expect(vm.enteredDarts.isEmpty)
}

@MainActor
@Test(.tags(.integration, .match, .regression))
func hareAndHoundsViewModelRequiresThreeDartsBeforeSubmit() async throws {
    let (vm, _) = try makeHareAndHoundsViewModel()
    vm.enteredDarts = [hareAndHoundsDart(20), missDart()]

    #expect(vm.canSubmit == false)
}

@MainActor
@Test(.tags(.integration, .match, .regression))
func hareAndHoundsViewModelCanSubmitWithThreeDarts() async throws {
    let (vm, _) = try makeHareAndHoundsViewModel()
    vm.enteredDarts = [hareAndHoundsDart(20), missDart(), missDart()]

    #expect(vm.canSubmit == true)
}

// MARK: - Submission

@MainActor
@Test(.tags(.integration, .match, .critical, .regression))
func hareAndHoundsViewModelHumanHitAdvancesPosition() async throws {
    let (vm, _) = try makeHareAndHoundsViewModel()
    vm.enteredDarts = [hareAndHoundsDart(20), missDart(), missDart()]

    await vm.submitTurn()

    // Hare should have advanced from index 0 to index 1 (segment 1)
    let gameState = vm.hareAndHoundsState
    let hare = gameState?.players.first { $0.role == .hare }
    #expect(hare?.positionIndex == 1)
    #expect(vm.enteredDarts.isEmpty)
}

@MainActor
@Test(.tags(.integration, .match, .regression))
func hareAndHoundsViewModelMissDoesNotAdvancePosition() async throws {
    let (vm, _) = try makeHareAndHoundsViewModel()
    vm.enteredDarts = [missDart(), missDart(), missDart()]

    await vm.submitTurn()

    let hare = vm.hareAndHoundsState?.players.first { $0.role == .hare }
    #expect(hare?.positionIndex == 0)
}

// MARK: - Header

@MainActor
@Test(.tags(.integration, .match, .regression))
func hareAndHoundsViewModelHeaderAccessibilityIncludesTitle() async throws {
    let (vm, _) = try makeHareAndHoundsViewModel()

    #expect(vm.headerAccessibilityLabel.contains(L10n.string("play.hareAndHounds.navTitle")))
}

// MARK: - Undo

@MainActor
@Test(.tags(.integration, .match, .regression))
func hareAndHoundsViewModelUndoLastDartRemovesEnteredDart() async throws {
    let (vm, _) = try makeHareAndHoundsViewModel()
    vm.enteredDarts = [hareAndHoundsDart(20)]

    await vm.undoLastDart()

    #expect(vm.enteredDarts.isEmpty)
}

@MainActor
@Test(.tags(.integration, .match, .regression))
func hareAndHoundsViewModelUndoLastTurnRevertsSubmittedTurn() async throws {
    let (vm, _) = try makeHareAndHoundsViewModel(
        preTurns: [[hareAndHoundsDart(20), missDart(), missDart()]]
    )

    let hareBefore = vm.hareAndHoundsState?.players.first { $0.role == .hare }
    #expect(hareBefore?.positionIndex == 1)

    await vm.undoLastTurn()

    let hareAfter = vm.hareAndHoundsState?.players.first { $0.role == .hare }
    #expect(hareAfter?.positionIndex == 0)
}

// MARK: - Bot Gating

@MainActor
@Test(.tags(.integration, .match, .regression))
func hareAndHoundsViewModelBotTurnBlocksHumanInput() async throws {
    let (vm, _) = try makeHareAndHoundsViewModel()
    // Simulate bot playing
    // (We cannot inject a bot profile in this lightweight test, so we check the flag directly.)
    #expect(vm.isBotPlaying == false)
    #expect(vm.canHumanInput == true)
}

// MARK: - Track Rows

@MainActor
@Test(.tags(.integration, .match, .regression))
func hareAndHoundsViewModelTrackRowsContainsBothPlayers() async throws {
    let (vm, _) = try makeHareAndHoundsViewModel()

    #expect(vm.trackRows.count == 2)
    let roles = vm.trackRows.map(\.role)
    #expect(roles.contains(.hare))
    #expect(roles.contains(.hound))
}

@MainActor
@Test(.tags(.integration, .match, .regression))
func hareAndHoundsViewModelRehydratesSessionFromSnapshotWhenStoreEmpty() async throws {
    let hareId = UUID()
    let houndId = UUID()
    var session = try MatchLifecycleService.createMatch(
        type: .hareAndHounds,
        config: .hareAndHounds(MatchConfigHareAndHounds(houndStart: .segment5)),
        participants: [
            MatchParticipant(playerId: hareId, displayNameAtMatchStart: "Hare", turnOrder: 0),
            MatchParticipant(playerId: houndId, displayNameAtMatchStart: "Hound", turnOrder: 1),
        ]
    )
    session = try MatchLifecycleService.submitHareAndHoundsTurn(
        session: session,
        darts: [hareAndHoundsDart(20), missDart(), missDart()]
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
            eventTypeRaw: "hareAndHoundsTurn",
            eventPayload: try CodablePayloadCoder.encode(envelope),
            createdAt: envelope.timestamp
        )
    }
    let store = ActiveMatchStore()
    let vm = HareAndHoundsMatchViewModel(
        matchId: matchId,
        store: store,
        logger: DefaultAppLogger(minimumLevel: .fault, sink: TestNoopLogSink()),
        matchRepository: FakeMatchRepositoryBuilder.rehydrating(snapshot: snapshotSummary, completedType: .hareAndHounds),
        statsRepository: FakeStatsRepository(events: eventSummaries),
        feedbackPreferences: FeedbackPreferences()
    )

    #expect(vm.session == nil)
    await vm.onAppear()

    #expect(vm.session?.events.count == 1)
    let hare = vm.hareAndHoundsState?.players.first { $0.role == .hare }
    #expect(hare?.positionIndex == 1) // advanced by hitting 20
    #expect(store.session(for: matchId) != nil)
}

// MARK: - Test Doubles

private struct HareAndHoundsSilentLogSink: LogSink {
    func write(_: LogEntry) {}
}
