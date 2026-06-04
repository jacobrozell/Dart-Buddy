# Setup Flow Specification

## 1. Purpose
Define new-match configuration on the Play tab: roster selection, mode options, validation, active-match conflict, and launch into gameplay.

Play tab chrome (resume banner, recents) is in [`PlayHomeSpec.md`](PlayHomeSpec.md). Bots: [`BotOpponentSpec.md`](BotOpponentSpec.md), [`TrainingBotSpec.md`](TrainingBotSpec.md).

---

## 2. MVP Scope

### In Scope (1.0.0)
- Combined setup surface on Play home (`SetupHomeView` + `MatchSetupViewModel`)
- Game mode: **X01** or **Cricket**
- Roster: 2..N players, ordered throw order, optional random order at start
- X01 options: start score (101–601), legs, sets, leg format (first-to / best-of), checkout (straight / double / master out), check-in (straight / double / master in)
- Cricket options: points on/off, normal / cut throat, legs, sets, leg format
- Add preset bot from difficulty menu; add existing Training Partner bots
- Quick-add player when roster empty
- Prefill from `SettingsRecord` + `CricketSetupPreferences`
- Persist last successful setup to settings / cricket prefs
- Active-match conflict dialog (abandon + replace)

### Out of Scope
- Online match lobby
- Saved named presets (“Tuesday league”)

---

## 3. UI Specification

## Layout
- Mode segmented control (X01 | Cricket)
- Option chips grid (mode-specific) — see `SetupHomeView+OptionChips`, `SetupHomeView+CricketOptionChips`
- Available players list + selected roster with reorder
- Add Bot menu (preset tiers + training section)
- Sticky **Start Match** CTA (`safeAreaInset` bottom)
- Inline validation keys below chips (accessibility layout) or via `displayValidationErrors`

## Roster
- Toggle player in/out of `selectedPlayerIds` (ordered)
- Drag reorder on selected list
- `QuickAddPlayerScreen` returns new id via `PendingMatchPlayerSelections`
- At least one **human** required (`setup.validation.requiresHuman`)

## Random order
- When enabled at start, shuffles participant order once before persisting match

---

## 4. Validation Rules

| Rule | Key |
|------|-----|
| Minimum 2 participants | `setup.validation.minimumPlayers` |
| Not all bots | `setup.validation.requiresHuman` |
| X01 start score in allowed set | `setup.validation.invalidStartScore` |
| Legs / sets > 0 when enabled | `setup.validation.invalidLegs`, `setup.validation.invalidSets` |
| Cricket + any bot + Points Off | `setup.validation.cricketBotUnsupported` |

Minimum-player message hidden while roster completely empty (UX polish).

---

## 5. Defaults and Prefill

On `onAppear`:
- Load active players (non-archived)
- Dequeue pending selections from quick-add / player detail shortcuts
- Seed settings defaults: X01 start, legs, sets, checkout, check-in, leg format, default match type
- Load `CricketSetupPreferences` for points / scoring mode
- `PendingMatchPlayerSelections.consumePreferredMatchType()` overrides mode when set

After successful start, write back defaults (including cricket prefs and sets-enabled from last setup).

### Code alignment (`MatchSetupViewModel` / `Domain`)

| Option | Source | Allowed values (1.0) |
|--------|--------|----------------------|
| X01 start score | `X01StartScores.all` | `101, 201, 301, 401, 501, 601` |
| X01 checkout | `X01CheckoutMode.allCases` | `singleOut`, `doubleOut`, `masterOut` |
| X01 check-in | `X01CheckInMode.allCases` | `straightIn`, `doubleIn`, `masterIn` |
| Leg format (X01 + Cricket) | `X01LegFormat.allCases` | `firstTo`, `bestOf` |
| Cricket scoring | `CricketScoringMode` | `standard`, `cutThroat` |
| Cricket points | `cricketPointsEnabled` | `Bool` (bots require `true`) |
| Random order | `randomOrder` | Shuffles `selectedPlayerIds` once at start |

---

## 6. Start Match Flow

1. `revalidate()` → `canStart`
2. `fetchActiveMatch()` — if exists, show conflict alert (no silent fail)
3. `performStart()`:
   - Build `MatchConfigPayload` (versioned) for X01 or Cricket
   - Create `MatchRecord`, participants (snapshots, bot kind, training skill payload)
   - Initialize engine + snapshot
   - Return `PlayRoute` (`.x01Match` / `.cricketMatch`)

`confirmReplaceActiveMatch()` abandons prior active match per [`MatchSpec.md`](MatchSpec.md) then starts.

---

## 7. Data Contract

- `MatchConfigPayload` version in `MatchRecord.configPayload`
- Participant snapshots: `displayNameAtMatchStart`, avatar/color tokens
- Bot fields: `botKindRaw`, `botDifficultyRaw`, `botSkillProfilePayload` (training)

Authoritative schema: [`SwiftData.md`](SwiftData.md), [`DataSchemaSpec.md`](DataSchemaSpec.md).

---

## 8. Testing

## Unit
- `MatchSetupViewModelTests` — validation, cut throat + bot, conflict, config payload
- Prefill and mode switch tests

## UI
- Setup smoke, localization smoke (tab + setup labels)
- Cut throat + bot UI test

---

## 9. Accessibility verification
- Requirements: [`AccessibilitySpec.md`](AccessibilitySpec.md)
- Manual: [`accessibility/wcag-2.1-aa/screens/match-setup.md`](../accessibility/wcag-2.1-aa/screens/match-setup.md), [`play-home.md`](../accessibility/wcag-2.1-aa/screens/play-home.md)
- Automated: `WCAGAccessibilityUITests` (setup + start CTA identifiers)

## 10. Analytics
[`FirebaseBackendAnalyticsSpec.md`](FirebaseBackendAnalyticsSpec.md) §12 — `match_started`, `match_start_failed`, `active_match_*`, `match_abandoned` (replace flow).

## 11. Verification
| Field | Value |
|-------|--------|
| **Last verified** | 2026-06-04 |
| **Commit** | `0c25396` |
| **Code** | `MatchSetupViewModel.swift`, `SetupHomeView*.swift` |

---

## 12. Future Improvements
- Collapse advanced X01 chips (check-in, set/leg) behind “Advanced”
- Named setup presets
