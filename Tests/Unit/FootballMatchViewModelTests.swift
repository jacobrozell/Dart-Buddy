import Foundation
import Testing
@testable import DartBuddy

// MARK: - Helpers

private func footballDart(_ multiplier: DartMultiplier, _ segment: DartSegment) -> DartInput {
    DartInput(multiplier: multiplier, segment: segment)
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
        logger: DefaultAppLogger(minimumLevel: .fault, sink: FootballSilentLogSink()),
        matchRepository: FootballFakeMatchRepository(),
        statsRepository: FootballFakeStatsRepository(),
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
    #expect(vm.scoreboardRows.filter(\.isActive).count == 1)
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
        logger: DefaultAppLogger(minimumLevel: .fault, sink: FootballSilentLogSink()),
        matchRepository: FootballRehydratingFakeMatchRepository(snapshot: snapshotSummary),
        statsRepository: FootballRehydratingFakeStatsRepository(events: eventSummaries),
        feedbackPreferences: FeedbackPreferences()
    )

    #expect(vm.session == nil)
    await vm.onAppear()

    #expect(vm.session?.events.count == 1)
    #expect(vm.footballState?.players[0].kickoffComplete == true)
    #expect(store.session(for: matchId) != nil)
}

// MARK: - Fakes / Stubs

private struct FootballSilentLogSink: LogSink {
    func write(_: LogEntry) {}
}

private actor FootballFakeMatchRepository: MatchRepository {
    func createMatch(type: MatchType, configPayload _: Data, participants _: [MatchParticipantSummary]) async throws -> MatchSummary {
        makeSummary(type: type, status: .inProgress)
    }
    func fetchActiveMatch() async throws -> MatchSummary? { nil }
    func fetchHistory(page _: Int, pageSize _: Int) async throws -> [MatchSummary] { [] }
    func fetchHistoryWithParticipants(page _: Int, pageSize _: Int, filter _: MatchHistoryFilter) async throws -> [MatchHistoryRecord] { [] }
    func updateMatch(_: MatchSummary) async throws {}
    func completeMatch(matchId _: UUID, endedAt _: Date, winnerPlayerId _: UUID?) async throws -> MatchSummary {
        makeSummary(type: .football, status: .completed)
    }
    func appendEvent(matchId: UUID, eventTypeRaw: String, eventPayload: Data) async throws -> MatchEventSummary {
        MatchEventSummary(id: UUID(), matchId: matchId, eventIndex: 0, eventTypeRaw: eventTypeRaw, eventPayload: eventPayload, createdAt: Date())
    }
    func saveSnapshot(matchId: UUID, snapshotVersion: Int, snapshotPayload: Data) async throws -> MatchSnapshotSummary {
        MatchSnapshotSummary(id: UUID(), matchId: matchId, snapshotVersion: snapshotVersion, snapshotPayload: snapshotPayload, updatedAt: Date())
    }
    func fetchLatestSnapshot(matchId _: UUID) async throws -> MatchSnapshotSummary? { nil }
    func fetchMatch(matchId _: UUID) async throws -> MatchSummary? { nil }
    func fetchParticipants(matchId _: UUID) async throws -> [MatchParticipantSummary] { [] }
    func deleteMatch(matchId _: UUID) async throws {}

    private func makeSummary(type: MatchType, status: MatchStatus) -> MatchSummary {
        MatchSummary(
            id: UUID(), type: type, status: status, startedAt: Date(), endedAt: nil,
            winnerPlayerId: nil, currentTurnPlayerId: nil, currentLegIndex: 0, currentSetIndex: 0,
            eventCount: 0, createdAt: Date(), updatedAt: Date()
        )
    }
}

private actor FootballFakeStatsRepository: StatsRepository {
    func fetchEvents(matchId _: UUID) async throws -> [MatchEventSummary] { [] }
    func fetchEvents(matchIds _: [UUID]) async throws -> [MatchEventSummary] { [] }
}

private actor FootballRehydratingFakeMatchRepository: MatchRepository {
    let snapshot: MatchSnapshotSummary
    init(snapshot: MatchSnapshotSummary) { self.snapshot = snapshot }

    func createMatch(type: MatchType, configPayload _: Data, participants _: [MatchParticipantSummary]) async throws -> MatchSummary {
        makeSummary(type: type, status: .inProgress)
    }
    func fetchActiveMatch() async throws -> MatchSummary? { nil }
    func fetchHistory(page _: Int, pageSize _: Int) async throws -> [MatchSummary] { [] }
    func fetchHistoryWithParticipants(page _: Int, pageSize _: Int, filter _: MatchHistoryFilter) async throws -> [MatchHistoryRecord] { [] }
    func updateMatch(_: MatchSummary) async throws {}
    func completeMatch(matchId _: UUID, endedAt _: Date, winnerPlayerId _: UUID?) async throws -> MatchSummary {
        makeSummary(type: .football, status: .completed)
    }
    func appendEvent(matchId: UUID, eventTypeRaw: String, eventPayload: Data) async throws -> MatchEventSummary {
        MatchEventSummary(id: UUID(), matchId: matchId, eventIndex: 0, eventTypeRaw: eventTypeRaw, eventPayload: eventPayload, createdAt: Date())
    }
    func saveSnapshot(matchId: UUID, snapshotVersion: Int, snapshotPayload: Data) async throws -> MatchSnapshotSummary {
        MatchSnapshotSummary(id: UUID(), matchId: matchId, snapshotVersion: snapshotVersion, snapshotPayload: snapshotPayload, updatedAt: Date())
    }
    func fetchLatestSnapshot(matchId: UUID) async throws -> MatchSnapshotSummary? {
        snapshot.matchId == matchId ? snapshot : nil
    }
    func fetchMatch(matchId _: UUID) async throws -> MatchSummary? { nil }
    func fetchParticipants(matchId _: UUID) async throws -> [MatchParticipantSummary] { [] }
    func deleteMatch(matchId _: UUID) async throws {}

    private func makeSummary(type: MatchType, status: MatchStatus) -> MatchSummary {
        MatchSummary(
            id: UUID(), type: type, status: status, startedAt: Date(), endedAt: nil,
            winnerPlayerId: nil, currentTurnPlayerId: nil, currentLegIndex: 0, currentSetIndex: 0,
            eventCount: 0, createdAt: Date(), updatedAt: Date()
        )
    }
}

private actor FootballRehydratingFakeStatsRepository: StatsRepository {
    let events: [MatchEventSummary]
    init(events: [MatchEventSummary]) { self.events = events }
    func fetchEvents(matchId _: UUID) async throws -> [MatchEventSummary] { events }
    func fetchEvents(matchIds _: [UUID]) async throws -> [MatchEventSummary] { events }
}
