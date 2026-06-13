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
    /// Local profile achievements. Default on in Debug / `dev`; opt in on Release with `-enable_achievements`. See `specs/AchievementsSpec.md`.
    case enableAchievements
    /// Journey / campaign tab. Spec-only until `Features/Campaign/` ships. See `specs/CampaignSpec.md`.
    case enableCampaign
    /// Daily challenge hub. Spec-only until service ships. See `specs/DailyChallengeSpec.md`.
    case enableDailyChallenge
    /// Local bracket tournaments. Spec-only until hub ships. See `specs/TournamentSpec.md`.
    case enableLocalTournaments
    /// Online bracket tournaments. Requires `enableOnlinePlay`. See `specs/TournamentSpec.md`.
    case enableOnlineTournaments
}
