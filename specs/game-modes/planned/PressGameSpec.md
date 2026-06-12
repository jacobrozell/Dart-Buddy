# Press Game Specification

## 1. Purpose

Define **Press** — a push-your-luck party mode. Each turn the app (or opponent) calls a **segment**; hitting singles → doubles → triples on the **same segment** banks escalating points unless the player **banks** or **misses** and loses the round stake.

**Status:** Planned (`party.press`).  
**Brainstorm origin:** [`FutureIdeas/custom-games-brainstorm.md`](../../../FutureIdeas/custom-games-brainstorm.md) §27.

**Related specs:**
- [`SoloPracticeModesSpec.md`](../../SoloPracticeModesSpec.md) — per-turn challenge shape
- [`CalloutVoicesSpec.md`](../../CalloutVoicesSpec.md) — segment callout
- [`MatchSpec.md`](../../MatchSpec.md) — lifecycle, resume, abandon

---

## 2. Catalog metadata

| Field | Value |
|-------|-------|
| **Section** | Party |
| **UI template** | S — Solo challenge per turn (`soloChallenge`) |
| **Stat kind** | `pressBanked` (new; biggest bank, presses attempted) |
| **Ruleset (v1)** | `press_standard` |
| **Catalog id** | `party.press` |
| **MatchType** | `press` (when implemented) |

**Display name:** Press  
**Marketing blurb:** "Hit it, bank it, or press for more — miss and lose the lot."

---

## Player count

| Question | Answer |
|----------|--------|
| **Solo?** | No (v1) |
| **Minimum** | 2 |
| **Recommended** | 2–4 |
| **App maximum** | 4 |

---

## 3. MVP Scope

### In scope (v1)

| Item | Default | Configurable |
|------|---------|--------------|
| Win score | **50** points | 30 / 50 / 100 |
| Ladder steps | Single **1** → Double **3** → Triple **7** | Fixed |
| Darts per step | **1** dart per press decision | — |
| Target caller | **Random** each turn | Random / opponent picks |
| Bank | End turn, keep round points | — |
| Miss | Lose all **unbanked** round points | — |
| Turn structure | One player completes turn (bank or bust) then rotate | — |
| Undo | Undo last dart in current turn only | — |
| History | Highest single bank, win margin | — |

### Out of scope (v1)
- Cross-segment press
- Solo high-score Press

---

## 4. Product goals

| Goal | How Press delivers |
|------|---------------------|
| **Casino sweat** | T20 single → "do I press?" |
| **Simple rules** | One segment ladder |
| **Party friendly** | 2–4 quick rounds |
| **Dart Buddy exclusive** | Push-your-luck ladder per turn |

---

## 5. Rules Engine (`PressEngine`)

### 5.1 Config (`MatchConfigPress`, payload v1)

| Field | Type | Default |
|-------|------|---------|
| `pointsToWin` | Int | `50` |
| `targetCaller` | `random` \| `opponent` | `random` |

### 5.2 Ladder

On called `segment`:

| Step | Required hit | Bank value if stop here |
|------|--------------|-------------------------|
| 0 | Single on segment | **1** |
| 1 | Double on segment | **3** (cumulative replace: round value = 3) |
| 2 | Triple on segment | **7** |

Values are **round totals**, not additive steps.

### 5.3 Turn flow

1. Call segment (random or opponent picker UI).
2. Player throws 1 dart:
   - **Hit current step:** advance step; offer **Press** (continue) or **Bank** (add round value to total score, end turn).
   - **Miss:** round value lost; end turn with 0 added.
3. If at step 2 (triple) and hit: auto-bank 7 (cannot press further v1).
4. First to `pointsToWin` wins.

### 5.4 Opponent target pick

When `targetCaller == opponent`: opponent selects segment before thrower throws (cannot pick same segment as previous turn — optional house rule).

### 5.5 State

```text
scores: [PlayerId: Int]
currentPlayerId
calledSegment
ladderStep: 0|1|2
roundValue: Int  // 0 until first hit
```

---

## 6. UI notes

- Ladder visualization: 1 → 3 → 7 with current step highlighted.
- **Bank** / **Press** buttons after successful hit.
- Bust animation clears ladder.

---

## 7. Localization (draft)

| Key | EN (draft) |
|-----|------------|
| `play.rules.press.title` | Press |
| `play.rules.press.summary` | Climb the ladder on one segment — bank or press your luck. |
| `play.press.bank` | Bank {n} |
| `play.press.press` | Press! |
| `play.press.bust` | Bust — lost {n} |

---

## 8. Open questions

1. Opponent pick target in v1 or random-only?
2. Bull as callable segment?
