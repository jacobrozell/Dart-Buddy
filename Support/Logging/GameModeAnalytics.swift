import Foundation

/// Product-health telemetry for which game modes users play.
///
/// Catalog-backed metadata keeps new shipped modes reportable without touching
/// analytics wiring — add a `GameModeCatalog` row and `MatchType` case.
enum GameModeAnalytics {
    static let playedEventName = "game_mode_played"
    static let completedEventName = "game_mode_completed"
    static let forfeitedEventName = "game_mode_forfeited"

    static func metadata(
        for matchType: MatchType,
        participantCount: Int? = nil,
        participants: [MatchParticipant]? = nil,
        status: MatchLifecycleStatus? = nil,
        extra: [String: String] = [:]
    ) -> [String: String] {
        var result = extra
        result["matchType"] = matchType.rawValue
        if let participantCount {
            result["participantCount"] = String(participantCount)
        }

        if let entry = GameModeCatalog.entry(for: matchType) {
            result["gameModeId"] = entry.id
            result["gameModeSection"] = entry.section.rawValue
            result["uiTemplate"] = entry.uiTemplate.rawValue
            result["statKind"] = entry.statKind.rawValue
        } else {
            result["gameModeId"] = matchType.rawValue
        }

        if let status {
            result["status"] = status.rawValue
        }

        if let participants {
            result.merge(BotAnalytics.metadata(for: participants)) { _, new in new }
        }

        return AnalyticsMetadataKeys.withoutPersonalData(result)
    }
}
