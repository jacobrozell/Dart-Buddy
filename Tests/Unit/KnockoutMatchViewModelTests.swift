import Foundation
import Testing
@testable import DartBuddy

// MARK: - Helpers

private func knockoutDart(_ value: Int) -> DartInput {
    DartInput(multiplier: .single, segment: .oneToTwenty(value))
}

private func knockoutVisit(_ total: Int) -> [DartInput] {
    let twenties = min(total / 20, 3)
    let rem = total - twenties * 20
    var darts: [DartInput] = Array(repeating: knockoutDart(20), count: twenties)
    if rem > 0, darts.count < 3 {
        darts.append(knockoutDart(rem))
    }
    while darts.count < 3 {
        darts.append(DartInput(multiplier: .single, segment: .miss, isMiss: true))
    }
    return darts
}

@MainActor
private func makeKnockoutViewModel(
    participantCount: Int = 2,
    strikesToEliminate: Int = 3,
    preTurns: [[DartInput]] = []
) throws -> (vm: KnockoutMatchViewModel, store: ActiveMatchStore) {
    let ids = (0 ..< participantCount).map { _ in UUID() }
    let participants = ids.enumerated().map { index, id in
        MatchParticipant(playerId: id, displayNameAtMatchStart: "P\(index + 1)", turnOrder: index)
    }
    var session = try MatchLifecycleService.createMatch(
        type: .knockout,
        config: .knockout(MatchConfigKnockout(strikesToEliminate: strikesToEliminate)),
        participants: participants
    )
    for darts in preTurns {
        session = try MatchLifecycleService.submitKnockoutTurn(session: session, darts: darts)
    }
    let store = ActiveMatchStore()
    store.save(session)
    let vm = KnockoutMatchViewModel(
        matchId: session.runtime.matchId,
        store: store,
        logger: DefaultAppLogger(minimumLevel: .fault, sink: KnockoutSilentLogSink()),
        matchRepository: KnockoutFakeMatchRepository(),
        statsRepository: KnockoutFakeStatsRepository(),
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
func knockoutViewModelInitialStateIsReady() async throws {
    let (vm, _) = try makeKnockoutViewModel()

    #expect(vm.state == .readyTurn)
    #expect(vm.knockoutState?.currentHigh == 0)
    #expect(vm.knockoutState?.currentRound == 1)
}

@MainActor
@Test(.tags(.integration, .match, .regression))
func knockoutViewModelRequiresThreeDartsBeforeSubmit() async throws {
    let (vm, _) = try makeKnockoutViewModel()

    vm.enteredDarts = [knockoutDart(20), knockoutDart(20)]
    #expect(vm.canSubmit == false)

    vm.enteredDarts = [knockoutDart(20), knockoutDart(20), knockoutDart(20)]
    #expect(vm.canSubmit == true)
}

@MainActor
@Test(.tags(.integration, .match, .critical, .regression))
func knockoutViewModelHumanSubmitRecordsStrike() async throws {
    let (vm, _) = try makeKnockoutViewModel(
        preTurns: [knockoutVisit(60)] // P1 sets high 60
    )
    // Now P2 is active; score below 60.
    vm.enteredDarts = knockoutVisit(20)

    await vm.submitTurn()

    #expect(vm.state == .readyTurn)
    let p2State = vm.knockoutState?.players[1]
    #expect(p2State?.strikes == 1)
    #expect(vm.enteredDarts.isEmpty)
}

@MainActor
@Test(.tags(.integration, .match, .critical, .regression))
func knockoutViewModelEliminationCompletesMatch() async throws {
    let (vm, store) = try makeKnockoutViewModel(strikesToEliminate: 1)
    // P1 sets high.
    vm.enteredDarts = knockoutVisit(60)
    await vm.submitTurn()
    // P2 fails — should be eliminated and match ends.
    vm.enteredDarts = knockoutVisit(10)
    await vm.submitTurn()

    #expect(vm.state == .matchCompleted)
    #expect(vm.knockoutState?.isComplete == true)
    #expect(store.completedSessions().count == 1)
}

@MainActor
@Test(.tags(.integration, .match, .regression))
func knockoutViewModelCurrentHighTextContainsValue() async throws {
    let (vm, _) = try makeKnockoutViewModel()

    #expect(vm.currentHighText.contains("0"))
    #expect(vm.knockoutState?.currentHigh == 0)
}

@MainActor
@Test(.tags(.integration, .match, .regression))
func knockoutViewModelScoreboardRowCountMatchesParticipants() async throws {
    let (vm, _) = try makeKnockoutViewModel(participantCount: 4)

    #expect(vm.scoreboardRows.count == 4)
    let activeRow = vm.scoreboardRows.first(where: \.isActive)
    #expect(activeRow != nil)
}

@MainActor
@Test(.tags(.integration, .match, .regression))
func knockoutViewModelHeaderAccessibilityContainsTitle() async throws {
    let (vm, _) = try makeKnockoutViewModel()

    #expect(vm.headerAccessibilityLabel.contains(L10n.string("play.knockout.navTitle")))
}

@MainActor
@Test(.tags(.integration, .match, .regression))
func knockoutViewModelRehydratesSessionFromSnapshotWhenStoreEmpty() async throws {
    let ids = [UUID(), UUID()]
    var session = try MatchLifecycleService.createMatch(
        type: .knockout,
        config: .knockout(MatchConfigKnockout()),
        participants: ids.enumerated().map { index, id in
            MatchParticipant(playerId: id, displayNameAtMatchStart: "P\(index + 1)", turnOrder: index)
        }
    )
    session = try MatchLifecycleService.submitKnockoutTurn(session: session, darts: knockoutVisit(40))
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
            eventTypeRaw: "knockoutTurn",
            eventPayload: try CodablePayloadCoder.encode(envelope),
            createdAt: envelope.timestamp
        )
    }
    let store = ActiveMatchStore()
    let vm = KnockoutMatchViewModel(
        matchId: matchId,
        store: store,
        logger: DefaultAppLogger(minimumLevel: .fault, sink: KnockoutSilentLogSink()),
        matchRepository: KnockoutRehydratingFakeMatchRepository(snapshot: snapshotSummary),
        statsRepository: KnockoutRehydratingFakeStatsRepository(events: eventSummaries),
        feedbackPreferences: FeedbackPreferences()
    )

    #expect(vm.session == nil)
    await vm.onAppear()

    #expect(vm.session?.events.count == 1)
    #expect(store.session(for: matchId) != nil)
}

// MARK: - Fakes

private struct KnockoutSilentLogSink: LogSink {
    func write(_: LogEntry) {}
}

private actor KnockoutFakeMatchRepository: MatchRepository {
    func createMatch(type: MatchType, configPayload _: Data, participants _: [MatchParticipantSummary]) async throws -> MatchSummary {
        makeSummary(type: type, status: .inProgress)
    }
    func fetchActiveMatch() async throws -> MatchSummary? { nil }
    func fetchHistory(page _: Int, pageSize _: Int) async throws -> [MatchSummary] { [] }
    func fetchHistoryWithParticipants(page _: Int, pageSize _: Int, filter _: MatchHistoryFilter) async throws -> [MatchHistoryRecord] { [] }
    func updateMatch(_: MatchSummary) async throws {}
    func completeMatch(matchId _: UUID, endedAt _: Date, winnerPlayerId _: UUID?) async throws -> MatchSummary {
        makeSummary(type: .knockout, status: .completed)
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

private actor KnockoutFakeStatsRepository: StatsRepository {
    func fetchEvents(matchId _: UUID) async throws -> [MatchEventSummary] { [] }
    func fetchEvents(matchIds _: [UUID]) async throws -> [MatchEventSummary] { [] }
}

private actor KnockoutRehydratingFakeMatchRepository: MatchRepository {
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
        makeSummary(type: .knockout, status: .completed)
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

private actor KnockoutRehydratingFakeStatsRepository: StatsRepository {
    let events: [MatchEventSummary]
    init(events: [MatchEventSummary]) { self.events = events }
    func fetchEvents(matchId _: UUID) async throws -> [MatchEventSummary] { events }
    func fetchEvents(matchIds _: [UUID]) async throws -> [MatchEventSummary] { events }
}
