import SwiftUI

/// Thread-safe feedback toggles shared between settings UI and gated feedback services.
public final class FeedbackPreferences: @unchecked Sendable {
    public var hapticsEnabled = true
    public var soundEnabled = true
}

@MainActor
public final class UserPreferencesStore: ObservableObject {
    @Published private(set) var preferredColorScheme: ColorScheme?
    let feedback = FeedbackPreferences()

    func apply(_ settings: SettingsSummary) {
        preferredColorScheme = Self.colorScheme(for: settings.appearanceModeRaw)
        feedback.hapticsEnabled = settings.hapticsEnabled
        feedback.soundEnabled = settings.soundEnabled
    }

    static func colorScheme(for raw: String) -> ColorScheme? {
        switch raw {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }
}
