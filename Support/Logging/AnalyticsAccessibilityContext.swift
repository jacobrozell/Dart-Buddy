import FirebaseAnalytics
import Foundation

/// User-scoped accessibility signals for product-health segmentation.
///
/// Coarse booleans and buckets only — never assistive-tech transcripts or personal data.
@MainActor
public enum AnalyticsAccessibilityContext {
    public static func userPropertyValues(from snapshot: ClientEnvironmentSnapshot) -> [String: String] {
        [
            "voiceover_enabled": boolString(snapshot.isVoiceOverRunning),
            "switch_control_enabled": boolString(snapshot.isSwitchControlRunning),
            "content_size_category": snapshot.contentSizeCategory,
            "reduce_motion_enabled": boolString(snapshot.isReduceMotionEnabled),
            "bold_text_enabled": boolString(snapshot.isBoldTextEnabled)
        ]
    }

    public static func sync(from snapshot: ClientEnvironmentSnapshot = ClientEnvironment.snapshot) {
        guard FirebaseBootstrap.shouldConfigure, FirebaseBootstrap.isAnalyticsCollectionEnabled else { return }

        for (name, value) in userPropertyValues(from: snapshot) {
            Analytics.setUserProperty(value, forName: name)
        }
    }

    private static func boolString(_ value: Bool) -> String {
        value ? "true" : "false"
    }
}
