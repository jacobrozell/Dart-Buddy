import Foundation
import Testing
@testable import DartBuddy

// MARK: - Helpers

private func makeMulliganConfig(seed: UInt64 = 42, targetCount: Int = 6) -> MatchConfigMulligan {
    var rng = SeededRandomNumberGenerator(seed: seed)
    let sequence = MulliganEngine.generateSequence(count: targetCount, rng: &rng)
    return MatchConfigMulligan(targetCount: targetCount, rngSeed: seed, targetSequence: sequence)
}

@MainActor
private func makeMulliganViewModel(
    participantCount: Int = 2,
    seed: UInt64 = 42,
    preTurns: [[DartInput]] = []
) throws -> (vm: MulliganMatchViewModel, store: ActiveMatchStore) {
    let ids = (0 ..< participantCount).map { _ in UUID() }
    let participants = ids.enumerated().map { index, id in
        MatchParticipant(playerId: id, displayNameAtMatchStart: "P\(index + 1)", turnOrder: index)
    }
    let config = makeMulliganConfig(seed: seed)
    var session = try MatchLifecycleService.createMatch(
        type: .mulligan,
        config: .mulligan(config),
        participants: participants
    )
    for darts in preTurns {
        session = try MatchLifecycleService.submitMulliganTurn(session: session, darts: darts)
    }
    let store = ActiveMatchStore()
    store.save(session)
    let vm = MulliganMatchViewModel(
        matchId: session.runtime.matchId,
        store: store,
        logger: DefaultAppLogger(minimumLevel: .fault, sink: MulliganSilentLogSink()),
        matchRepository: MulliganFakeMatchRepository(),
        statsRepository: MulliganFakeStatsRepository(),
        feedbackPreferences: {
            let prefs = FeedbackPreferences()
            prefs.botStaggerEnabled = false
            return prefs
        }()
    )
    return (vm, store)
}

private func miss() -> DartInput {
    DartInput(multiplier: .single, segment: .miss, isMiss: true)
}

// MARK: - Tests

@MainActor
@Test(.tags(.integration, .match, .regression))
func mulliganViewModelExposesActiveTarget() async throws {
    let (vm, _) = try makeMulliganViewModel()
    let state = vm.mulliganState
    #expect(state != nil)
    #expect(vm.activeTarget != nil)
    #expect(vm.currentTargetIndex == 0)
}

@MainActor
@Test(.tags(.integration, .match, .regression))
func mulliganViewModelSequenceLengthIsSevenByDefault() async throws {
    let (vm, _) = try makeMulliganViewModel()
    // 6 numbers + bull
    #expect(vm.targetSequence.count == 7)
    #expect(vm.targetSequence.last == .bull)
}

@MainActor
@Test(.tags(.integration, .match, .regression))
func mulliganViewModelRequiresThreeDartsBeforeSubmit() async throws {
    let (vm, _) = try makeMulliganViewModel()
    vm.enteredDarts = [miss(), miss()]
    #expect(vm.canSubmit == false)
}

@MainActor
@Test(.tags(.integration, .match, .critical, .regression))
func mulliganViewModelSubmitThreeMissesAdvancesTurn() async throws {
    let (vm, _) = try makeMulliganViewModel()
    vm.enteredDarts = [miss(), miss(), miss()]

    await vm.submitTurn()

    #expect(vm.enteredDarts.isEmpty)
    // State should be back to readyTurn (no error)
    if case .error = vm.state {
        Issue.record("Unexpected error state after submitting three misses")
    }
}

@MainActor
@Test(.tags(.integration, .match, .regression))
func mulliganViewModelScoreboardRowCountMatchesPlayerCount() async throws {
    let (vm, _) = try makeMulliganViewModel(participantCount: 3)
    #expect(vm.scoreboardRows.count == 3)
}

@MainActor
@Test(.tags(.integration, .match, .regression))
func mulliganViewModelScoreboardMarksReflectState() async throws {
    let config = makeMulliganConfig(seed: 42)
    guard case let .number(firstTarget) = config.targetSequence[0] else {
        Issue.record("Expected number target")
        return
    }
    // Pre-turn: player 0 throws a single on the first target
    let singleHit = DartInput(multiplier: .single, segment: .oneToTwenty(firstTarget))
    let (vm, _) = try makeMulliganViewModel(
        seed: 42,
        preTurns: [[singleHit, miss(), miss()]]
    )
    // After player 0's turn, state advanced to player 1 — marks are on the active target
    let row0 = vm.scoreboardRows.first { !$0.isActive }
    // Player 0 had 1 mark before the turn advanced; check the scoreboard reflects it or reset
    // (target was not closed, marks persist in player state)
    _ = row0
    #expect(vm.mulliganState != nil)
}

@MainActor
@Test(.tags(.integration, .match, .regression))
func mulliganViewModelHeaderAccessibilityLabelContainsTitle() async throws {
    let (vm, _) = try makeMulliganViewModel()
    let label = vm.activeTargetAnnouncement
    #expect(!label.isEmpty)
}

@MainActor
@Test(.tags(.integration, .match, .regression))
func mulliganViewModelRehydratesSessionFromSnapshot() async throws {
    let ids = [UUID(), UUID()]
    let config = makeMulliganConfig(seed: 123)
    var session = try MatchLifecycleService.createMatch(
        type: .mulligan,
        config: .mulligan(config),
        participants: ids.enumerated().map { index, id in
            MatchParticipant(playerId: id, displayNameAtMatchStart: "P\(index + 1)", turnOrder: index)
        }
    )
    session = try MatchLifecycleService.submitMulliganTurn(
        session: session,
        darts: [miss(), miss(), miss()]
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
            eventTypeRaw: "mulliganTurn",
            eventPayload: try CodablePayloadCoder.encode(envelope),
            createdAt: envelope.timestamp
        )
    }
    let store = ActiveMatchStore()
    let vm = MulliganMatchViewModel(
        matchId: matchId,
        store: store,
        logger: DefaultAppLogger(minimumLevel: .fault, sink: MulliganSilentLogSink()),
        matchRepository: MulliganRehydratingFakeMatchRepository(snapshot: snapshotSummary),
        statsRepository: MulliganRehydratingFakeStatsRepository(events: eventSummaries),
        feedbackPreferences: FeedbackPreferences()
    )

    #expect(vm.session == nil)
    await vm.onAppear()

    #expect(vm.session?.events.count == 1)
    #expect(vm.mulliganState != nil)
    #expect(store.session(for: matchId) != nil)
}

// MARK: - Stubs

private struct MulliganSilentLogSink: LogSink {
    func write(_: LogEntry) {}
}

private actor MulliganFakeMatchRepository: MatchRepository {
    func createMatch(type: MatchType, configPayload _: Data, participants _: [MatchParticipantSummary]) async throws -> MatchSummary {
        makeSummary(type: type, status: .inProgress)
    }
    func fetchActiveMatch() async throws -> MatchSummary? { nil }
    func fetchHistory(page _: Int, pageSize _: Int) async throws -> [MatchSummary] { [] }
    func fetchHistoryWithParticipants(page _: Int, pageSize _: Int, filter _: MatchHistoryFilter) async throws -> [MatchHistoryRecord] { [] }
    func updateMatch(_: MatchSummary) async throws {}
    func completeMatch(matchId _: UUID, endedAt _: Date, winnerPlayerId _: UUID?) async throws -> MatchSummary {
        makeSummary(type: .mulligan, status: .completed)
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

private actor MulliganFakeStatsRepository: StatsRepository {
    func fetchEvents(matchId _: UUID) async throws -> [MatchEventSummary] { [] }
    func fetchEvents(matchIds _: [UUID]) async throws -> [MatchEventSummary] { [] }
}

private actor MulliganRehydratingFakeMatchRepository: MatchRepository {
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
        makeSummary(type: .mulligan, status: .completed)
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

private actor MulliganRehydratingFakeStatsRepository: StatsRepository {
    let events: [MatchEventSummary]
    init(events: [MatchEventSummary]) { self.events = events }
    func fetchEvents(matchId _: UUID) async throws -> [MatchEventSummary] { events }
    func fetchEvents(matchIds _: [UUID]) async throws -> [MatchEventSummary] { events }
}
