import SwiftUI

/// Centralizes iOS 26 Liquid Glass navigation policy so feature screens avoid scattered `#available` checks.
enum SystemNavigationPolicy {
    /// When true, system tab bars and navigation toolbars use Liquid Glass; do not override with opaque toolbar backgrounds.
    static var usesSystemLiquidGlassNav: Bool {
        if #available(iOS 26, *) { return true }
        return false
    }
}

extension View {
    /// Pre-iOS 26 settings used an opaque toolbar fill matching the screen background.
    @ViewBuilder
    func legacyOpaqueSettingsNavigationBarBackground(_ color: Color) -> some View {
        if SystemNavigationPolicy.usesSystemLiquidGlassNav {
            self
        } else {
            self
                .toolbarBackground(color, for: .navigationBar)
                .toolbarBackground(.visible, for: .navigationBar)
        }
    }

    /// Pre-iOS 26 onboarding hid the navigation bar background over full-bleed step chrome.
    @ViewBuilder
    func legacyHiddenNavigationBarBackground() -> some View {
        if SystemNavigationPolicy.usesSystemLiquidGlassNav {
            self
        } else {
            self.toolbarBackground(.hidden, for: .navigationBar)
        }
    }
}
