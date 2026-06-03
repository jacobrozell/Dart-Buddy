# Play Reminders — Assessment & Spec

Assessment for [todo.md](../docs/release/todo.md) item: *Push notifications — simple reminder to play a game of darts once a week, configurable in Settings, integrated with Firebase.*

---

## Executive summary

| Dimension | Rating | Notes |
|-----------|--------|-------|
| **Overall difficulty** | **Low–medium** | No notification code exists today, but Settings persistence and Firebase Analytics hooks are already in place. |
| **MVP (local reminders + Settings toggle + frequency picker)** | **1–2 dev days** | Assumes product rules for permission UX and default schedule are decided up front. |
| **Polished v1 (permission edge cases, analytics, privacy, QA)** | **3–5 dev days** | Denied-permission flow, open-settings deep link, localization, device QA, privacy copy. |
| **FCM server push (optional later)** | **+2–4 dev days** | Separate phase; not required for recurring personal reminders. |
| **Risk** | **Low** | Local notifications are well understood; main risk is over-scoping into FCM when local scheduling suffices. |

**Bottom line:** This is a good post-1.0 feature. Use **local notifications** for the recurring “nudge to play” reminder. Reserve **Firebase Cloud Messaging (FCM)** for a later phase if you want server-driven campaigns — not for weekly personal reminders.

---

## Why the codebase is well positioned

- **Settings are canonical in SwiftData** — `SettingsRecord` → `SettingsSummary` → `SettingsViewModel` → `SettingsRootView` already handle toggles and pickers with immediate persistence ([`specs/SettingsSpec.md`](../specs/SettingsSpec.md)).
- **Bootstrap loads settings on launch** — `AppBootstrapper` seeds defaults and applies `UserPreferencesStore`; a reminder sync hook fits naturally after settings load.
- **Feature flags exist** — `FeatureFlag` + `LocalFeatureFlagsProvider` can gate the UI and service behind `enablePlayReminders` (default `false`) until post-1.0.
- **Firebase Analytics is wired (Release)** — `AppLogger` / Analytics allowlist can log reminder lifecycle events without adding FCM ([`specs/FirebaseBackendAnalyticsSpec.md`](../specs/FirebaseBackendAnalyticsSpec.md)).
- **Local-first architecture unchanged** — reminders do not require network, auth, or cloud sync.

## Gaps to close first

| Gap | Impact |
|-----|--------|
| No `UserNotifications` integration | Blocker — add `PlayReminderService` wrapping `UNUserNotificationCenter` |
| No Settings fields for reminder prefs | Blocker — extend `SettingsRecord` / `SettingsSummary` |
| No notification permission UX | Required — system prompt + denied-state helper in Settings |
| `FirebaseMessaging` not in SPM | Not needed for MVP — local notifications only |
| Privacy policy / App Store labels | Required before ship — disclose optional local notifications |
| Testing | Unit-test scheduling logic; manual permission + delivery QA on device |

---

## Local notifications vs Firebase (FCM)

| Approach | Use for play reminders? | Why |
|----------|-------------------------|-----|
| **Local notifications** (`UNUserNotificationCenter`) | **Yes — MVP** | User-controlled schedule, works offline, no server, matches “remind me weekly” |
| **Firebase Cloud Messaging (FCM)** | **Later, optional** | Server-initiated pushes (campaigns, re-engagement blasts, A/B tests) |
| **Firebase Analytics** | **Yes — MVP** | Log `reminder_enabled`, `reminder_frequency_changed`, `reminder_opened` (privacy-safe) |

The todo mentions “Firebase notifications.” **Recommended interpretation:**

1. **Phase 1:** Local notification scheduling + Firebase **Analytics** events.
2. **Phase 2 (optional):** Add `FirebaseMessaging` only if product needs remote campaigns or cross-device reminder sync via a backend.

Do **not** block MVP on FCM. Weekly personal reminders are not push notifications in the FCM sense.

---

## Design decisions (decide before building)

### 1. What triggers a reminder?

**Recommended:** Time-based calendar trigger, not activity-based.

- Fire on a fixed weekday + time (e.g. Saturday 10:00, device local timezone).
- **Do not** infer “hasn’t played in 7 days” from match history for MVP — harder to explain, edge cases around time zones and partial matches.

### 2. Frequency options

**Recommended picker values:**

| Raw value | Label | Interval |
|-----------|-------|----------|
| `off` | Off | Cancel all pending reminders |
| `weekly` | Weekly | Every 7 days (same weekday/time) |
| `biweekly` | Every 2 weeks | Every 14 days |
| `monthly` | Monthly | Same day-of-month (clamp day 29–31 to last day of month) |

Default: **Off** (opt-in only — avoids permission prompt on first launch).

### 3. Permission UX

**Recommended:**

1. User turns **Play reminders** on in Settings.
2. App requests notification authorization (`.alert`, `.sound` — no badge required for MVP).
3. If **granted** → schedule next notification.
4. If **denied** → revert toggle (or show inline “Notifications disabled — open Settings”) and do not persist `enabled = true`.

Never request permission on cold launch without user action.

### 4. What happens when the user opens the app from a reminder?

**Recommended:** Deep link to **Play tab** (match setup home). Log `reminder_opened` analytics event. No special modal.

### 5. Reset all local data

**Recommended:** `resetAllLocalData()` cancels pending reminder notifications and resets reminder prefs to off (same as other settings defaults).

### 6. Feature flag

**Recommended:** `enablePlayReminders` — default `false` in Release until post-1.0 approval. Hide Settings section when disabled.

---

## Recommended architecture

```
Support/Notifications/
  PlayReminderInterval.swift       // enum: off, weekly, biweekly, monthly
  PlayReminderService.swift        // schedule, cancel, sync(from: SettingsSummary)
  PlayReminderNotificationContent.swift  // title, body, identifier constants

Features/Settings/
  (extend SettingsRootView)        // Reminders section — toggle + frequency picker
  (extend SettingsViewModel)       // persist + call PlayReminderService.sync

App/Bootstrap/
  AppDelegate.swift                // UNUserNotificationCenterDelegate (optional MVP)
  AppBootstrapper.swift            // sync reminders after settings load (if flag on)
```

**Hook points**

1. **Settings save** — after `updateSettings`, call `PlayReminderService.sync(settings:)`.
2. **App bootstrap** — after settings seed/load, sync schedule (handles OS clearing pending notifications on reinstall).
3. **App foreground** — optional: refresh next fire date if using one-shot requests instead of repeating triggers.

Keep scheduling logic pure and testable (inject `Date` / `Calendar` for tests).

### Settings persistence (new fields)

Add to `SettingsRecord` (optional nil for existing stores, same pattern as `botStaggerEnabled`):

| Field | Type | Default |
|-------|------|---------|
| `playReminderEnabled` | `Bool?` | `false` |
| `playReminderIntervalRaw` | `String?` | `"weekly"` when enabled |

Mirror in `SettingsSummary` as non-optional with repository mapping defaults.

### Notification content (draft)

| Key | English copy |
|-----|----------------|
| Title | Time for darts |
| Body | Start a match and keep your game sharp. |

Localize via `Resources/en.lproj/Localizable.strings` (`settings.reminders.*`, `notification.playReminder.*`).

### Analytics events (allowlist)

| Event | When | Metadata |
|-------|------|----------|
| `reminder_enabled` | User turns reminders on (after permission grant) | `interval` |
| `reminder_disabled` | User turns off | — |
| `reminder_frequency_changed` | Interval picker change | `interval` |
| `reminder_opened` | User taps notification | `interval` |

No PII. Follow existing Analytics allowlist in [`specs/LoggingSpec.md`](../specs/LoggingSpec.md).

---

## Suggested rollout phases

### Phase 1 — Local reminders MVP (day 1–2)

- Feature flag `enablePlayReminders`
- `PlayReminderService` + Settings fields + UI section
- Permission-on-enable flow
- Unit tests for next-fire-date / interval logic
- Update `docs/privacy.html` (optional notifications, no data leaves device for scheduling)

### Phase 2 — Polish (day 3–5)

- Denied-permission inline helper + Open Settings URL
- `UNUserNotificationCenterDelegate` for open analytics
- Bootstrap sync on launch
- Manual QA checklist (grant, deny, change frequency, reset data)
- UI test: toggle + picker persistence

### Phase 3 — FCM (optional, later)

Only if product needs server-driven messaging:

- Add `FirebaseMessaging` to `project.yml`
- APNs key in Firebase console + push capability in Xcode
- `Messaging.messaging().delegate` in `AppDelegate`
- Topic or token storage — **still** keep local schedule as primary for user-configured cadence unless product pivots to server-only

Document in [`specs/FirebaseBackendAnalyticsSpec.md`](../specs/FirebaseBackendAnalyticsSpec.md) Phase 2+ before implementing.

---

## App Store & privacy checklist

- [ ] Privacy policy: optional local notifications; no reminder content sent to Firebase for MVP
- [ ] App Store privacy questionnaire: Notifications (if asked — user-initiated, on-device)
- [ ] No tracking via reminders; analytics events are product-health only
- [ ] Settings copy explains reminders are optional and require notification permission

---

## Testing strategy

| Layer | Approach |
|-------|----------|
| **Scheduling logic** | Swift Testing — given `SettingsSummary` + fixed `Date`/`Calendar`, assert `UNNotificationRequest` count, identifier, and next trigger |
| **Settings integration** | Mock `PlayReminderService` in `SettingsViewModelTests` — verify sync called on persist |
| **Manual** | Device: enable → grant → wait or advance time; deny → verify toggle reverts; change frequency → single pending request |
| **Regression** | Reset all data clears pending notifications; feature flag off hides UI and cancels schedule |

---

## Open questions for you

1. **Default day/time:** Fixed Saturday 10:00, or let user pick weekday + time in v1?
2. **Single vs repeating trigger:** `UNCalendarNotificationTrigger(repeats: true)` vs reschedule after each fire?
3. **Match activity skip:** If user completed a match this week, skip the next reminder? (Adds complexity — defer?)
4. **FCM phase:** Is server push ever needed, or is local + Analytics enough permanently?
5. **Ship timing:** 1.1 with Game Center, or later?

---

## Related files in codebase

| Area | File |
|------|------|
| Settings UI | `Features/Settings/SettingsRootView.swift` |
| Settings VM | `Features/Settings/SettingsViewModel.swift` |
| Settings persistence | `Persistence/Schemas/SchemaV1.swift`, `Data/Repositories/SwiftDataSettingsRepository.swift` |
| Settings spec | `specs/SettingsSpec.md` |
| App bootstrap | `App/Bootstrap/AppBootstrapper.swift`, `App/Bootstrap/AppDelegate.swift` |
| Feature flags | `Support/FeatureFlags/FeatureFlag.swift`, `LocalFeatureFlagsProvider.swift` |
| Firebase (Phase 1) | `App/Bootstrap/FirebaseBootstrap.swift`, `specs/FirebaseBackendAnalyticsSpec.md` |
| Privacy | `docs/privacy.html`, `specs/SecurityPrivacySpec.md` |
