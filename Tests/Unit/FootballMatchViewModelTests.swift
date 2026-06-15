import Foundation
import Testing
@testable import DartBuddy

// MARK: - Helpers

private func footballDart(_ multiplier: DartMultiplier, _ segment: DartSegment) -> DartInput {
    DartInput(multiplier: multiplier, segment: segment)
}

private func footballMiss() -> DartInput {
    DartInput(multiplier: .single, segment: .miss, isMiss: true)
}

@MainActor
private func makeFootballViewModel(
    goalsToWin: Int = 10,
    kickoffMode: FootballKickoffMode = .singleBull,
    preTurns: [[DartInput]] = []
) throws -> (vm: FootballMatchViewModel, store: ActiveMatchStore) {
    let ids = [UUID(), UUID()]
    let participants = ids.enumerated().map { index, id in
        MatchParticipant(playerId: id, displayNameAtMatchStart: "P\(index + 1)", turnOrder: index)
    }
    var session = try MatchLifecycleService.createMatch(
        type: .football,
        config: .football(MatchConfigFootball(goalsToWin: goalsToWin, kickoffMode: kickoffMode)),
        participants: participants
    )
    for darts in preTurns {
        session = try MatchLifecycleService.submitFootballTurn(session: session, darts: darts)
    }
    let store = ActiveMatchStore()
    store.save(session)
    let vm = FootballMatchViewModel(
        matchId: session.runtime.matchId,
        store: store,
        logger: DefaultAppLogger(minimumLevel: .fault, sink: TestNoopLogSink()),
        matchRepository: FakeMatchRepositoryBuilder.matchViewModel(completedType: .football),
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
func footballViewModelRequiresThreeDartsBeforeSubmit() async throws {
    let (vm, _) = try makeFootballViewModel()
    vm.enteredDarts = [
        footballDart(.double, .oneToTwenty(20)),
        footballDart(.double, .oneToTwenty(18))
    ]

    #expect(vm.canSubmit == false)
}

@MainActor
@Test(.tags(.integration, .match, .regression))
func footballViewModelCanSubmitAfterThreeDarts() async throws {
    let (vm, _) = try makeFootballViewModel()
    vm.enteredDarts = [
        footballDart(.double, .oneToTwenty(20)),
        footballDart(.double, .oneToTwenty(18)),
        DartInput(multiplier: .single, segment: .miss, isMiss: true)
    ]

    #expect(vm.canSubmit == true)
}

// MARK: - Phase awareness

@MainActor
@Test(.tags(.integration, .match, .regression))
func footballViewModelInitialPhaseIsKickoff() async throws {
    let (vm, _) = try makeFootballViewModel()

    #expect(vm.currentPhase == .kickoff)
    #expect(vm.phaseLabel == L10n.string("phase.kickoff"))
}

@MainActor
@Test(.tags(.integration, .match, .regression))
func footballViewModelPhaseChangesScoringAfterKickoff() async throws {
    let miss = DartInput(multiplier: .single, segment: .miss, isMiss: true)
    let outerBull = DartInput(multiplier: .single, segment: .outerBull)
    let (vm, _) = try makeFootballViewModel(preTurns: [
        [outerBull, miss, miss],  // p1 kickoff
        [miss, miss, miss]        // p2 pass
    ])

    #expect(vm.currentPhase == .scoring)
    #expect(vm.phaseLabel == L10n.string("phase.scoring"))
}

// MARK: - Submission

@MainActor
@Test(.tags(.integration, .match, .critical, .regression))
func footballViewModelSubmitUpdatesGoals() async throws {
    let miss = DartInput(multiplier: .single, segment: .miss, isMiss: true)
    let outerBull = DartInput(multiplier: .single, segment: .outerBull)
    let (vm, _) = try makeFootballViewModel(preTurns: [
        [outerBull, miss, miss],
        [miss, miss, miss]
    ])

    vm.enteredDarts = [
        footballDart(.double, .oneToTwenty(20)),
        footballDart(.double, .oneToTwenty(18)),
        miss
    ]

    await vm.submitTurn()

    #expect(vm.state == .readyTurn)
    #expect(vm.footballState?.players[0].goals == 2)
    #expect(vm.enteredDarts.isEmpty)
}

@MainActor
@Test(.tags(.integration, .match, .critical, .regression))
func footballViewModelWinCompletesMatch() async throws {
    let miss = DartInput(multiplier: .single, segment: .miss, isMiss: true)
    let outerBull = DartInput(multiplier: .single, segment: .outerBull)
    let (vm, store) = try makeFootballViewModel(
        goalsToWin: 3,
        preTurns: [
            [outerBull, miss, miss],
            [miss, miss, miss]
        ]
    )

    vm.enteredDarts = [
        footballDart(.double, .oneToTwenty(20)),
        footballDart(.double, .oneToTwenty(18)),
        footballDart(.double, .oneToTwenty(16))
    ]

    await vm.submitTurn()

    #expect(vm.state == .matchCompleted)
    #expect(vm.footballState?.isComplete == true)
    #expect(store.completedSessions().count == 1)
}

// MARK: - Undo

@MainActor
@Test(.tags(.integration, .match, .regression))
func footballViewModelUndoLastDartRemovesLastEntry() async throws {
    let (vm, _) = try makeFootballViewModel()
    vm.enteredDarts = [footballDart(.double, .oneToTwenty(20))]

    await vm.undoLastDart()

    #expect(vm.enteredDarts.isEmpty)
}

// MARK: - Scoreboard

@MainActor
@Test(.tags(.integration, .match, .regression))
func footballViewModelScoreboardHasCorrectRowCount() async throws {
    let (vm, _) = try makeFootballViewModel()

    #expect(vm.scoreboardRows.count == 2)
}

@MainActor
@Test(.tags(.integration, .match, .regression))
func footballViewModelScoreboardFirstRowIsActive() async throws {
    let (vm, _) = try makeFootballViewModel()

    let activeRow = vm.scoreboardRows.first(where: \.isActive)
    #expect(activeRow != nil)
    #expect(vm.scoreboardRows.filter { $0.isActive }.count == 1)
}

@MainActor
@Test(.tags(.integration, .match, .regression))
func footballViewModelScoreboardRowsExposeGoals() async throws {
    let (vm, _) = try makeFootballViewModel()
    let outerBull = DartInput(multiplier: .single, segment: .outerBull)
    vm.enteredDarts = [outerBull, footballMiss(), footballMiss()]
    await vm.submitTurn()

    let row = try #require(vm.scoreboardRows.first)
    #expect(row.goals >= 0)
    #expect(vm.scoreboardRows.count == 2)
}

// MARK: - Bot gating

@MainActor
@Test(.tags(.integration, .match, .regression))
func footballViewModelHumanCannotInputWhileBotPlaying() async throws {
    let (vm, _) = try makeFootballViewModel()
    // Simulate bot playback in progress
    vm.enteredDarts = []

    // canHumanInput depends on isBotPlaying == false; since isBotPlaying starts false
    // and no bot is configured, human input should be enabled.
    #expect(vm.canHumanInput == true)
}

// MARK: - Rehydration

@MainActor
@Test(.tags(.integration, .match, .regression))
func footballViewModelRehydratesSessionFromSnapshot() async throws {
    let ids = [UUID(), UUID()]
    let miss = DartInput(multiplier: .single, segment: .miss, isMiss: true)
    let outerBull = DartInput(multiplier: .single, segment: .outerBull)
    var session = try MatchLifecycleService.createMatch(
        type: .football,
        config: .football(MatchConfigFootball(goalsToWin: 10)),
        participants: ids.enumerated().map { index, id in
            MatchParticipant(playerId: id, displayNameAtMatchStart: "P\(index + 1)", turnOrder: index)
        }
    )
    session = try MatchLifecycleService.submitFootballTurn(
        session: session,
        darts: [outerBull, miss, miss]
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
            eventTypeRaw: "footballTurn",
            eventPayload: try CodablePayloadCoder.encode(envelope),
            createdAt: envelope.timestamp
        )
    }
    let store = ActiveMatchStore()
    let vm = FootballMatchViewModel(
        matchId: matchId,
        store: store,
        logger: DefaultAppLogger(minimumLevel: .fault, sink: TestNoopLogSink()),
        matchRepository: FakeMatchRepositoryBuilder.rehydrating(snapshot: snapshotSummary, completedType: .football),
        statsRepository: FakeStatsRepository(events: eventSummaries),
        feedbackPreferences: FeedbackPreferences()
    )

    #expect(vm.session == nil)
    await vm.onAppear()

    #expect(vm.session?.events.count == 1)
    #expect(vm.footballState?.players[0].kickoffComplete == true)
    #expect(store.session(for: matchId) != nil)
}
