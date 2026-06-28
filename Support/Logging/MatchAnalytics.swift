import Foundation

/// Composes catalog, roster, config, and entry-source metadata for match telemetry.
enum MatchAnalytics {
    static let resumedEventName = "match_resumed"

    static func metadata(
        for matchType: MatchType,
        config: MatchConfigPayload,
        participantCount: Int,
        participants: [MatchParticipant]? = nil,
        startSource: MatchStartSource? = nil,
        status: MatchLifecycleStatus? = nil,
        extra: [String: String] = [:]
    ) -> [String: String] {
        var result = GameModeAnalytics.metadata(
            for: matchType,
            participantCount: participantCount,
            participants: participants,
            status: status,
            extra: extra
        )
        result.merge(MatchConfigAnalytics.metadata(for: config)) { _, new in new }
        if let startSource {
            result["startSource"] = startSource.rawValue
        }
        return result
    }

    static func metadata(
        for session: MatchLifecycleSession,
        startSource: MatchStartSource? = nil,
        extra: [String: String] = [:]
    ) -> [String: String] {
        metadata(
            for: session.runtime.type,
            config: session.runtime.config,
            participantCount: session.runtime.participants.count,
            participants: session.runtime.participants,
            startSource: startSource,
            status: session.runtime.status,
            extra: extra.merging(MatchTurnSupport.matchProgressMetadata(for: session)) { _, new in new }
        )
    }

    static func forfeitMetadata(
        for session: MatchLifecycleSession,
        resolution: String,
        durationSeconds: Int
    ) -> [String: String] {
        var metadata = metadata(for: session)
        metadata["durationSeconds"] = String(durationSeconds)
        metadata["resolution"] = resolution
        return metadata
    }

    static func resumeMetadata(
        for match: MatchSummary,
        startSource: MatchStartSource,
        session: MatchLifecycleSession? = nil
    ) -> [String: String] {
        if let session, session.runtime.matchId == match.id {
            return metadata(for: session, startSource: startSource)
        }

        var result = GameModeAnalytics.metadata(
            for: match.type,
            status: MatchLifecycleStatus(rawValue: match.status.rawValue)
        )
        result["startSource"] = startSource.rawValue
        if match.eventCount > 0 {
            result["eventCount"] = String(match.eventCount)
        }
        return result
    }

    static func logResumed(
        logger: any AppLogger,
        match: MatchSummary,
        startSource: MatchStartSource,
        session: MatchLifecycleSession? = nil
    ) {
        let metadata = resumeMetadata(for: match, startSource: startSource, session: session)
        logger.info(
            .ui,
            eventName: resumedEventName,
            message: "User resumed an in-progress match.",
            metadata: metadata,
            correlationId: match.id.uuidString
        )
        logger.info(
            .scoring,
            eventName: GameModeAnalytics.playedEventName,
            message: "User resumed playing a game mode.",
            metadata: metadata,
            correlationId: match.id.uuidString
        )
        AnalyticsUserIdentity.syncLastGameMode(for: match.type)
    }

    static func logGameModePlayed(
        logger: any AppLogger,
        matchType: MatchType,
        metadata: [String: String],
        correlationId: String
    ) {
        logger.info(
            .scoring,
            eventName: GameModeAnalytics.playedEventName,
            message: "User started playing a game mode.",
            metadata: metadata,
            correlationId: correlationId
        )
        AnalyticsUserIdentity.syncLastGameMode(for: matchType)
    }
}
