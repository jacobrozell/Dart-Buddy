# Settings

| Field | Value |
|-------|-------|
| Screen ID | `settings` |
| Primary source | `Features/Settings/SettingsRootView.swift` |
| Core flow | No (tab) |
| Last verified | 2026-06-02 |
| Screen status | `Partial` |

## Criterion checklist

| ID | Status | Implementation notes | Evidence |
|----|--------|----------------------|----------|
| P-1.1.1 | Pass | Form controls standard | |
| P-1.3.1 | Pass | `Form` / `Section` | |
| P-1.3.2 | Untested | | |
| P-1.3.4 | Untested | iPad max width 760 | |
| P-1.4.1 | Pass | | |
| P-1.4.3 | Untested | Light form vs dark tabs (`todo.md`) | `snapshots/iphone17-settings-dark-axxxl-contrast.png` (link only) |
| P-1.4.4 | Untested | | |
| P-1.4.10 | Untested | | |
| P-1.4.11 | Untested | | |
| O-2.4.3 | Untested | | |
| O-2.4.4 | Pass | Toggle labels; reset `settings_resetAllDataButton` | |
| O-2.5.3 | Pass | Visible matches control name | |
| DBX-TARGET-44 | Pass | System toggles | |
| U-3.1.1 | Pass | L10n keys | |
| U-3.3.1 | Partial | Reset confirmation dialog (system) | |
| U-3.3.2 | Pass | Section headers/footers | |
| R-4.1.2 | Pass | Feedback toggles + reset button IDs/labels | |
| DBX-CONTRAST-MODES | Partial | Token audit + Settings light native form; `evidence/contrast/brand-token-samples-2026-06-02.md` |

## Open work

- [x] Reset button identifier + accessibility label
- [ ] VoiceOver: destructive reset flow end-to-end (manual)
- [ ] Theme cohesion with Play tab in dark preference
- [ ] AXXXL Form layout on iPhone

## Verification log

| Date | Tester | Result | Notes |
|------|--------|--------|-------|
| 2026-06-02 | Agent | Partial | Reset a11y label added; manual VO pending |
