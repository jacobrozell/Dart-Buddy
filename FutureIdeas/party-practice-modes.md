# Party & Practice Modes — R&D Brief

**Status:** R&D / post-1.0  
**Source:** [Target Darts — dart games](https://www.target-darts.co.uk/dart-games)  
**Index:** [`additional-game-modes.md`](additional-game-modes.md)  
**Deep specs:** [`killer-darts.md`](killer-darts.md), [`baseball-darts.md`](baseball-darts.md)

Lightweight assessments for modes not yet specced in depth. Promote to `specs/*GameSpec.md` when scheduled.

---

## Bob's 27

**Type:** Solo practice (doubling out trainer).

| Item | Detail |
|------|--------|
| Objective | Start at **27 points**. 21 rounds: double 1, double 2, … double 20, then bull. |
| Scoring | Hit intended double → **add** face value (e.g. D2 = +4). Miss all three → **subtract** that double’s value. Hit 0 → game over. |
| Perfect game | 1,437 ([Target](https://www.target-darts.co.uk/dart-games)) |
| Dart Buddy fit | **Practice tab** or single-player “challenge” without full `MatchRecord` parity initially |
| Engine size | Small state machine: `roundIndex`, `score`, `gameOver` |
| UI | Round label “Double 12”, 3-dart turn, running total, best score leaderboard (local) |
| Effort | ~3–5 d including persistence optional |

**Open:** Bull scoring on miss (27?) — confirm standard before implementation.

---

## Around the Clock

**Type:** Race / practice (1+ players).

| Item | Detail |
|------|--------|
| Objective | Hit 1 → 2 → … → 20 in order, then **bull** to win. |
| Turn | 3 darts per turn; advance on first hit of current target ([Target](https://www.target-darts.co.uk/dart-games)). |
| Reset rule | Target: “missing or failing to advance within three throws resets progress” — **variant-heavy**. Options: `noReset`, `resetOnThreeMisses`, `resetEntireSequence` |
| Dart Buddy fit | Solo practice + multiplayer race; progress UI (chip trail 1–20) |
| Engine | `currentTarget`, `playerProgress[playerId]` |
| Effort | ~4–6 d (reset policy UX + multiplayer) |

**Note:** Different from Cricket’s 15–20 — no mark closure.

---

## Shanghai

**Type:** Multiplayer points per round.

| Item | Detail |
|------|--------|
| Objective | Each round focuses one number (e.g. 15). Score S/D/T on that number only (15 / 30 / 45). **Shanghai** = all three in one turn → bonus (house: instant win or +150). |
| Flow | Rotate target number each round or fixed rounds per number ([Target](https://www.target-darts.co.uk/dart-games)) |
| Dart Buddy fit | Similar engine to Baseball (fixed segment per round) + Shanghai detector on turn |
| Effort | ~6–8 d (bonus rules + round config) |

**Open:** Bonus amount and whether Shanghai ends the game — lock in setup presets.

---

## Halve-It

**Type:** Pressure / gambling-style descent.

| Item | Detail |
|------|--------|
| Objective | Start at score (e.g. **301**). Each round aims at a **declared target** (sequence varies by house). Hit → score **halved** (round down?). Miss → score unchanged or **double** per some rules ([Target](https://www.target-darts.co.uk/dart-games) is vague). |
| Problem | **Least standardized** of the set — needs a named `halveIt_ruleset` before coding |
| Dart Buddy fit | Defer until after Baseball/Killer; or ship one curated sequence (e.g. 20→19→…→bull) |
| Effort | ~8–10 d including rules research and playtesting |

**Recommendation:** User-facing “House rules” doc link in setup; default one published sequence cited in promoted spec.

---

## Cross-mode comparison

| Mode | Players | Standardization | Reuse of `ScoringInputPad` | Priority |
|------|---------|-----------------|---------------------------|----------|
| Bob's 27 | 1 | High | Double picker + miss | P2 |
| Around the Clock | 1+ | Medium (reset) | Segment sequence | P2 |
| Shanghai | 2+ | Medium | Per-round segment | P2 |
| Halve-It | 1+ | Low | Per-round target | P3 |

---

## Suggested “Practice” hub (optional product shape)

Instead of five new top-level Play tiles:

```
Play
  ├── X01 / Cricket (existing)
  └── Practice ▾
        ├── Bob's 27
        ├── Around the Clock
        └── (future) Halve-It
Party
  ├── Killer
  ├── Baseball
  └── Shanghai
```

Reduces setup clutter; feature-flag per mode. Document in setup spec when promoting.

---

## References

- [Target Darts — What Dart Games Can I Play?](https://www.target-darts.co.uk/dart-games)
