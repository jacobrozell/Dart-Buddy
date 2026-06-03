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
  - Gameplay Defaults
  - Feedback
  - Data
  - About

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

---

## 5. Data Reset Behavior

`Reset All Local Data` must:
1. Confirm with destructive modal
2. Remove players, matches, events, stats cache, settings
3. Return app to first-launch defaults
4. Not leave partial data state if interrupted

Implementation note:
- Execute reset in transactional sequence where possible.
- On failure, present recoverable error and retry path.

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
- Reset truly clears all local tables and preferences

## UI
- Appearance toggle behavior
- Destructive reset confirmation flow

---

## 8. Future Improvements
- Backup/export settings profile
- Separate advanced gameplay rules section
- Diagnostic mode toggle for internal builds
- iCloud settings sync (post local-only milestone)
