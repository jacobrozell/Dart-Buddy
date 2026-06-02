import Foundation

public enum FirebaseBootstrap {
    private static let featureFlags = LocalFeatureFlagsProvider()

    /// Skip Firebase when the bundled plist is still the checked-in placeholder (CI, fresh clones).
    public static var shouldConfigure: Bool {
        guard
            let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
            let plist = NSDictionary(contentsOfFile: path),
            let appID = plist["GOOGLE_APP_ID"] as? String
        else {
            return false
        }
        return !appID.contains("REPLACE_WITH")
    }

    public static var isAnalyticsCollectionEnabled: Bool {
        shouldConfigure && featureFlags.isEnabled(.enableFirebaseAnalytics)
    }
}
