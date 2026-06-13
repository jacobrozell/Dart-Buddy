import Foundation

public struct LocalFeatureFlagsProvider: FeatureFlagsProvider {
    private let overrides: [FeatureFlag: Bool]
    private let arguments: [String]

    public init(
        overrides: [FeatureFlag: Bool] = [:],
        arguments: [String] = ProcessInfo.processInfo.arguments
    ) {
        self.overrides = overrides
        self.arguments = arguments
    }

    public func isEnabled(_ flag: FeatureFlag) -> Bool {
        if let override = overrides[flag] {
            return override
        }
        return Self.defaultValue(for: flag, arguments: arguments)
    }

    public static func defaultValue(for flag: FeatureFlag, arguments: [String]) -> Bool {
        switch flag {
        case .enableFirebaseAnalytics:
            if arguments.contains("-disable_firebase_analytics") || arguments.contains("-ui_test_reset") {
                return false
            }
            if arguments.contains("-firebase_analytics_debug") {
                return true
            }
            #if DEBUG
            return false
            #else
            return true
            #endif
        case .enableFirebaseCrashlytics:
            if arguments.contains("-disable_firebase_analytics") || arguments.contains("-ui_test_reset") {
                return false
            }
            if arguments.contains("-firebase_analytics_debug") {
                return true
            }
            #if DEBUG
            return false
            #else
            return true
            #endif
        case .enableAppleWatchCompanion,
             .enableOnlinePlay,
             .enableAdvancedDiagnostics:
            return false
        case .enableCampaign:
            if arguments.contains("-enable_campaign") {
                return true
            }
            return false
        case .enableDailyChallenge:
            if arguments.contains("-enable_daily_challenge") {
                return true
            }
            return false
        case .enableLocalTournaments:
            if arguments.contains("-enable_local_tournaments") {
                return true
            }
            return false
        case .enableOnlineTournaments:
            if arguments.contains("-enable_online_tournaments") {
                return true
            }
            return false
        case .enableVisionAutoScoring:
            // Phase A camera scoring. On dev/Debug builds, on by default for dogfood; opt out with `-ui_test_reset`.
            if arguments.contains("-enable_vision_scoring") {
                return true
            }
            if arguments.contains("-ui_test_reset") {
                return false
            }
            #if DEBUG
            return true
            #else
            return false
            #endif
        case .enableAppIntents:
            if arguments.contains("-enable_app_intents") {
                return true
            }
            if arguments.contains("-ui_test_reset") {
                return false
            }
            #if DEBUG
            return true
            #else
            return false
            #endif
        case .enableAchievements:
            if arguments.contains("-enable_achievements") {
                return true
            }
            return false
        }
    }
}
