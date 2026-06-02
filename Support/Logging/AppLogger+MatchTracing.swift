import Foundation

public extension AppLogger {
    func logMatch(
        _ level: LogLevel,
        matchId: UUID,
        matchType: MatchType,
        category: LogCategory = .scoring,
        eventName: String,
        message: String,
        metadata: [String: String]? = nil
    ) {
        var merged = metadata ?? [:]
        merged["matchId"] = matchId.uuidString
        merged["matchType"] = matchType.rawValue
        log(
            level: level,
            category: category,
            eventName: eventName,
            message: message,
            metadata: merged,
            correlationId: matchId.uuidString
        )
    }

    func matchDebug(
        matchId: UUID,
        matchType: MatchType,
        category: LogCategory = .scoring,
        eventName: String,
        message: String,
        metadata: [String: String]? = nil
    ) {
        logMatch(.debug, matchId: matchId, matchType: matchType, category: category, eventName: eventName, message: message, metadata: metadata)
    }

    func matchInfo(
        matchId: UUID,
        matchType: MatchType,
        category: LogCategory = .scoring,
        eventName: String,
        message: String,
        metadata: [String: String]? = nil
    ) {
        logMatch(.info, matchId: matchId, matchType: matchType, category: category, eventName: eventName, message: message, metadata: metadata)
    }

    func matchWarning(
        matchId: UUID,
        matchType: MatchType,
        category: LogCategory = .scoring,
        eventName: String,
        message: String,
        metadata: [String: String]? = nil
    ) {
        logMatch(.warning, matchId: matchId, matchType: matchType, category: category, eventName: eventName, message: message, metadata: metadata)
    }

    func matchError(
        matchId: UUID,
        matchType: MatchType,
        category: LogCategory = .scoring,
        eventName: String,
        message: String,
        metadata: [String: String]? = nil
    ) {
        logMatch(.error, matchId: matchId, matchType: matchType, category: category, eventName: eventName, message: message, metadata: metadata)
    }
}
