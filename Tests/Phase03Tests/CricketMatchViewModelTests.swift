import Foundation
import Testing
@testable import DartsScoreboard

// State-machine coverage for the live Cricket match view model using in-memory fakes.

private func triple(_ value: Int) -> DartInput { DartInput(multiplier: .triple, segment: .oneToTwenty(value)) }
private func cricketMiss() -> DartInput { DartInput(multiplier: .single, segment: .miss, isMiss: true) }
private let cricketInnerBull = DartInput(multiplier: .single, segment: .innerBull)
private let cricketOuterBull = DartInput(multiplier: .single, segment: .outerBull)

@MainActor
private func makeCricketViewModel(
    preTurns: [[DartInput]] = [],
    failAppend: Bool = false
) throws -> (vm: CricketMatchViewModel, store: ActiveMatchStore) {
    let p0 = UUID()
    let p1 = UUID()
    var session = try MatchLifecycleService.createMatch(
        type: .cricket,
        config: .cricket(MatchConfigCricket()),
        participants: [
            MatchParticipant(playerId: p0, displayNameAtMatchStart: "A", turnOrder: 0),
            MatchParticipant(playerId: p1, displayNameAtMatchStart: "B", turnOrder: 1)
        ]
    )
    for darts in preTurns {
        session = try MatchLifecycleService.submitCricketTurn(session: session, darts: darts)
    }
    let store = ActiveMatchStore()
    store.save(session)
    let vm = CricketMatchViewModel(
        matchId: session.runtime.matchId,
        store: store,
        logger: DefaultAppLogger(minimumLevel: .fault, sink: CricketSilentLogSink()),
        matchRepository: CricketFakeMatchRepository(failAppend: failAppend),
        statsRepository: CricketFakeStatsRepository()
    )
    return (vm, store)
}

@MainActor
@Test(.tags(.integration, .cricket, .match, .regression))
func cricketViewModelEntersClosureTransitionOnNormalTurn() async throws {
    let (vm, _) = try makeCricketViewModel()
    vm.enteredDarts = [triple(20)]

    await vm.submitTurn()

    #expect(vm.state == .readyTurn)
    #expect(vm.enteredDarts.isEmpty)
}

@MainActor
@Test(.tags(.integration, .cricket, .match, .critical, .regression))
func cricketViewModelCompletesMatchOnFinalClose() async throws {
    // Pre-close everything for player 0 except the bull; opponent throws misses.
    let (vm, store) = try makeCricketViewModel(preTurns: [
        [triple(20), triple(19), triple(18)],
        [cricketMiss(), cricketMiss(), cricketMiss()],
        [triple(17), triple(16), triple(15)],
        [cricketMiss(), cricketMiss(), cricketMiss()]
    ])
    vm.enteredDarts = [cricketInnerBull, cricketOuterBull] // closes the bull (2 + 1 marks)

    await vm.submitTurn()

    #expect(vm.state == .matchCompleted)
    #expect(store.completedSessions().count == 1)
}

@MainActor
@Test(.tags(.integration, .cricket, .match, .regression))
func cricketViewModelSurfacesErrorWhenPersistenceFails() async throws {
    let (vm, _) = try makeCricketViewModel(failAppend: true)
    vm.enteredDarts = [triple(20)]

    await vm.submitTurn()

    if case .error = vm.state {
        #expect(Bool(true))
    } else {
        Issue.record("Expected error state, got \(vm.state)")
    }
}

// MARK: - Fakes

private final class CricketSilentLogSink: LogSink, @unchecked Sendable {
    func write(_: LogEntry) {}
}

private actor CricketFakeStatsRepository: StatsRepository {
    func fetchEvents(matchId _: UUID) async throws -> [MatchEventSummary] { [] }
}

private actor CricketFakeMatchRepository: MatchRepository {
    let failAppend: Bool
    init(failAppend: Bool = false) { self.failAppend = failAppend }

    func createMatch(type: MatchType, configPayload _: Data, participants _: [MatchParticipantSummary]) async throws -> MatchSummary {
        makeSummary(type: type, status: .inProgress)
    }
    func fetchActiveMatch() async throws -> MatchSummary? { nil }
    func fetchHistory(page _: Int, pageSize _: Int) async throws -> [MatchSummary] { [] }
    func fetchHistoryWithParticipants(page _: Int, pageSize _: Int) async throws -> [MatchHistoryRecord] { [] }
    func updateMatch(_: MatchSummary) async throws {}
    func completeMatch(matchId _: UUID, endedAt _: Date, winnerPlayerId _: UUID?) async throws -> MatchSummary {
        makeSummary(type: .cricket, status: .completed)
    }
    func appendEvent(matchId: UUID, eventTypeRaw: String, eventPayload: Data) async throws -> MatchEventSummary {
        if failAppend {
            throw AppError(code: .storageUnavailable, layer: .data, severity: .error, isRecoverable: true, userMessageKey: "error.repository.storage")
        }
        return MatchEventSummary(id: UUID(), matchId: matchId, eventIndex: 0, eventTypeRaw: eventTypeRaw, eventPayload: eventPayload, createdAt: Date())
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
