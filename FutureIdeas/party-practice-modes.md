# Party & Practice Modes — R&D Brief

**Status:** R&D / post-1.0 for **unshipped** modes below  
**Source:** [Target Darts — dart games](https://www.target-darts.co.uk/dart-games)  
**Index:** [`additional-game-modes.md`](additional-game-modes.md)

**Already shipped (see specs / code, not this file):** Baseball ([`specs/game-modes/implemented/BaseballGameSpec.md`](../specs/game-modes/implemented/BaseballGameSpec.md)), Killer ([`specs/game-modes/implemented/KillerGameSpec.md`](../specs/game-modes/implemented/KillerGameSpec.md)), Shanghai (`Domain/Engines/ShanghaiEngine.swift`).

**Superseded for rules** by `specs/*GameSpec.md` (see [`specs/README.md`](../specs/README.md)). This brief retains effort estimates and product-shape notes.

---

## Bob's 27

**Type:** Solo practice (doubling out trainer).

| Item | Detail |
|------|--------|
| Objective | Start at **27 points**. 21 rounds: double 1, double 2, … double 20, then bull. |
| Scoring | Hit intended double → **add** face value (e.g. D2 = +4). Miss all three → **subtract** that double's value. Hit 0 → game over. |
| Perfect game | 1,437 ([Target](https://www.target-darts.co.uk/dart-games)) |
| Dart Buddy fit | **Practice tab** or single-player "challenge" without full `MatchRecord` parity initially |
| Engine size | Small state machine: `roundIndex`, `score`, `gameOver` |
| UI | Round label "Double 12", 3-dart turn, running total, best score leaderboard (local) |
| Effort | ~3–5 d including persistence optional |

**Open:** Bull scoring on miss (27?) — confirm standard before implementation.

---

## Around the Clock

**Type:** Race / practice (1+ players).

| Item | Detail |
|------|--------|
| Objective | Hit 1 → 2 → … → 20 in order, then **bull** to win. |
| Turn | 3 darts per turn; advance on first hit of current target ([Target](https://www.target-darts.co.uk/dart-games)). |
| Reset rule | Target: "missing or failing to advance within three throws resets progress" — **variant-heavy**. Options: `noReset`, `resetOnThreeMisses`, `resetEntireSequence` |
| Dart Buddy fit | Solo practice + multiplayer race; progress UI (chip trail 1–20) |
| Engine | `currentTarget`, `playerProgress[playerId]` |
| Effort | ~4–6 d (reset policy UX + multiplayer) |

**Note:** Different from Cricket's 15–20 — no mark closure.

---

## Halve-It

**Type:** Pressure / gambling-style descent.

| Item | Detail |
|------|--------|
| Objective | Start at score (e.g. **301**). Each round aims at a **declared target** (sequence varies by house). Hit → score **halved** (round down?). Miss → score unchanged or **double** per some rules ([Target](https://www.target-darts.co.uk/dart-games) is vague). |
| Problem | **Least standardized** of the set — needs a named `halveIt_ruleset` before coding |
| Dart Buddy fit | Defer until after practice hub exists; or ship one curated sequence (e.g. 20→19→…→bull) |
| Effort | ~8–10 d including rules research and playtesting |

**Recommendation:** User-facing "House rules" doc link in setup; default one published sequence cited in promoted spec.

---

## Golf

**Type:** Multiplayer party (stroke play).

| Item | Detail |
|------|--------|
| Objective | Play **9 or 18 holes** in numeric order (segment 1, then 2, …). **Lowest total strokes** wins — like real golf. |
| Turn | Up to **3 darts per hole**; player may stop after 1 or 2 throws. **Only the last dart thrown** counts for that hole ([GLD](https://gldproducts.com/blogs/all/how-to-play-golf-darts), [A1 Darts](https://web.archive.org/web/20110226121020/www.a1darts.com/dart_rules/golf.html)). |
| Scoring (common) | Double = **1** stroke, triple = **2**, single = **3**, miss segment = **5** (worst per hole). Variants use wedge rings (1–5 strokes) or golf terms (birdie/bogey) — **house rules heavy**. |
| Dart Buddy fit | Party section; per-hole segment targeting reuses `ScoringInputPad` (same pattern as Baseball/Shanghai). Scorecard UI: hole column + running total; highlight current hole target. |
| Engine | `holeIndex`, `strokes[playerId][hole]`, `courseLength` (9 \| 18); last-dart-only resolution per hole |
| Bot | Moderate — aim at current segment by skill tier; bot "stops early" when it hits a double |
| Effort | ~6–8 d (stroke ruleset presets + last-dart UX + 9/18 scorecard) |

**Open:** Lock default ruleset (GLD 1/2/3/5 vs A1 wedge 1–5). Optional handicap strokes for mixed-skill pairs.

---

## Cross-mode comparison

| Mode | Players | Standardization | Reuse of `ScoringInputPad` | Priority |
|------|---------|-----------------|---------------------------|----------|
| Bob's 27 | 1 | High | Double picker + miss | P2 |
| Around the Clock | 1+ | Medium (reset) | Segment sequence | P2 |
| Halve-It | 1+ | Low | Per-round target | P3 |
| Golf | 2+ | Medium (last-dart) | Per-hole segment | P2 |

---

## Suggested "Practice" hub (optional product shape)

Instead of five new top-level Play tiles:

```
Play
  ├── X01 / Cricket (existing)
  └── Practice ▾
        ├── Bob's 27
        ├── Around the Clock
        └── (future) Halve-It
Party
  ├── Killer      (shipped)
  ├── Baseball    (shipped)
  ├── Shanghai    (shipped)
  └── Golf        (planned)
```

Reduces setup clutter; feature-flag per mode. Document in setup spec when promoting.

---

## References

- [Target Darts — What Dart Games Can I Play?](https://www.target-darts.co.uk/dart-games)
