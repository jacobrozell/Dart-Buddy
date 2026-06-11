import Foundation
import Testing
@testable import DartBuddy

// MARK: - Helpers

private func atcDart(_ value: Int) -> DartInput {
    DartInput(multiplier: .single, segment: .oneToTwenty(value))
}

private func atcMiss() -> DartInput {
    DartInput(multiplier: .single, segment: .miss, isMiss: true)
}

@MainActor
private func makeAroundTheClockViewModel(
    participantCount: Int = 2,
    includeBullFinish: Bool = false,
    resetPolicy: AroundTheClockResetPolicy = .noReset,
    preTurns: [[DartInput]] = []
) throws -> (vm: AroundTheClockMatchViewModel, store: ActiveMatchStore) {
    let ids = (0 ..< participantCount).map { _ in UUID() }
    let participants = ids.enumerated().map { index, id in
        MatchParticipant(playerId: id, displayNameAtMatchStart: "P\(index + 1)", turnOrder: index)
    }
    var session = try MatchLifecycleService.createMatch(
        type: .aroundTheClock,
        config: .aroundTheClock(MatchConfigAroundTheClock(
            includeBullFinish: includeBullFinish,
            resetPolicy: resetPolicy
        )),
        participants: participants
    )
    for darts in preTurns {
        session = try MatchLifecycleService.submitAroundTheClockTurn(session: session, darts: darts)
    }
    let store = ActiveMatchStore()
    store.save(session)
    let vm = AroundTheClockMatchViewModel(
        matchId: session.runtime.matchId,
        store: store,
        logger: DefaultAppLogger(minimumLevel: .fault, sink: AroundTheClockSilentLogSink()),
        matchRepository: AroundTheClockFakeMatchRepository(),
        statsRepository: AroundTheClockFakeStatsRepository(),
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
func aroundTheClockViewModelInitialTargetIsOne() async throws {
    let (vm, _) = try makeAroundTheClockViewModel()
    #expect(vm.currentTarget == 1)
    #expect(vm.lockedSegment == 1)
}

@MainActor
@Test(.tags(.integration, .match, .regression))
func aroundTheClockViewModelRequiresThreeDartsBeforeSubmit() async throws {
    let (vm, _) = try makeAroundTheClockViewModel()
    vm.enteredDarts = [atcDart(1), atcMiss()]
    #expect(vm.canSubmit == false)
}

@MainActor
@Test(.tags(.integration, .match, .critical, .regression))
func aroundTheClockViewModelHitAdvancesTarget() async throws {
    let (vm, _) = try makeAroundTheClockViewModel()
    vm.enteredDarts = [atcDart(1), atcMiss(), atcMiss()]

    await vm.submitTurn()

    #expect(vm.state == .readyTurn || vm.state == .targetAdvancedFeedback)
    #expect(vm.aroundTheClockState?.players[0].targetIndex == 1)
    #expect(vm.enteredDarts.isEmpty)
}

@MainActor
@Test(.tags(.integration, .match, .regression))
func aroundTheClockViewModelHeaderTextContainsTarget() async throws {
    let (vm, _) = try makeAroundTheClockViewModel()
    #expect(vm.headerText.contains("1"))
    #expect(vm.headerAccessibilityLabel.contains(L10n.string("play.aroundTheClock.navTitle")))
}

@MainActor
@Test(.tags(.integration, .match, .regression))
func aroundTheClockViewModelProgressRowsMatchPlayerCount() async throws {
    let (vm, _) = try makeAroundTheClockViewModel(participantCount: 3)
    #expect(vm.progressRows.count == 3)
}

@MainActor
@Test(.tags(.integration, .match, .critical, .regression))
func aroundTheClockViewModelCompletionSetsMatchCompleted() async throws {
    let p1 = UUID()
    let participants = [
        MatchParticipant(playerId: p1, displayNameAtMatchStart: "P1", turnOrder: 0),
        MatchParticipant(playerId: UUID(), displayNameAtMatchStart: "P2", turnOrder: 1)
    ]
    // Pre-set player 0 to targetIndex 19 via preTurns isn't possible without cheating state,
    // so we use a fresh session and manually advance state via the engine.
    var session = try MatchLifecycleService.createMatch(
        type: .aroundTheClock,
        config: .aroundTheClock(MatchConfigAroundTheClock()),
        participants: participants
    )
    // Manually replace state with one where player 0 is on target 19 (hitting 20 wins).
    // We do this by submitting enough turns (19 hits for P1, skip P2 each time).
    // That's 19 rounds — instead just build it synthetically.
    // In real app this would take real plays; for the test we submit 19 successful p1 darts
    // with p2 missing each round.
    for i in 1 ... 19 {
        session = try MatchLifecycleService.submitAroundTheClockTurn(
            session: session,
            darts: [DartInput(multiplier: .single, segment: .oneToTwenty(i)), atcMiss(), atcMiss()]
        )
        // P2 misses
        session = try MatchLifecycleService.submitAroundTheClockTurn(
            session: session,
            darts: [atcMiss(), atcMiss(), atcMiss()]
        )
    }
    let store = ActiveMatchStore()
    store.save(session)
    let vm = AroundTheClockMatchViewModel(
        matchId: session.runtime.matchId,
        store: store,
        logger: DefaultAppLogger(minimumLevel: .fault, sink: AroundTheClockSilentLogSink()),
        matchRepository: AroundTheClockFakeMatchRepository(),
        statsRepository: AroundTheClockFakeStatsRepository(),
        feedbackPreferences: {
            let prefs = FeedbackPreferences()
            prefs.botStaggerEnabled = false
            return prefs
        }()
    )

    vm.enteredDarts = [DartInput(multiplier: .single, segment: .oneToTwenty(20)), atcMiss(), atcMiss()]
    await vm.submitTurn()

    #expect(vm.state == .matchCompleted)
    #expect(vm.aroundTheClockState?.isComplete == true)
    #expect(store.completedSessions().count == 1)
}

@MainActor
@Test(.tags(.integration, .match, .regression))
func aroundTheClockViewModelRehydratesSessionFromSnapshotWhenStoreEmpty() async throws {
    let ids = [UUID(), UUID()]
    var session = try MatchLifecycleService.createMatch(
        type: .aroundTheClock,
        config: .aroundTheClock(MatchConfigAroundTheClock()),
        participants: ids.enumerated().map { index, id in
            MatchParticipant(playerId: id, displayNameAtMatchStart: "P\(index + 1)", turnOrder: index)
        }
    )
    session = try MatchLifecycleService.submitAroundTheClockTurn(
        session: session,
        darts: [atcDart(1), atcMiss(), atcMiss()]
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
            eventTypeRaw: "aroundTheClockTurn",
            eventPayload: try CodablePayloadCoder.encode(envelope),
            createdAt: envelope.timestamp
        )
    }
    let store = ActiveMatchStore()
    let vm = AroundTheClockMatchViewModel(
        matchId: matchId,
        store: store,
        logger: DefaultAppLogger(minimumLevel: .fault, sink: AroundTheClockSilentLogSink()),
        matchRepository: AroundTheClockRehydratingFakeMatchRepository(snapshot: snapshotSummary),
        statsRepository: AroundTheClockRehydratingFakeStatsRepository(events: eventSummaries),
        feedbackPreferences: FeedbackPreferences()
    )

    #expect(vm.session == nil)
    await vm.onAppear()

    #expect(vm.session?.events.count == 1)
    #expect(store.session(for: matchId) != nil)
}

// MARK: - Test doubles

private struct AroundTheClockSilentLogSink: LogSink {
    func write(_: LogEntry) {}
}

private actor AroundTheClockFakeMatchRepository: MatchRepository {
    func createMatch(type: MatchType, configPayload _: Data, participants _: [MatchParticipantSummary]) async throws -> MatchSummary {
        makeSummary(type: type, status: .inProgress)
    }
    func fetchActiveMatch() async throws -> MatchSummary? { nil }
    func fetchHistory(page _: Int, pageSize _: Int) async throws -> [MatchSummary] { [] }
    func fetchHistoryWithParticipants(page _: Int, pageSize _: Int, filter _: MatchHistoryFilter) async throws -> [MatchHistoryRecord] { [] }
    func updateMatch(_: MatchSummary) async throws {}
    func completeMatch(matchId _: UUID, endedAt _: Date, winnerPlayerId _: UUID?) async throws -> MatchSummary {
        makeSummary(type: .aroundTheClock, status: .completed)
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

private actor AroundTheClockFakeStatsRepository: StatsRepository {
    func fetchEvents(matchId _: UUID) async throws -> [MatchEventSummary] { [] }
    func fetchEvents(matchIds _: [UUID]) async throws -> [MatchEventSummary] { [] }
}

private actor AroundTheClockRehydratingFakeMatchRepository: MatchRepository {
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
        makeSummary(type: .aroundTheClock, status: .completed)
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

private actor AroundTheClockRehydratingFakeStatsRepository: StatsRepository {
    let events: [MatchEventSummary]
    init(events: [MatchEventSummary]) { self.events = events }
    func fetchEvents(matchId _: UUID) async throws -> [MatchEventSummary] { events }
    func fetchEvents(matchIds _: [UUID]) async throws -> [MatchEventSummary] { events }
}
