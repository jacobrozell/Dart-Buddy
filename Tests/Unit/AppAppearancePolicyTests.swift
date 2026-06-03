import Testing
@testable import DartBuddy

@Test(.tags(.unit, .settings, .regression))
func appearancePolicySettingsBrandPaletteWhenNotLight() {
    #expect(AppAppearancePolicy.settingsUsesBrandPalette(appearanceModeRaw: "dark"))
    #expect(AppAppearancePolicy.settingsUsesBrandPalette(appearanceModeRaw: "system"))
    #expect(!AppAppearancePolicy.settingsUsesBrandPalette(appearanceModeRaw: "light"))
}

@Test(.tags(.unit, .settings, .regression))
func appearancePolicySettingsColorSchemeFollowsLightChoice() {
    #expect(AppAppearancePolicy.settingsColorScheme(appearanceModeRaw: "light") == .light)
    #expect(AppAppearancePolicy.settingsColorScheme(appearanceModeRaw: "dark") == .dark)
    #expect(AppAppearancePolicy.settingsColorScheme(appearanceModeRaw: "system") == .dark)
}

@Test(.tags(.unit, .settings, .regression))
func appearancePolicyColorSchemeMatchesAppearanceRaw() {
    #expect(AppAppearancePolicy.colorScheme(for: "light") == .light)
    #expect(AppAppearancePolicy.colorScheme(for: "dark") == .dark)
    #expect(AppAppearancePolicy.colorScheme(for: "system") == nil)
}
