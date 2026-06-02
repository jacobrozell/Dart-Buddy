import SwiftUI

private struct BrandScoreboardChrome: ViewModifier {
    func body(content: Content) -> some View {
        content
            .preferredColorScheme(AppAppearancePolicy.scoreboardColorScheme)
            .background(Brand.background.ignoresSafeArea())
    }
}

private struct BrandSettingsChrome: ViewModifier {
    let usesBrandPalette: Bool

    func body(content: Content) -> some View {
        if usesBrandPalette {
            content
                .scrollContentBackground(.hidden)
                .background(Brand.background.ignoresSafeArea())
                .preferredColorScheme(.dark)
                .toolbarBackground(Brand.background, for: .navigationBar)
                .toolbarBackground(.visible, for: .navigationBar)
                .toolbarColorScheme(.dark, for: .navigationBar)
        } else {
            content
        }
    }
}

extension View {
    func brandScoreboardChrome() -> some View {
        modifier(BrandScoreboardChrome())
    }

    func brandSettingsChrome(appearanceModeRaw: String) -> some View {
        modifier(BrandSettingsChrome(
            usesBrandPalette: AppAppearancePolicy.settingsUsesBrandPalette(appearanceModeRaw: appearanceModeRaw)
        ))
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
