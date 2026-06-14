import Foundation

// Shared turn-submission plumbing for the X01 and Cricket match view models.
//
// Both modes wrap the same scaffolding around their domain engine: run the
// scoring call (measured), persist the resulting session, save it to the active
// store, and log a standard set of events. Only the post-turn state mapping
// differs (bust vs. closure, caller tokens, completion), so that part stays in
// each view model. `MatchTurnSupport` holds the pure helpers both view models
// reused verbatim.

enum MatchTurnSupport {
    static func matchSummary(from runtime: MatchRuntimeState) -> MatchSummary {
        MatchSummary(
            id: runtime.matchId,
            type: runtime.type,
            status: MatchStatus(rawValue: runtime.status.rawValue) ?? .inProgress,
            startedAt: runtime.startedAt,
            endedAt: runtime.endedAt,
            winnerPlayerId: runtime.winnerPlayerId,
            forfeitedByPlayerId: runtime.forfeitedByPlayerId,
            currentTurnPlayerId: runtime.currentTurnPlayerId,
            currentLegIndex: runtime.currentLegIndex,
            currentSetIndex: runtime.currentSetIndex,
            eventCount: runtime.eventCount,
            createdAt: runtime.startedAt,
            updatedAt: Date()
        )
    }

    static func matchProgressMetadata(for session: MatchLifecycleSession) -> [String: String] {
        [
            "eventCount": String(session.runtime.eventCount),
            "legIndex": String(session.runtime.currentLegIndex),
            "setIndex": String(session.runtime.currentSetIndex),
            "status": session.runtime.status.rawValue
        ]
    }

    static func appErrorMetadata(for error: Error) -> [String: String] {
        if let appError = error as? AppError {
            return [
                "errorCode": appError.code.rawValue,
                "layer": appError.layer.rawValue
            ]
        }
        return ["errorCode": "unknown"]
    }

    /// True when `scores[index]` is the single highest positive score (scoreboard leader chip).
    static func isUniqueLeader(scores: [Int], index: Int) -> Bool {
        guard scores.indices.contains(index),
              let maxScore = scores.max(), maxScore > 0 else { return false }
        return scores[index] == maxScore && scores.filter { $0 == maxScore }.count == 1
    }

    static func errorMessageKey(for error: Error, fallback: String) -> String {
        if let appError = error as? AppError {
            return appError.userMessageKey
        }
        return fallback
    }

    @MainActor
    static func undoLastDart(
        session: MatchLifecycleSession,
        matchId: UUID,
        store: ActiveMatchStore,
        matchRepository: any MatchRepository
    ) async throws -> UndoLastDartResult {
        let result = try MatchLifecycleService.undoLastDart(session: session)
        try await matchRepository.updateMatch(MatchTurnSupport.matchSummary(from: result.session.runtime))
        _ = try await matchRepository.saveSnapshot(
            matchId: matchId,
            snapshotVersion: result.session.latestSnapshot.payloadVersion,
            snapshotPayload: result.session.latestSnapshot.payload
        )
        store.save(result.session)
        return result
    }

    @MainActor
    static func undoLastTurn(
        session: MatchLifecycleSession,
        matchId: UUID,
        store: ActiveMatchStore,
        matchRepository: any MatchRepository
    ) async throws -> MatchLifecycleSession {
        let undone = try MatchLifecycleService.undoLastTurn(session: session)
        try await matchRepository.updateMatch(MatchTurnSupport.matchSummary(from: undone.runtime))
        _ = try await matchRepository.saveSnapshot(
            matchId: matchId,
            snapshotVersion: undone.latestSnapshot.payloadVersion,
            snapshotPayload: undone.latestSnapshot.payload
        )
        store.save(undone)
        return undone
    }
}

/// Runs the engine submit, persistence, store save, and standard logging shared by
/// both match view models. The caller maps the returned `Outcome` to its own state.
@MainActor
struct MatchTurnSubmitter {
    let matchId: UUID
    let matchType: MatchType
    /// Event type discriminator persisted with the appended turn (`x01Turn` / `cricketTurn`).
    let eventTypeRaw: String
    let store: ActiveMatchStore
    let logger: any AppLogger
    let matchRepository: any MatchRepository

    enum Outcome {
        /// The engine or persistence call was cancelled; restore the ready state.
        case cancelled
        /// The scoring engine rejected the visit; show the entry-invalid message.
        case rejected(messageKey: String)
        /// The accepted turn could not be persisted; surface a storage error.
        case persistFailed(messageKey: String)
        /// The turn was accepted, persisted, saved, and logged. Carries the updated session.
        case succeeded(MatchLifecycleSession)
    }

    /// - Parameters:
    ///   - current: The session the turn is applied to.
    ///   - invalidTurnFallbackKey: Message key used when a rejection error has no `AppError` mapping.
    ///   - engineSubmit: The mode-specific domain call producing the next session.
    func submitTurn(
        from current: MatchLifecycleSession,
        invalidTurnFallbackKey: String,
        engineSubmit: () throws -> MatchLifecycleSession
    ) async -> Outcome {
        let updated: MatchLifecycleSession
        do {
            updated = try PerformanceMonitor.measure(
                .submitTurn,
                logger: logger,
                metadata: ["matchType": matchType.rawValue]
            ) {
                try engineSubmit()
            }
        } catch is CancellationError {
            return .cancelled
        } catch {
            logger.matchDebug(
                matchId: matchId,
                matchType: matchType,
                eventName: "turn_submit_rejected",
                message: "Turn rejected by scoring engine.",
                metadata: MatchTurnSupport.appErrorMetadata(for: error)
            )
            return .rejected(messageKey: MatchTurnSupport.errorMessageKey(for: error, fallback: invalidTurnFallbackKey))
        }

        do {
            try await persistProgress(updated)
        } catch is CancellationError {
            return .cancelled
        } catch {
            logger.matchError(
                matchId: matchId,
                matchType: matchType,
                category: .persistence,
                eventName: "turn_persist_failed",
                message: "Failed to persist submitted turn.",
                metadata: MatchTurnSupport.appErrorMetadata(for: error)
            )
            return .persistFailed(messageKey: MatchTurnSupport.errorMessageKey(for: error, fallback: "error.repository.storage"))
        }

        store.save(updated)
        logger.matchInfo(
            matchId: matchId,
            matchType: matchType,
            eventName: "turn_submitted",
            message: "Turn accepted and persisted.",
            metadata: MatchTurnSupport.matchProgressMetadata(for: updated)
        )
        if updated.runtime.status == .completed {
            logger.matchInfo(
                matchId: matchId,
                matchType: matchType,
                category: .appLifecycle,
                eventName: "match_completed",
                message: "Match completed.",
                metadata: MatchTurnSupport.matchProgressMetadata(for: updated)
            )
            logger.matchInfo(
                matchId: matchId,
                matchType: matchType,
                category: .appLifecycle,
                eventName: GameModeAnalytics.completedEventName,
                message: "User completed a game mode match.",
                metadata: MatchAnalytics.metadata(for: updated)
            )
        }
        return .succeeded(updated)
    }

    func persistProgress(_ current: MatchLifecycleSession) async throws {
        if let event = current.events.last, event.eventIndex >= 0 {
            let payload = try CodablePayloadCoder.encode(event)
            _ = try await matchRepository.appendEvent(
                matchId: matchId,
                eventTypeRaw: eventTypeRaw,
                eventPayload: payload
            )
        }
        _ = try await matchRepository.saveSnapshot(
            matchId: matchId,
            snapshotVersion: current.latestSnapshot.payloadVersion,
            snapshotPayload: current.latestSnapshot.payload
        )
        if current.runtime.status == .completed {
            _ = try await matchRepository.completeMatch(
                matchId: matchId,
                endedAt: current.runtime.endedAt ?? Date(),
                winnerPlayerId: current.runtime.winnerPlayerId
            )
        } else {
            try await matchRepository.updateMatch(MatchTurnSupport.matchSummary(from: current.runtime))
        }
    }
}

extension MatchRuntimeState {
    /// Participant matched by player id, falling back to participant id for guests.
    func participant(for playerId: UUID) -> MatchParticipant? {
        participants.first { ($0.playerId ?? $0.id) == playerId }
    }
}
