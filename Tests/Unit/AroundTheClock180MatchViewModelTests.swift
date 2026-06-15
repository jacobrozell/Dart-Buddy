import Foundation
import Testing
@testable import DartBuddy

private func atc180Dart(_ multiplier: DartMultiplier, _ segment: Int) -> DartInput {
    DartInput(multiplier: multiplier, segment: .oneToTwenty(segment))
}

private func atc180Miss() -> DartInput {
    DartInput(multiplier: .single, segment: .miss, isMiss: true)
}

@MainActor
private func makeATC180ViewModel(
    participantCount: Int = 1,
    parScore: Int? = nil,
    preTurns: [[DartInput]] = []
) throws -> (vm: AroundTheClock180MatchViewModel, store: ActiveMatchStore) {
    let ids = (0 ..< participantCount).map { _ in UUID() }
    let participants = ids.enumerated().map { index, id in
        MatchParticipant(playerId: id, displayNameAtMatchStart: "P\(index + 1)", turnOrder: index)
    }
    var session = try MatchLifecycleService.createMatch(
        type: .aroundTheClock180,
        config: .aroundTheClock180(MatchConfigAroundTheClock180(parScore: parScore)),
        participants: participants
    )
    for darts in preTurns {
        session = try MatchLifecycleService.submitAroundTheClock180Turn(session: session, darts: darts)
    }
    let store = ActiveMatchStore()
    store.save(session)
    let vm = AroundTheClock180MatchViewModel(
        matchId: session.runtime.matchId,
        store: store,
        logger: DefaultAppLogger(minimumLevel: .fault, sink: TestNoopLogSink()),
        matchRepository: FakeMatchRepositoryBuilder.matchViewModel(completedType: .aroundTheClock180),
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
func atc180ViewModelLockedSegmentMatchesCurrentNumber() async throws {
    let (vm, _) = try makeATC180ViewModel()

    #expect(vm.lockedSegment == 1)
    #expect(vm.aroundTheClock180State?.currentNumber == 1)
}

@MainActor
@Test(.tags(.integration, .match, .regression))
func atc180ViewModelRequiresThreeDartsBeforeSubmit() async throws {
    let (vm, _) = try makeATC180ViewModel()
    vm.enteredDarts = [atc180Dart(.triple, 1), atc180Dart(.triple, 1)]

    #expect(vm.canSubmit == false)
}

@MainActor
@Test(.tags(.integration, .match, .regression))
func atc180ViewModelCanSubmitWithThreeDarts() async throws {
    let (vm, _) = try makeATC180ViewModel()
    vm.enteredDarts = [atc180Dart(.triple, 1), atc180Dart(.triple, 1), atc180Dart(.triple, 1)]

    #expect(vm.canSubmit == true)
}

// MARK: - Scoreboard rows

@MainActor
@Test(.tags(.integration, .match, .regression))
func atc180ViewModelScoreboardRowsExposeSoloLeader() async throws {
    let (vm, _) = try makeATC180ViewModel()
    vm.enteredDarts = [
        atc180Dart(.triple, 1),
        atc180Dart(.triple, 1),
        atc180Dart(.triple, 1),
    ]
    await vm.submitTurn()

    #expect(vm.scoreboardRows.count == 1)
    #expect(vm.scoreboardRows[0].cumulativePoints == 9)
    #expect(vm.scoreboardRows[0].isLeading == true)
}

// MARK: - Submission

@MainActor
@Test(.tags(.integration, .match, .critical, .regression))
func atc180ViewModelHumanSubmitUpdatesPoints() async throws {
    let (vm, _) = try makeATC180ViewModel()
    vm.enteredDarts = [
        atc180Dart(.triple, 1),
        atc180Dart(.triple, 1),
        atc180Dart(.triple, 1),
    ]

    await vm.submitTurn()

    #expect(vm.state == .readyTurn)
    #expect(vm.aroundTheClock180State?.players[0].cumulativePoints == 9)
    #expect(vm.enteredDarts.isEmpty)
}

@MainActor
@Test(.tags(.integration, .match, .regression))
func atc180ViewModelAdvancesNumberAfterSubmit() async throws {
    let (vm, _) = try makeATC180ViewModel()
    vm.enteredDarts = [atc180Miss(), atc180Miss(), atc180Miss()]

    await vm.submitTurn()

    #expect(vm.aroundTheClock180State?.currentNumber == 2)
}

// MARK: - Match completion

@MainActor
@Test(.tags(.integration, .match, .critical, .regression))
func atc180ViewModelCompletesAfterAllTwentyNumbers() async throws {
    // Pre-play 19 numbers, then submit final.
    var preTurns: [[DartInput]] = []
    for number in 1 ... 19 {
        preTurns.append([atc180Dart(.triple, number), atc180Dart(.triple, number), atc180Dart(.triple, number)])
    }
    let (vm, store) = try makeATC180ViewModel(preTurns: preTurns)

    vm.enteredDarts = [
        atc180Dart(.triple, 20),
        atc180Dart(.triple, 20),
        atc180Dart(.triple, 20),
    ]
    await vm.submitTurn()

    #expect(vm.state == .matchCompleted)
    #expect(vm.aroundTheClock180State?.isComplete == true)
    #expect(store.completedSessions().count == 1)
}

// MARK: - Undo

@MainActor
@Test(.tags(.integration, .match, .regression))
func atc180ViewModelUndoLastDartRemovesDartFromEntryList() async throws {
    let (vm, _) = try makeATC180ViewModel()
    vm.enteredDarts = [atc180Dart(.triple, 1), atc180Dart(.triple, 1)]

    await vm.undoLastDart()

    #expect(vm.enteredDarts.count == 1)
}

@MainActor
@Test(.tags(.integration, .match, .regression))
func atc180ViewModelUndoTurnRevertsToReadyState() async throws {
    let preTurns = [[atc180Miss(), atc180Miss(), atc180Miss()]]
    let (vm, _) = try makeATC180ViewModel(preTurns: preTurns)

    await vm.undoLastTurn()

    #expect(vm.state == .readyTurn)
    #expect(vm.aroundTheClock180State?.currentNumber == 1)
    #expect(vm.aroundTheClock180State?.players[0].cumulativePoints == 0)
}

// MARK: - Bot gating

@MainActor
@Test(.tags(.integration, .match, .regression))
func atc180ViewModelBotDoesNotPlayWhenNoBot() async throws {
    let (vm, _) = try makeATC180ViewModel()

    #expect(vm.isCurrentPlayerBot == false)
    #expect(vm.isBotPlaying == false)
}

// MARK: - Accessibility helpers

@MainActor
@Test(.tags(.integration, .match, .regression))
func atc180ViewModelHeaderAccessibilityLabelContainsTitleAndNumber() async throws {
    let (vm, _) = try makeATC180ViewModel()

    #expect(vm.headerAccessibilityLabel.contains(L10n.string("play.aroundTheClock180.navTitle")))
    #expect(vm.headerAccessibilityLabel.contains(vm.headerText))
}

@MainActor
@Test(.tags(.integration, .match, .regression))
func atc180ViewModelRunningTotalTextShownForSoloPlayer() async throws {
    let (vm, _) = try makeATC180ViewModel(participantCount: 1)

    #expect(vm.runningTotalText != nil)
}

@MainActor
@Test(.tags(.integration, .match, .regression))
func atc180ViewModelRunningTotalTextHiddenForMultiplePlayers() async throws {
    let (vm, _) = try makeATC180ViewModel(participantCount: 2)

    #expect(vm.runningTotalText == nil)
}

@MainActor
@Test(.tags(.integration, .match, .regression))
func atc180ViewModelParScoreTextShownWhenConfigured() async throws {
    let (vm, _) = try makeATC180ViewModel(parScore: 80)

    #expect(vm.parScoreText != nil)
}

@MainActor
@Test(.tags(.integration, .match, .regression))
func atc180ViewModelParScoreTextHiddenWhenNotConfigured() async throws {
    let (vm, _) = try makeATC180ViewModel(parScore: nil)

    #expect(vm.parScoreText == nil)
}

// MARK: - Rehydration

@MainActor
@Test(.tags(.integration, .match, .regression))
func atc180ViewModelRehydratesSessionFromSnapshotWhenStoreEmpty() async throws {
    let ids = [UUID()]
    var session = try MatchLifecycleService.createMatch(
        type: .aroundTheClock180,
        config: .aroundTheClock180(MatchConfigAroundTheClock180()),
        participants: ids.enumerated().map { index, id in
            MatchParticipant(playerId: id, displayNameAtMatchStart: "P\(index + 1)", turnOrder: index)
        }
    )
    session = try MatchLifecycleService.submitAroundTheClock180Turn(
        session: session,
        darts: [atc180Dart(.triple, 1)]
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
            eventTypeRaw: "aroundTheClock180Turn",
            eventPayload: try CodablePayloadCoder.encode(envelope),
            createdAt: envelope.timestamp
        )
    }
    let store = ActiveMatchStore()
    let vm = AroundTheClock180MatchViewModel(
        matchId: matchId,
        store: store,
        logger: DefaultAppLogger(minimumLevel: .fault, sink: TestNoopLogSink()),
        matchRepository: FakeMatchRepositoryBuilder.rehydrating(snapshot: snapshotSummary, completedType: .aroundTheClock180),
        statsRepository: FakeStatsRepository(events: eventSummaries),
        feedbackPreferences: FeedbackPreferences()
    )

    #expect(vm.session == nil)
    await vm.onAppear()

    #expect(vm.session?.events.count == 1)
    #expect(vm.aroundTheClock180State?.players[0].cumulativePoints == 3)
    #expect(store.session(for: matchId) != nil)
}
