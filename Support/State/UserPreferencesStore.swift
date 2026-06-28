import SwiftUI

extension Notification.Name {
    /// Posted after persisted settings are saved and applied to `UserPreferencesStore`.
    static let settingsDidUpdate = Notification.Name("dartBuddy.settingsDidUpdate")
}

/// Thread-safe feedback toggles shared between settings UI and gated feedback services.
public final class FeedbackPreferences: @unchecked Sendable {
    public var hapticsEnabled = true
    public var soundEnabled = true
    public var turnTotalCallerEnabled = false
    public var botStaggerEnabled = true
    public var botDartHapticsEnabled = true
    public var instantBotTurnsEnabled = false
}

@MainActor
public final class UserPreferencesStore: ObservableObject {
    @Published private(set) var appearanceModeRaw = "system"
    @Published private(set) var preferredColorScheme: ColorScheme?
    @Published private(set) var defaultDartEntryPresentation: DartEntryPresentation = .default
    let feedback = FeedbackPreferences()

    func apply(_ settings: SettingsSummary) {
        appearanceModeRaw = settings.appearanceModeRaw
        preferredColorScheme = AppAppearancePolicy.colorScheme(for: settings.appearanceModeRaw)
        defaultDartEntryPresentation = DartEntryPresentation(
            rawValueOrDefault: settings.defaultDartEntryPresentationRaw
        )
        feedback.hapticsEnabled = settings.hapticsEnabled
        feedback.soundEnabled = settings.soundEnabled
        feedback.turnTotalCallerEnabled = settings.turnTotalCallerEnabled
        feedback.botStaggerEnabled = settings.botStaggerEnabled
        feedback.botDartHapticsEnabled = settings.botDartHapticsEnabled
        feedback.instantBotTurnsEnabled = settings.instantBotTurnsEnabled
        AnalyticsUserContext.syncAfterSettingsApply(settings)
    }
}
