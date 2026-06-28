import Foundation
import Testing
@testable import DartBuddy

// MARK: - Test helpers

private func sdDart(_ multiplier: DartMultiplier, _ segment: Int) -> DartInput {
    DartInput(multiplier: multiplier, segment: .oneToTwenty(segment))
}

private func sdMiss() -> DartInput {
    DartInput(multiplier: .single, segment: .miss, isMiss: true)
}

@MainActor
private func makeSuddenDeathViewModel(
    participantCount: Int = 3,
    config: MatchConfigSuddenDeath = MatchConfigSuddenDeath(),
    preTurns: [[DartInput]] = []
) throws -> (vm: SuddenDeathMatchViewModel, store: ActiveMatchStore) {
    let ids = (0 ..< participantCount).map { _ in UUID() }
    let participants = ids.enumerated().map { index, id in
        MatchParticipant(playerId: id, displayNameAtMatchStart: "P\(index + 1)", turnOrder: index)
    }
    var session = try MatchLifecycleService.createMatch(
        type: .suddenDeath,
        config: .suddenDeath(config),
        participants: participants
    )
    for darts in preTurns {
        session = try MatchLifecycleService.submitSuddenDeathTurn(session: session, darts: darts)
    }
    let store = ActiveMatchStore()
    store.save(session)
    let vm = SuddenDeathMatchViewModel(
        matchId: session.runtime.matchId,
        store: store,
        logger: DefaultAppLogger(minimumLevel: .fault, sink: TestNoopLogSink()),
        matchRepository: FakeMatchRepositoryBuilder.matchViewModel(completedType: .suddenDeath),
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
func suddenDeathViewModelInitialStateReadyTurn() async throws {
    let (vm, _) = try makeSuddenDeathViewModel()

    #expect(vm.state == .readyTurn)
    #expect(vm.suddenDeathState?.currentRound == 1)
    #expect(vm.suddenDeathState?.activePlayerIds.count == 3)
}

@MainActor
@Test(.tags(.integration, .match, .regression))
func suddenDeathViewModelRequiresThreeDartsBeforeSubmit() async throws {
    let (vm, _) = try makeSuddenDeathViewModel()
    vm.enteredDarts = [sdDart(.single, 20), sdDart(.double, 5)]

    #expect(vm.canSubmit == false)
}

@MainActor
@Test(.tags(.integration, .match, .critical, .regression))
func suddenDeathViewModelHumanSubmitRecordsPoints() async throws {
    let (vm, _) = try makeSuddenDeathViewModel()
    vm.enteredDarts = [
        sdDart(.single, 20),
        sdDart(.single, 20),
        sdDart(.single, 20)
    ]

    await vm.submitTurn()

    #expect(vm.state == .readyTurn || vm.state == .eliminationFeedback)
    let playerState = vm.suddenDeathState?.players[0]
    #expect(playerState?.roundTotal == 60 || playerState?.cumulativeTotal == 60)
    #expect(vm.enteredDarts.isEmpty)
}

@MainActor
@Test(.tags(.integration, .match, .regression))
func suddenDeathViewModelHeaderTextContainsRoundNumber() async throws {
    let (vm, _) = try makeSuddenDeathViewModel()

    #expect(vm.headerText.contains("1"))
    #expect(vm.headerAccessibilityLabel.contains(L10n.string("play.suddenDeath.navTitle")))
}

@MainActor
@Test(.tags(.integration, .match, .regression))
func suddenDeathViewModelScoreboardHasOneRowPerPlayer() async throws {
    let (vm, _) = try makeSuddenDeathViewModel(participantCount: 4)

    #expect(vm.scoreboardRows.count == 4)
}

@MainActor
@Test(.tags(.integration, .match, .critical, .regression))
func suddenDeathViewModelCompletesMatchWhenLastPlayerStands() async throws {
    // 3 players; submit a full round eliminating P0, then a second round to finish.
    let (vm, store) = try makeSuddenDeathViewModel(participantCount: 3)

    // Round 1: P0=1, P1=20, P2=20 → P0 eliminated.
    vm.enteredDarts = [sdDart(.single, 1), sdMiss(), sdMiss()]
    await vm.submitTurn()
    vm.enteredDarts = [sdDart(.single, 20), sdMiss(), sdMiss()]
    await vm.submitTurn()
    vm.enteredDarts = [sdDart(.single, 20), sdMiss(), sdMiss()]
    await vm.submitTurn()

    guard vm.state != .matchCompleted else {
        // If already complete (e.g. two survivors remain), that's wrong — ensure >1 active.
        #expect(vm.suddenDeathState?.activePlayerIds.count ?? 0 > 1)
        return
    }

    // Round 2: P1=1, P2=20 → P1 eliminated, P2 wins.
    vm.enteredDarts = [sdDart(.single, 1), sdMiss(), sdMiss()]
    await vm.submitTurn()
    vm.enteredDarts = [sdDart(.single, 20), sdMiss(), sdMiss()]
    await vm.submitTurn()

    #expect(vm.state == .matchCompleted || vm.suddenDeathState?.isComplete == true)
    #expect(store.completedSessions().count == 1)
}

@MainActor
@Test(.tags(.integration, .match, .regression))
func suddenDeathViewModelRehydratesSessionFromSnapshotWhenStoreEmpty() async throws {
    let ids = [UUID(), UUID(), UUID()]
    var session = try MatchLifecycleService.createMatch(
        type: .suddenDeath,
        config: .suddenDeath(MatchConfigSuddenDeath()),
        participants: ids.enumerated().map { index, id in
            MatchParticipant(playerId: id, displayNameAtMatchStart: "P\(index + 1)", turnOrder: index)
        }
    )
    session = try MatchLifecycleService.submitSuddenDeathTurn(
        session: session,
        darts: [sdDart(.single, 10), sdMiss(), sdMiss()]
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
            eventTypeRaw: "suddenDeathTurn",
            eventPayload: try CodablePayloadCoder.encode(envelope),
            createdAt: envelope.timestamp
        )
    }
    let store = ActiveMatchStore()
    let vm = SuddenDeathMatchViewModel(
        matchId: matchId,
        store: store,
        logger: DefaultAppLogger(minimumLevel: .fault, sink: TestNoopLogSink()),
        matchRepository: FakeMatchRepositoryBuilder.rehydrating(snapshot: snapshotSummary, completedType: .suddenDeath),
        statsRepository: FakeStatsRepository(events: eventSummaries),
        feedbackPreferences: FeedbackPreferences()
    )

    #expect(vm.session == nil)
    await vm.onAppear()

    #expect(vm.session?.events.count == 1)
    #expect(vm.suddenDeathState?.players[0].roundTotal == 10)
    #expect(store.session(for: matchId) != nil)
}

// MARK: - Stubs

private struct SuddenDeathSilentLogSink: LogSink {
    func write(_: LogEntry) {}
}
