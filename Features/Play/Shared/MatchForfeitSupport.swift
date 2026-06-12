import Foundation

@MainActor
enum MatchForfeitSupport {
    static func persistForfeit(
        session: MatchLifecycleSession,
        forfeitingPlayerId: UUID,
        winnerPlayerId: UUID?,
        matchId: UUID,
        store: ActiveMatchStore,
        matchRepository: any MatchRepository,
        logger: any AppLogger,
        matchType: MatchType,
        resolution: String
    ) async throws -> MatchLifecycleSession {
        let forfeited = try MatchLifecycleService.forfeit(
            session: session,
            forfeitingPlayerId: forfeitingPlayerId,
            winnerPlayerId: winnerPlayerId
        )
        try await matchRepository.updateMatch(MatchTurnSupport.matchSummary(from: forfeited.runtime))
        _ = try await matchRepository.saveSnapshot(
            matchId: matchId,
            snapshotVersion: forfeited.latestSnapshot.payloadVersion,
            snapshotPayload: forfeited.latestSnapshot.payload
        )
        _ = try await matchRepository.forfeitMatch(
            matchId: matchId,
            endedAt: forfeited.runtime.endedAt ?? Date(),
            winnerPlayerId: winnerPlayerId,
            forfeitedByPlayerId: forfeitingPlayerId
        )
        store.remove(matchId: matchId)
        let duration = Int((forfeited.runtime.endedAt ?? Date()).timeIntervalSince(forfeited.runtime.startedAt))
        logger.matchInfo(
            matchId: matchId,
            matchType: matchType,
            category: .appLifecycle,
            eventName: "match_forfeited",
            message: "Match forfeited by user.",
            metadata: [
                "event_count": String(forfeited.runtime.eventCount),
                "participant_count": String(forfeited.runtime.participants.count),
                "forfeited_by_player_id": forfeitingPlayerId.uuidString,
                "winner_player_id": winnerPlayerId?.uuidString ?? "none",
                "duration_seconds": String(duration),
                "resolution": resolution
            ]
        )
        return forfeited
    }
}
