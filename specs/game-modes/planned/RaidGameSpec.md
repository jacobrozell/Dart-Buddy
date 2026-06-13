# Raid Game Specification

## 1. Purpose

Define **Raid** — a cooperative player-vs-boss mode where **1–3 humans** share one boss HP pool, rotate standard visits, and survive phase shifts (Shield → Expose → Enrage) until the boss is defeated or every hero is down.

**Status:** Planned (`coop.raid`).  
**Brainstorm origin:** [`FutureIdeas/custom-games-brainstorm.md`](../../../FutureIdeas/custom-games-brainstorm.md) §33.

**Related specs:**
- [`CoopPvEModesSpec.md`](../../CoopPvEModesSpec.md) — shared co-op platform (catalog, setup, summary)
- [`BotOpponentSpec.md`](../../BotOpponentSpec.md) — boss is a non-throwing bot participant (portrait + tier; no `DartBotEngine` visits in v1)
- [`CampaignSpec.md`](../../CampaignSpec.md) — Journey stages may script boss tier, HP, and hero hearts
- [`MatchSpec.md`](../../MatchSpec.md) — lifecycle, resume, abandon
- [`MatchForfeitSpec.md`](../../MatchForfeitSpec.md) — team forfeit as boss victory
- [`MatchSummarySpec.md`](../../MatchSummarySpec.md) — co-op victory variant (§9)
- [`HistorySpec.md`](../../HistorySpec.md) — list cards, detail, filters
- [`CricketSpec.md`](../implemented/CricketSpec.md) — mark math reused in Shield phase
- [`DeleteAllDataSpec.md`](../../DeleteAllDataSpec.md) — setup chip reset when config persists

---

## 2. Catalog metadata

| Field | Value |
|-------|-------|
| **Section** | Co-op |
| **UI template** | G — Phase race (`phaseRace`) + boss chrome |
| **Stat kind** | `bossRaid` (new `ModeStatKind`; see §12) |
| **Ruleset (v1)** | `raid_standard` |
| **Catalog id** | `coop.raid` |
| **MatchType** | `raid` (when implemented) |

---

## Player count

| Question | Answer |
|----------|--------|
| **Solo?** | **Yes** — 1 human vs boss is supported (Enrage uses solo threshold rule, §5.3) |
| **Minimum** | 1 human |
| **Recommended** | 2–3 humans (pub raid night) |
| **App maximum** | 3 humans (+ 1 boss entity, non-roster-cap) |

### Brainstorm
- Boss is **not** a fourth "player" in setup caps — humans only in roster picker; boss auto-attached at match start.
- **No preset/training/custom bots on hero team** in v1 — humans only. Journey may pair 1 human + NPC "ally" in a future amendment; out of scope here.
- Solo raid matters for Journey tutorials and practice.
- At 3 humans, full rounds are long but Enrage tension is highest — recommended party size.

---

## 3. MVP Scope

### In scope (v1)

| Item | Default | Configurable |
|------|---------|--------------|
| Boss tier | **Challenger** (45 HP) | Challenger / Standard (60) / Nightmare (80) |
| Hero hearts | **3** each | 3 / 4 / 5 |
| Boss phases | Shield → Expose → Enrage overlay | Tier adjusts HP thresholds (§5.2) |
| Shield damage | Team cricket close on 20–16 → **8 HP** | Fixed in v1 |
| Expose damage | Double **2 HP**, triple **3 HP**, single **0** | Fixed in v1 |
| Enrage | Lowest visit total loses 1 heart (2+ heroes); solo threshold rule | On/off chip (default on) |
| Turn order | Heroes rotate full 3-dart visits | — |
| Scoring input | Full-board dart pad (all phases) | Segment hints per phase |
| Undo | Undo last accepted hero visit | — |
| Pause / resume | Standard in-progress match resume | — |
| History | Full `MatchRecord` parity | Activity filter + co-op summary |
| Entry | Modes catalog + Play co-op picker (when co-op surface ships) | Journey scripted raids |

### Out of scope (v1)
- Boss throws darts at heroes (`DartBotEngine` boss visits)
- 4+ humans on one raid
- Hero bots or AI allies
- Loot / gear / persistent raid progression (Journey stars only)
- Online async co-op
- Points-off cricket variants in Shield
- Per-hero class roles (tank, healer, etc.) — future amendment
- Achievements tied to flawless raids

---

## 4. Product goals

| Goal | How Raid delivers |
|------|-------------------|
| **Co-op fantasy** | Shared boss HP bar; table cheers on closes and doubles |
| **Phase readability** | Banner + pad hints change damage rules — no rulebook lookup |
| **Hard moments, big payoff** | Expose doubles and Shield closes feel earned; Enrage punishes weak rounds |
| **Solo + party** | Same engine; Journey and pub night share one mode |
| **Dart Buddy exclusive** | Phase HP + team cricket + enrage strike is not a pub chalkboard game |

---

## 5. Rules Engine (`RaidEngine`)

Pure domain engine — no SwiftUI. Boss never submits darts in v1.

### 5.1 Config (`MatchConfigRaid`, payload v1)

| Field | Type | Default |
|-------|------|---------|
| `bossTier` | `challenger` \| `standard` \| `nightmare` | `standard` |
| `heroHearts` | Int | `3` |
| `enrageEnabled` | Bool | `true` |

Derived from `bossTier`:

| Tier | `bossMaxHP` | `shieldUntilHP` (exclusive floor) | `enrageAtHP` (inclusive ceiling) |
|------|-------------|-----------------------------------|----------------------------------|
| Challenger | 45 | 40 | 15 |
| Standard | 60 | 40 | 20 |
| Nightmare | 80 | 50 | 25 |

`shieldUntilHP`: while `bossHP > shieldUntilHP`, **Shield** rules apply.  
`enrageAtHP`: while `bossHP <= enrageAtHP` **and** `enrageEnabled`, **Enrage** overlay is active after each hero round.

### 5.2 State

```text
bossHP: Int
bossMaxHP: Int
phase: shield | expose          // derived from bossHP vs shieldUntilHP
enrageActive: Bool              // derived from bossHP vs enrageAtHP

teamCricketMarks: [Segment: Int] // 20,19,18,17,16 only; team-shared, 0..3+
heroes: [HeroState]
currentHeroIndex: Int
roundIndex: Int                 // full hero cycles since match start

HeroState:
  playerId: UUID
  hearts: Int
  damageDealt: Int              // running total for MVP
  isDown: Bool                  // hearts == 0
```

Boss participant record exists for display (`displayNameAtMatchStart` = tier name, e.g. "The Challenger") but has **no turn order slot**.

### 5.3 Phase damage rules

#### Shield (`bossHP > shieldUntilHP`)

- Valid damage segments: **20, 19, 18, 17, 16** only.
- Team marks (Cricket math): single = 1, double = 2, triple = 3 marks on segment.
- Marks accumulate on **shared** team track per segment.
- When team marks on a segment reach **3** (close):
  - Apply **8 HP** boss damage once per segment (first close only).
  - Segment marked **closed** — further hits on that segment in Shield deal **0** boss damage.
- Bull and segments 1–15 deal **0** boss damage in Shield (pad may grey them out).
- A single visit may close multiple segments; each first-close triggers 8 HP.

#### Expose (`bossHP <= shieldUntilHP`)

- **Double** (any segment 1–20, bull counts as double 25): **2 HP**.
- **Triple**: **3 HP**.
- **Single**: **0 HP**.
- Team cricket track is **inactive** (hidden in UI).

#### Enrage overlay (`bossHP <= enrageAtHP` and `enrageEnabled`)

- Shield or Expose damage rules still apply per current `phase` bracket.
- After **each hero round** — when every **living** hero has completed exactly one visit since the last enrage check — boss **strikes**:

| Heroes living | Strike rule |
|---------------|-------------|
| **1** | If visit total **< 60**, lose **1 heart**; else no strike. (Visit total = sum of three dart scores.) |
| **2+** | Each hero with the **lowest** visit total this round loses **1 heart**. Ties: **all** tied lowest lose 1 heart. |

- Down heroes skip turns; they do not count toward round completion.
- Enrage strike runs **before** next hero round begins; announce via banner + haptic.

### 5.4 Turn flow

1. Match starts at full boss HP; `phase = shield`.
2. Living heroes take turns in fixed seat order (setup `turnOrder`).
3. Hero submits up to 3 darts; engine resolves boss damage and updates cricket marks.
4. If `bossHP <= 0` → **Victory** (§5.6).
5. If enrage check due → apply strikes; if all heroes down → **Defeat**.
6. Advance `currentHeroIndex` to next living hero; increment `roundIndex` when wrap completes.
7. Recompute `phase` and `enrageActive` from `bossHP`.

### 5.5 Visit resolution (pseudocode)

```text
for each dart in visit:
  if phase == shield:
    if segment in {20..16} and segment not closed:
      add marks; on close: bossHP -= 8
  else if phase == expose:
    if multiplier == double: bossHP -= 2
    if multiplier == triple: bossHP -= 3
  clamp bossHP >= 0
  hero.damageDealt += damage this dart
```

### 5.6 Match completion

| Outcome | Condition | `MatchStatus` | `winnerPlayerId` |
|---------|-----------|---------------|------------------|
| **Victory** | `bossHP == 0` | `completed` | `nil` (co-op; see summary) |
| **Defeat** | All heroes `isDown` | `completed` | Boss participant id (stored for history/forfeit parity) |
| **Forfeit** | User forfeit | `forfeited` | Boss participant id |
| **Abandon** | User abandon | `abandoned` | — |

### 5.7 Undo

Replay from events restores `bossHP`, cricket marks, closed segments, hero hearts, `damageDealt`, turn index, and round index. Undo **cannot** cross match terminal states.

---

## 6. Boss participant (non-throwing)

| Field | Value |
|-------|-------|
| `botKindRaw` | `preset` |
| `botDifficultyRaw` | Maps from tier (Medium / Hard / Pro) — **flavor only** in v1 |
| Throws darts | **Never** in v1 |

Boss UI: portrait slot, tier name, HP bar, phase label, enrage indicator.

Future (`RaidEngine` v2): optional boss "interrupt" turns — separate spec amendment.

---

## 7. UI Specification

### Template G+ — Phase race with boss chrome

| Region | Content |
|--------|---------|
| **Boss header** | HP bar (`45/60`), phase pill (Shield / Expose), enrage flame when active |
| **Hero strip** | Hearts per human; down state greyed; current thrower highlight |
| **Main board** | Shield: mini team cricket grid (20–16). Expose: damage legend (D=2, T=3) |
| **Pad** | Full board; optional dim on inactive segments in Shield |
| **Banner** | Phase transition, close for 8 HP, enrage strike, victory/defeat |
| **Actions** | Submit visit, Undo |

### Setup (`SetupHomeView` party → Raid)

- Boss tier chip (Challenger / Standard / Nightmare)
- Hero hearts chip (3 / 4 / 5)
- Enrage toggle (on/off)
- Roster: 1–3 humans only; boss shown as fixed opponent card
- Validation: `setup.validation.raidHeroCount` (1...3), `setup.validation.raidHumansRequired`

### Match end

- Routes to **co-op summary** (§9) — not single-winner ceremony.
- History records all heroes + boss tier + outcome.

### Accessibility

- HP and hearts have accessibility values (`play.raid.bossHPAccessibilityFormat`, `play.raid.heartsAccessibilityFormat`).
- Phase changes announced to VoiceOver.
- Pad inactive segments still focusable with "no damage in Shield" hint.

Manual screen doc (when implemented): `accessibility/wcag-2.1-aa/screens/raid-match.md`.

---

## How to Play

| | |
|---|---|
| **Key prefix** | `play.rules.raid.` |
| **Shipped in app** | Planned |

### Overview

| **Title key** | `play.rules.raid.overview.title` |
| **Body key** | `play.rules.raid.overview.body` |

Work together to defeat the boss before you run out of hearts. Take turns throwing three darts each. The boss fight has two damage phases — cricket closes, then doubles — and enrage punishes weak rounds when the boss is almost down.

### Shield phase

| **Title key** | `play.rules.raid.shield.title` |
| **Body key** | `play.rules.raid.shield.body` |

While the boss has high health, only **twenty through sixteen** matter. Your team shares cricket marks on those numbers. Closing a number deals **eight** damage. Other segments do nothing in this phase.

### Expose phase

| **Title key** | `play.rules.raid.expose.title` |
| **Body key** | `play.rules.raid.expose.body` |

When the boss is wounded, **doubles** deal two damage anywhere and **triples** deal three. Singles score no damage — go big or go home.

### Enrage

| **Title key** | `play.rules.raid.enrage.title` |
| **Body key** | `play.rules.raid.enrage.body` |

When the boss is nearly defeated, enrage activates. After each full round of hero throws, the boss strikes. With two or more players, whoever had the **lowest visit total** loses a heart. Solo? Score at least **sixty** on your visit or lose a heart.

### Hearts and down

| **Title key** | `play.rules.raid.hearts.title` |
| **Body key** | `play.rules.raid.hearts.body` |

Each hero starts with a limited number of hearts. Lose them all and you're **down** — you skip turns. If every hero is down, the boss wins.

### Winning

| **Title key** | `play.rules.raid.winning.title` |
| **Body key** | `play.rules.raid.winning.body` |

Reduce the boss to **zero** health before the team is wiped out.

---

## 8. Localization

| Status | Meaning |
|--------|---------|
| **New** | All keys below — add at implementation |

### Catalog & setup

| Key | Notes |
|-----|-------|
| `modes.catalog.coop.raid.name` | "Raid" |
| `modes.catalog.coop.raid.blurb` | e.g. "Co-op boss fight — close, then finish" |
| `play.coop.raid.title` / `.subtitle` | Setup header |
| `play.raid.setup.bossTier` | Tier picker label |
| `play.raid.setup.bossTier.challenger` / `.standard` / `.nightmare` | |
| `play.raid.setup.heroHearts` | |
| `play.raid.setup.enrageEnabled` | |
| `setup.validation.raidHeroCount` | 1–3 humans |
| `setup.validation.raidHumansRequired` | At least one human |

### Gameplay (`play.raid.*`)

| Key | Notes |
|-----|-------|
| `play.raid.navTitle` | |
| `play.raid.phase.shield` / `.expose` | |
| `play.raid.enrage.active` | |
| `play.raid.bossHPFormat` | `"%d / %d"` |
| `play.raid.closeDamageFormat` | "Closed %@ — 8 damage!" |
| `play.raid.exposeDamageFormat` | Double/triple callouts |
| `play.raid.enrageStrikeFormat` | Who lost a heart |
| `play.raid.heroDown` | |
| `play.raid.victory` / `play.raid.defeat` | |
| `play.raid.pad.shieldHint` / `.exposeHint` | |
| `play.raid.mvpFormat` | Most damage dealt |

### How to play (`play.rules.raid.*`)

`overview`, `shield`, `expose`, `enrage`, `hearts`, `winning` — see §How to Play.

### History

| Key | Notes |
|-----|-------|
| `history.timeline.raidVisitFormat` | Hero visit + damage |
| `history.timeline.raidPhaseChangeFormat` | |
| `history.timeline.raidEnrageFormat` | |
| `history.detail.raidSummaryFormat` | Outcome, tier, MVP |
| `history.filter.raid` | Mode filter label |

### Errors (`error.match.raid.*`)

| Key | When |
|-----|------|
| `invalidHeroCount` | Setup |
| `heroDown` | Turn submission while down |
| `matchComplete` | Input after terminal |

Register in `GameRulesCatalog.raid` when shipping.

---

## 9. Match summary (co-op variant)

Raid uses a **team outcome** layout — extend [`MatchSummarySpec.md`](../../MatchSummarySpec.md):

| Element | Victory | Defeat |
|---------|---------|--------|
| Headline | "Boss defeated!" | "Raid failed" |
| Subhead | Boss tier + remaining hero hearts sum | Boss HP remaining |
| MVP row | Hero with highest `damageDealt` | Same (moral victory) |
| Stats row | Total damage, rounds, phase reached | |
| Hero list | All participants with damage + hearts left | |
| Winner card | **Hidden** — no single winner ceremony |
| Actions | Done · Raid again (prefill tier) | |

`winnerPlayerId` on `MatchRecord` is `nil` on victory; boss id on defeat/forfeit for stats pipeline consistency.

---

## 10. Persistence & history

### Match platform

- `MatchType.raid`
- `MatchRecord` + hero `MatchParticipantRecord`s + boss `MatchParticipantRecord`
- `MatchSnapshotRecord` for resume
- `status`: `inProgress` → `completed` | `forfeited` | `abandoned`

### Events (append-only)

| Event | Payload highlights |
|-------|-------------------|
| `RaidVisitEvent` | `heroId`, `darts[]`, `visitTotal`, `bossDamageDealt`, `marksBefore/After`, `phase` |
| `RaidPhaseChangeEvent` | `from`, `to`, `bossHP` |
| `RaidEnrageStrikeEvent` | `affectedHeroIds[]`, `visitTotals` |
| `RaidHeroDownEvent` | `heroId` |

### History card (`MatchHistoryCardPayload`)

- Mode badge: **Raid**
- Primary chip: `Victory` / `Defeat` + boss tier
- Secondary chip: `Boss HP 0` or `%d HP left`
- Participants: hero names (truncate at 3)

### Filters & stats

- Activity mode filter includes **Raid** when shipped.
- Statistics: §12; campaign-tagged raids filter per [`CampaignSpec.md`](../../CampaignSpec.md) when Journey ships.

Schema registration: bump [`SwiftData.md`](../../SwiftData.md) when implementing.

---

## 11. Forfeit & standings

Per [`MatchForfeitSpec.md`](../../MatchForfeitSpec.md) §6.7 when `raid` ships:

| Case | Standings leader |
|------|------------------|
| Hero forfeits | Boss wins |
| Compare metric | `bossHP` remaining (lower is better for heroes) — used in summary only |

Register `MatchForfeitStandingsRegistry.raid`.

---

## 12. Statistics (`bossRaid` stat kind)

New `ModeStatKind.bossRaid` in [`GameModeCatalog.swift`](../../../Features/Modes/GameModeCatalog.swift).

| Metric | Description |
|--------|-------------|
| `raidsCompleted` | Victories |
| `bossesDefeated` | Count by tier |
| `totalBossDamage` | Sum across raids |
| `avgRoundsPerVictory` | Pace |
| `enrageSurvivals` | Rounds in enrage without team wipe |

Player detail Statistics segment: show when player participated in ≥1 raid.

---

## 13. Journey integration (optional content)

Raid stages may appear in bundled Journey JSON per [`CampaignSpec.md`](../../CampaignSpec.md):

```json
{
  "stageId": "act2_raid_challenger",
  "matchType": "raid",
  "config": {
    "bossTier": "challenger",
    "heroHearts": 3,
    "enrageEnabled": true
  },
  "winCondition": "bossDefeated",
  "stars": { "1": "win", "2": "2+ hearts team total", "3": "no hero down" }
}
```

Journey raids auto-bind primary player + optional guest slots — amendment to Campaign spec when first raid stage ships.

---

## 14. Testing

### Unit (`RaidEngineTests`)

- Shield: marks accumulate team-wide; close deals 8 once; closed segment no repeat damage
- Phase transition at `shieldUntilHP` boundary
- Expose: double/triple/single damage table
- Enrage: multi-hero lowest visit; tie breaks; solo threshold 60
- Hero down skips turns; wipe at 0 hearts
- Victory at `bossHP == 0`; defeat when all down
- Undo restores full raid state

### Setup

- 1–3 humans accepted; 0 humans rejected; hero bots rejected
- Boss tier chips persist in config payload

### UI

- Phase banner transitions; enrage indicator; boss HP accessibility labels
- Co-op summary layout (no winner card on victory)

### Forfeit

- `everyShippedMatchTypeHasForfeitStandingsRegistered` includes `raid`

---

## 15. Implementation order (suggested)

1. `RaidEngine` + unit tests (pure domain)
2. `MatchType.raid`, config payload, events, snapshot codec
3. `RaidMatchViewModel` + `RaidMatchScreen` (boss chrome + shield cricket grid)
4. Setup chips + catalog row (`status: .planned` → shipped)
5. Co-op match summary + history card builder
6. Forfeit registration + UI smoke
7. Journey stage template (optional)

---

## 16. Open questions

1. **8 HP per close** — playtest tuning; may drop to 5 on Challenger tier.
2. **Enrage solo threshold** — 60 aligns with "one ton" fantasy; configurable?
3. **Nightmare tier** — +1 heart loss on enrage strike (brainstorm) — defer to v1.1?
4. **Hero classes** — v2 archetypes (e.g. double damage on expose) — separate amendment.
5. **Boss throws** — v2 adds `DartBotEngine` "interrupt" visits targeting hero hearts.

---

## 17. Verification

| Field | Value |
|-------|-------|
| **Status** | Planned |
| **Spec author** | 2026-06-11 brainstorm promotion |
| **Code** | Not started |
| **Catalog id** | `coop.raid` |
