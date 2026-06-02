import Foundation

public enum FeatureFlag: String, CaseIterable, Sendable {
    case enableFirebaseAnalytics
    case enableFirebaseCrashlytics
    case enableAppleWatchCompanion
    case enableVisionAutoScoring
    case enableOnlinePlay
    case enableAdvancedDiagnostics
}
