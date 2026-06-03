import SwiftUI

private struct BrandScoreboardChrome: ViewModifier {
    let appearanceModeRaw: String

    func body(content: Content) -> some View {
        content
            .preferredColorScheme(AppAppearancePolicy.colorScheme(for: appearanceModeRaw))
            .background(Brand.background.ignoresSafeArea())
    }
}

private struct BrandSettingsNavigationChrome: ViewModifier {
    let appearanceModeRaw: String

    private var usesBrandPalette: Bool {
        AppAppearancePolicy.settingsUsesBrandPalette(appearanceModeRaw: appearanceModeRaw)
    }

    func body(content: Content) -> some View {
        if usesBrandPalette {
            content
                .preferredColorScheme(AppAppearancePolicy.settingsColorScheme(appearanceModeRaw: appearanceModeRaw))
                .toolbarBackground(Brand.background, for: .navigationBar)
                .toolbarBackground(.visible, for: .navigationBar)
                .toolbarColorScheme(.dark, for: .navigationBar)
        } else {
            content
        }
    }
}

private struct BrandSettingsFormChrome: ViewModifier {
    let appearanceModeRaw: String

    private var usesBrandPalette: Bool {
        AppAppearancePolicy.settingsUsesBrandPalette(appearanceModeRaw: appearanceModeRaw)
    }

    func body(content: Content) -> some View {
        if usesBrandPalette {
            content
                .scrollContentBackground(.hidden)
                .background(Brand.background.ignoresSafeArea())
        } else {
            content
        }
    }
}

extension View {
    /// Styles `ContentUnavailableView` for scoreboard tabs on `Brand.background`.
    func brandScoreboardEmptyState() -> some View {
        foregroundStyle(Brand.textPrimary)
    }

    @ViewBuilder
    func brandScoreboardEmptyState(when applies: Bool) -> some View {
        if applies {
            brandScoreboardEmptyState()
        } else {
            self
        }
    }

    func brandScoreboardChrome(appearanceModeRaw: String) -> some View {
        modifier(BrandScoreboardChrome(appearanceModeRaw: appearanceModeRaw))
    }

    func brandSettingsNavigationChrome(appearanceModeRaw: String) -> some View {
        modifier(BrandSettingsNavigationChrome(appearanceModeRaw: appearanceModeRaw))
    }

    func brandSettingsFormChrome(appearanceModeRaw: String) -> some View {
        modifier(BrandSettingsFormChrome(appearanceModeRaw: appearanceModeRaw))
    }

    @ViewBuilder
    func brandFormRowBackground(when usesBrandPalette: Bool) -> some View {
        if usesBrandPalette {
            listRowBackground(Brand.card)
        } else {
            self
        }
    }
}
