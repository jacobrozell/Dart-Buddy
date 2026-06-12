import Foundation

/// Loads a match session from the in-memory store, or rehydrates it from the
/// latest persisted snapshot plus tail events. Shared by all match view models.
@MainActor
enum MatchSessionLoader {
    enum LoadResult {
        case loaded(MatchLifecycleSession)
        case missing
        case failed(messageKey: String)
    }

    static func load(
        matchId: UUID,
        matchType: MatchType,
        store: ActiveMatchStore,
        logger: any AppLogger,
        matchRepository: any MatchRepository,
        statsRepository: any StatsRepository,
        sessionMissingFallbackKey: String
    ) async -> LoadResult {
        if let existing = store.session(for: matchId) {
            logger.matchDebug(
                matchId: matchId,
                matchType: matchType,
                eventName: "match_session_resumed_from_memory",
                message: "Loaded active match session from memory.",
                metadata: MatchTurnSupport.matchProgressMetadata(for: existing)
            )
            return .loaded(existing)
        }
        do {
            guard let snapshotSummary = try await matchRepository.fetchLatestSnapshot(matchId: matchId) else {
                return .missing
            }
            let runtime = try CodablePayloadCoder.decode(MatchRuntimeState.self, from: snapshotSummary.snapshotPayload)
            let events = try await statsRepository.fetchEvents(matchId: matchId)
            let envelopes = try events
                .map { try CodablePayloadCoder.decode(MatchEventEnvelope.self, from: $0.eventPayload) }
                .sorted { $0.eventIndex < $1.eventIndex }
            let tailEvents = envelopes.filter { $0.eventIndex >= runtime.eventCount }
            let snapshot = MatchSnapshot(
                payloadVersion: snapshotSummary.snapshotVersion,
                eventCount: runtime.eventCount,
                createdAt: snapshotSummary.updatedAt,
                payload: snapshotSummary.snapshotPayload
            )
            let rehydrated = try MatchLifecycleService.rehydrate(snapshot: snapshot, tailEvents: tailEvents)
            store.save(rehydrated)
            logger.matchInfo(
                matchId: matchId,
                matchType: matchType,
                eventName: "match_session_rehydrated",
                message: "Rehydrated match session from snapshot.",
                metadata: [
                    "source": "snapshot",
                    "eventCount": String(rehydrated.runtime.eventCount)
                ]
            )
            return .loaded(rehydrated)
        } catch {
            logger.matchError(
                matchId: matchId,
                matchType: matchType,
                eventName: "match_session_load_failed",
                message: "Failed to load match session.",
                metadata: MatchTurnSupport.appErrorMetadata(for: error)
            )
            return .failed(messageKey: MatchTurnSupport.errorMessageKey(for: error, fallback: sessionMissingFallbackKey))
        }
    }
}
