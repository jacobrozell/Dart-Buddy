import Foundation
import Testing
@testable import DartsScoreboard

@Test(.tags(.unit, .stats, .regression))
func matchStatsLoaderPaginatesHistoryAndBatchFetchesEvents() async throws {
    let matchRepo = PaginatingMatchRepository(pageSize: 2, totalPages: 2)
    let statsRepo = BatchTrackingStatsRepository()

    let result = try await MatchStatsLoader.load(
        matchRepository: matchRepo,
        statsRepository: statsRepo,
        request: MatchStatsLoadRequest(matchType: .x01),
        pageSize: 2
    )

    #expect(await matchRepo.fetchCallCount == 3)
    #expect(await statsRepo.batchFetchCallCount == 2)
    #expect(result.inputs.count == 4)
    #expect(result.namesById.count == 8)
}

@Test(.tags(.unit, .stats, .regression))
func matchStatsLoaderFiltersByParticipant() async throws {
    let target = UUID()
    let other = UUID()
    let matchRepo = SinglePageMatchRepository(records: [
        makeHistoryRecord(participantIds: [target, other], type: .x01),
        makeHistoryRecord(participantIds: [other], type: .x01),
    ])
    let statsRepo = BatchTrackingStatsRepository()

    let result = try await MatchStatsLoader.load(
        matchRepository: matchRepo,
        statsRepository: statsRepo,
        request: MatchStatsLoadRequest(matchType: .x01, participantPlayerId: target)
    )

    #expect(result.inputs.count == 1)
    #expect(result.inputs[0].participantKeys.contains(target))
}

private func makeHistoryRecord(participantIds: [UUID], type: MatchType) -> MatchHistoryRecord {
    let matchId = UUID()
    let now = Date()
    return MatchHistoryRecord(
        summary: MatchSummary(
            id: matchId,
            type: type,
            status: .completed,
            startedAt: now,
            endedAt: now,
            winnerPlayerId: participantIds.first,
            currentTurnPlayerId: nil,
            currentLegIndex: 0,
            currentSetIndex: 0,
            eventCount: 0,
            createdAt: now,
            updatedAt: now
        ),
        participants: participantIds.enumerated().map { index, id in
            MatchParticipantSummary(
                id: UUID(),
                matchId: matchId,
                playerId: id,
                turnOrder: index,
                displayNameAtMatchStart: index == 0 ? "A" : "B"
            )
        }
    )
}

private actor PaginatingMatchRepository: MatchRepository {
    let pageSize: Int
    let totalPages: Int
    private(set) var fetchCallCount = 0

    init(pageSize: Int, totalPages: Int) {
        self.pageSize = pageSize
        self.totalPages = totalPages
    }

    func fetchHistoryWithParticipants(page: Int, pageSize: Int, filter _: MatchHistoryFilter) async throws -> [MatchHistoryRecord] {
        fetchCallCount += 1
        guard page < totalPages else { return [] }
        return (0..<pageSize).map { _ in
            makeHistoryRecord(participantIds: [UUID(), UUID()], type: .x01)
        }
    }

    func createMatch(type _: MatchType, configPayload _: Data, participants _: [MatchParticipantSummary]) async throws -> MatchSummary { fatalError() }
    func fetchActiveMatch() async throws -> MatchSummary? { nil }
    func fetchHistory(page _: Int, pageSize _: Int) async throws -> [MatchSummary] { [] }
    func updateMatch(_: MatchSummary) async throws {}
    func completeMatch(matchId _: UUID, endedAt _: Date, winnerPlayerId _: UUID?) async throws -> MatchSummary { fatalError() }
    func appendEvent(matchId _: UUID, eventTypeRaw _: String, eventPayload _: Data) async throws -> MatchEventSummary { fatalError() }
    func saveSnapshot(matchId _: UUID, snapshotVersion _: Int, snapshotPayload _: Data) async throws -> MatchSnapshotSummary { fatalError() }
    func fetchLatestSnapshot(matchId _: UUID) async throws -> MatchSnapshotSummary? { nil }
    func fetchMatch(matchId _: UUID) async throws -> MatchSummary? { nil }
    func fetchParticipants(matchId _: UUID) async throws -> [MatchParticipantSummary] { [] }
    func deleteMatch(matchId _: UUID) async throws {}
}

private actor SinglePageMatchRepository: MatchRepository {
    let records: [MatchHistoryRecord]

    init(records: [MatchHistoryRecord]) {
        self.records = records
    }

    func fetchHistoryWithParticipants(page: Int, pageSize: Int, filter: MatchHistoryFilter) async throws -> [MatchHistoryRecord] {
        guard page == 0 else { return [] }
        return records.filter { record in
            if let type = filter.matchType, record.summary.type != type { return false }
            if let startedAfter = filter.startedAfter, record.summary.startedAt < startedAfter { return false }
            return true
        }.prefix(pageSize).map { $0 }
    }

    func createMatch(type _: MatchType, configPayload _: Data, participants _: [MatchParticipantSummary]) async throws -> MatchSummary { fatalError() }
    func fetchActiveMatch() async throws -> MatchSummary? { nil }
    func fetchHistory(page _: Int, pageSize _: Int) async throws -> [MatchSummary] { [] }
    func updateMatch(_: MatchSummary) async throws {}
    func completeMatch(matchId _: UUID, endedAt _: Date, winnerPlayerId _: UUID?) async throws -> MatchSummary { fatalError() }
    func appendEvent(matchId _: UUID, eventTypeRaw _: String, eventPayload _: Data) async throws -> MatchEventSummary { fatalError() }
    func saveSnapshot(matchId _: UUID, snapshotVersion _: Int, snapshotPayload _: Data) async throws -> MatchSnapshotSummary { fatalError() }
    func fetchLatestSnapshot(matchId _: UUID) async throws -> MatchSnapshotSummary? { nil }
    func fetchMatch(matchId _: UUID) async throws -> MatchSummary? { nil }
    func fetchParticipants(matchId _: UUID) async throws -> [MatchParticipantSummary] { [] }
    func deleteMatch(matchId _: UUID) async throws {}
}

private actor BatchTrackingStatsRepository: StatsRepository {
    private(set) var batchFetchCallCount = 0

    func fetchEvents(matchId _: UUID) async throws -> [MatchEventSummary] { [] }
    func fetchEvents(matchIds: [UUID]) async throws -> [MatchEventSummary] {
        batchFetchCallCount += 1
        return matchIds.map {
            MatchEventSummary(
                id: UUID(),
                matchId: $0,
                eventIndex: 0,
                eventTypeRaw: "turn",
                eventPayload: Data(),
                createdAt: Date()
            )
        }
    }
}
