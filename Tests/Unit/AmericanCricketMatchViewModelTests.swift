import Foundation
import Testing
@testable import DartBuddy

// MARK: - Helpers

private func acVMDart(_ multiplier: DartMultiplier, _ segment: Int) -> DartInput {
    DartInput(multiplier: multiplier, segment: .oneToTwenty(segment))
}

@MainActor
private func makeAmericanCricketViewModel(
    participantCount: Int = 2,
    pointsEnabled: Bool = true,
    preTurns: [[DartInput]] = []
) throws -> (vm: AmericanCricketMatchViewModel, store: ActiveMatchStore) {
    let ids = (0 ..< participantCount).map { _ in UUID() }
    let participants = ids.enumerated().map { index, id in
        MatchParticipant(playerId: id, displayNameAtMatchStart: "P\(index + 1)", turnOrder: index)
    }
    var session = try MatchLifecycleService.createMatch(
        type: .americanCricket,
        config: .americanCricket(MatchConfigAmericanCricket(pointsEnabled: pointsEnabled)),
        participants: participants
    )
    for darts in preTurns {
        session = try MatchLifecycleService.submitAmericanCricketTurn(session: session, darts: darts)
    }
    let store = ActiveMatchStore()
    store.save(session)
    let vm = AmericanCricketMatchViewModel(
        matchId: session.runtime.matchId,
        store: store,
        logger: DefaultAppLogger(minimumLevel: .fault, sink: AmericanCricketSilentLogSink()),
        matchRepository: AmericanCricketFakeMatchRepository(),
        statsRepository: AmericanCricketFakeStatsRepository(),
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
func americanCricketViewModelInitialActiveTarget20() async throws {
    let (vm, _) = try makeAmericanCricketViewModel()
    #expect(vm.americanCricketState?.activeTarget == .t20)
    #expect(vm.americanCricketState?.activeTargetIndex == 0)
}

@MainActor
@Test(.tags(.integration, .match, .regression))
func americanCricketViewModelCanSubmitRequiresDarts() async throws {
    let (vm, _) = try makeAmericanCricketViewModel()
    #expect(vm.canSubmit == false)
    vm.enteredDarts = [acVMDart(.single, 20)]
    #expect(vm.canSubmit == true)
}

@MainActor
@Test(.tags(.integration, .match, .critical, .regression))
func americanCricketViewModelSubmitUpdatesMarks() async throws {
    let (vm, _) = try makeAmericanCricketViewModel()
    vm.enteredDarts = [acVMDart(.triple, 20)]
    await vm.submitTurn()
    let marks = vm.americanCricketState?.players[0].marks["20"] ?? 0
    #expect(marks == 3)
    #expect(vm.enteredDarts.isEmpty)
}

@MainActor
@Test(.tags(.integration, .match, .regression))
func americanCricketViewModelBoardColumnsMatchPlayerCount() async throws {
    let (vm, _) = try makeAmericanCricketViewModel(participantCount: 3)
    #expect(vm.boardColumns.count == 3)
}

@MainActor
@Test(.tags(.integration, .match, .regression))
func americanCricketViewModelActiveBoardColumnIsCurrentPlayer() async throws {
    let (vm, _) = try makeAmericanCricketViewModel()
    let activeColumn = vm.boardColumns.first(where: \.isActive)
    #expect(activeColumn != nil)
    let activeBoardID = vm.activeBoardColumnID
    #expect(activeBoardID == activeColumn?.id)
}

@MainActor
@Test(.tags(.integration, .match, .regression))
func americanCricketViewModelUndoRestoresPreviousState() async throws {
    let (vm, _) = try makeAmericanCricketViewModel()
    vm.enteredDarts = [acVMDart(.double, 20)]
    await vm.submitTurn()
    let marksAfterTurn = vm.americanCricketState?.players[0].marks["20"] ?? 0
    #expect(marksAfterTurn == 2)

    await vm.undoLastTurn()
    let marksAfterUndo = vm.americanCricketState?.players[0].marks["20"] ?? 0
    #expect(marksAfterUndo == 0)
}

@MainActor
@Test(.tags(.integration, .match, .regression))
func americanCricketViewModelUndoLastDartPopsEnteredDart() async throws {
    let (vm, _) = try makeAmericanCricketViewModel()
    vm.enteredDarts = [acVMDart(.single, 20), acVMDart(.single, 20)]
    await vm.undoLastDart()
    #expect(vm.enteredDarts.count == 1)
}

@MainActor
@Test(.tags(.integration, .match, .regression))
func americanCricketViewModelBotGatedByIsCurrentPlayerBot() async throws {
    let (vm, _) = try makeAmericanCricketViewModel()
    // No bots wired — isCurrentPlayerBot should be false.
    #expect(vm.isCurrentPlayerBot == false)
    #expect(vm.canHumanInput == true)
}

@MainActor
@Test(.tags(.integration, .match, .regression))
func americanCricketViewModelRehydratesFromSnapshot() async throws {
    let ids = [UUID(), UUID()]
    var session = try MatchLifecycleService.createMatch(
        type: .americanCricket,
        config: .americanCricket(MatchConfigAmericanCricket()),
        participants: ids.enumerated().map { index, id in
            MatchParticipant(playerId: id, displayNameAtMatchStart: "P\(index + 1)", turnOrder: index)
        }
    )
    session = try MatchLifecycleService.submitAmericanCricketTurn(
        session: session,
        darts: [acVMDart(.single, 20)]
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
            eventTypeRaw: "americanCricketTurn",
            eventPayload: try CodablePayloadCoder.encode(envelope),
            createdAt: envelope.timestamp
        )
    }
    let store = ActiveMatchStore()
    let vm = AmericanCricketMatchViewModel(
        matchId: matchId,
        store: store,
        logger: DefaultAppLogger(minimumLevel: .fault, sink: AmericanCricketSilentLogSink()),
        matchRepository: AmericanCricketRehydratingFakeMatchRepository(snapshot: snapshotSummary),
        statsRepository: AmericanCricketRehydratingFakeStatsRepository(events: eventSummaries),
        feedbackPreferences: FeedbackPreferences()
    )

    #expect(vm.session == nil)
    await vm.onAppear()

    #expect(vm.session?.events.count == 1)
    #expect(vm.americanCricketState?.players[0].marks["20"] == 1)
    #expect(store.session(for: matchId) != nil)
}

// MARK: - Test infrastructure

private struct AmericanCricketSilentLogSink: LogSink {
    func write(_: LogEntry) {}
}

private actor AmericanCricketFakeMatchRepository: MatchRepository {
    func createMatch(type: MatchType, configPayload _: Data, participants _: [MatchParticipantSummary]) async throws -> MatchSummary {
        makeSummary(type: type, status: .inProgress)
    }
    func fetchActiveMatch() async throws -> MatchSummary? { nil }
    func fetchHistory(page _: Int, pageSize _: Int) async throws -> [MatchSummary] { [] }
    func fetchHistoryWithParticipants(page _: Int, pageSize _: Int, filter _: MatchHistoryFilter) async throws -> [MatchHistoryRecord] { [] }
    func updateMatch(_: MatchSummary) async throws {}
    func completeMatch(matchId _: UUID, endedAt _: Date, winnerPlayerId _: UUID?) async throws -> MatchSummary {
        makeSummary(type: .americanCricket, status: .completed)
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

private actor AmericanCricketFakeStatsRepository: StatsRepository {
    func fetchEvents(matchId _: UUID) async throws -> [MatchEventSummary] { [] }
    func fetchEvents(matchIds _: [UUID]) async throws -> [MatchEventSummary] { [] }
}

private actor AmericanCricketRehydratingFakeMatchRepository: MatchRepository {
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
        makeSummary(type: .americanCricket, status: .completed)
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

private actor AmericanCricketRehydratingFakeStatsRepository: StatsRepository {
    let events: [MatchEventSummary]
    init(events: [MatchEventSummary]) { self.events = events }
    func fetchEvents(matchId _: UUID) async throws -> [MatchEventSummary] { events }
    func fetchEvents(matchIds _: [UUID]) async throws -> [MatchEventSummary] { events }
}
