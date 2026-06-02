import SwiftUI

/// Centralizes how the global theme picker maps to scoreboard vs settings chrome.
enum AppAppearancePolicy {
    /// Gameplay and data tabs always use the reference dark scoreboard palette.
    static let scoreboardColorScheme: ColorScheme = .dark

    /// Settings uses brand styling whenever the user has not explicitly chosen Light.
    static func settingsUsesBrandPalette(appearanceModeRaw: String) -> Bool {
        appearanceModeRaw != "light"
    }

    static func colorScheme(for appearanceModeRaw: String) -> ColorScheme? {
        switch appearanceModeRaw {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }

    static func settingsColorScheme(appearanceModeRaw: String) -> ColorScheme? {
        settingsUsesBrandPalette(appearanceModeRaw: appearanceModeRaw) ? .dark : .light
    }
}
