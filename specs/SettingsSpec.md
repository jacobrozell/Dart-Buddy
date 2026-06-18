**Estimated release:** `1.0`

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

### Post-MVP (documented; see linked specs)
- **Instant bot turns** — app-wide bot playback speed ([`InstantBotTurnsSpec.md`](InstantBotTurnsSpec.md))

---

## 3. UI Specification

## Layout
- Grouped SwiftUI form sections:
  - Appearance
  - Starting Mode
  - Match Defaults
  - X01 Defaults
  - During Play (scoring input presentation, haptics, sound, turn-total caller, **instant bot turns** — [`InstantBotTurnsSpec.md`](InstantBotTurnsSpec.md))
  - Bot Opponents (bot stagger, bot dart haptics — disabled when instant bot turns is on)
  - Data
  - Help & Feedback (support FAQ, send feedback mailto, rate app, privacy policy)
  - About (view onboarding replay, dynamic version, optional **StoreKit tip jar** — post-1.0; see [`docs/plans/storekit-tip-jar-plan.md`](../docs/plans/storekit-tip-jar-plan.md); external tip URLs are not App Store compliant)

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
- `turnTotalCallerEnabled`
- `instantBotTurnsEnabled` (optional persisted; default `false` — [`InstantBotTurnsSpec.md`](InstantBotTurnsSpec.md))
- `defaultMatchType`
- `defaultX01StartScore`
- `defaultCheckoutMode`
- `defaultLegsToWin`
- `defaultSetsEnabled` (persisted from last Play setup on Start; no Settings UI control)
- `defaultDartEntryPresentationRaw` (number pad vs visual dartboard — [`VisualDartboardInputSpec.md`](VisualDartboardInputSpec.md))
- `botStaggerEnabled` (optional persisted; default `true`)
- `botDartHapticsEnabled` (optional persisted; default `true`)

Runtime mirror: `FeedbackPreferences` in `UserPreferencesStore` reflects `hapticsEnabled`, `soundEnabled`, `turnTotalCallerEnabled`, `instantBotTurnsEnabled`, `botStaggerEnabled`, and `botDartHapticsEnabled` for in-match services.

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
| **Estimated release** | `1.0` |
| **Last verified** | 2026-06-04 |
| **Commit** | `0c25396` |
| **Code** | `SettingsRootView.swift`, `SettingsViewModel.swift` |

---

## 11. During Play and Bot Opponents (feedback keys)

| Setting | Section | Persisted key | Default | Spec |
|---------|---------|---------------|---------|------|
| Dart entry presentation | During Play | `defaultDartEntryPresentationRaw` | number pad | [`VisualDartboardInputSpec.md`](VisualDartboardInputSpec.md) |
| Haptics | During Play | `hapticsEnabled` | `true` | This spec |
| Sound | During Play | `soundEnabled` | `true` | This spec |
| Turn total caller | During Play | `turnTotalCallerEnabled` | `false` | This spec |
| **Instant bot turns** | During Play | `instantBotTurnsEnabled` | `false` | [`InstantBotTurnsSpec.md`](InstantBotTurnsSpec.md) |
| Bot stagger | Bot Opponents | `botStaggerEnabled` | `true` | [`BotOpponentSpec.md`](BotOpponentSpec.md), [`InstantBotTurnsSpec.md`](InstantBotTurnsSpec.md) |
| Bot dart haptics | Bot Opponents | `botDartHapticsEnabled` | `true` | [`BotOpponentSpec.md`](BotOpponentSpec.md), [`InstantBotTurnsSpec.md`](InstantBotTurnsSpec.md) |

**Instant bot turns** is app-wide: one toggle affects all modes and all bot kinds. It is not per-bot and not per-match. When on, stagger and bot dart haptics have no effect (controls disabled in UI).

---

## 12. Future Improvements
- Backup/export settings profile
- Separate advanced gameplay rules section
- In-app “Reduce animations” toggle (UI motion only — [`AnimationSpec.md`](AnimationSpec.md) §5.3)
- Diagnostic mode toggle for internal builds
- iCloud settings sync (post local-only milestone)