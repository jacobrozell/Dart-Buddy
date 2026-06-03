# Killer Darts — R&D Specification

**Status:** R&D / post-1.0  
**Source inspiration:** [Target Darts — Killer](https://www.target-darts.co.uk/dart-games)  
**Index:** [`additional-game-modes.md`](additional-game-modes.md)

---

## 1. Purpose

Define Killer as a multiplayer elimination party game for Dart Buddy: rules (with explicit variant choice), engine behavior, UI concept, persistence sketch, and fit with the existing match platform.

**Minimum players:** 3 (2-player Killer is uncommon and awkward for targeting).

---

## 2. Game summary

Each player owns a **target number** (segment 1–20). Players start with **lives**. After becoming a **Killer**, they can remove opponents’ lives by hitting opponents’ numbers. Last player with lives wins.

Target’s copy is high-level (“hit your number three times → killer; hit others’ numbers to eliminate”). Published house rules **differ** on how you become a Killer and what counts as a hit — §3 locks a **recommended default** and lists variants.

---

## 3. Rules

### 3.1 Recommended default (Dart Buddy v1)

**Name:** `killer_double_standard` — aligns with common pub explanations ([GLD](https://gldproducts.com/blogs/all/how-to-play-killer-darts), [Dart Scout](https://thedartscout.com/dart-rules-explained/)).

| Phase | Behavior |
|-------|----------|
| **Setup — number pick** | Each player throws **one dart with non-dominant hand** (app: dedicated “Pick number” step). Segment hit (single area of 1–20) becomes their number. Miss board → rethrow. Number already taken → rethrow. Bull on pick: treat as miss or rethrow (config: `bullAllowedOnPick`, default `false`). |
| **Setup — order** | Closest to bull on pick dart wins throw order (optional; default: seat order from setup). |
| **Lives** | Each player starts with **3 lives** (config `startingLives`, range 3–5). |
| **Turn** | 3 darts per turn. |
| **Become Killer** | Hit the **double** of your own number (any one dart in a turn). Once Killer, status persists until match end (config `loseKillerStatusOnDeath`: default `false`). |
| **As Killer — attack** | Hits on **another player’s number** remove lives from that player: **double** of their number → −1 life (only doubles count for damage in this variant). |
| **As Killer — self infliction** | Hit **your own double** → −1 life on yourself. |
| **Non-Killer attacks** | Hits on others’ numbers **before** you are Killer have **no effect**. |
| **Elimination** | At 0 lives, player is **out** (cannot throw; still a target if house allows — default: **not** a target when out). |
| **Win** | Last player with ≥1 life. |

**Not in v1 default:** triples scoring, “marks to Killer” progression, blind Killer, or reviving by hitting own segment after elimination.

### 3.2 Variant: marks-to-Killer (party alt)

**Name:** `killer_marks_progression` — described on [Darts Corner](https://www.dartscorner.co.uk/blogs/how-to/how-to-play-killer-darts).

| Action | Effect |
|--------|--------|
| Hit **own** number | +1 life per single, +2 per double, +3 per triple (cap lives at `maxLives`, default 3) |
| Reach `maxLives` | Become Killer |
| As Killer, hit **opponent’s** number | Remove lives by same S/D/T weights |
| Hit own number while Killer | Lose lives by same weights |

**Recommendation:** Ship as setup toggle **after** `killer_double_standard` is stable — engine is different (life pool 0…max vs fixed starting lives).

### 3.3 Other variants (document only)

| Variant | Note |
|---------|------|
| Killer straight off | Everyone starts as Killer |
| Blind Killer | Numbers hidden / random assign |
| Triples count | Triple of opponent number removes 3 lives |
| Singles damage | Weaker players: single on opponent number −1 life |
| Pre-Killer elimination | Allow damage before Killer status (not recommended) |

---

## 4. Rules engine (domain)

### 4.1 Config (`MatchConfigKiller`)

```swift
// Conceptual — not implemented
struct MatchConfigKiller: Codable {
    var ruleset: KillerRuleset // .doubleStandard, .marksProgression
    var startingLives: Int      // default 3
    var maxLives: Int           // marks variant only
    var bullAllowedOnPick: Bool
    var useNonDominantPick: Bool // UI reminder only
}
```

### 4.2 State (`KillerBoardState`)

Per player:

- `playerId`
- `assignedNumber: Int?` (nil until pick phase complete)
- `lives: Int`
- `isKiller: Bool`
- `isEliminated: Bool`

Global:

- `phase: KillerPhase` — `.numberPick`, `.playing`, `.completed`
- `currentTurnPlayerId`
- `pickQueue: [UUID]` (who still needs a number)

### 4.3 Commands

- `submitPickDart(segment, multiplier)` — pick phase only
- `submitTurn(darts: [DartInput])` — validate 1–3 darts, all on valid segments
- `undoLastTurn()` — restore lives, killer flags, elimination

### 4.4 Dart resolution (`double_standard`)

For each dart in turn:

1. Resolve segment + multiplier (miss = no segment).
2. If thrower not Killer: only check if dart is **double on own number** → set `isKiller = true`.
3. If thrower is Killer:
   - Double on **own** number → `lives -= 1` (floor 0, then eliminate).
   - Double on **opponent’s** number (active opponents only) → opponent `lives -= 1`, eliminate at 0.
4. Singles/triples on opponent numbers: no effect in default ruleset.

**Edge cases**

- Same turn: become Killer on dart 1, attack on darts 2–3 allowed.
- Eliminated player: skip in rotation.
- All killers eliminated except one: should not happen if lives logic correct; engine should still detect single survivor.

---

## 5. UI specification (conceptual)

### 5.1 Setup

- Mode tile: **Killer** (subtitle: “3+ players · elimination”)
- Players: min 3, max N (cap e.g. 8 for readability)
- Rules: lives count (3/4/5), ruleset picker (greyed until marks variant exists)

### 5.2 Number pick flow

- Full-screen or sheet per player: “Throw with your other hand” + single dart entry
- Show taken numbers grid (1–20) with player initials
- Cannot start play until all `assignedNumber` set

### 5.3 Play screen

| Region | Content |
|--------|---------|
| Header | Current thrower, “Killer” badge if applicable |
| Board | Row per **active** player: number chip, lives (pips or numeric), killer icon |
| Target hint | “Your number: 14” / “Aim: doubles” |
| Input | `ScoringInputPad` restricted to entered segments (or full board with validation error) |
| Actions | Submit turn, Undo |

**Accessibility:** Lives as text + symbol; Killer status = icon + label, not red/green only.

### 5.4 Match end

- Winner banner, summary: kills dealt, lives remaining, optional “became Killer” count

---

## 6. Data capture (sketch)

Align with event-sourced match model when promoted.

**`KillerTurnEvent`**

- `matchId`, `playerId`, `turnIndex`, `phase`
- `darts: [KillerDartResolution]` (segment, multiplier, effects: `becameKiller`, `lifeDelta` per affected player)
- `boardBeforePayload`, `boardAfterPayload`

**History**

- Show life timeline per player; highlight killer activation turn

**Stats (post-1.0)**

- Games played, wins, average lives remaining when winning

---

## 7. Integration & effort

| Area | Estimate | Risk |
|------|----------|------|
| `KillerEngine` + unit tests | 2–3 d | Rule variant confusion — lock default in tests |
| Pick phase UI | 1–2 d | UX for 6+ players |
| Play UI + input constraints | 2–3 d | Segment ownership clarity |
| Persistence + history | 2 d | Schema migration |
| Setup + navigation | 1 d | `MatchType.killer`, routes |
| **Total MVP** | **~8–12 d** | |

**Bots:** Defer v1. Killer is social; a bot needs target selection (lowest lives, threat), not just segment accuracy.

---

## 8. Testing plan (when implemented)

### Unit

- Number pick: collision, miss, rethrow
- Become Killer on own double only
- Damage only as Killer; self-double penalty
- Elimination and turn skip
- Undo across killer activation and life changes

### UI

- 4-player pick → play → eliminate to winner
- VoiceOver: lives and killer status per row

---

## 9. Open questions

1. **Promote which ruleset first?** Recommendation: `killer_double_standard` (simpler state machine).
2. **Record non-dominant pick in app?** Honor system + copy only, or force 1-dart pick UI?
3. **Eliminated players as targets?** Default no.
4. **Tie on simultaneous elimination?** Rare; last turn order wins or sudden-death bull — defer.
5. **Achievements** ([`achievements.md`](achievements.md)): “Win Killer with 1 life left”, “5-player Killer” — define when mode ships.

---

## 10. References

- [Target Darts — Killer](https://www.target-darts.co.uk/dart-games)
- [How to Play Killer Darts — GLD](https://gldproducts.com/blogs/all/how-to-play-killer-darts)
- [Killer — Dart Scout](https://thedartscout.com/dart-rules-explained/)
- [Killer darts — Darts Corner](https://www.dartscorner.co.uk/blogs/how-to/how-to-play-killer-darts) (marks variant)
