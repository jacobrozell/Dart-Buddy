import Foundation

public struct FirebaseAnalyticsEvent: Equatable, Sendable {
    public let name: String
    public let parameters: [String: String]

    public init(name: String, parameters: [String: String]) {
        self.name = name
        self.parameters = parameters
    }
}

public enum FirebaseAnalyticsEventMapping {
    private static let allowlistedLogEvents: Set<String> = [
        "app_bootstrap_ready",
        "main_tab_presented",
        "play_home_ready",
        "play_home_active_match",
        "match_setup_start",
        "match_started",
        "game_mode_played",
        "game_mode_completed",
        "match_resumed",
        "match_setup_baseball",
        "match_screen_appeared",
        "match_completed",
        "turn_submitted",
        "turn_undone",
        "dart_undone",
        "match_abandoned",
        "match_forfeited",
        "match_forfeit_failed",
        "match_start_failed",
        "turn_persist_failed",
        "bootstrap_store_open_failed",
        "deep_link_received",
        "deep_link_applied",
        "deep_link_deferred",
        "deep_link_failed",
        "intent_performed",
        "intent_failed",
        "client_environment_changed",
        "onboarding_completed"
    ]

    private static let allowlistedParameterKeys: Set<String> = AnalyticsMetadataKeys.firebaseParameters

    private static let firebaseNameOverrides: [String: String] = [
        "app_bootstrap_ready": "app_open",
        "turn_undone": "undo_used",
        "dart_undone": "undo_used"
    ]

    public static func map(_ entry: LogEntry, appVersion: String?) -> FirebaseAnalyticsEvent? {
        guard allowlistedLogEvents.contains(entry.eventName) else {
            return nil
        }

        var parameters = sanitizedParameters(from: entry.metadata)
        if let appVersion, !appVersion.isEmpty {
            parameters["app_version"] = appVersion
        }
        parameters["log_category"] = entry.category.rawValue

        let firebaseName = firebaseNameOverrides[entry.eventName] ?? entry.eventName
        return FirebaseAnalyticsEvent(name: firebaseName, parameters: parameters)
    }

    private static func sanitizedParameters(from metadata: [String: String]) -> [String: String] {
        metadata.reduce(into: [:]) { result, pair in
            guard allowlistedParameterKeys.contains(pair.key) else { return }
            let value = String(pair.value.prefix(100))
            guard !value.isEmpty else { return }
            result[pair.key] = value
        }
    }
}
