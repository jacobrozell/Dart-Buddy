import Testing
@testable import DartBuddy

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

@Test(.tags(.unit, .regression))
func appIntentsEnabledOnDevDebugBuilds() {
    let provider = LocalFeatureFlagsProvider(arguments: ["-ui_test_reset"])
    #expect(!provider.isEnabled(.enableAppIntents))

    #if DEBUG
    let devProvider = LocalFeatureFlagsProvider(arguments: [])
    #expect(devProvider.isEnabled(.enableAppIntents))
    #else
    let releaseProvider = LocalFeatureFlagsProvider(arguments: [])
    #expect(!releaseProvider.isEnabled(.enableAppIntents))
    #endif
}

@Test(.tags(.unit, .regression))
func appIntentsEnabledWithLaunchArgument() {
    let provider = LocalFeatureFlagsProvider(arguments: ["-enable_app_intents"])
    #expect(provider.isEnabled(.enableAppIntents))
}

@Test(.tags(.unit, .regression))
func visionAutoScoringEnabledOnDevDebugBuilds() {
    let provider = LocalFeatureFlagsProvider(arguments: ["-ui_test_reset"])
    #expect(!provider.isEnabled(.enableVisionAutoScoring))

    #if DEBUG
    let devProvider = LocalFeatureFlagsProvider(arguments: [])
    #expect(devProvider.isEnabled(.enableVisionAutoScoring))
    #else
    let releaseProvider = LocalFeatureFlagsProvider(arguments: [])
    #expect(!releaseProvider.isEnabled(.enableVisionAutoScoring))
    #endif
}

@Test(.tags(.unit, .regression))
func visionAutoScoringEnabledWithLaunchArgument() {
    let provider = LocalFeatureFlagsProvider(arguments: ["-enable_vision_scoring"])
    #expect(provider.isEnabled(.enableVisionAutoScoring))
}
