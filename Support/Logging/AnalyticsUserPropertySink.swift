import FirebaseAnalytics
import Foundation

/// Allowlisted Firebase Analytics user-property writes.
///
/// Match-complete and settings sync paths must not call `Analytics.setUserProperty`
/// directly — route through this sink so names stay privacy-reviewed.
enum AnalyticsUserPropertySink {
    static let allowlistedNames: Set<String> = [
        "last_match_type",
        "last_game_mode_id",
        "last_game_mode_section",
        "onboarding_complete",
        "app_locale",
        "product_surface",
        "build_number",
        "appearance_mode",
        "haptics_enabled",
        "sound_enabled",
        "turn_caller_enabled",
        "bot_stagger_enabled",
        "bot_dart_haptics_enabled",
        "dart_entry_default",
        "default_match_type",
        "voiceover_enabled",
        "switch_control_enabled",
        "content_size_category",
        "reduce_motion_enabled",
        "bold_text_enabled"
    ]

    static func set(_ value: String?, forName name: String) {
        guard allowlistedNames.contains(name) else { return }
        guard FirebaseBootstrap.shouldConfigure, FirebaseBootstrap.isAnalyticsCollectionEnabled else { return }
        Analytics.setUserProperty(value, forName: name)
    }

    static func setAll(_ values: [String: String]) {
        for (name, value) in values {
            set(value, forName: name)
        }
    }
}
