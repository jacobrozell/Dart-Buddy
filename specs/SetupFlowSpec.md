**Estimated release:** `1.0`

# Setup Flow Specification

## 1. Purpose
Define new-match configuration on the Play tab: roster selection, mode options, validation, active-match conflict, and launch into gameplay.

Play tab chrome (resume banner, recents) is in [`PlayHomeSpec.md`](PlayHomeSpec.md). Bots: [`BotOpponentSpec.md`](BotOpponentSpec.md), [`TrainingBotSpec.md`](TrainingBotSpec.md).

---

## 2. MVP Scope

### In Scope (1.0.0)
- Combined setup surface on Play home (`SetupHomeView` + `MatchSetupViewModel`)
- **Standard** category: X01 or Cricket
- **Party** category: Baseball (v1); Killer/Shanghai coming soon
- Roster: 2..N players, ordered throw order, optional random order at start
- X01 options: start score (101–601), legs, sets, leg format (first-to / best-of), checkout (straight / double / master out), check-in (straight / double / master in)
- Cricket options: points on/off, normal / cut throat, legs, sets, leg format
- Baseball options (party): innings, tie-breaker, 7th-inning stretch (`BaseballSetupPreferences`)
- Add preset bot from difficulty menu; add existing Training Partner or custom bots (standard category only; baseball allows preset bots only)
- Quick-add player when roster empty
- Prefill from `SettingsRecord` + `CricketSetupPreferences` + `BaseballSetupPreferences`
- Persist last successful setup to settings / cricket prefs
- Active-match conflict dialog (abandon + replace)

### Out of Scope
- Online match lobby
- Saved named presets (“Tuesday league”)

---

## 3. UI Specification

## Layout
- Category segmented control (Standard | Party)
- Standard: mode segmented control (X01 | Cricket)
- Party: game picker (`PartyGamePickerView`) + baseball option chips when Baseball selected
- Option chips grid (mode-specific) — see `SetupHomeView+OptionChips`, `SetupHomeView+CricketOptionChips`, `SetupHomeView+BaseballOptionChips`
- Available players list + selected roster with reorder
- Add Bot menu (preset tiers + training section)
- Sticky **Start Match** CTA (`safeAreaInset` bottom)
- Inline validation keys below chips (accessibility layout) or via `displayValidationErrors`

## Roster
- Toggle player in/out of `selectedPlayerIds` (ordered)
- Drag reorder on selected list
- Full add-player sheet (`PlayerEditSheet`) from setup **Add Players**; returns new id via `PendingMatchPlayerSelections`
- At least one **human** required (`setup.validation.requiresHuman`)
- Per-mode **minimum / maximum** participants come from [`GameModeCatalog`](../Features/Modes/GameModeCatalog.swift) (`minimumPlayers`, `maximumPlayers`); each `*GameSpec.md` § Player count documents solo eligibility and rationale. App-wide default max is **8** unless a mode sets lower (e.g. Football, Scam = 2). Solo-only modes (`maximumPlayers: 1`, e.g. Bob's 27) skip roster per `GameModeCatalogEntry.isSolo`.

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
| Baseball + training/custom bot | `setup.validation.baseballBotsPresetOnly` |

Minimum-player message hidden while roster completely empty (UX polish).

---

## 5. Defaults and Prefill

On `onAppear`:
- Load active players (non-archived)
- Dequeue pending selections from setup add-player / player detail shortcuts
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
   - Build `MatchConfigPayload` (versioned) for X01, Cricket, or Baseball
   - Create `MatchRecord`, participants (snapshots, bot kind, training skill payload)
   - Initialize engine + snapshot
   - Return `PlayRoute` (`.x01Match` / `.cricketMatch` / `.baseballMatch`)

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
| **Estimated release** | `1.0` |
| **Last verified** | 2026-06-04 |
| **Commit** | `0c25396` |
| **Code** | `MatchSetupViewModel.swift`, `SetupHomeView*.swift` |

---

## 12. Future Improvements
- Collapse advanced X01 chips (check-in, set/leg) behind “Advanced”
- Named setup presets

---

## 13. Solo practice setup (planned)

Shared platform for all `isSolo` modes: [`SoloPracticeModesSpec.md`](SoloPracticeModesSpec.md) §5.

### Call & Hit

When Modes tab routes `practice.callAndHit` → Play setup ([`CallAndHitGameSpec.md`](game-modes/planned/CallAndHitGameSpec.md)):

### Layout additions
- **Session preset** horizontal chips (Standard, Sharp, Blitz, …) above advanced chips
- **Custom** expands: target count, darts per target, target kind, include bull, callout voice
- **No roster section** (`isSolo` — single human from active profile or picker sheet)
- **No bot menu**

### Validation
| Rule | Key |
|------|-----|
| Exactly one human participant | reuse `setup.validation.requiresHuman` |
| Config | `targetCount` ∈ {25, 50, 100} | `setup.validation.callAndHit.invalidTargetCount` |
| Config | `dartsPerTarget` ∈ {1, 2, 3} | `setup.validation.callAndHit.invalidDartsPerTarget` |
| Config | Triples + include bull | disallowed — bull chip hidden |

### Start flow
- `MatchConfigCallAndHit` payload → `MatchType.callAndHit`
- Route: `.callAndHitMatch` → `VoiceDrillMatchScreen`
- Persist last preset + custom chips to `SettingsRecord` or `CallAndHitSetupPreferences`

### Prefill
- Dequeue `PendingModeSelection` from Modes tab with catalog id `practice.callAndHit`
- **Practice again** from summary preloads prior session config

### Bob's 27 / Halve-It (future)

Same solo platform: skip roster, mode-specific chips (round/score rules per game spec), `MatchType` route to Template F screen, **Practice again** CTA on summary.