# Settings — reset flow AX spot-check

**Date:** 2026-06-06  
**Device:** iPhone 17 Pro Simulator  
**Launch args:** `-ui_test_reset -seed_players -ui_test_disable_feedback -disable_firebase_analytics`  
**Method:** XCTest accessibility tree (`SettingsUITests.testSettingsResetAlertAccessibilityContract`) + code review of `SettingsRootView` labels  
**Criteria:** O-2.4.4 (Link/button purpose), U-3.3.1 (Error prevention / destructive confirm), R-4.1.2 (Name, Role, Value)

## Flow exercised

1. Open **Settings** tab  
2. Scroll to **Data** section  
3. Activate **Reset All Local Data** (`settings_resetAllDataButton`)  
4. Inspect system confirmation alert  
5. Dismiss with **Cancel** (destructive confirm not executed in automated pass)

## Expected VoiceOver traversal (English)

| Step | Control | Spoken label / role | Identifier | Pass |
|------|---------|---------------------|------------|------|
| 1 | Settings tab | Settings, tab | `tab_settings` | ✓ (tab bar) |
| 2 | Reset row | **Reset all data**, button | `settings_resetAllDataButton` | ✓ |
| 3 | Alert title | Reset all local data? | (system alert) | ✓ |
| 4 | Alert message | This clears all local data on this device: players, matches, settings, saved preferences, and the welcome tour. | (system alert) | ✓ |
| 5 | Cancel | Cancel, button | (system) | ✓ |
| 6 | Confirm | Reset Data, button (destructive) | (system) | ✓ |

**Note:** Visible row text is “Reset All Local Data”; VoiceOver uses the shorter `settings.reset.accessibility` label (“Reset all data”) so the destructive action is clear without repeating section chrome.

## Dependent toggles (During Play / Bot Opponents)

| Control | Label | Hint | Identifier |
|---------|-------|------|------------|
| Announce Turn Total | Announce Turn Total, switch | Requires Sound to be on. | `settings_turnTotalCallerToggle` |
| Bot Dart Haptics | Bot Dart Haptics, switch | Follows the Haptics toggle when enabled. | `settings_botDartHapticsToggle` |

## Automated regression

- `SettingsUITests.testSettingsResetAlertAccessibilityContract` — alert labels + hittable actions  
- `WCAGAccessibilityUITests.testSettingsRequiredControlsExposeIdentifiers` — full-form identifier matrix  
- `WCAGAccessibilityUITests.testSettingsPassesDynamicTypeAuditAtAXXXL` — P-1.4.4 Dynamic Type + text clipping

## Not covered (manual VoiceOver audio)

- Swipe order from **Appearance** through **About** with all section headers/footers (`O-2.4.3`)  
- Actual execution of **Reset Data** and post-reset empty-state announcement  
- German / Spanish / Dutch alert copy (localized via `Localizable.strings`; verify once per locale before release)

## Manual re-check script

1. Settings → VoiceOver on → swipe to Data → double-tap Reset all data.  
2. Confirm title + message read completely before action buttons.  
3. Cancel → focus returns to reset row.  
4. Repeat in **de**, **es**, **nl** (Settings tab label + alert strings).  
5. Optional: execute reset on test device; confirm app returns to onboarding/defaults without orphan focus.
