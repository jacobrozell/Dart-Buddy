**Estimated release:** `TBD`

# Instant Bot Turns Specification

## 1. Purpose

Define an **app-wide** preference that makes bot throw playback virtually instant across all game modes and all bot kinds (preset, training, custom). When enabled, bot visits skip staggered dart reveals, per-dart hit/miss audio and haptics, and mode-specific post-turn pacing delays tied to bot playback.

This spec is authoritative for bot **playback pacing** and feedback during bot turns. Bot **skill generation** remains in [`BotOpponentSpec.md`](BotOpponentSpec.md), [`TrainingBotSpec.md`](TrainingBotSpec.md), and [`CustomBotSpec.md`](CustomBotSpec.md). Decorative UI motion during matches remains governed by [`AnimationSpec.md`](AnimationSpec.md).

**Related:**
- [`SettingsSpec.md`](SettingsSpec.md) — Settings UI placement and persistence keys
- [`BotOpponentSpec.md`](BotOpponentSpec.md) — bot turn generation and in-match behavior
- [`AnimationSpec.md`](AnimationSpec.md) — UI motion policy (separate from bot pacing)
- [`AccessibilitySpec.md`](AccessibilitySpec.md) — system Reduce Motion expectations
- Code today: `Support/Gameplay/BotTurnPacing.swift`, `Features/Play/Shared/MatchBotPlaybackLifecycle.swift`, `Features/Play/Shared/PlayViewHelpers.swift` (`playBotDartEntryFeedback`)

---

## 2. Product goals

- **Speed** — players who frequently face bots can finish matches faster without changing bot difficulty or match rules.
- **Global** — one persisted toggle applies to every mode and every bot participant; not per-bot, not per-match.
- **Predictable** — instant means zero artificial delay and no per-dart bot throw feedback; human turns and committed match feedback (bust banners, leg wins, summary celebration) are unchanged.
- **Discoverable** — explicit in-app control under Settings; optional alignment with iOS Reduce Motion for accessibility.

---

## 3. Scope

### In scope

| Area | Behavior when instant bot turns are active |
|------|---------------------------------------------|
| Dart reveal pacing | All three darts appear in one update (or with zero `Task.sleep` between reveals) |
| Submit delay | Zero pause between last dart and turn submit |
| Per-dart bot audio | Skipped (hit/miss sounds during bot playback) |
| Per-dart bot haptics | Skipped (`botDartHapticsEnabled` ignored during instant bot playback) |
| Mode transition sleeps | Zero delay for bot-triggered pacing constants in `BotTurnPacing` (cricket closure, Shanghai achievement, golf hole complete, killer became-killer, baseball perfect inning, etc.) |
| All bot kinds | Preset, training, and custom bots |
| All implemented game modes | Any mode using `BotVisitPlayback.revealVisit`, `MatchSessionController.playBotVisitAndSubmit`, or `BotTurnPacing` directly |

### Out of scope

- Changing bot skill, RNG, or visit contents (`DartBotEngine` output is identical).
- Per-bot or per-match overrides (setup flow does not expose this).
- Skipping human turn feedback, leg-checkout audio, match-finished fanfare, or turn-total caller (those follow existing `soundEnabled` / `turnTotalCallerEnabled` rules on **human** submits).
- UI celebration motion on scoreboards and summary screens (see [`AnimationSpec.md`](AnimationSpec.md)).
- Replacing the existing **Bot stagger** toggle — stagger remains the pacing choice when instant is **off** (staggered vs fast).

---

## 4. Settings UI

### Placement

Add toggle under **Settings → During Play** (same section as haptics, sound, turn-total caller). Rationale: this is a global gameplay-speed preference, not a per-opponent configuration.

Keep **Bot stagger** and **Bot dart haptics** under **Settings → Bot Opponents**. When instant bot turns is **on**, those controls are disabled (or hidden) with footer copy explaining they have no effect until instant is turned off.

### Control contract

| Property | Value |
|----------|--------|
| Label key | `settings.feedback.instantBotTurns` |
| Footer key | `settings.feedback.instantBotTurns.hint` |
| Accessibility identifier | `settings_instantBotTurnsToggle` |
| Accessibility hint | Explains that bot throws resolve immediately and per-dart sounds/haptics are skipped |
| Default | `false` (preserve current shipped feel) |
| Applies | Immediately to matches in progress (read from `FeedbackPreferences` on each bot turn) |

### Interaction with related toggles

| Toggle | When instant bot turns ON |
|--------|---------------------------|
| Bot stagger | Ignored for pacing; UI disabled |
| Bot dart haptics | Ignored during bot playback; UI disabled |
| Sound (global) | Still applies to human play and non-bot events; per-dart bot hit/miss skipped by instant policy |
| Haptics (global) | Still applies to human pad input; bot dart haptics skipped by instant policy |
| iOS Reduce Motion | See §5 — optional OR with in-app toggle |

---

## 5. Effective policy

Centralize in `BotTurnPacing` (or a thin `BotPlaybackPolicy` helper) so view models do not duplicate logic.

```swift
enum BotPlaybackPolicy {
  static func instantBotTurnsActive(
    instantBotTurnsEnabled: Bool,
    reduceMotion: Bool = UIAccessibility.isReduceMotionEnabled,
    uiTestInstantBots: Bool = UITestLaunchArguments.instantBotsActive
  ) -> Bool {
    instantBotTurnsEnabled || reduceMotion || uiTestInstantBots
  }
}
```

**Recommended default:** OR with `UIAccessibility.isReduceMotionEnabled` so users who enable system Reduce Motion get instant bot playback without hunting for an in-app toggle. The in-app toggle remains available for players who want speed without enabling full Reduce Motion.

**UITest:** Existing launch argument `-ui_test_instant_bots` continues to force instant playback (must not be removable by user settings).

---

## 6. Engineering specification

### 6.1 Persistence

| Layer | Field |
|-------|--------|
| `SettingsRecord` | `instantBotTurnsEnabled: Bool?` (optional; `nil` → `false`) |
| `SettingsSummary` | `instantBotTurnsEnabled: Bool` |
| `FeedbackPreferences` | `instantBotTurnsEnabled: Bool` |

Apply via `UserPreferencesStore.apply(_:)` alongside existing feedback keys. Post `Notification.Name.settingsDidUpdate` on save (existing behavior).

### 6.2 Pacing (`BotTurnPacing`)

Extend existing `resolved*Nanoseconds` helpers to accept `instantBots: Bool` from policy (today only UITest sets `instantBots: true`).

| Constant / helper | Instant behavior |
|-------------------|------------------|
| `resolvedDartDelayNanoseconds` | `0` |
| `resolvedSubmitDelayNanoseconds` | `0` |
| `resolvedCricketClosureTransitionNanoseconds` | `0` |
| `shanghaiAchievementTransitionNanoseconds` | Add `resolved*` wrapper → `0` |
| `golfHoleCompleteTransitionNanoseconds` | Add `resolved*` wrapper → `0` |
| `killerBecameKillerTransitionNanoseconds` | Add `resolved*` wrapper → `0` |
| `baseballPerfectInningTransitionNanoseconds` | Add `resolved*` wrapper → `0` |
| `baseballStretchGateHintNanoseconds` | Add `resolved*` wrapper → `0` |
| `mickeyMouseTargetAdvancedTransitionNanoseconds` | Add `resolved*` wrapper → `0` |
| `briefModeFeedbackTransitionNanoseconds` | Add `resolved*` wrapper → `0` |

Public entry points (`dartDelayNanoseconds`, `submitDelayNanoseconds`, etc.) take `FeedbackPreferences` (or `instantBots: Bool`) so call sites do not pass UITest flags manually.

### 6.3 Dart reveal

**Preferred:** When instant, append all planned darts in a single `setEnteredDarts` update inside `BotVisitPlayback.revealVisit` (no per-dart loop). This avoids three rapid `onChange` callbacks and matches user perception of “instant.”

**Alternative (acceptable MVP):** Keep the loop with zero delay; must still skip feedback per §6.4.

### 6.4 Per-dart feedback

`playBotDartEntryFeedback` must no-op when `BotPlaybackPolicy.instantBotTurnsActive(...)` is true.

Call sites in match screens remain unchanged if the helper reads `FeedbackPreferences` (or receives an `instantBotTurns` flag).

### 6.5 View model coverage

Modes already using `BotVisitPlayback.revealVisit` inherit dart/submit pacing automatically once `BotTurnPacing` is wired:

- X01, Cricket, Shanghai, Baseball, Killer
- `MatchSessionController.playBotVisitAndSubmit` (Golf, Knockout, …)

Modes with custom `playBotTurnIfNeeded` loops must use centralized `BotTurnPacing` helpers for **all** sleeps (including mode-specific transitions listed in §6.2). Audit list: Football, Grand National, Hare and Hounds, Mickey Mouse, English Cricket, Around the Clock, Around the Clock 180, Nine Lives, Mulligan, Sudden Death, Chase the Dragon, Fifty-One by Fives, American Cricket, Fleet, Golf (transitions), etc.

### 6.6 What must not change

- `isBotPlaying` lifecycle and undo/recovery (`MatchBotPlaybackLifecycle`, `MatchBotUndoSupport`)
- Bot visit contents from `DartBotEngine`
- Human scoring hot path and `submittingTurn` guards ([`AnimationSpec.md`](AnimationSpec.md) §9)

---

## 7. Pacing reference (when instant is OFF)

Documented for contrast; values live in `BotTurnPacing.swift` — do not duplicate numbers in multiple specs.

| Profile | Per-dart delay | Submit delay | Typical 3-dart visit |
|---------|----------------|--------------|----------------------|
| Staggered (`botStaggerEnabled == true`) | 650 ms | 350 ms | ~2.3 s |
| Fast (`botStaggerEnabled == false`) | 220 ms | 180 ms | ~0.84 s |
| **Instant** (`instantBotTurnsEnabled` or policy OR) | 0 | 0 | ~0 s (+ engine/submit work) |

---

## 8. Accessibility

- VoiceOver: When instant, bot visits should still announce the committed visit outcome via existing turn/submit flows; do not rely on per-dart audio.
- **Reduce Motion:** Instant bot turns align with [`AnimationSpec.md`](AnimationSpec.md) principle that motion must not block gameplay comprehension. Bot pacing is explicitly **not** UI motion (AnimationSpec §5.1 note on Class E / `BotTurnPacing`).
- Settings toggle requires label, hint, and `settings_instantBotTurnsToggle` identifier ([`accessibility/wcag-2.1-aa/screens/settings.md`](../accessibility/wcag-2.1-aa/screens/settings.md)).
- Dependent-toggle pattern: when instant is on, Bot Opponents stagger/haptics toggles are disabled with footer explanation (same pattern as turn-total caller requiring sound).

---

## 9. Localization

Add keys to `en` and mirror in `de`, `es`, `nl`, `fr` per [`LocalizationSpec.md`](LocalizationSpec.md):

- `settings.feedback.instantBotTurns`
- `settings.feedback.instantBotTurns.hint`
- `settings.feedback.instantBotTurns.accessibilityHint`
- `settings.botOpponents.instantOverridesStagger` (footer when instant is on)

---

## 10. Testing

### Unit

- `BotTurnPacingTests` — instant policy forces zero for dart, submit, and each `resolved*Transition` helper
- `BotPlaybackPolicyTests` — OR logic: setting, Reduce Motion, UITest flag
- `SettingsRecordMigrationTests` — `nil` instant field defaults to `false`
- One mode integration test per pattern:
  - `BotVisitPlayback.revealVisit` path (e.g. X01)
  - Custom loop path (e.g. Football or Around the Clock 180)
  - Mode-specific transition (e.g. Cricket closure or Shanghai achievement)

### UI

- `SettingsUITests` — toggle exists, persists, disables bot stagger when on
- `WCAGAccessibilityUITests` — identifier + interactive contract for `settings_instantBotTurnsToggle`
- Existing `-ui_test_instant_bots` regression tests continue to pass

### Manual

- Play one leg vs bot in X01 and Cricket with instant on: no per-dart sound, turn advances immediately
- Toggle mid-match: next bot turn respects new value
- Reduce Motion on (in-app off): verify OR policy if implemented

---

## 11. Analytics

No new Analytics events for MVP. Optional log-only diagnostic: `settings_instant_bot_turns_changed` (follow [`FirebaseBackendAnalyticsSpec.md`](FirebaseBackendAnalyticsSpec.md) §12 patterns). Not required for ship.

---

## 12. Verification

| Field | Value |
|-------|--------|
| **Estimated release** | `TBD` |
| **Last verified** | — |
| **Commit** | — |
| **Code** | `BotTurnPacing.swift`, `MatchBotPlaybackLifecycle.swift`, `PlayViewHelpers.swift`, `SettingsRootView.swift`, `UserPreferencesStore.swift` |

---

## 13. Future improvements

- Three-way picker: Staggered / Fast / Instant (replaces separate stagger + instant toggles)
- Onboarding prompt for frequent bot players
- Per-session “speed run” override without changing Settings (low priority; conflicts with global preference goal)
