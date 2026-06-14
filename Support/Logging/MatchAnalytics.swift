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

    static func resumeMetadata(
        for match: MatchSummary,
        startSource: MatchStartSource
    ) -> [String: String] {
        var result = GameModeAnalytics.metadata(
            for: match.type,
            participantCount: 0
        )
        result["startSource"] = startSource.rawValue
        result["status"] = match.status.rawValue
        return result
    }

    static func logResumed(
        logger: any AppLogger,
        match: MatchSummary,
        startSource: MatchStartSource
    ) {
        logger.info(
            .ui,
            eventName: resumedEventName,
            message: "User resumed an in-progress match.",
            metadata: resumeMetadata(for: match, startSource: startSource),
            correlationId: match.id.uuidString
        )
    }
}
