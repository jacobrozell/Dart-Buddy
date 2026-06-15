import Foundation
import Testing
@testable import DartBuddy

// MARK: - Helpers

private func acVMDart(_ multiplier: DartMultiplier, _ segment: Int) -> DartInput {
    DartInput(multiplier: multiplier, segment: .oneToTwenty(segment))
}

@MainActor
private func makeAmericanCricketViewModel(
    participantCount: Int = 2,
    pointsEnabled: Bool = true,
    preTurns: [[DartInput]] = []
) throws -> (vm: AmericanCricketMatchViewModel, store: ActiveMatchStore) {
    let ids = (0 ..< participantCount).map { _ in UUID() }
    let participants = ids.enumerated().map { index, id in
        MatchParticipant(playerId: id, displayNameAtMatchStart: "P\(index + 1)", turnOrder: index)
    }
    var session = try MatchLifecycleService.createMatch(
        type: .americanCricket,
        config: .americanCricket(MatchConfigAmericanCricket(pointsEnabled: pointsEnabled)),
        participants: participants
    )
    for darts in preTurns {
        session = try MatchLifecycleService.submitAmericanCricketTurn(session: session, darts: darts)
    }
    let store = ActiveMatchStore()
    store.save(session)
    let vm = AmericanCricketMatchViewModel(
        matchId: session.runtime.matchId,
        store: store,
        logger: DefaultAppLogger(minimumLevel: .fault, sink: TestNoopLogSink()),
        matchRepository: FakeMatchRepositoryBuilder.matchViewModel(completedType: .americanCricket),
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
func americanCricketViewModelInitialActiveTarget20() async throws {
    let (vm, _) = try makeAmericanCricketViewModel()
    #expect(vm.americanCricketState?.activeTarget == .t20)
    #expect(vm.americanCricketState?.activeTargetIndex == 0)
}

@MainActor
@Test(.tags(.integration, .match, .regression))
func americanCricketViewModelCanSubmitRequiresDarts() async throws {
    let (vm, _) = try makeAmericanCricketViewModel()
    #expect(vm.canSubmit == false)
    vm.enteredDarts = [acVMDart(.single, 20)]
    #expect(vm.canSubmit == true)
}

@MainActor
@Test(.tags(.integration, .match, .critical, .regression))
func americanCricketViewModelSubmitUpdatesMarks() async throws {
    let (vm, _) = try makeAmericanCricketViewModel()
    vm.enteredDarts = [acVMDart(.triple, 20)]
    await vm.submitTurn()
    let marks = vm.americanCricketState?.players[0].marks["20"] ?? 0
    #expect(marks == 3)
    #expect(vm.enteredDarts.isEmpty)
}

@MainActor
@Test(.tags(.integration, .match, .regression))
func americanCricketViewModelBoardColumnsMatchPlayerCount() async throws {
    let (vm, _) = try makeAmericanCricketViewModel(participantCount: 3)
    #expect(vm.boardColumns.count == 3)
}

@MainActor
@Test(.tags(.integration, .match, .regression))
func americanCricketViewModelActiveBoardColumnIsCurrentPlayer() async throws {
    let (vm, _) = try makeAmericanCricketViewModel()
    let activeColumn = vm.boardColumns.first(where: \.isActive)
    #expect(activeColumn != nil)
    let activeBoardID = vm.activeBoardColumnID
    #expect(activeBoardID == activeColumn?.id)
}

@MainActor
@Test(.tags(.integration, .match, .regression))
func americanCricketViewModelBoardColumnsExposeMarks() async throws {
    let (vm, _) = try makeAmericanCricketViewModel()
    vm.enteredDarts = [acVMDart(.double, 20)]
    await vm.submitTurn()

    let column = try #require(vm.boardColumns.first)
    #expect(column.marks["20"] == 2)
}

@MainActor
@Test(.tags(.integration, .match, .regression))
func americanCricketViewModelUndoRestoresPreviousState() async throws {
    let (vm, _) = try makeAmericanCricketViewModel()
    vm.enteredDarts = [acVMDart(.double, 20)]
    await vm.submitTurn()
    let marksAfterTurn = vm.americanCricketState?.players[0].marks["20"] ?? 0
    #expect(marksAfterTurn == 2)

    await vm.undoLastTurn()
    let marksAfterUndo = vm.americanCricketState?.players[0].marks["20"] ?? 0
    #expect(marksAfterUndo == 0)
}

@MainActor
@Test(.tags(.integration, .match, .regression))
func americanCricketViewModelUndoLastDartPopsEnteredDart() async throws {
    let (vm, _) = try makeAmericanCricketViewModel()
    vm.enteredDarts = [acVMDart(.single, 20), acVMDart(.single, 20)]
    await vm.undoLastDart()
    #expect(vm.enteredDarts.count == 1)
}

@MainActor
@Test(.tags(.integration, .match, .regression))
func americanCricketViewModelBotGatedByIsCurrentPlayerBot() async throws {
    let (vm, _) = try makeAmericanCricketViewModel()
    // No bots wired — isCurrentPlayerBot should be false.
    #expect(vm.isCurrentPlayerBot == false)
    #expect(vm.canHumanInput == true)
}

@MainActor
@Test(.tags(.integration, .match, .regression))
func americanCricketViewModelRehydratesFromSnapshot() async throws {
    let ids = [UUID(), UUID()]
    var session = try MatchLifecycleService.createMatch(
        type: .americanCricket,
        config: .americanCricket(MatchConfigAmericanCricket()),
        participants: ids.enumerated().map { index, id in
            MatchParticipant(playerId: id, displayNameAtMatchStart: "P\(index + 1)", turnOrder: index)
        }
    )
    session = try MatchLifecycleService.submitAmericanCricketTurn(
        session: session,
        darts: [acVMDart(.single, 20)]
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
            eventTypeRaw: "americanCricketTurn",
            eventPayload: try CodablePayloadCoder.encode(envelope),
            createdAt: envelope.timestamp
        )
    }
    let store = ActiveMatchStore()
    let vm = AmericanCricketMatchViewModel(
        matchId: matchId,
        store: store,
        logger: DefaultAppLogger(minimumLevel: .fault, sink: TestNoopLogSink()),
        matchRepository: FakeMatchRepositoryBuilder.rehydrating(snapshot: snapshotSummary, completedType: .americanCricket),
        statsRepository: FakeStatsRepository(events: eventSummaries),
        feedbackPreferences: FeedbackPreferences()
    )

    #expect(vm.session == nil)
    await vm.onAppear()

    #expect(vm.session?.events.count == 1)
    #expect(vm.americanCricketState?.players[0].marks["20"] == 1)
    #expect(store.session(for: matchId) != nil)
}
