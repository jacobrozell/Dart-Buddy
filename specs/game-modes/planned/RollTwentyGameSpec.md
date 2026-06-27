# Roll Twenty Game Specification

## 1. Purpose

Define **Roll Twenty** — a party mode where the app rolls a **D20** (values 1–20) at the start of each visit; the active player tries to hit that segment in three darts. Higher multipliers score more. First to the target total wins.

**Status:** Planned (`party.rollTwenty`).  
**Brainstorm origin:** Tabletop D20 + pub dart games; no prior Dart Buddy spec.

**Related specs:**
- [`TeamPlaySpec.md`](../../TeamPlaySpec.md) — optional 2-team scoring
- [`ScoringInputSpec.md`](../../ScoringInputSpec.md) — dart pad / visual board entry
- [`VisualDartboardInputSpec.md`](../../VisualDartboardInputSpec.md) — highlight rolled segment on board
- [`MatchSpec.md`](../../MatchSpec.md) — lifecycle, undo, resume

---

## 2. Catalog metadata

| Field | Value |
|-------|-------|
| **Section** | Party |
| **UI template** | **S** — Dice target (`diceTarget`) — new |
| **Stat kind** | `diceTarget` (new; hit % on rolled segment, avg points per visit) |
| **Ruleset (v1)** | `roll_twenty_standard` |
| **Catalog id** | `party.rollTwenty` |
| **MatchType** | `rollTwenty` (when implemented) |

**Display name:** Roll Twenty  
**Marketing blurb:** "Roll a D20. Hit that number before the table does."

---

## Player count

| Question | Answer |
|----------|--------|
| **Solo?** | Yes — accuracy / high-score practice |
| **Minimum** | 1 |
| **Recommended** | 2–4 FFA; 4 or 6 for teams (even, see [`TeamPlaySpec.md`](../../TeamPlaySpec.md)) |
| **App maximum** | 8 |

### Brainstorm
- Solo: chase personal best hit rate or points in N visits.
- FFA: each player rolls their own target every visit — no shared roll.
- **Teams (v1 optional):** team points sum; same visit rules per thrower.
- Bots allowed as opponents (preset tiers); bot "rolls" use seeded RNG like other bot engines.

---

## 3. MVP Scope

### In scope (v1)

| Item | Default | Configurable |
|------|---------|--------------|
| Die | D20 → segment **1–20** | Fixed (no D12/D10 variants in v1) |
| Darts per visit | **3** | Fixed v1 |
| Scoring on target | S=**1**, D=**2**, T=**3** | Fixed v1 |
| Off-target dart | **0** | Fixed v1 |
| Win condition | First to **50** team/player points | 30 / 50 / 100 |
| Match shape | Single game (no legs) | — |
| Roll moment | Start of each visit, before first dart | — |
| **Roll mode** | **Single die** — one D20 = target segment (20 is segment 20) | Single / **Double dice** (§5.5) |
| Teams | **Off** (FFA) — ship **after** FFA + [`TeamPlaySpec.md`](../../TeamPlaySpec.md) | Off / 2 teams (post-FFA) |
| Input | Standard pad + visual board | — |
| Undo | Undo last dart; **does not** re-roll die until visit resets | — |
| History | Points, hit rate, double-dice bull visits, sudden-death rounds | — |

### Out of scope (v1)
- D20 values that map to doubles/trebles by die face (e.g. "roll D = double that number")
- Shared roll for whole table (one target per round — defer; FFA is clearer)
- Online sync
- Vision verify
- Team mode (ships after FFA + [`TeamPlaySpec.md`](../../TeamPlaySpec.md))

---

## 4. Product goals

| Goal | How Roll Twenty delivers |
|------|---------------------------|
| **Instant hook** | Dice animation + big target number — readable from across the bar |
| **Low rules burden** | One sentence: roll, hit it, score by ring |
| **Tabletop crossover** | D20 idiom for RPG / board-game crowds |
| **Reuse scoring stack** | Standard `DartInput`; no new engine primitives |
| **Team nights** | Optional team totals without new mode |

---

## 5. Rules Engine (`RollTwentyEngine`)

### 5.1 Config (`MatchConfigRollTwenty`, payload v1)

| Field | Type | Default |
|-------|------|---------|
| `pointsToWin` | Int | `50` |
| `rollMode` | `singleDie` \| `doubleDie` | `singleDie` |
| `teamMode` | `freeForAll` \| `twoTeams` | `freeForAll` |
| `teamAssignment` | `[PlayerId: TeamSide]` | — when `twoTeams` (post-FFA) |

`TeamSide`: `teamA` \| `teamB` — see [`TeamPlaySpec.md`](../../TeamPlaySpec.md).

### 5.2 State

```text
scores: [PlayerId: Int]              // FFA
teamAScore / teamBScore: Int         // twoTeams
currentPlayerId: PlayerId
rolledPrimary: Int?                  // 1...20; nil before roll completes
rolledSecondary: Int?                // doubleDie only
targetKind: segment | bull | eitherSegment  // see §5.5
targetSegments: [Int]                // 1...20 subset for UI highlight
visitDartsThrown: Int                // 0...3
phase: regulation | suddenDeath       // suddenDeath when tied at win line
suddenDeathParticipantIds: [PlayerId] // or team sides when twoTeams
rngSeed: UInt64
isComplete: Bool
winnerPlayerIds: [PlayerId]
winningTeam: TeamSide?
```

### 5.3 Visit flow

1. **Roll** (per `rollMode` — §5.5) → set `targetKind` + `targetSegments`.
2. Player throws up to 3 darts. Each dart:
   - Resolve segment + multiplier.
   - If dart matches active target rules: add ring points (S=1, D=2, T=3) to player (and team when enabled).
   - Else: 0.
3. End visit → next player (or sudden-death rotation) → new roll.

**Regulation:** standard rotation until win or sudden-death trigger.

### 5.4 Win detection & sudden death

**Regulation win**
- **FFA:** first `scores[id] >= pointsToWin`.
- **Teams:** first `teamAScore` or `teamBScore >= pointsToWin`.

**Sudden-death trigger (locked)**
- Two or more players (or teams) reach `>= pointsToWin` on the **same scoring pass**, **or** multiple leaders tie at the top after a visit that crosses the line.
- Only tied leaders enter sudden death; others eliminated from tie-break.

**Sudden-death visit**
1. Set `phase = suddenDeath`.
2. Each tied leader gets one full visit (roll + 3 darts) in turn order.
3. **Winner:** highest **visit point total** among tied leaders.
4. Still tied → **repeat** sudden-death rounds until exactly one leader remains.
5. No shared victories at `pointsToWin`.

### 5.5 Roll modes (locked)

#### `singleDie` (default)

- Roll one D20 → `targetKind = segment`, `targetSegments = [roll]`.
- **20 is segment 20** — no reroll, no bull wildcard.

#### `doubleDie` (setup option)

- Roll **two** D20s (`rolledPrimary`, `rolledSecondary`).

| Outcome | Target |
|---------|--------|
| **Same value** (e.g. 3 + 3) | `targetKind = bull` — hit **outer or inner bull**; score S=1 / D=2 / T=3 on bull rings (no segment scoring this visit) |
| **Different values** (e.g. 7 + 12) | `targetKind = eitherSegment`, `targetSegments = [7, 12]` — score on **either** segment with normal S/D/T |

- UI shows both dice; board highlights one wedge or both; bull ring glow when doubles match.
- Accessibility: `rollTwenty.accessibility.doubleMatchBull` vs `rollTwenty.accessibility.doubleTwoTargets`.

**Removed (do not ship):** nat-20 reroll, bull wildcard on single 20 — superseded by double-dice bull rule.

### 5.6 Bots

`DartBotEngine+RollTwenty`: aim rolled segment with tier hit rates; on miss, random segment per existing bot spray rules.

### 5.7 Undo

Remove last dart event; restore scores and visit dart count. **Do not** revert roll unless undo clears entire visit (all 3 darts + roll) — same policy as Around the Clock visit undo.

### 5.8 Events (history / stats)

`RollTwentyVisitEvent`:
- `playerId`, `turnIndex`, `rollMode`, `rolledPrimary`, `rolledSecondary?`, `targetKind`
- `darts: [RollTwentyDartEvent]` — segment, multiplier, pointsAwarded
- `phase`, `timestamp`

---

## 6. UI Specification (Template S — `diceTarget`)

### 6.1 Layout

```text
+--------------------------------------------------+
| Roll Twenty          Team A 24 · Team B 31       |
|--------------------------------------------------|
|         [ animated D20 showing 14 ]              |
|         [ second D20 when doubleDie ]            |
|         TARGET: 14  (or BULL / 7 or 12)          |
|--------------------------------------------------|
|     (dartboard — segment 14 highlighted)         |
|--------------------------------------------------|
| Visit: ●●○   You: 18 pts                         |
|--------------------------------------------------|
| [ standard scoring pad / visual board ]          |
+--------------------------------------------------+
```

- **Dice card:** one or two die faces; roll animation ~800 ms (Reduce Motion → fade to result).
- **Target callout:** segment, dual-segment, or bull copy per §5.5; highlight on board.
- **Double match:** gold flash + haptic when both dice show the same value → bull target.
- **Scoreboard:** FFA player chips with points; teams mode (post-FFA) shows team totals.

### 6.2 Setup chips

- Points to win: 30 / 50 / 100
- Roll mode: **Single die** / **Double dice**
- Teams: Off / 2 teams (post-FFA; requires [`TeamPlaySpec.md`](../../TeamPlaySpec.md))

### 6.3 Accessibility

- Announce roll result per target kind (segment / two segments / bull).
- Die animation decorative; result in accessibility label on target card.

---

## How to Play

| | |
|---|---|
| **Key prefix** | `play.rules.rollTwenty.` |
| **Shipped in app** | No (planned) |
| **Estimated release** | `TBD` |

### Overview
| **Title key** | `play.rules.rollTwenty.overview.title` |
| **Body key** | `play.rules.rollTwenty.overview.body` |

Each turn, the app rolls a twenty-sided die showing a number from 1 to 20. You have three darts to hit that segment. Singles score 1 point, doubles 2, triples 3. First player or team to the target score wins. Ties at the win line go to sudden-death visits.

### Double dice
| **Title key** | `play.rules.rollTwenty.doubleDice.title` |
| **Body key** | `play.rules.rollTwenty.doubleDice.body` |

Optional: roll two dice. If they show the same number, aim for the bull this turn. If they differ, score on either number shown.

### Sudden death
| **Title key** | `play.rules.rollTwenty.suddenDeath.title` |
| **Body key** | `play.rules.rollTwenty.suddenDeath.body` |

If two or more players tie at the win score, each tied player gets one more turn. Most points on that turn wins. Still tied? Do it again.

### Natural 20
| **Title key** | `play.rules.rollTwenty.naturalTwenty.title` |
| **Body key** | `play.rules.rollTwenty.naturalTwenty.body` |

A 20 is just segment 20 — no special rule unless you turn on Double dice (matching doubles aim at the bull).

### Teams
| **Title key** | `play.rules.rollTwenty.teams.title` |
| **Body key** | `play.rules.rollTwenty.teams.body` |

In team mode, all points go to your team's total. Teammates still roll and throw on their own visits.

---

## 7. Stats & history

| Metric | Formula |
|--------|---------|
| `visits` | completed visits |
| `hitsOnTarget` | darts with pointsAwarded > 0 |
| `hitPercent` | hitsOnTarget / dartsThrown |
| `avgPointsPerVisit` | sum points / visits |
| `doubleDiceBullVisits` | visits where double dice matched → bull target |
| `suddenDeathRounds` | count of sudden-death phases |

`StatKind.diceTarget` — Player Detail shows hit % + avg points; no 3-dart average.

---

## 8. Testing

### Unit
- Roll distribution smoke (1...20)
- Scoring S/D/T on/off target; either-segment mode
- Double dice: match → bull; mismatch → either segment
- Sudden death at tied win line
- Team score aggregation (when teams ship)
- Undo dart vs undo full visit

### UI
- Dice animation Reduce Motion path
- Board highlight matches rolled segment
- Team setup validation delegates to TeamPlaySpec tests

---

## 9. Cross-references

| Spec | Relationship |
|------|----------------|
| [`TeamPlaySpec.md`](../../TeamPlaySpec.md) | Optional 2-team mode |
| [`StatsSpec.md`](../../StatsSpec.md) §12 | Register `diceTarget` stat kind |
| [`SetupFlowSpec.md`](../../SetupFlowSpec.md) | Setup chips + team roster |
| [`MatchForfeitSpec.md`](../../MatchForfeitSpec.md) | Forfeit standings when shipped |

---

## 10. Verification

| Field | Value |
|-------|--------|
| **Estimated release** | `TBD` |
| **Last verified** | — |
| **Commit** | — |
| **Code** | — (planned) |

---

## 11. Decisions (locked 2026-06-26)

| # | Question | Decision |
|---|----------|----------|
| 1 | Tie at `pointsToWin` | **Sudden death** — tied leaders each get a roll + 3-dart visit; highest visit points wins; repeat until one leader remains. No shared win. |
| 2 | Roll 20 / extra dice | **Single die (default):** 20 = segment 20. **Double dice (option):** two D20s; **matching values → bull target**; different values → score on **either** segment. No nat-20 reroll. |
| 3 | Ship FFA before teams | **Yes** — FFA ships first; team mode after [`TeamPlaySpec.md`](../../TeamPlaySpec.md). |
