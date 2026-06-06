import SwiftUI

private struct BrandScoreboardChrome: ViewModifier {
    let appearanceModeRaw: String

    func body(content: Content) -> some View {
        content
            .preferredColorScheme(AppAppearancePolicy.colorScheme(for: appearanceModeRaw))
            .background(Brand.background.ignoresSafeArea())
    }
}

private struct BrandSettingsScreenChrome: ViewModifier {
    let appearanceModeRaw: String

    private var usesBrandPalette: Bool {
        AppAppearancePolicy.settingsUsesBrandPalette(appearanceModeRaw: appearanceModeRaw)
    }

    func body(content: Content) -> some View {
        content
            .preferredColorScheme(AppAppearancePolicy.settingsColorScheme(appearanceModeRaw: appearanceModeRaw))
            .background(screenBackground.ignoresSafeArea())
            .legacyOpaqueSettingsNavigationBarBackground(screenBackground)
            .toolbarColorScheme(usesBrandPalette ? .dark : .light, for: .navigationBar)
    }

    private var screenBackground: Color {
        usesBrandPalette
            ? Brand.background
            : Color(uiColor: .systemGroupedBackground)
    }
}

private struct BrandSettingsFormChrome: ViewModifier {
    let appearanceModeRaw: String

    private var usesBrandPalette: Bool {
        AppAppearancePolicy.settingsUsesBrandPalette(appearanceModeRaw: appearanceModeRaw)
    }

    func body(content: Content) -> some View {
        if usesBrandPalette {
            content.scrollContentBackground(.hidden)
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

    func brandSettingsScreenChrome(appearanceModeRaw: String) -> some View {
        modifier(BrandSettingsScreenChrome(appearanceModeRaw: appearanceModeRaw))
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
