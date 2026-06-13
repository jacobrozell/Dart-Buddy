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
func appIntentsDisabledByDefault() {
    let provider = LocalFeatureFlagsProvider(arguments: [])
    #expect(!provider.isEnabled(.enableAppIntents))
}

@Test(.tags(.unit, .regression))
func appIntentsEnabledWithLaunchArgument() {
    let provider = LocalFeatureFlagsProvider(arguments: ["-enable_app_intents"])
    #expect(provider.isEnabled(.enableAppIntents))
}

@Test(.tags(.unit, .regression))
func visionAutoScoringDisabledByDefault() {
    let provider = LocalFeatureFlagsProvider(arguments: [])
    #expect(!provider.isEnabled(.enableVisionAutoScoring))
}

@Test(.tags(.unit, .regression))
func visionAutoScoringEnabledWithLaunchArgument() {
    let provider = LocalFeatureFlagsProvider(arguments: ["-enable_vision_scoring"])
    #expect(provider.isEnabled(.enableVisionAutoScoring))
}

@Test(.tags(.unit, .regression))
func visualDartboardInputDisabledByDefault() {
    let provider = LocalFeatureFlagsProvider(arguments: [])
    #expect(!provider.isEnabled(.enableVisualDartboardInput))
}

@Test(.tags(.unit, .regression))
func visualDartboardInputEnabledWithLaunchArgument() {
    let provider = LocalFeatureFlagsProvider(arguments: ["-enable_visual_dartboard"])
    #expect(provider.isEnabled(.enableVisualDartboardInput))
}

@Test(.tags(.unit, .regression))
func achievementsDisabledByDefault() {
    let provider = LocalFeatureFlagsProvider(arguments: ["-ui_test_reset"])
    #expect(!provider.isEnabled(.enableAchievements))

    #if DEBUG
    let devProvider = LocalFeatureFlagsProvider(arguments: [])
    #expect(devProvider.isEnabled(.enableAchievements))
    #else
    let releaseProvider = LocalFeatureFlagsProvider(arguments: [])
    #expect(!releaseProvider.isEnabled(.enableAchievements))
    #endif
}

@Test(.tags(.unit, .regression))
func achievementsEnabledWithLaunchArgument() {
    let provider = LocalFeatureFlagsProvider(arguments: ["-enable_achievements"])
    #expect(provider.isEnabled(.enableAchievements))
}

@Test(.tags(.unit, .regression))
func plannedFeatureFlagsDisabledByDefault() {
    let provider = LocalFeatureFlagsProvider(arguments: [])
    #expect(!provider.isEnabled(.enableCampaign))
    #expect(!provider.isEnabled(.enableDailyChallenge))
    #expect(!provider.isEnabled(.enableLocalTournaments))
    #expect(!provider.isEnabled(.enableOnlineTournaments))
}
