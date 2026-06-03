import SwiftUI

/// Centralizes how the global theme picker maps to scoreboard vs settings chrome.
enum AppAppearancePolicy {
    static func colorScheme(for appearanceModeRaw: String) -> ColorScheme? {
        switch appearanceModeRaw {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }

    /// Settings uses native grouped styling only when the user explicitly chooses Light.
    static func settingsUsesBrandPalette(appearanceModeRaw: String) -> Bool {
        appearanceModeRaw != "light"
    }

    static func settingsColorScheme(appearanceModeRaw: String) -> ColorScheme? {
        settingsUsesBrandPalette(appearanceModeRaw: appearanceModeRaw) ? .dark : .light
    }
}
