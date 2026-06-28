import Foundation
import Testing
@testable import DartBuddy

// MARK: - Helpers

private func gnHit(_ segment: Int) -> DartInput {
    DartInput(multiplier: .single, segment: .oneToTwenty(segment))
}

private func gnMiss() -> DartInput {
    DartInput(multiplier: .single, segment: .miss, isMiss: true)
}

@MainActor
private func makeGrandNationalViewModel(
    participantCount: Int = 2,
    laps: Int = 2,
    preTurns: [[DartInput]] = []
) throws -> (vm: GrandNationalMatchViewModel, store: ActiveMatchStore) {
    let ids = (0 ..< participantCount).map { _ in UUID() }
    let participants = ids.enumerated().map { index, id in
        MatchParticipant(playerId: id, displayNameAtMatchStart: "P\(index + 1)", turnOrder: index)
    }
    var session = try MatchLifecycleService.createMatch(
        type: .grandNational,
        config: .grandNational(MatchConfigGrandNational(laps: laps)),
        participants: participants
    )
    for darts in preTurns {
        session = try MatchLifecycleService.submitGrandNationalTurn(session: session, darts: darts)
    }
    let store = ActiveMatchStore()
    store.save(session)
    let vm = GrandNationalMatchViewModel(
        matchId: session.runtime.matchId,
        store: store,
        logger: DefaultAppLogger(minimumLevel: .fault, sink: TestNoopLogSink()),
        matchRepository: FakeMatchRepositoryBuilder.matchViewModel(completedType: .grandNational),
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
func grandNationalViewModelLockedSegmentIsFirstHurdle() async throws {
    let (vm, _) = try makeGrandNationalViewModel()
    // First hurdle in the anticlockwise course is 20.
    #expect(vm.lockedSegment == 20)
    #expect(vm.currentHurdle == 20)
}

@MainActor
@Test(.tags(.integration, .match, .regression))
func grandNationalViewModelRequiresThreeDartsBeforeSubmit() async throws {
    let (vm, _) = try makeGrandNationalViewModel()
    vm.enteredDarts = [gnHit(20), gnMiss()]
    #expect(vm.canSubmit == false)
}

@MainActor
@Test(.tags(.integration, .match, .critical, .regression))
func grandNationalViewModelHitHurdleAdvancesPosition() async throws {
    let (vm, _) = try makeGrandNationalViewModel()
    vm.enteredDarts = [gnHit(20), gnMiss(), gnMiss()]

    await vm.submitTurn()

    #expect(vm.state == .readyTurn || vm.state == .hurdleClearedFeedback)
    #expect(vm.grandNationalState?.players[0].segmentIndex == 1)
    #expect(vm.enteredDarts.isEmpty)
}

@MainActor
@Test(.tags(.integration, .match, .critical, .regression))
func grandNationalViewModelMissAllEliminatesPlayer() async throws {
    let (vm, _) = try makeGrandNationalViewModel()
    // Throw three darts that don't hit hurdle 20.
    vm.enteredDarts = [gnHit(5), gnMiss(), gnMiss()]

    await vm.submitTurn()

    #expect(vm.grandNationalState?.players[0].isEliminated == true)
}

@MainActor
@Test(.tags(.integration, .match, .regression))
func grandNationalViewModelHeaderAccessibilityContainsTitle() async throws {
    let (vm, _) = try makeGrandNationalViewModel()
    #expect(vm.headerAccessibilityLabel.contains(L10n.string("play.grandNational.navTitle")))
}

@MainActor
@Test(.tags(.integration, .match, .regression))
func grandNationalViewModelCourseRowsMatchPlayerCount() async throws {
    let (vm, _) = try makeGrandNationalViewModel(participantCount: 4)
    #expect(vm.courseRows.count == 4)
}

@MainActor
@Test(.tags(.integration, .match, .regression))
func grandNationalViewModelCourseRowsMarkActivePlayer() async throws {
    let (vm, _) = try makeGrandNationalViewModel()

    #expect(vm.courseRows.count == 2)
    #expect(vm.courseRows.filter { $0.isActive }.count == 1)
    #expect(vm.courseRows.allSatisfy { !$0.isEliminated })
}

@MainActor
@Test(.tags(.integration, .match, .critical, .regression))
func grandNationalViewModelLastSurvivorCompletesMatch() async throws {
    let (vm, store) = try makeGrandNationalViewModel(participantCount: 2)
    // P0 hits, P1 misses → P1 eliminated → P0 wins.
    vm.enteredDarts = [gnHit(20), gnMiss(), gnMiss()]
    await vm.submitTurn()
    // P1's turn: miss the first hurdle (20).
    vm.enteredDarts = [gnHit(5), gnMiss(), gnMiss()]
    await vm.submitTurn()

    #expect(vm.state == .matchCompleted)
    #expect(vm.grandNationalState?.isComplete == true)
    #expect(store.completedSessions().count == 1)
}

@MainActor
@Test(.tags(.integration, .match, .regression))
func grandNationalViewModelUndoRestoresEliminatedPlayer() async throws {
    let (vm, _) = try makeGrandNationalViewModel()
    // P0 gets eliminated.
    vm.enteredDarts = [gnHit(5), gnMiss(), gnMiss()]
    await vm.submitTurn()
    #expect(vm.grandNationalState?.players[0].isEliminated == true)

    await vm.undoLastTurn()

    #expect(vm.grandNationalState?.players[0].isEliminated == false)
    #expect(vm.state == .readyTurn)
}
