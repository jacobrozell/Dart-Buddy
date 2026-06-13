# Settings Specification

## 1. Purpose
Define configurable app preferences and data management controls for MVP.

---

## 2. MVP Scope
- Theme preference (`System`, `Light`, `Dark`)
- Haptics toggle
- Sound effects toggle
- Default game setup values
- Local data reset action (destructive)

---

## 3. UI Specification

## Layout
- Grouped SwiftUI form sections:
  - Appearance
  - Starting Mode
  - Match Defaults
  - X01 Defaults
  - During Play (scoring input presentation, haptics, sound, turn-total caller)
  - Bot Opponents
  - Data
  - Help & Feedback (support FAQ, send feedback mailto, rate app, privacy policy)
  - About (view onboarding replay, dynamic version, optional tip link)

## Behavior
- Preference changes apply immediately where safe.
- Destructive actions require confirmation dialog with clear consequences.
- Provide brief helper text for each section.

---

## 4. Data and Persistence
- Canonical storage is `SettingsRecord` in SwiftData (aligns with schema/migration specs).
- `AppStorage` can be used only as a view-layer cache/mirror, not source of truth.
- Settings are device-local in 1.0.0
- Defaults should be initialized once and versioned for migrations

Recommended keys:
- `appearanceMode`
- `hapticsEnabled`
- `soundEnabled`
- `defaultMatchType`
- `defaultX01StartScore`
- `defaultCheckoutMode`
- `defaultLegsToWin`
- `defaultSetsEnabled` (persisted from last Play setup on Start; no Settings UI control)
- `defaultDartEntryPresentationRaw` (number pad vs visual dartboard — [`VisualDartboardInputSpec.md`](VisualDartboardInputSpec.md))

---

## 5. Data Reset Behavior

Authoritative reset policy, inventory, scaling checklist, and tests: [`DeleteAllDataSpec.md`](DeleteAllDataSpec.md).

Summary: **Reset All Local Data** requires destructive confirmation, clears all inventoried SwiftData tables and UserDefaults, clears in-memory session stores, re-seeds default settings, and returns the app to first-launch data defaults. On failure, present a recoverable error.

---

## 6. Accessibility
- Clear VoiceOver labels for each toggle/picker
- No ambiguous destructive copy
- Sufficient spacing and tap targets for all controls

---

## 7. Testing

## Unit
- Settings defaults and enum serialization
- Reset workflow service logic

## Integration
- Changed defaults appear in New Match setup prefill
- Reset inventory and table coverage: [`DeleteAllDataSpec.md`](DeleteAllDataSpec.md) §8

## UI
- Appearance toggle behavior
- Destructive reset confirmation flow

---

## 8. Accessibility verification
- Manual: [`settings.md`](../accessibility/wcag-2.1-aa/screens/settings.md)

## 9. Analytics
§12 — `settings_seeded` (log-only). Successful reset logs `settings_reset_all_data` (log-only, not Analytics). Failures log `settings_reset_failed` → Crashlytics allowlist.

## 10. Verification
| Field | Value |
|-------|--------|
| **Last verified** | 2026-06-04 |
| **Commit** | `0c25396` |
| **Code** | `SettingsRootView.swift`, `SettingsViewModel.swift` |

---

## 11. Future Improvements
- Backup/export settings profile
- Separate advanced gameplay rules section
- Diagnostic mode toggle for internal builds
- iCloud settings sync (post local-only milestone)
