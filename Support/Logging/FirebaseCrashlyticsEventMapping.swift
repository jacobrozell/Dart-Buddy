import Foundation

public enum FirebaseCrashlyticsEventMapping {
    private static let errorDomain = "com.jacobrozell.DartBuddy.logger"

    private static let allowlistedLogEvents: Set<String> = [
        "bootstrap_store_open_failed",
        "match_start_failed",
        "turn_persist_failed",
        "match_session_load_failed",
        "play_home_load_failed",
        "active_match_lookup_failed",
        "active_match_replace_failed",
        "turn_undo_failed",
        "x01_abandon_failed",
        "cricket_abandon_failed",
        "settings_reset_failed"
    ]

    /// Stable NSError codes for Crashlytics grouping (documented in unit tests).
    static let eventCodes: [String: Int] = [
        "bootstrap_store_open_failed": 1001,
        "match_start_failed": 1002,
        "turn_persist_failed": 1003,
        "match_session_load_failed": 1004,
        "play_home_load_failed": 1005,
        "active_match_lookup_failed": 1006,
        "active_match_replace_failed": 1007,
        "turn_undo_failed": 1008,
        "x01_abandon_failed": 1009,
        "cricket_abandon_failed": 1010,
        "settings_reset_failed": 1011
    ]

    private static let allowlistedParameterKeys: Set<String> = AnalyticsMetadataKeys.crashlyticsParameters

    public static func nonFatalError(for entry: LogEntry, appVersion: String?) -> NSError? {
        guard entry.level >= .error,
              allowlistedLogEvents.contains(entry.eventName),
              let code = eventCodes[entry.eventName]
        else {
            return nil
        }

        var userInfo = sanitizedParameters(from: entry.metadata)
        userInfo["log_category"] = entry.category.rawValue
        userInfo["event_name"] = entry.eventName
        if let appVersion, !appVersion.isEmpty {
            userInfo["app_version"] = appVersion
        }

        return NSError(domain: errorDomain, code: code, userInfo: userInfo)
    }

    private static func sanitizedParameters(from metadata: [String: String]) -> [String: String] {
        FirebaseMetadataSanitizer.sanitize(metadata, allowedKeys: allowlistedParameterKeys)
    }
}
