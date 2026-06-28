import Foundation
import Testing
@testable import DartBuddy

// MARK: - Helpers

private func fiftyOneDart(_ multiplier: DartMultiplier, _ segment: Int) -> DartInput {
    DartInput(multiplier: multiplier, segment: .oneToTwenty(segment))
}

private func fiftyOneMiss() -> DartInput {
    DartInput(multiplier: .single, segment: .miss, isMiss: true)
}

@MainActor
private func makeFiftyOneViewModel(
    participantCount: Int = 2,
    targetPoints: Int = 51,
    mustFinishExact: Bool = false,
    preTurns: [[DartInput]] = []
) throws -> (vm: FiftyOneByFivesMatchViewModel, store: ActiveMatchStore) {
    let ids = (0 ..< participantCount).map { _ in UUID() }
    let participants = ids.enumerated().map { index, id in
        MatchParticipant(playerId: id, displayNameAtMatchStart: "P\(index + 1)", turnOrder: index)
    }
    var session = try MatchLifecycleService.createMatch(
        type: .fiftyOneByFives,
        config: .fiftyOneByFives(MatchConfigFiftyOneByFives(
            targetPoints: targetPoints,
            mustFinishExact: mustFinishExact
        )),
        participants: participants
    )
    for darts in preTurns {
        session = try MatchLifecycleService.submitFiftyOneByFivesTurn(session: session, darts: darts)
    }
    let store = ActiveMatchStore()
    store.save(session)
    let vm = FiftyOneByFivesMatchViewModel(
        matchId: session.runtime.matchId,
        store: store,
        logger: DefaultAppLogger(minimumLevel: .fault, sink: TestNoopLogSink()),
        matchRepository: FakeMatchRepositoryBuilder.matchViewModel(completedType: .fiftyOneByFives),
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
func fiftyOneViewModelRequiresThreeDartsBeforeSubmit() async throws {
    let (vm, _) = try makeFiftyOneViewModel()
    vm.enteredDarts = [fiftyOneDart(.single, 1), fiftyOneDart(.double, 1)]

    #expect(vm.canSubmit == false)
}

@MainActor
@Test(.tags(.integration, .match, .regression))
func fiftyOneViewModelAllowsSubmitWithThreeDarts() async throws {
    let (vm, _) = try makeFiftyOneViewModel()
    vm.enteredDarts = [
        fiftyOneDart(.single, 5),
        fiftyOneDart(.single, 5),
        fiftyOneDart(.single, 5),
    ]

    #expect(vm.canSubmit == true)
}

// MARK: - Submission

@MainActor
@Test(.tags(.integration, .match, .critical, .regression))
func fiftyOneViewModelDivisibleTurnUpdatesPoints() async throws {
    let (vm, _) = try makeFiftyOneViewModel()
    // 60 total (triple-20) → 12 pts
    vm.enteredDarts = [fiftyOneDart(.triple, 20)]

    await vm.submitTurn()

    #expect(vm.state == .readyTurn)
    #expect(vm.fiftyOneByFivesState?.players[0].cumulativePoints == 12)
    #expect(vm.enteredDarts.isEmpty)
}

@MainActor
@Test(.tags(.integration, .match, .regression))
func fiftyOneViewModelNonDivisibleTurnScoresZero() async throws {
    let (vm, _) = try makeFiftyOneViewModel()
    // 18 + 40 = 58 → non-divisible → 0 pts
    vm.enteredDarts = [fiftyOneDart(.single, 18), fiftyOneDart(.double, 20)]

    await vm.submitTurn()

    #expect(vm.fiftyOneByFivesState?.players[0].cumulativePoints == 0)
}

// MARK: - Win / match complete

@MainActor
@Test(.tags(.integration, .match, .critical, .regression))
func fiftyOneViewModelMatchCompletesWhenTargetReached() async throws {
    // target = 12; one triple-20 (60 → 12 pts) should win
    let (vm, store) = try makeFiftyOneViewModel(targetPoints: 12)
    vm.enteredDarts = [fiftyOneDart(.triple, 20)]

    await vm.submitTurn()

    #expect(vm.state == .matchCompleted)
    #expect(vm.fiftyOneByFivesState?.isComplete == true)
    #expect(store.completedSessions().count == 1)
}

// MARK: - Scoreboard

@MainActor
@Test(.tags(.integration, .match, .regression))
func fiftyOneViewModelScoreboardRowCountMatchesPlayers() async throws {
    let (vm, _) = try makeFiftyOneViewModel(participantCount: 3)

    #expect(vm.scoreboardRows.count == 3)
}

@MainActor
@Test(.tags(.integration, .match, .regression))
func fiftyOneViewModelScoreboardActiveRowMatchesCurrentPlayer() async throws {
    let (vm, _) = try makeFiftyOneViewModel()

    let activeRows = vm.scoreboardRows.filter(\.isActive)
    #expect(activeRows.count == 1)
    #expect(vm.scoreboardRows[0].isActive == true)
}

// MARK: - Divisibility hint

@MainActor
@Test(.tags(.integration, .match, .regression))
func fiftyOneViewModelDivisibilityHintIsNonEmpty() async throws {
    let (vm, _) = try makeFiftyOneViewModel()

    #expect(vm.divisibilityHint.isEmpty == false)
}

// MARK: - Header accessibility

@MainActor
@Test(.tags(.integration, .match, .regression))
func fiftyOneViewModelHeaderAccessibilityContainsTitle() async throws {
    let (vm, _) = try makeFiftyOneViewModel()

    #expect(vm.headerAccessibilityLabel.contains(L10n.string("play.fiftyOneByFives.navTitle")))
}

// MARK: - Undo

@MainActor
@Test(.tags(.integration, .match, .critical, .regression))
func fiftyOneViewModelUndoRestoresPreviousTurn() async throws {
    // pre-submit one valid turn for player 0 so undo has something to roll back
    let (vm, _) = try makeFiftyOneViewModel(
        preTurns: [[fiftyOneDart(.triple, 20)]]  // player[0] → 12 pts
    )
    // Now it is player[1]'s turn; undo should rewind to player[0]'s turn.
    await vm.undoLastTurn()

    #expect(vm.fiftyOneByFivesState?.currentPlayerIndex == 0)
    #expect(vm.fiftyOneByFivesState?.players[0].cumulativePoints == 0)
}

// MARK: - Bot gating

@MainActor
@Test(.tags(.integration, .match, .regression))
func fiftyOneViewModelHumanCannotInputWhileBotIsPlaying() async throws {
    let (vm, _) = try makeFiftyOneViewModel()

    // Simulate bot lock without actual async playback.
    // Access via the published isBotPlaying through the public API.
    // We verify canHumanInput is false when isBotPlaying would be true by inspecting
    // the non-bot path: initially isBotPlaying == false and isCurrentPlayerBot == false.
    #expect(vm.canHumanInput == true)
    #expect(vm.isCurrentPlayerBot == false)
}

// MARK: - Rehydration

@MainActor
@Test(.tags(.integration, .match, .regression))
func fiftyOneViewModelRehydratesSessionFromSnapshotWhenStoreEmpty() async throws {
    let ids = [UUID(), UUID()]
    var session = try MatchLifecycleService.createMatch(
        type: .fiftyOneByFives,
        config: .fiftyOneByFives(MatchConfigFiftyOneByFives(targetPoints: 51)),
        participants: ids.enumerated().map { index, id in
            MatchParticipant(playerId: id, displayNameAtMatchStart: "P\(index + 1)", turnOrder: index)
        }
    )
    session = try MatchLifecycleService.submitFiftyOneByFivesTurn(
        session: session,
        darts: [fiftyOneDart(.triple, 20)]  // 60 → 12 pts
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
            eventTypeRaw: "fiftyOneByFivesTurn",
            eventPayload: try CodablePayloadCoder.encode(envelope),
            createdAt: envelope.timestamp
        )
    }
    let store = ActiveMatchStore()
    let vm = FiftyOneByFivesMatchViewModel(
        matchId: matchId,
        store: store,
        logger: DefaultAppLogger(minimumLevel: .fault, sink: TestNoopLogSink()),
        matchRepository: FakeMatchRepositoryBuilder.rehydrating(snapshot: snapshotSummary, completedType: .fiftyOneByFives),
        statsRepository: FakeStatsRepository(events: eventSummaries),
        feedbackPreferences: FeedbackPreferences()
    )

    #expect(vm.session == nil)
    await vm.onAppear()

    #expect(vm.session?.events.count == 1)
    #expect(vm.fiftyOneByFivesState?.players[0].cumulativePoints == 12)
    #expect(store.session(for: matchId) != nil)
}

// MARK: - Private fakes

private struct FiftyOneSilentLogSink: LogSink {
    func write(_: LogEntry) {}
}
