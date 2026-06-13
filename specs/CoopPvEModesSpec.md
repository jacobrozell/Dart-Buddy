# Co-op Modes — Shared Specification

## 1. Purpose

Define **cross-mode contracts** for cooperative modes in Dart Buddy: catalog registration, setup (humans-only roster), match lifecycle, shared-objective UI, co-op summary, history, and statistics. Mode-specific rules stay in each `*GameSpec.md`; this doc is the shared platform.

**Status:** **In progress** — Phase 0 (catalog + platform spec) landed; first playable mode not shipped.

**Progress tracker:** §13 (update checklist rows when work lands). **Implementation plan / agent query:** [`docs/plans/coop-mode-grouping.md`](../docs/plans/coop-mode-grouping.md).

**Consumers (planned Co-op section):**

| Mode | Catalog id | Opponent shape | UI template | Stat kind |
|------|------------|----------------|-------------|-----------|
| Raid | `coop.raid` | Boss entity (non-throwing) | `phaseRace` + boss chrome | `bossRaid` |
| Cerberus | `coop.cerberus` | Tri-head boss (non-throwing) | `roleSplit` + boss chrome | `bossRaid` |
| The Vault | `coop.theVault` | Shared puzzle (no villain bot) | `phaseRace` + combo chrome | `coopHeist` |
| Clear the Board | `coop.clearTheBoard` | Shared board / decay meter / human teams | `boardState` + heat map | `boardClaim` |

**Related:**
- [`SoloPracticeMatchSummarySupplement.md`](SoloPracticeMatchSummarySupplement.md) — co-op victory variant (no single-winner ceremony)
- [`MatchSummarySpec.md`](MatchSummarySpec.md) — Raid §9 co-op summary
- [`BotOpponentSpec.md`](BotOpponentSpec.md) — boss portrait + tier; v1 bosses do not throw darts
- [`SetupFlowSpec.md`](SetupFlowSpec.md) — roster validation for co-op modes
- [`ModesTabSpec.md`](ModesTabSpec.md)
- [`DesignSystemSpec.md`](DesignSystemSpec.md) — semantic colors, Dynamic Type, light/dark contrast
- [`AccessibilitySpec.md`](AccessibilitySpec.md) — WCAG 2.1 AA baseline
- [`AnimationSpec.md`](AnimationSpec.md) — motion + Reduce Motion
- [`game-modes/planned/RaidGameSpec.md`](game-modes/planned/RaidGameSpec.md) — flagship reference implementation

---

## 2. Definitions

| Term | Rule |
|------|------|
| **Co-op section** | `GameModeSection.coop` — browsed under Modes → Co-op |
| **Hero team** | All human participants in roster; rotate standard visits unless mode says otherwise |
| **Boss participant** | Non-roster entity (boss HP, phases, portrait) — not counted in `maximumPlayers` |
| **Shared objective** | Team wins or loses together; no PvP scoring between humans on the hero team |
| **Co-op summary** | `summaryStyle: .coop` — stars/margin hero, no winner card on team victory |
| **Pressure meter** | Non-bot antagonist (decay, alarm, oxygen) — still co-op; no `DartBotEngine` visits |

**Not co-op (different section):**
- Party PvP (Killer, Knockout, etc.) — `GameModeSection.party`
- Solo-only drills — `SoloPracticeModesSpec.md`
- 1v1 vs throwing bot (X01 + bot, Fleet) — standard/party roster contracts

---

## 3. Catalog contract

Every co-op mode **must** satisfy:

| Field | Value |
|-------|-------|
| `section` | `.coop` |
| `id` prefix | `coop.{camelCaseMode}` |
| `minimumPlayers` | `1` when solo-capable; else mode minimum |
| `maximumPlayers` | Human cap only (boss/meters excluded) |
| `matchType` | `nil` while planned; set when shipped |
| `status` | `.planned` until engine ships |

### Opponent families

| Family | Roster | Setup bots | Examples |
|--------|--------|------------|----------|
| **Boss PvE** | Humans only | **Blocked** — boss auto-attached at match start | Raid, Cerberus |
| **Shared puzzle** | Humans only | **Blocked** | The Vault |
| **Shared board** | Humans only (Team vs Team: even human teams) | **Blocked** in v1 | Clear the Board |

**Test contract:** co-op catalog entries never set `maximumPlayers == 1` with `isSolo == true` unless the mode is a solo achievement variant inside a multiplayer-capable engine (Clear the Board Pure).

---

## 4. Discovery & entry

| Surface | Co-op v1 policy |
|---------|-----------------|
| Modes tab → Co-op section | **Primary** entry |
| Play home quick action | Deferred |
| Journey scripted legs | [`CampaignSpec.md`](CampaignSpec.md) — may override boss tier / hearts |
| Lean Play setup picker | Shows co-op rows when `ProductSurface.showsPartyModes` (same gate as Party/Practice) |

Tap available card → `PendingModeSelection` → Play setup with mode pre-selected.

---

## 5. Setup contract

### Roster

| Rule | Detail |
|------|--------|
| Humans required | ≥ `minimumPlayers` humans selected |
| Preset/training/custom bots | **Rejected** on hero team in v1 (`setup.validation.coopHumansOnly`) |
| Boss attachment | Engine injects boss participant after `MatchStartService` — not in roster picker |
| Solo | Supported where mode spec allows (Raid, Cerberus, Vault, Clear the Board Pure) |

### Config chips

Mode-specific chips live in each `*GameSpec.md`. Shared patterns:
- Boss tier / difficulty (Raid, Cerberus)
- Hero hearts / team lives
- Variant picker (Clear the Board: Pure / Decay / Team vs Team)

### Validation keys (reserved)

| Key | When |
|-----|------|
| `setup.validation.coopHumansOnly` | Any bot in roster for boss/puzzle co-op |
| `setup.validation.coopPlayerCap` | Humans > `maximumPlayers` |
| `setup.validation.coopEvenTeams` | Clear the Board Team vs Team odd split |

---

## 6. Match lifecycle

| Concern | Co-op rule |
|---------|------------|
| Turn order | Heroes rotate unless mode uses per-dart pool (Vault) |
| Forfeit | Team forfeit = shared defeat ([`MatchForfeitSpec.md`](MatchForfeitSpec.md)) |
| Pause / resume | Standard `MatchRecord` snapshot parity |
| Undo | Per-mode; boss state rewinds with last hero visit where applicable |
| Bot visits | Bosses do **not** submit darts in v1 — damage is rules-driven from hero input |

---

## 7. UI — surfaces & shared chrome

Reuse match chrome from existing templates ([`docs/full-game-catalog-ui.md`](../docs/full-game-catalog-ui.md) §5). Co-op modes add a **team objective band** above the template scoreboard (boss, meters, or shared board). Per-mode layout detail stays in each `*GameSpec.md` § UI.

### 7.1 Modes tab — Co-op section

| Element | Rule |
|---------|------|
| Section header | `modes.section.coop` — amber accent via `GameModeCatalogEntry.accentColor` (`.coop` → `Brand.amber`) |
| Catalog badge | `GameModeCatalogBadge` when `matchType == nil`; shipped modes may use `GameModeBadge` |
| Coming soon | `StatusBadge` + `opacity(0.72)` on card; non-tappable; VoiceOver includes coming-soon in label |
| Player count | `modes.playerCount.solo` or `minimumFormat` / `exactFormat` — never omit from accessibility value |
| iPad | Two-column `LazyVGrid` per [`ModesTabSpec.md`](ModesTabSpec.md) |
| Card id | `modes_card_{catalogId}` e.g. `modes_card_coop.raid` |

```text
+--------------------------------------------------+
| CO-OP                                 4 modes    |
|  ┌────────────────────────────────────────────┐  |
|  │ [🛡] Raid                          1–3 pl   │  |
|  │      Co-op boss fight — close, then finish  │  |
|  │                        [Coming soon]        │  |
|  │                        [Learn the rules →]  │  |  ← when guide registered (§8)
|  └────────────────────────────────────────────┘  |
+--------------------------------------------------+
```

### 7.2 Play setup

| Element | Rule |
|---------|------|
| Header | `play.coop.{mode}.title` + `.subtitle` |
| Roster | Humans only; boss shown as **fixed opponent card** (not in picker) on boss modes |
| Config chips | Boss tier, hearts, variant — collapsed under **Edit options** by default |
| Validation hint | Inline under roster when `< minimumPlayers` or bot in roster |
| Start CTA | Disabled with accessible explanation until roster valid |

### 7.3 Gameplay — shared chrome contract

Fixed top-to-bottom order (all co-op match screens):

```text
+--------------------------------------------------+
| [←]  {Mode} · config summary          [⋯ menu]   |
|--------------------------------------------------|
| TEAM OBJECTIVE REGION (co-op chrome — §7.3a)     |
| STATUS BANNERS (phase, damage, alarm, enrage)    |
|--------------------------------------------------|
| SCOREBOARD REGION (template-specific)            |
| SCORING INPUT (template-specific pad)            |
+--------------------------------------------------+
```

#### 7.3a Team objective chrome

**Boss PvE (Raid, Cerberus)**

| Element | Identifier | Visual |
|---------|------------|--------|
| Boss HP bar | `coop_boss_hp_bar` | Fill on `Brand.card`; depletion `Brand.red` / `Brand.redAccent` |
| Phase banner | `coop_boss_phase_banner` | Pill: **icon + text** (Shield / Expose / Enrage) — not color-only |
| Hero hearts strip | `coop_hero_hearts` | SF Symbol heart + numeric label; down state = strikethrough + secondary text |

**Shared meters (Vault, Clear the Board Decay)**

| Element | Identifier | Visual |
|---------|------------|--------|
| Team dart pool / alarm | `coop_team_meter` | Segmented or numeric; alarm state adds **icon + label** |
| Decay / pressure meter | `coop_pressure_meter` | Step meter; collapse threshold announced in banner |

**Board state (Clear the Board)**

| Element | Rule |
|---------|------|
| Heat map | Closed cells: fill **+** checkmark or hatch — not color alone |
| Team colors | Distinct hues with pattern/icon for Team vs Team |
| Current cell | Ring highlight + text label (`T12`, `D5`, etc.) |

### 7.4 Co-op match summary

See §10. Hero strip shows participants **without trophy**; team outcome headline (`VICTORY` / `DEFEAT`) uses `Brand.textPrimary`, not winner green alone.

### 7.5 Appearance — light & dark mode

All co-op UI **must** use semantic `Brand.*` tokens ([`DesignSystemSpec.md`](DesignSystemSpec.md) §4.5) — no hardcoded RGB in co-op chrome.

| Surface | Light / dark rule |
|---------|-------------------|
| Screen background | `Brand.background` |
| Cards, boss panel | `Brand.card` / `Brand.cardElevated` |
| Primary text | `Brand.textPrimary` |
| Phase / meter labels | `Brand.textSecondary` minimum; phase emphasis may use `Brand.amber` or `Brand.orange` **with** text label |
| Success (team win) | `Brand.green` + headline copy |
| Warning (enrage, alarm) | `Brand.amber` + icon + banner text |
| Defeat | `Brand.redAccent` + headline copy — not red fill alone |

**Quality gate (per shipped co-op mode):**
- WCAG 2.1 AA contrast on all co-op chrome in **both** appearances ([`AccessibilitySpec.md`](AccessibilitySpec.md) §3)
- Snapshot or manual check: boss header, phase pill, heat map closed cell, summary hero — light **and** dark
- Dynamic Type: at `accessibilityExtraExtraExtraLarge`, team objective band **stacks** above scoreboard; no clipped HP/hearts (see [`DesignSystemSpec.md`](DesignSystemSpec.md) §4.4)

---

## 8. Learn to play

In-app rules use [`GameRulesGuideView`](../Features/Play/Rules/GameRulesGuideView.swift) + [`GameRulesCatalog`](../Features/Play/Rules/GameRulesCatalog.swift). Authoritative copy lives in each game spec § **How to Play**; mirror into all four `Localizable.strings` when keys change ([`LocalizationSpec.md`](LocalizationSpec.md)).

### Platform contract

| Item | Rule |
|------|------|
| Key prefix | `play.rules.{mode}.` — e.g. `play.rules.raid.overview.body` |
| Section shape | `overview` required; mode-specific sections (phases, meters, variants) per game spec |
| Catalog link | `modes_learnRules_{catalogId}` on card — e.g. `modes_learnRules_coop.raid` |
| Registration | Add `GameRulesCatalog.{mode}` when `MatchType` ships |
| Co-op framing | Copy emphasizes **team** language ("your team", "together") — not PvP winner language |

### Per-mode guides (specced)

| Mode | Guide sections (min) | Spec |
|------|------------------------|------|
| Raid | overview, shield, expose, enrage, hearts, winning | [`RaidGameSpec.md`](game-modes/planned/RaidGameSpec.md) § How to Play |
| Cerberus | overview, assignments, heads, bites, winning | [`CerberusGameSpec.md`](game-modes/planned/CerberusGameSpec.md) |
| The Vault | overview, locks, combos, alarm, solo vs co-op | [`TheVaultGameSpec.md`](game-modes/planned/TheVaultGameSpec.md) |
| Clear the Board | overview, cells, points, variants (Pure / Decay / TvT), bull catch-up | [`ClearTheBoardGameSpec.md`](game-modes/planned/ClearTheBoardGameSpec.md) |

### Coming-soon cards

[`ModesTabSpec.md`](ModesTabSpec.md) and [`docs/full-game-catalog-ui.md`](../docs/full-game-catalog-ui.md) intend **Learn the rules** on planned modes when copy exists. Today `hasRulesGuide` requires a shipped `MatchType` — co-op stubs cannot show the button until Raid registers in `GameRulesCatalog`.

**Phase 1 follow-up (recommended):** extend `GameModeCatalogEntry.hasRulesGuide` (or parallel `hasRulesPreview`) for planned co-op entries once `play.rules.{mode}.*` keys exist in `en`, so users can read rules before the engine ships.

**Status:** **Done for Raid** — `coop.raid` shows Learn the rules via `GameRulesCatalog.previewGuide`; Cerberus, Vault, and Clear the Board remain planned until their `play.rules.*` keys land.

---

## 9. Accessibility

Baseline: [`AccessibilitySpec.md`](AccessibilitySpec.md) (WCAG 2.1 AA, VoiceOver, Dynamic Type, 44pt targets, light/dark contrast).

### Co-op-specific requirements

| Area | Requirement |
|------|-------------|
| Team outcome | Summary speaks "Team victory" / "Team defeated" — not a single player name |
| Boss HP | `accessibilityValue` with current/max format key (`play.raid.bossHPAccessibilityFormat` pattern) |
| Hero hearts | Per-hero value; down state spoken explicitly |
| Phase / meter changes | `AccessibilityNotification.Announcement` on phase shift, enrage, alarm tier, decay tick |
| Pad hints | Inactive segments focusable with hint text (e.g. Shield: "No damage this phase") |
| Heat map cells | Combined label: segment, ring, open/closed, owning team — not color-only |
| Banners | Live region or announcement for damage, close, strike, lock progress |
| Coming soon cards | `modes.card.comingSoonAccessibilityFormat` includes mode name + blurb + coming soon |
| Learn rules | `modes_learnRules_*` — minimum 44pt hit target (already on card footer) |

### Engineering

- Co-op chrome components live in `DesignSystem` or `Features/Play/Shared/` with default accessibility labels
- New identifiers in §7.3 are **UI test contract** — wire WCAG tests when Raid ships ([`Tests/UI/WCAGAccessibilityUITests.swift`](../Tests/UI/WCAGAccessibilityUITests.swift))
- Respect `accessibilityReduceMotion` for phase transitions ([`AnimationSpec.md`](AnimationSpec.md))

### Evidence (per shipped co-op mode)

Create `accessibility/wcag-2.1-aa/screens/{mode}-match.md` before release:

| Mode | Screen doc (planned path) |
|------|---------------------------|
| Raid | `accessibility/wcag-2.1-aa/screens/raid-match.md` |
| Cerberus | `…/cerberus-match.md` |
| The Vault | `…/the-vault-match.md` |
| Clear the Board | `…/clear-the-board-match.md` |

Each doc: VoiceOver script, Dynamic Type spot-check, light/dark contrast notes, landscape pass.

---

## 10. Match summary (co-op variant)

Extend [`SoloPracticeMatchSummarySupplement.md`](SoloPracticeMatchSummarySupplement.md) §3 with `summaryStyle: .coop`:

```text
+--------------------------------------------------+
| Match Summary                                    |
|--------------------------------------------------|
| [Mode badge: Raid]                               |
| VICTORY — Boss defeated                          |  ← team outcome, not "Alice won"
|--------------------------------------------------|
| ┌──────────────────────────────────────────────┐ |
| │  ★★★  Flawless Shield phase                   │ |
| │  Boss HP: 0 · Darts: 84 · Rounds: 12          │ |
| └──────────────────────────────────────────────┘ |
| Hero strip (no trophy per player)                |
|--------------------------------------------------|
| [ Raid again ]              (primary)            |
| [ View in History ]         (secondary)          |
| [ Done ]                    (tertiary)           |
+--------------------------------------------------+
```

| Outcome | Winner card | Primary CTA |
|---------|-------------|-------------|
| Team victory | Hidden | `{mode} again` |
| Team defeat | Hidden | `{mode} again` or `Done` |
| Abandon | Hidden | `Done` |

---

## 11. History & Activity

| Item | Rule |
|------|------|
| `MatchRecord` | Full parity — config fingerprint includes co-op variant |
| List card | Team outcome badge; no single-winner name |
| Activity filter | New `ActivityModeFilter` cases when each `MatchType` ships |
| Stats segment | Per `ModeStatKind`: `bossRaid`, `coopHeist`, `boardClaim` supplements |

---

## 12. Localization

| Prefix | Use |
|--------|-----|
| `modes.section.coop` | Section header |
| `modes.catalog.coop.{mode}.*` | Catalog card |
| `play.coop.{mode}.*` | Setup title/subtitle/chips |
| `coop.summary.*` | Shared summary strings |
| `setup.validation.coop*` | Roster errors |
| `play.rules.{mode}.*` | Learn to play sections (§8) |
| `play.{mode}.*AccessibilityFormat` | VoiceOver value templates for HP, hearts, meters |

---

## 13. Implementation progress

**Rule:** Check off items in the same PR that lands the behavior. Bump §16 **Verification** when this table changes.

### Phase 0 — Catalog & platform (current)

| Item | Status | Code / doc |
|------|--------|------------|
| `GameModeSection.coop` | **Done** | `GameModeCatalog.swift` |
| Catalog stubs (Raid, Cerberus, Vault, Clear the Board) | **Done** | `GameModeCatalog.swift` |
| `ModeStatKind.bossRaid`, `coopHeist` | **Done** | `GameModeCatalog.swift` |
| Section + catalog localization (`en` / `de` / `es` / `nl`) | **Done** | `Localizable.strings`, `Scripts/locale_data/*.json` |
| Modes tab renders Co-op section | **Done** | `ModesRootView.swift` (via `GameModeSection.allCases`) |
| Play setup picker includes Co-op rows | **Done** | `GameModeCatalog.playSetupPickerSections()` |
| Unit tests: 33 modes, 4 sections, coop stubs | **Done** | `GameModeCatalogTests.swift`, `GameModeSectionTests.swift` |
| Per-mode specs migrated to `coop.*` ids | **Done** | `game-modes/planned/RaidGameSpec.md`, `CerberusGameSpec.md`, `TheVaultGameSpec.md`, `ClearTheBoardGameSpec.md` |
| This platform spec + index links | **Done** | `CoopPvEModesSpec.md`, `specs/README.md` |
| Learn rules preview on `coop.raid` (planned card) | **Done** | `GameRulesCatalog.swift`, `GameModeCatalogEntry.hasRulesGuide`, `play.rules.raid.*` in `en` / `de` / `es` / `nl` |

### Phase 1 — Raid (flagship; target first ship)

| Item | Status | Owner spec |
|------|--------|------------|
| `MatchType.raid` + `RaidEngine` | Planned | [`RaidGameSpec.md`](game-modes/planned/RaidGameSpec.md) |
| Boss chrome UI + accessibility IDs | Planned | §7, §9, Raid spec §8 |
| Learn to play — `GameRulesCatalog.raid` + localization | **Done** (preview on coming-soon card) | §8, Raid spec § How to Play |
| Light/dark + Dynamic Type pass on Raid chrome | Planned | §7.5, §9 evidence doc |
| Humans-only roster validation | Planned | §5, [`SetupFlowSpec.md`](SetupFlowSpec.md) |
| `BossParticipant` attachment at match start | Planned | §5, [`BotOpponentSpec.md`](BotOpponentSpec.md) |
| Co-op match summary (`summaryStyle: .coop`) | Planned | §10, [`SoloPracticeMatchSummarySupplement.md`](SoloPracticeMatchSummarySupplement.md) |
| History list card + Activity filter | Planned | §11, [`HistorySpec.md`](HistorySpec.md) |
| `GameRulesCatalog` + How to Play | Planned | §8, Raid spec § Localization |
| Promote catalog `status` → `.shipped` | Planned | `GameModeCatalog.swift` |

### Phase 2 — Shared platform extraction (after Raid)

| Item | Status | Notes |
|------|--------|-------|
| `BossParticipant` type (reusable) | Planned | Extract from Raid match start |
| `CoopMatchSummary` shell | Planned | No single-winner ceremony |
| `setup.validation.coopHumansOnly` | Planned | Block bots on hero roster |
| Stats reducer for `bossRaid` | Planned | [`StatsSpec.md`](StatsSpec.md) supplement TBD |

### Phase 3 — Second co-op mode

| Mode | Status | Spec |
|------|--------|------|
| The Vault | Planned | [`TheVaultGameSpec.md`](game-modes/planned/TheVaultGameSpec.md) |
| Cerberus | Planned | [`CerberusGameSpec.md`](game-modes/planned/CerberusGameSpec.md) |

### Phase 4 — Clear the Board

| Item | Status | Spec |
|------|--------|------|
| Ring-cell engine + heat map UI | Planned | [`ClearTheBoardGameSpec.md`](game-modes/planned/ClearTheBoardGameSpec.md) |
| Pure / Decay / Team vs Team variants | Planned | Same |
| `setup.validation.coopEvenTeams` | Planned | §5 |

### Per-mode ship status

| Mode | Catalog id | Rules spec | Engine | UI | Learn | A11y doc | History | Stats |
|------|------------|------------|--------|-----|-------|----------|---------|-------|
| Raid | `coop.raid` | Done | — | — | **Done** (preview) | — | — | — |
| Cerberus | `coop.cerberus` | Done | — | — | Partial | — | — | — |
| The Vault | `coop.theVault` | Done | — | — | Partial | — | — | — |
| Clear the Board | `coop.clearTheBoard` | Done | — | — | Partial | — | — | — |

---

## 14. Promotion checklist (any co-op mode)

1. Game spec §2 catalog metadata uses `section: Co-op` and `coop.{mode}` id
2. `MatchType` + engine land in `Domain/Engines/`
3. Gameplay screen + ViewModel on correct `GameplayUITemplate`
4. Co-op summary content provider (§10)
5. `MatchForfeitStandingsRegistry` if competitive chrome applies
6. Setup chips + `setup.validation.coop*` keys
7. `GameRulesCatalog` + `play.rules.{mode}.*` + `play.coop.{mode}.*` (§8)
8. WCAG screen evidence `accessibility/wcag-2.1-aa/screens/{mode}-match.md` (§9)
9. Light/dark contrast check on co-op chrome (§7.5)
10. History card builder + `ActivityModeFilter` case
11. Stats reducer if new `ModeStatKind` metrics ship
12. SwiftData events + migration if new payload shapes
13. Catalog `status` → `.shipped`; update [`docs/feature-inventory.md`](../docs/feature-inventory.md)
14. UI + WCAG tests for §7 identifiers; gameplay layout tests per [`gameplay-layout-size-classes.mdc`](../.cursor/rules/gameplay-layout-size-classes.mdc)

---

## 15. Open decisions

| # | Question | Recommendation |
|---|----------|----------------|
| 1 | `PlaySetupCategory.coop` vs route via `matchType` only? | Defer dedicated category until Raid ships; Modes tab is primary entry |
| 2 | Hero cap unify at 3 or 4? | **4** for Vault / Clear the Board; Raid/Cerberus stay at 3 until playtest |
| 3 | Team vs Team inside co-op section? | **Yes** — human teams share co-op contract; filter by variant in stats |
| 4 | Learn rules on coming-soon co-op cards before engine ships? | **Resolved — Yes** — `hasRulesGuide` checks `GameRulesCatalog.hasPreviewGuide(for:)` when `matchType == nil`; Raid landed first |

---

## 16. Verification

| Field | Value |
|-------|--------|
| **Last verified** | 2026-06-12 |
| **Commit** | (pending — Scope A browse polish) |
| **Status** | Phase 0 done; Raid learn-rules preview on Modes tab; Phase 1 engine/UI not started |
| **Code** | `GameModeCatalog.swift`, `GameRulesCatalog.swift`, `ModesRootView.swift`, `GameModeCatalogCard.swift`, `GameModeCatalogTests.swift`, `GameModeSectionTests.swift`, `GameRulesCatalogTests.swift` |
| **Catalog ids** | `coop.raid`, `coop.cerberus`, `coop.theVault`, `coop.clearTheBoard` |
