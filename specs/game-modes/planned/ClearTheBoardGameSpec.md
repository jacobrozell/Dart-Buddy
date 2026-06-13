# Clear the Board Game Specification

## 1. Purpose

Define **Clear the Board** — a ring-cell sweep where players close **segment × ring** wedges (e.g. T1, D1, and S1 are three independent cells). Points accrue on first-time closes; bulls use a special **catch-up** rule by default. Ships in three shapes: **co-op** (Pure, Decay) and **Team vs Team** (friends vs friends, **no bots** in v1).

**Status:** Planned (`coop.clearTheBoard`).  
**Brainstorm origin:** [`FutureIdeas/custom-games-brainstorm.md`](../../../FutureIdeas/custom-games-brainstorm.md) §48.

**Related specs:**
- [`CoopPvEModesSpec.md`](../../CoopPvEModesSpec.md) — shared co-op platform
- [`RaidGameSpec.md`](RaidGameSpec.md) — co-op summary variant (§9)
- [`FleetGameSpec.md`](FleetGameSpec.md) — shared `BoardCell` / ring grid concepts
- [`MatchSpec.md`](../../MatchSpec.md) — lifecycle, resume, abandon
- [`SoloPracticeMatchSummarySupplement.md`](../../SoloPracticeMatchSummarySupplement.md) — co-op stars (Pure variant)
- [`MatchSummarySpec.md`](../../MatchSummarySpec.md) — winner ceremony (Team vs Team)

---

## 2. Catalog metadata

| Field | Value |
|-------|-------|
| **Section** | Co-op |
| **UI template** | H — Board state (`boardState`) + **ring-cell** heat map |
| **Stat kind** | `boardClaim` (cells cleared, team points, darts-to-clear) |
| **Ruleset (v1)** | `clear_the_board_standard` |
| **Catalog id** | `coop.clearTheBoard` |
| **MatchType** | `clearTheBoard` (when implemented) |

**Display name:** Clear the Board  
**Marketing blurb:** "Close every single, double, and triple — together or team vs team."

---

## Player count

| Question | Answer |
|----------|--------|
| **Solo?** | **Yes** — Pure variant only (1 human) |
| **Minimum** | 1 human (Pure); **2 humans** (Team vs Team) |
| **Recommended** | 2–4 humans co-op; **2–8** for Team vs Team (even teams) |
| **App maximum** | 4 (Pure / Decay); **8** (Team vs Team — up to **4v4**) |

### Brainstorm
- **Pure / Decay:** one shared closure map — all humans co-op; cap **4** (turn length).
- **Team vs Team:** two human teams, **no bots in v1** — pass-and-play on one device.
- Team vs Team roster: **even split** only — **1v1, 2v2, 3v3, or 4v4** (2, 4, 6, or 8 humans). Odd counts rejected.
- 4v4 is long but valid for league nights; expect ~25–40 min — same as long X01 legs.
- Solo Pure is a practice achievement run; stars compare darts-to-clear on same config (local bests).

---

## 3. MVP Scope

### Three variants (setup primary picker — separate modes, not overlays)

| Variant | Opponent | Win | Lose |
|---------|----------|-----|------|
| **Pure Clear** | None (co-op) | All wedge cells closed | — (abandon only) |
| **Decay** | Decay meter (co-op) | All cells closed before collapse | Third collapse |
| **Team vs Team** | Other human team | **Most points** when all 60 cells claimed | Lower score at board complete |

Each variant uses the same ring-cell resolution; co-op shares one scoreboard, Team vs Team uses **claim** rules (§5.6c).

**No bots in v1** for any Clear the Board variant (including Decay — collapse is a meter, not a bot opponent).

### In scope (v1)

| Item | Default | Configurable |
|------|---------|--------------|
| Variant | **Pure Clear** | Pure / Decay / Team vs Team |
| Wedge cells | 60 (1–20 × S/D/T) | Fixed |
| Close points | S=**1**, D=**2**, T=**3** | Fixed in v1 (no triple 5 until post-ship tuning) |
| Bull rule | **Catch-up** (§5.4) | Catch-up / Standard / Off |
| Re-hit closed wedge | **Waste** | Waste / Penalty (−1 team point) |
| Turn structure | Full 3-dart visits, rotate players | Fixed v1 |
| Undo | Undo last dart | — |
| History | Full `MatchRecord` + co-op summary | — |

### Out of scope (v1)
- Triple = 5 jackpot chip (revisit after playtest data exists)
- **Bots** in any variant (no AI rival, no bot fill for teams)
- Odd-player Team vs Team (2v1, 3v2, etc.) — even teams only
- 5v5 or larger (10+ humans)
- Per-player score leaderboard inside co-op (team totals only)
- Online / multi-device teams
- Long-term global par curves (use static pace table §5.5a)

---

## 4. Product goals

| Goal | How mode delivers |
|------|-------------------|
| **Completion fantasy** | Heat map empties — visceral 100% clear |
| **Ring literacy** | T1 ≠ D1 ≠ S1 teaches board geography |
| **Co-op** | One shared board; table calls open cells |
| **Team vs Team** | Same ring cells, friends claim wedges for points |
| **Catch-up bull** | Comeback when behind (pace, decay, or score trail) |
| **No bots** | Humans only — pub crew vs crew |
| **Configurable strictness** | Waste vs penalty on closed-cell replays |

---

## 5. Rules Engine (`ClearTheBoardEngine`)

### 5.1 Config (`MatchConfigClearTheBoard`, payload v1)

| Field | Type | Default |
|-------|------|---------|
| `variant` | `pure` \| `decay` \| `teamVsTeam` | `pure` |
| `bullRule` | `catchUp` \| `standard` \| `off` | `catchUp` |
| `closedCellReplay` | `waste` \| `penalty` | `waste` |
| `maxCollapses` | Int | `3` (Decay only) |
| `teamAssignment` | `[PlayerId: TeamSide]` | — (Team vs Team setup) |

`TeamSide`: `teamA` \| `teamB` — display names from roster colors at match start.

### 5.2 Ring cells (`BoardRingCell`)

Wedge cells (closeable):

```text
For segment in 1...20:
  cells: (segment, single), (segment, double), (segment, triple)
Total: 60 cells
```

Map `DartInput` → cell:
- `.single` on segment → `(segment, single)`
- `.double` → `(segment, double)`
- `.triple` → `(segment, triple)`
- Miss → no cell

**Bull** is **not** a wedge cell when `bullRule == catchUp` (§5.4).  
When `bullRule == standard`, bull adds **2** closable cells: `(bull, outer)` and `(bull, inner)` → **62** cells total.  
When `bullRule == off`, **60** cells only.

### 5.3 State

```text
closed: Set<BoardRingCell>
claimedBy: [BoardRingCell: TeamSide]   // Team vs Team only; empty in co-op
teamPoints: Int                        // co-op: one total
teamAPoints / teamBPoints: Int         // Team vs Team only
teamDartsThrown: Int
currentPlayerIndex: Int

// Decay (co-op)
decayMeter: Int              // 0..10
collapseCount: Int
```

### 5.4 Scoring on wedge close

When dart resolves to **open** wedge cell `C`:

| Ring | Points | Action (co-op) |
|------|--------|----------------|
| Single | 1 | Add to `teamPoints`; add `C` to `closed` |
| Double | 2 | Same |
| Triple | 3 | Same |

**Team vs Team** on open cell `C` by player on `side`:
- Add points to `teamAPoints` or `teamBPoints`.
- `closed.insert(C)`; `claimedBy[C] = side`.

**Re-hit closed wedge** (`closedCellReplay`):

| Setting | Effect |
|---------|--------|
| `waste` | No points; cell stays closed; dart consumed |
| `penalty` | No close; **−1** active scorer's team points (floor **0**; co-op uses single `teamPoints`) |

### 5.5 Bull rules

#### A. Catch-up (default — `bullRule: catchUp`)

Bull **never closes** and is **never** part of the 60-cell win checklist. It is a permanent **comeback valve**.

| Bull hit | Points (if eligible) | Closes? |
|----------|----------------------|---------|
| Outer bull | **2** | Never |
| Inner bull | **3** | Never |

**Eligible** only when team is **behind** (variant-specific):

| Variant | Behind when (scoring team) |
|---------|---------------------------|
| **Pure** | `closed.count < paceExpectedCloses(teamDartsThrown)` — static pace table (§5.5a) |
| **Decay** | `decayMeter >= 4` **OR** Pure behind rule |
| **Team vs Team** | Thrower's team points **<** opponent team points (strict `<`; tie = not behind) |

When **not behind:** bull hits follow `closedCellReplay` (waste or −1) — no positive points.

UI: bull ring glows **gold** when catch-up eligible for **active thrower's team**; dim when not.

#### B. Standard (`bullRule: standard`)

- Outer bull and inner bull are normal wedge-like cells (62-cell board).
- Points on first close: outer **2**, inner **3**; then closed forever.
- Win checklist includes both bull cells.

#### C. Off (`bullRule: off`)

- Bull hits ignored (waste); 60-cell win only.

#### 5.5a Pace table (Pure catch-up, no historical stats)

v1 uses a **fixed** expected-close curve (no long-term match DB required):

| `teamDartsThrown` (≥) | `paceExpectedCloses` |
|-----------------------|----------------------|
| 0 | 0 |
| 12 | 4 |
| 24 | 10 |
| 36 | 18 |
| 48 | 28 |
| 60 | 38 |
| 72 | 48 |
| 84+ | `min(59, closed.count + 2)` — always slightly behind at endgame unless clearing fast |

**Behind** when `closed.count < paceExpectedCloses(teamDartsThrown)`.

Tunable in one JSON file post-ship; not user-facing in v1.

### 5.6 Variant rules

#### Pure Clear

- No `decayMeter` / rival.
- **Win:** `closed` contains all wedge cells (60, or 62 if `bullRule == standard`).
- **Summary stars:** 1★ clear; 2★ under par darts (default par **90**); 3★ no penalty points lost.

#### Decay

- After each full **team round** (every living player threw once): if **zero** new wedge closes that round → `decayMeter += 1`; else `decayMeter = max(0, decayMeter - 1)`.
- When `decayMeter >= 10` → **Collapse:** reopen **one** closed wedge cell (lowest segment, prefer **single** ring if multiple) and reset meter to **5**.
- **Win:** full board clear before **3** collapses (setup: `maxCollapses: 3` default).
- **Lose:** third collapse.

#### Team vs Team (§5.6c)

See §5.6c — humans only, no bots.

### 5.6c Team vs Team

**Roster:** **2, 4, 6, or 8** humans — **1v1, 2v2, 3v3, or 4v4** — split evenly into **Team A** and **Team B** in setup (color chips). Validation: `setup.validation.clearTheBoardTeamEvenSplit` (count ∈ {2,4,6,8}, equal seats per side).

**Shared board, claim model:**
- One global 60-cell map (62 if `bullRule == standard`).
- First team to **close** an open cell **claims** it — opponent cannot score that cell again.
- Game **always** runs until **all** wedge cells are closed — **no early win** when a team reaches 31 cells.

#### Why not “most cells wins”?

On a 60-cell board, **31 cells = mathematical majority**. If the match ended there (or players treat cell lead as decisive), the trailing team has **no path to victory** — the game dies with 29 cells still open.

| Rejected rule | Problem |
|---------------|---------|
| First to **31 cells** wins | Opponent cannot catch up on cells; ~half the board unplayed |
| **Most cells** as sole win at full board | Same issue once 31 is hit mid-game — table gives up before finish |

**v1 resolution:** **Points win at full board**; **cells claimed** is a live race stat + tiebreaker, not an early or sole victory condition.

| Priority | Rule |
|----------|------|
| **1 — End** | All 60 (or 62) cells claimed — both teams keep throwing until the board is full |
| **2 — Winner** | Higher **team points** (S=1, D=2, T=3 per claimed cell) |
| **3 — Tie on points** | Higher **cells claimed** wins |
| **4 — Tie both** | Bull shootout (§5.6c) |

**Comeback on points:** A team ahead **31–29 on cells** can still **lose** if their closes were mostly singles and the opponent’s 29 were mostly triples/doubles.

*Example:* Team A claims **31 singles** → **31 pts**. Team B claims **29 cells** (mix of 10 triples, 10 doubles, 9 singles) → **30+20+9 = 59 pts**. B wins despite never leading the cell count.

**UI copy when cell majority reached:** *“31 cells — but points decide the win.”* Never show match-over at 31.

**Catch-up bull** keys off **point trail**, not cell trail — aligns with official win condition.

**Turn order:** Interleave teams each full visit — **A1 → B1 → A2 → B2 → …** → wrap (works for 1v1 through 4v4). Example **3v3:** A1 → B1 → A2 → B2 → A3 → B3 → A1… Example **4v4:** through A4/B4 before wrap.

**Catch-up bull:** active thrower's team must trail on points (`teamAPoints < teamBPoints` or reverse).

**Standard bull (Team vs Team):** each bull cell can be claimed once like any wedge — worth 2/3 to claiming team.

**Pass-and-play:** same device; optional identity handoff between throws (reuse Fleet handoff pattern when `handoffEachTurn` on).

**Bull shootout** (points **and** cells tied at 60/60): one dart each, catch-up off, outer/inner = 2/3; highest wins (re-throw on tie).

**Summary:** winning team + **point margin** primary; cells claimed shown as secondary (e.g. “Won 67–58 on points · 28–32 cells”).

### 5.9b Example (Team vs Team comeback)

Config: Team vs Team, catch-up bull, waste on re-hit.

1. Team A rushes singles → **31 cells**, **31 points**.
2. Team B slower but aims rings → **29 cells**, **59 points** (10×T + 10×D + 9×S).
3. Board hits 60/60 — **Team B wins on points** though they never held cell majority.
4. Mid-game: B was eligible for **catch-up bull** while behind on points even if they trailed on cells.

### 5.7 Turn flow

1. Active player throws up to 3 darts; each dart resolves immediately (close / bull / waste / penalty).
2. Check win/lose conditions.
3. Advance to next player (Team vs Team: alternate teams per §5.6c).
4. End of co-op team round → apply Decay tick (Pure/Decay only).

### 5.8 Undo

Replay removes last dart: reopen cell if it was closed, restore points, `claimedBy`, decay state.

### 5.9 Example (user scenario)

Config: Pure, catch-up bull, waste on re-hit.

1. Jacob **T1** → T1 closed, **+3** points.
2. Morgan **S1** → S1 closed, **+1** point. **D1 still open.**
3. Jacob **D1** → D1 closed, **+2** points. Segment 1 fully cleared.
4. Morgan **T1** → waste (already closed).
5. Team behind on pace → Morgan **inner bull** → **+3** catch-up points; bull still active.
6. Team ahead on pace → inner bull → waste.

---

## 6. UI Specification

### 6.1 Ring-cell heat map

| State | Visual |
|-------|--------|
| Open wedge | Dim wedge ring segment |
| Closed wedge (co-op) | Filled in team color |
| Claimed wedge (Team vs Team) | Team A / Team B color per `claimedBy` |
| Bull catch-up eligible | Gold bull halo |
| Bull not eligible | Neutral bull |

Tap open cell on map → optional pad hint (segment pre-select).

### 6.2 Header chrome

| Variant | Primary meter |
|---------|---------------|
| Pure | `42 / 60 cells` + team points |
| Decay | Decay meter bar + cells remaining |
| Team vs Team | **Points** (primary) + cells claimed A vs B (secondary); banner if cell majority but point deficit |

### 6.3 Setup

- **Variant** chip: Pure / Decay / Team vs Team (primary)
- **Bull rule:** Catch-up (recommended) / Standard / Off
- **Re-hit closed cell:** Waste / −1 point
- **Co-op:** roster 1–4 humans
- **Team vs Team:** roster **2, 4, 6, or 8** (1v1–4v4); assign Team A / Team B per player (no bots)

### 6.4 Match end

- Co-op summary (Pure/Decay win): cells cleared, points, darts, collapses (Decay).
- Team vs Team: winner team + point margin + claim breakdown.
- Heat map shows **full** board with team colors (Team vs Team) or single color (co-op).

---

## How to Play

| | |
|---|---|
| **Key prefix** | `play.rules.clearTheBoard.` |
| **Shipped in app** | Planned |

### Overview

| **Title key** | `play.rules.clearTheBoard.overview.title` |
| **Body key** | `play.rules.clearTheBoard.overview.body` |

Work together to close every single, double, and triple on the board. Each ring on each number counts separately — hitting triple 1 does not close double 1 or single 1. Score team points on first-time closes.

### Scoring closes

| **Title key** | `play.rules.clearTheBoard.scoring.title` |
| **Body key** | `play.rules.clearTheBoard.scoring.body` |

Singles earn 1 point, doubles 2, triples 3 for the team. Once a cell is closed, it stays closed unless Decay reopens one.

### Bull catch-up

| **Title key** | `play.rules.clearTheBoard.bullCatchUp.title` |
| **Body key** | `play.rules.clearTheBoard.bullCatchUp.body` |

By default the bull never closes. When your team is behind, outer bull scores 2 and inner bull scores 3 — a comeback chance. When you're ahead, bull hits don't score. Use Standard bull rules in setup if you want the bull to close like any other cell.

### Re-hitting closed cells

| **Title key** | `play.rules.clearTheBoard.rehit.title` |
| **Body key** | `play.rules.clearTheBoard.rehit.body` |

Setup choice: wasted dart (no effect) or lose 1 team point. Applies to closed wedges and to bull when catch-up is not active.

### Variants

| **Title key** | `play.rules.clearTheBoard.variants.title` |
| **Body key** | `play.rules.clearTheBoard.variants.body` |

**Pure** — clear the board together. **Decay** — idle rounds fill a decay meter; too many collapses and you lose. **Team vs Team** — two human crews race to claim cells and outscore each other when the board is full.

### Team vs Team

| **Title key** | `play.rules.clearTheBoard.teamVsTeam.title` |
| **Body key** | `play.rules.clearTheBoard.teamVsTeam.body` |

Split into two even teams (1v1 through 4v4). The first team to close a cell claims it — the other team cannot score there. Play continues until **every** cell is claimed (reaching 31 cells does not end the game). The team with the **most points** wins; triples and doubles are worth more than singles. If points tie, most cells claimed wins. Catch-up bull only helps the team that is behind on **points**.

---

## 7. Localization (new keys)

| Key | Notes |
|-----|-------|
| `modes.catalog.coop.clearTheBoard.name` / `.blurb` | |
| `play.clearTheBoard.setup.variant.pure` / `.decay` / `.teamVsTeam` | |
| `play.clearTheBoard.setup.teamA` / `.teamB` | Roster assignment |
| `setup.validation.clearTheBoardTeamEvenSplit` | 2/4/6/8 players, equal teams |
| `play.clearTheBoard.setup.teamSizeFormat` | "3v3", "4v4", etc. |
| `play.clearTheBoard.setup.bullRule.catchUp` / `.standard` / `.off` | |
| `play.clearTheBoard.setup.closedReplay.waste` / `.penalty` | |
| `play.clearTheBoard.cellsRemainingFormat` | |
| `play.clearTheBoard.teamPointsFormat` | |
| `play.clearTheBoard.cellClosedFormat` | |
| `play.clearTheBoard.bullCatchUpActive` / `.inactive` | |
| `play.clearTheBoard.decayCollapse` | |
| `play.clearTheBoard.teamScoreFormat` | A vs B |
| `play.clearTheBoard.teamVsTeamWinFormat` | |
| `play.clearTheBoard.cellMajorityNotOver` | "31 cells — points decide the win" |
| `play.clearTheBoard.trailingOnCellsLeadingOnPoints` | Comeback hint |
| `play.rules.clearTheBoard.*` | §How to Play |

---

## 8. Persistence & history

- `MatchType.clearTheBoard`
- Events: `ClearTheBoardDartEvent` (cell, points, bullCatchUp flag, replay penalty)
- History card: variant + `60/60` + team points + darts
- Schema: [`SwiftData.md`](../../SwiftData.md) when shipping

---

## 9. Testing

### Unit

- T1 then S1 then D1 independence
- Triple = 3 points (v1 fixed)
- Re-hit waste vs penalty floor at 0
- Catch-up bull eligible/ineligible per variant rules
- Standard bull 62-cell win
- Decay collapse reopens single preferentially
- Team vs Team: no early end at 31 cells; point winner despite cell deficit
- Team vs Team: tie on points → cells tiebreaker → bull shootout
- Team vs Team catch-up bull when trailing on points only

### UI

- Heat map 60 cells; closed state persists per cell
- Bull gold state toggles with behind flag

---

## 10. Open questions (narrowed)

1. **Pace table tuning** — playtest after first RC; no user-facing slider in v1.
2. **Decay reopen pick** — lowest segment + prefer single; alternate: random open cell.
3. **Triple 5** — deferred until Activity data on average clears exists.
4. **Catch-up bull on tie (Team vs Team)** — strict `<` on **points**; intentional.
5. **Cell majority at 31** — resolved: never end early; points primary; cells tiebreaker (§5.6c).

---

## 11. Verification

| Field | Value |
|-------|-------|
| **Status** | Planned |
| **Catalog id** | `coop.clearTheBoard` |
| **Code** | Not started |
