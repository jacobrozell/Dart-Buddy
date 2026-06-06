# Party & Practice Modes — R&D Brief

**Status:** R&D / post-1.0  
**Sources:**

- [Target Darts — dart games](https://www.target-darts.co.uk/dart-games)
- [Darts Corner — what darts games can you play](https://www.dartscorner.co.uk/blogs/how-to/what-darts-games-can-you-play)

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

## Darts Corner additions

Brief assessments for games from the [Darts Corner catalog](https://www.dartscorner.co.uk/blogs/how-to/what-darts-games-can-you-play) not covered above.

### 180 Around the Clock

**Type:** Scored practice / race (1+ players).

| Item | Detail |
|------|--------|
| Objective | Hit segments 1→20 in order; **score** each hit (S=1, D=2, T=3). Max 9 per round, perfect game = 180. |
| Win | Highest total after 20 rounds (multiplayer) or beat personal best (solo). |
| Dart Buddy fit | Natural extension of Around the Clock; reuse progress UI + add running score |
| Effort | ~3–5 d on top of base ATC engine |

---

### Chase the Dragon

**Type:** Precision race (1+ players).

| Item | Detail |
|------|--------|
| Objective | Hit **trebles** 10→11→…→20 in order, then outer bull, then bull. |
| Win | First to complete the 13-step sequence. |
| Dart Buddy fit | Practice tab; treble-only validation per step |
| Effort | ~4–5 d (similar engine to ATC, stricter hit filter) |

---

### Nine Lives

**Type:** Race with elimination (2+ players).

| Item | Detail |
|------|--------|
| Objective | Around the Clock 1→20; each player starts with **9 lives**. |
| Penalty | Fail to hit required segment in a full turn → lose one life. |
| Win | Most lives remaining when someone finishes, or last standing. |
| Dart Buddy fit | ATC engine + lives UI (reuse Killer lives component) |
| Effort | ~5–6 d |

---

### Blind Killer

**Type:** Party elimination (3+ players).

| Item | Detail |
|------|--------|
| Objective | Like Killer, but assigned numbers are **hidden**. Players throw at any double; after a double is closed (3 hits), reveal whether it matches a player’s number → elimination. |
| Dart Buddy fit | Killer variant; needs secret assignment UX (per-device reveal or pass-and-play) |
| Effort | ~4–6 d as Killer add-on |

**Open:** Online/async play needs async-safe reveal — defer.

---

### Mickey Mouse

**Type:** Closing race (2+ players).

| Item | Detail |
|------|--------|
| Objective | Close segments **20→19→…→12** then bull (S=1 / D=2 / T=3 hits). First to close all wins. |
| Dart Buddy fit | Strong reuse of Cricket mark engine (descending range, no scoring phase) |
| Effort | ~5–7 d |

---

### American Cricket

**Type:** Marks + points (2+ players / teams).

| Item | Detail |
|------|--------|
| Objective | Close 20→15 + bull (3 hits each), then **score** on closed segments until opponent closes them. Highest points when both sides finish bull wins. |
| Note | **Not** the same as shipped Dart Buddy Cricket (15–20 + bull, cut-throat option). American Cricket adds an explicit points race after closing. |
| Dart Buddy fit | New `MatchType` or named Cricket variant; engine fork from `CricketEngine` |
| Effort | ~8–10 d |

---

### English Cricket

**Type:** Innings team game (2+ players / teams).

| Item | Detail |
|------|--------|
| Objective | Batting team scores freely; bowling team hits bull for wickets (outer=1, bull=2). 10 wickets ends the innings; teams swap and chase the score. |
| Dart Buddy fit | Similar shape to Baseball innings; wicket counter + role swap |
| Effort | ~8–10 d |

---

### Mulligan

**Type:** Random closing race (2+ players).

| Item | Detail |
|------|--------|
| Objective | Six **random** segments (chosen at setup) + bull; close each in order (3 hits). First to finish wins. |
| Dart Buddy fit | Mickey Mouse engine with random segment list in config |
| Effort | ~3–4 d once Mickey Mouse exists |

---

### 51 By 5's

**Type:** Arithmetic party game (2+ players).

| Item | Detail |
|------|--------|
| Objective | 3-dart turn total must be **divisible by 5** to count; score = total ÷ 5. First to **51** wins. |
| Dart Buddy fit | Simple turn-total validator; no segment constraint |
| Effort | ~3–4 d |

---

### Follow the Leader / Loop

**Type:** Copy-the-segment elimination (2+ players).

| Item | Detail |
|------|--------|
| Objective | Player 1 sets a target segment; next player must hit the **exact** sub-segment (small single ≠ big single). Hit early → spare darts set next target. Miss all three → lose a life. |
| Loop variant | Adds **wire loops** (4, 6, 8, 9, 10, 14, 16, 18, 19, 20) as valid targets — needs precise hit classification. |
| Dart Buddy fit | Hard without granular segment metadata; Loop especially niche |
| Effort | ~8–12 d (Follow the Leader); Loop likely defer |

---

### Knockout

**Type:** Score beat-or-lose (2+ players).

| Item | Detail |
|------|--------|
| Objective | First player sets a 3-dart score; each next player must **beat** it or lose a life. Last standing wins. |
| Dart Buddy fit | Minimal engine; reuse turn total entry |
| Effort | ~3–4 d |

---

### Sudden Death

**Type:** Round elimination (3+ players).

| Item | Detail |
|------|--------|
| Objective | Each round, **lowest** 3-dart score is eliminated until one remains. |
| Dart Buddy fit | Trivial engine; good filler party mode |
| Effort | ~2–3 d |

---

### Football

**Type:** Race to goals (2+ players).

| Item | Detail |
|------|--------|
| Objective | Hit bull to start; then each **double** (incl. bull) = 1 goal. First to **10** goals wins. |
| Dart Buddy fit | Phase state machine (kickoff → scoring); double-only input after kickoff |
| Effort | ~4–5 d |

---

### Grand National

**Type:** Survival race (2+ players).

| Item | Detail |
|------|--------|
| Objective | Anti-clockwise from 20; each turn must hit **at least one** segment in the current “hurdle” or you’re out. First to complete the circuit wins. |
| Dart Buddy fit | Segment-sequence engine (reverse ATC); elimination UI |
| Effort | ~4–5 d |

---

### Hare and Hounds

**Type:** Two-player chase (2 players only).

| Item | Detail |
|------|--------|
| Objective | Hare starts on 20, hound on 5; both advance clockwise segment-by-segment. Hare wins by lapping to 20; hound wins by catching up. |
| Dart Buddy fit | Simple dual-track progress; good intro mode for kids |
| Effort | ~4–5 d |

---

### Prisoner

**Type:** Collection race (2+ players; best with ~5).

| Item | Detail |
|------|--------|
| Objective | Place one dart in each segment 1→20 clockwise. Miss → dart stays as a **prisoner** for one turn; opponents can capture it by hitting the same segment (gain an extra dart). |
| Dart Buddy fit | Unusual state (darts left on board); needs board-position model |
| Effort | ~8–10 d |

---

### Scam

**Type:** Two-role points (2 players).

| Item | Detail |
|------|--------|
| Objective | **Stopper** hits segments 20→1 to block scorer; **Scorer** accumulates on open segments until all blocked. Swap roles; higher scorer total wins. |
| Dart Buddy fit | Segment-block set + free scoring; 2-player only |
| Effort | ~6–8 d |

---

### Snooker

**Type:** Alternating sequence (2+ players / teams).

| Item | Detail |
|------|--------|
| Objective | Alternate **red** (any 1–15) then **colour** (16=yellow … 20=pink, bull=black). Points per snooker values; fouls and frame rules vary heavily. |
| Problem | Full rule set is complex — Darts Corner defers to a separate guide |
| Dart Buddy fit | Defer; or ship simplified “reds then colours” without full foul table |
| Effort | ~12–15 d for full rules |

---

### Tic-Tac-Toe

**Type:** Grid claim (2+ players / teams).

| Item | Detail |
|------|--------|
| Objective | 3×3 grid of segments (bull center + 8 others); hit to claim a cell; first three-in-a-row wins. |
| Dart Buddy fit | Custom grid setup + claim state; fun party novelty |
| Effort | ~5–7 d |

---

## Cross-mode comparison

| Mode | Players | Standardization | Reuse of `ScoringInputPad` | Priority |
|------|---------|-----------------|---------------------------|----------|
| Bob's 27 | 1 | High | Double picker + miss | P2 |
| Around the Clock | 1+ | Medium (reset) | Segment sequence | P2 |
| 180 Around the Clock | 1+ | High | Segment sequence + scored | P2 |
| Chase the Dragon | 1+ | High | Treble-only sequence | P2 |
| Nine Lives | 2+ | Medium | Segment sequence + lives | P2 |
| Shanghai | 2+ | Medium | Per-round segment | P2 |
| Blind Killer | 3+ | Medium | Killer + hidden numbers | P2 |
| Mickey Mouse | 2+ | High | Mark closure 20→12 | P2 |
| American Cricket | 2+ | Medium | Cricket-like marks + points | P2 |
| Halve-It | 1+ | Low | Per-round target | P3 |
| English Cricket | 2+ | Medium | Free scoring + bull wickets | P3 |
| 51 By 5's | 2+ | High | Turn total only | P3 |
| Knockout | 2+ | High | Turn total only | P3 |
| Sudden Death | 3+ | High | Turn total only | P3 |
| Football | 2+ | High | Bull then doubles | P3 |
| Grand National | 2+ | High | Anti-clockwise sequence | P3 |
| Hare and Hounds | 2 | High | Dual progress tracks | P3 |
| Mulligan | 2+ | Medium | Random close list | P3 |
| Follow the Leader | 2+ | Medium | Exact sub-segment | P3 |
| Loop | 2+ | Low | Wire-loop hits | P3 |
| Prisoner | 2+ | Medium | Board-position state | P3 |
| Scam | 2 | Medium | Block + score | P3 |
| Snooker | 2+ | Low | Alternating targets | P3 |
| Tic-Tac-Toe | 2+ | Medium | Grid claim | P3 |

---

## Suggested “Practice” hub (optional product shape)

Instead of many top-level Play tiles:

```
Play
  ├── X01 / Cricket (existing)
  └── Practice ▾
        ├── Bob's 27
        ├── Around the Clock
        ├── 180 Around the Clock
        ├── Chase the Dragon
        └── (future) Halve-It
Party
  ├── Killer
  ├── Blind Killer
  ├── Baseball
  ├── Shanghai
  ├── Mickey Mouse
  ├── Knockout / Sudden Death
  └── (future) Football, Grand National, …
Cricket variants (sub-menu or setup preset)
  ├── American Cricket
  └── English Cricket
```

Reduces setup clutter; feature-flag per mode. Document in setup spec when promoting.

---

## References

- [Target Darts — What Dart Games Can I Play?](https://www.target-darts.co.uk/dart-games)
- [Darts Corner — Dart Games: The Ultimate Guide](https://www.dartscorner.co.uk/blogs/how-to/what-darts-games-can-you-play)
