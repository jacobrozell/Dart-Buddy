import Foundation
import Testing
@testable import DartBuddy

// MARK: - Helpers

private func nlHit(_ segment: Int) -> DartInput {
    DartInput(multiplier: .single, segment: .oneToTwenty(segment))
}

private func nlMiss() -> DartInput {
    DartInput(multiplier: .single, segment: .miss, isMiss: true)
}

@MainActor
private func makeNineLivesViewModel(
    participantCount: Int = 2,
    startingLives: NineLivesStartingLives = .nine,
    preTurns: [[DartInput]] = []
) throws -> (vm: NineLivesMatchViewModel, store: ActiveMatchStore) {
    let ids = (0 ..< participantCount).map { _ in UUID() }
    let participants = ids.enumerated().map { index, id in
        MatchParticipant(playerId: id, displayNameAtMatchStart: "P\(index + 1)", turnOrder: index)
    }
    var session = try MatchLifecycleService.createMatch(
        type: .nineLives,
        config: .nineLives(MatchConfigNineLives(startingLives: startingLives)),
        participants: participants
    )
    for darts in preTurns {
        session = try MatchLifecycleService.submitNineLivesTurn(session: session, darts: darts)
    }
    let store = ActiveMatchStore()
    store.save(session)
    let vm = NineLivesMatchViewModel(
        matchId: session.runtime.matchId,
        store: store,
        logger: DefaultAppLogger(minimumLevel: .fault, sink: TestNoopLogSink()),
        matchRepository: FakeMatchRepositoryBuilder.matchViewModel(completedType: .nineLives),
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
func nineLivesViewModelInitialTargetIsOne() async throws {
    let (vm, _) = try makeNineLivesViewModel()
    #expect(vm.lockedSegment == 1)
    #expect(vm.nineLivesState?.players[0].currentTarget == 1)
}

@MainActor
@Test(.tags(.integration, .match, .regression))
func nineLivesViewModelLockedSegmentAdvancesDuringVisitEntry() async throws {
    let (vm, _) = try makeNineLivesViewModel()
    vm.enteredDarts = [nlHit(1)]
    #expect(vm.lockedSegment == 2)

    vm.enteredDarts = [nlHit(1), nlHit(2)]
    #expect(vm.lockedSegment == 3)
}

@MainActor
@Test(.tags(.integration, .match, .critical, .regression))
func nineLivesViewModelMultipleHitsInOneTurnAdvanceTarget() async throws {
    let (vm, _) = try makeNineLivesViewModel()
    vm.enteredDarts = [nlHit(1), nlHit(2), nlHit(3)]

    await vm.submitTurn()

    #expect(vm.state == .readyTurn)
    #expect(vm.nineLivesState?.players[0].targetIndex == 3)
    #expect(vm.enteredDarts.isEmpty)
}

@MainActor
@Test(.tags(.integration, .match, .regression))
func nineLivesViewModelRequiresThreeDartsBeforeSubmit() async throws {
    let (vm, _) = try makeNineLivesViewModel()
    vm.enteredDarts = [nlHit(1), nlMiss()]
    #expect(vm.canSubmit == false)
}

@MainActor
@Test(.tags(.integration, .match, .critical, .regression))
func nineLivesViewModelHitAdvancesTarget() async throws {
    let (vm, _) = try makeNineLivesViewModel()
    vm.enteredDarts = [nlHit(1), nlMiss(), nlMiss()]

    await vm.submitTurn()

    #expect(vm.state == .readyTurn)
    #expect(vm.nineLivesState?.players[0].targetIndex == 1)
    #expect(vm.enteredDarts.isEmpty)
}

@MainActor
@Test(.tags(.integration, .match, .critical, .regression))
func nineLivesViewModelMissLosesLife() async throws {
    let (vm, _) = try makeNineLivesViewModel()
    vm.enteredDarts = [nlMiss(), nlMiss(), nlMiss()]

    await vm.submitTurn()

    #expect(vm.state == .readyTurn)
    #expect(vm.nineLivesState?.players[0].lives == 8)
    #expect(vm.enteredDarts.isEmpty)
}

@MainActor
@Test(.tags(.integration, .match, .regression))
func nineLivesViewModelHeaderTextContainsTarget() async throws {
    let (vm, _) = try makeNineLivesViewModel()
    #expect(vm.headerText.contains("1"))
    #expect(vm.headerAccessibilityLabel.contains(L10n.string("play.nineLives.navTitle")))
}

@MainActor
@Test(.tags(.integration, .match, .regression))
func nineLivesViewModelScoreboardRowsMatchPlayerCount() async throws {
    let (vm, _) = try makeNineLivesViewModel(participantCount: 3)
    #expect(vm.scoreboardRows.count == 3)
}

@MainActor
@Test(.tags(.integration, .match, .regression))
func nineLivesViewModelScoreboardShowsStartingLives() async throws {
    let (vm, _) = try makeNineLivesViewModel(startingLives: .three)
    let firstRow = try #require(vm.scoreboardRows.first)
    #expect(firstRow.lives == 3)
    #expect(firstRow.startingLives == 3)
}

@MainActor
@Test(.tags(.integration, .match, .critical, .regression))
func nineLivesViewModelEliminationCompletesMatch() async throws {
    // 2 players, 3 lives each; p2 loses all lives → p1 wins
    let (vm, store) = try makeNineLivesViewModel(startingLives: .three)

    // Round 1: p1 hits, p2 misses
    vm.enteredDarts = [nlHit(1), nlMiss(), nlMiss()]
    await vm.submitTurn()
    vm.enteredDarts = [nlMiss(), nlMiss(), nlMiss()]
    await vm.submitTurn()

    // Round 2: p1 hits, p2 misses
    vm.enteredDarts = [nlHit(2), nlMiss(), nlMiss()]
    await vm.submitTurn()
    vm.enteredDarts = [nlMiss(), nlMiss(), nlMiss()]
    await vm.submitTurn()

    // Round 3: p1 hits, p2 misses → p2 eliminated → match complete
    vm.enteredDarts = [nlHit(3), nlMiss(), nlMiss()]
    await vm.submitTurn()
    vm.enteredDarts = [nlMiss(), nlMiss(), nlMiss()]
    await vm.submitTurn()

    #expect(vm.state == .matchCompleted)
    #expect(vm.nineLivesState?.isComplete == true)
    #expect(store.completedSessions().count == 1)
}

@MainActor
@Test(.tags(.integration, .match, .regression))
func nineLivesViewModelRehydratesSessionFromSnapshotWhenStoreEmpty() async throws {
    let ids = [UUID(), UUID()]
    var session = try MatchLifecycleService.createMatch(
        type: .nineLives,
        config: .nineLives(MatchConfigNineLives()),
        participants: ids.enumerated().map { index, id in
            MatchParticipant(playerId: id, displayNameAtMatchStart: "P\(index + 1)", turnOrder: index)
        }
    )
    session = try MatchLifecycleService.submitNineLivesTurn(
        session: session,
        darts: [nlHit(1), nlMiss(), nlMiss()]
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
            eventTypeRaw: "nineLivesTurn",
            eventPayload: try CodablePayloadCoder.encode(envelope),
            createdAt: envelope.timestamp
        )
    }
    let store = ActiveMatchStore()
    let vm = NineLivesMatchViewModel(
        matchId: matchId,
        store: store,
        logger: DefaultAppLogger(minimumLevel: .fault, sink: TestNoopLogSink()),
        matchRepository: FakeMatchRepositoryBuilder.rehydrating(snapshot: snapshotSummary, completedType: .nineLives),
        statsRepository: FakeStatsRepository(events: eventSummaries),
        feedbackPreferences: FeedbackPreferences()
    )

    #expect(vm.session == nil)
    await vm.onAppear()

    #expect(vm.session?.events.count == 1)
    #expect(store.session(for: matchId) != nil)
}
