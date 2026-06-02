import Foundation
import Testing
@testable import DartsScoreboard

@Test(.tags(.unit, .stats, .regression))
func matchStatsLoaderBuildsPlayerSummaries() async throws {
    let jacob = UUID()
    let sam = UUID()
    let matchRepo = CatalogMatchRepository(records: [
        makeCatalogRecord(id: UUID(), type: .x01, winner: jacob, participants: [(jacob, "Jacob"), (sam, "Sam")], playedAt: Date()),
        makeCatalogRecord(id: UUID(), type: .cricket, winner: sam, participants: [(jacob, "Jacob"), (sam, "Sam")], playedAt: Date().addingTimeInterval(-86400)),
    ])

    let summaries = try await MatchStatsLoader.buildPlayerSummaries(matchRepository: matchRepo)

    #expect(summaries[jacob]?.games == 2)
    #expect(summaries[jacob]?.wins == 1)
    #expect(summaries[sam]?.games == 2)
    #expect(summaries[sam]?.wins == 1)
}

@Test(.tags(.unit, .stats, .regression))
func matchStatsLoaderRecentMatchesReturnsNewestFirst() async throws {
    let jacob = UUID()
    let sam = UUID()
    let older = makeCatalogRecord(id: UUID(), type: .x01, winner: jacob, participants: [(jacob, "Jacob"), (sam, "Sam")], playedAt: Date().addingTimeInterval(-86_400))
    let newer = makeCatalogRecord(id: UUID(), type: .cricket, winner: sam, participants: [(jacob, "Jacob"), (sam, "Sam")], playedAt: Date())
    let matchRepo = CatalogMatchRepository(records: [newer, older])

    let recent = try await MatchStatsLoader.recentMatches(for: jacob, matchRepository: matchRepo, limit: 2)

    #expect(recent.count == 2)
    #expect(recent[0].type == .cricket)
    #expect(recent[0].opponentLabel == "Sam")
    #expect(recent[0].didWin == false)
    #expect(recent[1].type == .x01)
    #expect(recent[1].didWin == true)
}

private func makeCatalogRecord(
    id: UUID,
    type: MatchType,
    winner: UUID,
    participants: [(UUID, String)],
    playedAt: Date
) -> MatchHistoryRecord {
    MatchHistoryRecord(
        summary: MatchSummary(
            id: id,
            type: type,
            status: .completed,
            startedAt: playedAt,
            endedAt: playedAt,
            winnerPlayerId: winner,
            currentTurnPlayerId: nil,
            currentLegIndex: 0,
            currentSetIndex: 0,
            eventCount: 0,
            createdAt: playedAt,
            updatedAt: playedAt
        ),
        participants: participants.enumerated().map { index, entry in
            MatchParticipantSummary(
                id: UUID(),
                matchId: id,
                playerId: entry.0,
                turnOrder: index,
                displayNameAtMatchStart: entry.1
            )
        }
    )
}

private actor CatalogMatchRepository: MatchRepository {
    let records: [MatchHistoryRecord]

    init(records: [MatchHistoryRecord]) {
        self.records = records
    }

    func fetchHistoryWithParticipants(page: Int, pageSize: Int, filter: MatchHistoryFilter) async throws -> [MatchHistoryRecord] {
        let filtered = records.filter { record in
            if let type = filter.matchType, record.summary.type != type { return false }
            if let startedAfter = filter.startedAfter, record.summary.startedAt < startedAfter { return false }
            if let playerId = filter.participantPlayerId {
                guard record.participants.contains(where: { $0.playerId == playerId }) else { return false }
            }
            return true
        }
        let start = max(0, page) * max(1, pageSize)
        guard start < filtered.count else { return [] }
        return Array(filtered.dropFirst(start).prefix(pageSize))
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
