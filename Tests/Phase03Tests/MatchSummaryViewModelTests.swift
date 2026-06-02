import Foundation
import Testing
@testable import DartsScoreboard

@MainActor
@Test(.tags(.integration, .match, .regression))
func matchSummaryViewModelLoadsSessionFromRepositoryWhenStoreEmpty() async throws {
    let p0 = UUID()
    let p1 = UUID()
    var session = try MatchLifecycleService.createMatch(
        type: .x01,
        config: .x01(MatchConfigX01(startScore: 101, legsToWin: 1, setsEnabled: false, setsToWin: nil, checkoutMode: .singleOut)),
        participants: [
            MatchParticipant(playerId: p0, displayNameAtMatchStart: "Alice", turnOrder: 0),
            MatchParticipant(playerId: p1, displayNameAtMatchStart: "Bob", turnOrder: 1)
        ]
    )
    session = try MatchLifecycleService.submitX01Turn(session: session, enteredTotal: 60, darts: nil)
    session = try MatchLifecycleService.submitX01Turn(session: session, enteredTotal: 0, darts: nil)
    session = try MatchLifecycleService.submitX01Turn(session: session, enteredTotal: 41, darts: nil)

    let matchId = session.runtime.matchId
    let snapshot = session.latestSnapshot
    let store = ActiveMatchStore()
    let matchRepo = SummaryFakeMatchRepository(
        snapshot: MatchSnapshotSummary(
            id: UUID(),
            matchId: matchId,
            snapshotVersion: snapshot.payloadVersion,
            snapshotPayload: snapshot.payload,
            updatedAt: Date()
        )
    )
    let eventSummaries = try session.events.map { envelope in
        MatchEventSummary(
            id: UUID(),
            matchId: matchId,
            eventIndex: envelope.eventIndex,
            eventTypeRaw: "x01Turn",
            eventPayload: try CodablePayloadCoder.encode(envelope),
            createdAt: envelope.timestamp
        )
    }
    let statsRepo = SummaryFakeStatsRepository(events: eventSummaries)

    let vm = MatchSummaryViewModel(
        matchId: matchId,
        store: store,
        matchRepository: matchRepo,
        statsRepository: statsRepo
    )

    #expect(!vm.hasResult)
    await vm.loadIfNeeded()

    #expect(vm.hasResult)
    #expect(vm.winnerName == "Alice")
    #expect(vm.playerRows.count == 2)
    #expect(store.session(for: matchId) != nil)
}

private actor SummaryFakeMatchRepository: MatchRepository {
    let snapshot: MatchSnapshotSummary

    init(snapshot: MatchSnapshotSummary) {
        self.snapshot = snapshot
    }

    func createMatch(type _: MatchType, configPayload _: Data, participants _: [MatchParticipantSummary]) async throws -> MatchSummary {
        throw AppError(code: .unsupportedOperation, layer: .data, severity: .warning, isRecoverable: true, userMessageKey: "error")
    }
    func fetchActiveMatch() async throws -> MatchSummary? { nil }
    func fetchHistory(page _: Int, pageSize _: Int) async throws -> [MatchSummary] { [] }
    func fetchHistoryWithParticipants(page _: Int, pageSize _: Int, filter _: MatchHistoryFilter) async throws -> [MatchHistoryRecord] { [] }
    func updateMatch(_: MatchSummary) async throws {}
    func completeMatch(matchId _: UUID, endedAt _: Date, winnerPlayerId _: UUID?) async throws -> MatchSummary {
        throw AppError(code: .unsupportedOperation, layer: .data, severity: .warning, isRecoverable: true, userMessageKey: "error")
    }
    func appendEvent(matchId _: UUID, eventTypeRaw _: String, eventPayload _: Data) async throws -> MatchEventSummary {
        throw AppError(code: .unsupportedOperation, layer: .data, severity: .warning, isRecoverable: true, userMessageKey: "error")
    }
    func saveSnapshot(matchId _: UUID, snapshotVersion _: Int, snapshotPayload _: Data) async throws -> MatchSnapshotSummary {
        throw AppError(code: .unsupportedOperation, layer: .data, severity: .warning, isRecoverable: true, userMessageKey: "error")
    }
    func fetchLatestSnapshot(matchId: UUID) async throws -> MatchSnapshotSummary? {
        snapshot.matchId == matchId ? snapshot : nil
    }
    func fetchMatch(matchId _: UUID) async throws -> MatchSummary? { nil }
    func fetchParticipants(matchId _: UUID) async throws -> [MatchParticipantSummary] { [] }
    func deleteMatch(matchId _: UUID) async throws {}
}

private actor SummaryFakeStatsRepository: StatsRepository {
    let events: [MatchEventSummary]

    init(events: [MatchEventSummary]) {
        self.events = events
    }

    func fetchEvents(matchId: UUID) async throws -> [MatchEventSummary] {
        events.filter { $0.matchId == matchId }
    }

    func fetchEvents(matchIds _: [UUID]) async throws -> [MatchEventSummary] { [] }
}
