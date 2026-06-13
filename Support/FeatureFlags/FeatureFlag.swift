import Foundation

public enum FeatureFlag: String, CaseIterable, Sendable {
    case enableFirebaseAnalytics
    case enableFirebaseCrashlytics
    case enableAppleWatchCompanion
    case enableVisionAutoScoring
    case enableOnlinePlay
    case enableAdvancedDiagnostics
    /// Siri/Shortcuts integration. Default off until QA; enable locally with `-enable_app_intents`. See `specs/AppIntentsSpec.md`.
    case enableAppIntents
    /// Local profile achievements. Default off; enable with `-enable_achievements`. See `specs/AchievementsSpec.md`.
    case enableAchievements
    /// Tappable visual dartboard scoring input. Default off; enable with `-enable_visual_dartboard`.
    case enableVisualDartboardInput
}
