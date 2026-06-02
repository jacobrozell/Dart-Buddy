import SwiftUI

/// Thread-safe feedback toggles shared between settings UI and gated feedback services.
public final class FeedbackPreferences: @unchecked Sendable {
    public var hapticsEnabled = true
    public var soundEnabled = true
    public var turnTotalCallerEnabled = false
}

@MainActor
public final class UserPreferencesStore: ObservableObject {
    @Published private(set) var preferredColorScheme: ColorScheme?
    let feedback = FeedbackPreferences()

    func apply(_ settings: SettingsSummary) {
        preferredColorScheme = AppAppearancePolicy.colorScheme(for: settings.appearanceModeRaw)
        feedback.hapticsEnabled = settings.hapticsEnabled
        feedback.soundEnabled = settings.soundEnabled
        feedback.turnTotalCallerEnabled = settings.turnTotalCallerEnabled
    }
}
