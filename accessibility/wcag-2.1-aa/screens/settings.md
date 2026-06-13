# Settings

| Field | Value |
|-------|-------|
| Screen ID | `settings` |
| Primary source | `Features/Settings/SettingsRootView.swift` |
| Core flow | No (tab) |
| Last verified | 2026-06-06 |
| Screen status | `Partial` |

## Criterion checklist

| ID | Status | Implementation notes | Evidence |
|----|--------|----------------------|----------|
| P-1.1.1 | Pass | Form controls standard | |
| P-1.3.1 | Pass | `Form` / `Section` (Appearance, Starting Mode, Match Defaults, X01 Defaults, During Play, Bot Opponents, Data, Help & Feedback, About) | |
| P-1.3.2 | Untested | | |
| P-1.3.4 | Pass | iPad max width 760; Form scrolls in landscape | `SettingsUITests.testSettingsControlsReachableInLandscape` |
| P-1.4.1 | Pass | | |
| P-1.4.3 | Partial | Light form vs dark tabs; Increase Contrast + Reduce Transparency audits | `WCAGAccessibilityUITests` contrast / reduce-transparency settings tests |
| P-1.4.4 | Partial | AXXXL reachability + Dynamic Type audit after full-form scroll | `testSettingsCriticalControlsUsableAtAXXXL`, `testSettingsPassesDynamicTypeAuditAtAXXXL`; `accessibility/screenshots/iphone-17-pro-settings_dark_accessibility-extra-extra-extra-large.png` |
| P-1.4.10 | Untested | | |
| P-1.4.11 | Untested | | |
| O-2.4.3 | Untested | | |
| O-2.4.4 | Pass | Toggle labels; reset `settings_resetAllDataButton`; dependent-toggle hints (turn total, bot haptics) | |
| O-2.5.3 | Pass | Visible matches control name | |
| DBX-TARGET-44 | Pass | System toggles + touch-target audit after full-form scroll | |
| U-3.1.1 | Pass | L10n keys; de/es/nl section smoke tests | `GermanLocalizationSmokeUITests`, `SpanishLocalizationSmokeUITests`, `DutchLocalizationSmokeUITests` |
| U-3.3.1 | Partial | Reset confirmation dialog (system); AX spot-check + UI test | `evidence/voiceover/settings-reset-ax-spotcheck-2026-06-06.md`, `SettingsUITests.testSettingsResetAlertAccessibilityContract` |
| U-3.3.2 | Pass | Section headers/footers | |
| R-4.1.2 | Pass | All pickers/toggles/buttons expose stable IDs (`settings_*`) | `WCAGAccessibilityUITests.testSettingsRequiredControlsExposeIdentifiers` |
| DBX-CONTRAST-MODES | Partial | Token audit + Settings light native form; `evidence/contrast/brand-token-samples-2026-06-02.md` |

## Open work

- [x] Reset button identifier + accessibility label
- [x] Full-form identifier contract for reorganized sections
- [x] Dependent-toggle VoiceOver hints (turn total requires sound; bot haptics follows haptics)
- [x] Landscape + AXXXL automated smoke
- [x] Localized section headers (de/es/nl smoke)
- [x] Reset destructive flow AX spot-check + automated alert contract test
- [x] Dynamic Type WCAG audit at AXXXL (automated)
- [ ] VoiceOver: destructive reset flow audio pass (manual — see `evidence/voiceover/core-flow-settings-reset.md`)
- [ ] Theme cohesion with Play tab in dark preference
- [ ] Manual AXXXL walkthrough of every picker row (automated audit scrolls form but does not assert each row label)

## Verification log

| Date | Tester | Result | Notes |
|------|--------|--------|-------|
| 2026-06-02 | Agent | Partial | Reset a11y label added; manual VO pending |
| 2026-06-06 | Agent | Partial | Reorganized sections; full identifier matrix; landscape/AXXXL/locale smoke; reset AX spot-check + Dynamic Type audit |
