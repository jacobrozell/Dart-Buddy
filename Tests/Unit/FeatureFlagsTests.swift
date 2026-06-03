import Testing
@testable import DartsScoreboard

@Test(.tags(.unit, .regression))
func firebaseAnalyticsDisabledForUITestResetArgument() {
    let provider = LocalFeatureFlagsProvider(arguments: ["-ui_test_reset"])
    #expect(!provider.isEnabled(.enableFirebaseAnalytics))
}

@Test(.tags(.unit, .regression))
func firebaseAnalyticsEnabledWithDebugLaunchArgument() {
    let provider = LocalFeatureFlagsProvider(arguments: ["-firebase_analytics_debug"])
    #expect(provider.isEnabled(.enableFirebaseAnalytics))
}

@Test(.tags(.unit, .regression))
func firebaseAnalyticsOverrideHonored() {
    let provider = LocalFeatureFlagsProvider(overrides: [.enableFirebaseAnalytics: false])
    #expect(!provider.isEnabled(.enableFirebaseAnalytics))
}

@Test(.tags(.unit, .regression))
func crashlyticsRemainsDisabledByDefault() {
    let provider = LocalFeatureFlagsProvider(arguments: [])
    #expect(!provider.isEnabled(.enableFirebaseCrashlytics))
}

@Test(.tags(.unit, .regression))
func crashlyticsDisabledForUITestResetArgument() {
    let provider = LocalFeatureFlagsProvider(arguments: ["-ui_test_reset"])
    #expect(!provider.isEnabled(.enableFirebaseCrashlytics))
}

@Test(.tags(.unit, .regression))
func crashlyticsEnabledWithDebugLaunchArgument() {
    let provider = LocalFeatureFlagsProvider(arguments: ["-firebase_analytics_debug"])
    #expect(provider.isEnabled(.enableFirebaseCrashlytics))
}

@Test(.tags(.unit, .regression))
func crashlyticsHonorsDisableFirebaseAnalyticsArgument() {
    let provider = LocalFeatureFlagsProvider(arguments: ["-disable_firebase_analytics"])
    #expect(!provider.isEnabled(.enableFirebaseCrashlytics))
}
