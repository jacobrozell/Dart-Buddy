# Baseball Darts — R&D Specification

**Status:** R&D / post-1.0  
**Source inspiration:** [Target Darts — Baseball](https://www.target-darts.co.uk/dart-games)  
**Index:** [`additional-game-modes.md`](additional-game-modes.md)

---

## 1. Purpose

Define Baseball darts for Dart Buddy: inning structure, run scoring, tie-breakers, engine/UI concepts, and persistence sketch. Baseball is a strong **second mode** after X01/Cricket because it reuses familiar 3-dart turns and segment multipliers.

**Players:** 2+ individuals (or teams as alternating throwers — v1: individuals only).

---

## 2. Game summary

Nine **innings** (rounds). In inning *n*, only hits on segment **n** count. Runs come from multiplier on that segment, **not** from the segment face value:

| Hit | Runs |
|-----|------|
| Single (thin/black of *n*) | 1 |
| Double (outer ring of *n*) | 2 |
| Triple (inner ring of *n*) | 3 |

Misses or hits on other segments = 0 runs. Highest total runs after 9 innings wins.

Standard references: [GLD Products](https://gldproducts.com/blogs/all/how-to-play-baseball-darts), [Dartspin](https://dartspin.com/baseball-dart-game/).

---

## 3. Rules

### 3.1 Recommended default (`baseball_standard`)

| Setting | Value |
|---------|--------|
| Innings | 9 (segments 1–9) |
| Darts per turn | 3 |
| Turn order | Rotate each **half-inning** (all players throw for inning 1, then inning 2, …) |
| Scoring | S/D/T on active inning segment = 1/2/3 runs (§2) |
| Off-segment | 0 runs |
| Bull | Not a scoring segment in standard 9-inning game |
| Max runs per player per inning | 9 (three triples) |
| Max runs per player per game | 81 |

**Inning flow**

1. Display “Inning 4 — Aim for 4”.
2. Each active player throws 3 darts; sum runs for that player-inning.
3. Advance to next inning when all players have completed the inning.
4. After inning 9, highest cumulative runs wins.

### 3.2 Tie-breaker (config)

| Option | Behavior |
|--------|----------|
| `extraInnings` (default) | Continue inning 10, 11, … (target = inning number) until one leader after a full inning |
| `bullPlayoff` | Each tied player throws 3 at bull: outer bull = 1 run, inner = 2; highest wins (single round or repeat) |

Document both; implement `extraInnings` first (matches [Dartspin](https://dartspin.com/baseball-dart-game/) extra-innings description).

### 3.3 Optional variants (not v1)

| Variant | Description |
|---------|-------------|
| **7th inning stretch** | Inning 7 only: must hit at least one bull before runs on 7 count; else 0 for turn ([Dartspin pitching variant](https://dartspin.com/baseball-dart-game/)) |
| **10-inning board** | Extend to segments 10–10 for longer games |
| **Team baseball** | Two teams alternate one thrower per half-inning |
| **“Wrong” scoring** | Some house rules multiply runs × inning number — **exclude** (conflicts with standard S/D/T = 1/2/3) |

Target’s marketing line (“singles, doubles, triples, and home runs”) maps to **S/D/T run weights**, not literal baseball bases — do not implement base-running unless a separate “Baseball League” variant is requested.

---

## 4. Rules engine (domain)

### 4.1 Config (`MatchConfigBaseball`)

```swift
struct MatchConfigBaseball: Codable {
    var inningCount: Int              // default 9
    var tieBreaker: BaseballTieBreaker // .extraInnings, .bullPlayoff
    var seventhInningStretch: Bool    // default false
}
```

### 4.2 State (`BaseballBoardState`)

- `currentInning: Int` (1-based)
- `inningHalf: InningHalf` — `.top` / `.bottom` if needed for UI only; rotation is “all players per inning”
- `runsByPlayer: [UUID: Int]` cumulative
- `runsThisInning: [UUID: Int]` scratch for current inning
- `completedInnings: Int`
- `isExtraInning: Bool`

### 4.3 Turn submission

Input: `[DartInput]` up to 3 darts.

For each dart:

1. If `seventhInningStretch` and inning == 7 and `stretchGateOpen == false`: only bull hits open gate; no runs on 7 until gate open.
2. Else if segment == `currentInning` and multiplier valid: add runs per §2.
3. Else: 0.

`submitTurn` adds `runsThisInning[player]` sum to cumulative after 3 darts (or explicit per-dart UI if using dart-by-dart).

**Advance inning:** When last player in order finishes inning *n*, reset `runsThisInning`, increment `currentInning`. If `currentInning > inningCount` and not tie → complete match. If tie → enter extra innings (`inningCount` effective target continues 10, 11, …).

**Winner:** `argmax(runsByPlayer)`; tie-break policy from config.

### 4.4 Undo

Restore cumulative runs, inning-local runs, `currentInning`, and turn index — same guarantees as X01 undo.

---

## 5. UI specification (conceptual)

### 5.1 Setup

- Mode: **Baseball**
- Players: 2–8
- Options: innings (9), tie-breaker, 7th-inning stretch toggle

### 5.2 Play screen

| Region | Content |
|--------|---------|
| Header | “Inning 5 · Target 5”, optional extra-inning badge |
| Scoreboard | Cumulative runs per player (primary); optional column “this inning” |
| Inning strip | Dots 1–9 filled for completed innings |
| Input | `ScoringInputPad`: segment locked to `currentInning` (or highlight + validate) |
| Actions | Submit, Undo |

**Perfect inning:** Optional celebration at 9 runs in one inning.

### 5.3 Match end

- Final score table, inning-by-inning grid (expandable in history detail)
- Tie-break note in summary if extra innings played

---

## 6. Data capture (sketch)

**`BaseballTurnEvent`**

- `matchId`, `playerId`, `turnIndex`, `inning`
- `darts: [BaseballDartEvent]` — segment, multiplier, `runsAwarded`
- `inningRunsAfterTurn`, `cumulativeRunsAfterTurn`

**`BaseballDartEvent`**

- `dartOrder`, `segment`, `multiplier`, `runsAwarded`, `wasMiss`

**History detail**

- Line score: rows = players, columns = innings 1–9 (+ extras)

**Stats**

- Avg runs per inning, best inning, perfect innings count

---

## 7. Integration & effort

| Area | Estimate | Notes |
|------|----------|-------|
| `BaseballEngine` + tests | 2 d | Straightforward scoring |
| Play UI + locked segment input | 2 d | Reuse X01 pad patterns |
| Inning progression + scoreboard | 1–2 d | |
| Persistence + history line score | 2 d | |
| Setup + `MatchType.baseball` | 1 d | |
| Tie / extra innings | 1 d | |
| **Total MVP** | **~7–10 d** | Lower than Killer |

**Bots:** Feasible v1 — bot aims at `currentInning` with skill-based S/D/T distribution (similar to X01 segment bots).

---

## 8. Testing plan (when implemented)

### Unit

- Runs 1/2/3 for S/D/T on active segment only
- Off-segment and wrong inning → 0
- Inning rotation with 3 players
- 9-inning completion and winner
- Extra-inning tie break
- 7th-inning stretch gate (if enabled)
- Undo mid-inning and across inning boundary

### UI

- 2-player full game smoke
- Accessibility: cumulative runs announced on submit

---

## 9. Comparison to existing modes

| Aspect | X01 | Cricket | Baseball |
|--------|-----|---------|----------|
| Turn structure | 3 darts, subtract | Marks/points | 3 darts, runs add |
| Target | Any (checkout rules) | 15–20 + bull | Single inning segment |
| Win condition | Reach 0 | Close + points | Most runs |
| Engine complexity | Bust/checkout | Marks/close | Low |

---

## 10. Open questions

1. **Per-dart vs visit total entry?** Recommend per-dart (consistent with X01/Cricket) for stats quality.
2. **Show inning mini-scores on main board?** Yes for 2–4 players; collapse for 6+.
3. **Stats tab:** New `MatchType.baseball` filter or grouped “Party modes”?
4. **Achievements:** “Perfect inning”, “81-run game” (theoretical) — threshold in [`achievements.md`](achievements.md).

---

## 11. References

- [Target Darts — Baseball](https://www.target-darts.co.uk/dart-games)
- [How to Play Baseball Darts — GLD](https://gldproducts.com/blogs/all/how-to-play-baseball-darts)
- [Baseball dart game — Dartspin](https://dartspin.com/baseball-dart-game/)
- [Baseball darts — Bar Games 101](https://bargames101.com/how-to-play-baseball-darts/)
