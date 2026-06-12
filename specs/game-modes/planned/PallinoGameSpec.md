# Pallino Game Specification

## 1. Purpose

Define **Pallino** — a bocce-inspired **2–4 player** game where each round the app calls a **pallino** target. Players alternate **one dart** (3 stones each). Closest single stone to the pallino wins the round; first to **11** round wins takes the match.

**Status:** Planned (`party.pallino`).  
**Brainstorm origin:** [`FutureIdeas/custom-games-brainstorm.md`](../../../FutureIdeas/custom-games-brainstorm.md) §16.

**Related specs:**
- [`CalloutVoicesSpec.md`](../../CalloutVoicesSpec.md) — pallino callout
- [`CallAndHitGameSpec.md`](CallAndHitGameSpec.md) — call-and-throw pattern
- [`EndSheetGameSpec.md`](EndSheetGameSpec.md) — shared `territoryAim` template
- [`MatchSpec.md`](../../MatchSpec.md) — lifecycle, resume, abandon

---

## 2. Catalog metadata

| Field | Value |
|-------|-------|
| **Section** | Party |
| **UI template** | T — Territory aim (`territoryAim`) |
| **Stat kind** | `roundsWon` (rounds won, kiss count) |
| **Ruleset (v1)** | `pallino_standard` |
| **Catalog id** | `party.pallino` |
| **MatchType** | `pallino` (when implemented) |

**Display name:** Pallino  
**Marketing blurb:** "Hit the pallino — closest stone wins the round."

---

## Player count

| Question | Answer |
|----------|--------|
| **Solo?** | No |
| **Minimum** | 2 |
| **Recommended** | 2–4 |
| **App maximum** | 4 |

---

## 3. MVP Scope

### In scope (v1)

| Item | Default | Configurable |
|------|---------|--------------|
| Match target | **11** round wins | 7 / 11 / 15 |
| Stones per player per round | **3** | Fixed |
| Turn order | Alternate 1 dart | — |
| Pallino draw | Random segment + ring (weighted to singles) | — |
| Distance scoring | Proxy table (§5.3) | Fixed v1 |
| Round winner | **Best single stone** (not sum) | — |
| Kiss rule | Exact pallino match **replaces** opponent stone | On / off |
| Callout | TTS + on-screen label | — |
| Undo | Undo last stone | — |
| History | Rounds won, kiss count | — |

### Out of scope (v1)
- True mm distance / camera assist
- Teams (2v2)

---

## 4. Product goals

| Goal | How Pallino delivers |
|------|------------------------|
| **Surgical aim** | Narrow targets each round |
| **Callout integration** | TTS pallino each round |
| **Distinct from End Sheet** | Segment pallino vs bull house |
| **Dart Buddy exclusive** | Ring-adjacency proxy scoring |

---

## 5. Rules Engine (`PallinoEngine`)

### 5.1 Config (`MatchConfigPallino`, payload v1)

| Field | Type | Default |
|-------|------|---------|
| `roundsToWin` | Int | `11` |
| `kissEnabled` | Bool | `true` |
| `pallinoWeightSingles` | Float | `0.6` |

### 5.2 Pallino generation

Each round: draw `PallinoTarget { segment, ring }` where ring ∈ S/D/T.

Weight singles higher for tighter play.

### 5.3 Distance proxy score

Compare landed `DartHit` to pallino:

| Match | Score |
|-------|-------|
| Exact segment + ring | **100** |
| Same segment, adjacent ring | **70** |
| Same ring, adjacent segment (clock) | **50** |
| Same segment, any ring | **40** |
| Miss (outside board) | **0** |

`adjacent ring`: S↔D↔T on same segment.  
`adjacent segment`: ±1 on clock (wrap 20→1).

### 5.4 Round resolution

1. After all players throw 3 stones, each has up to 3 distance scores.
2. Each player's **best** stone = their round score.
3. Highest best stone wins round (+1 match point).
4. Tie → sudden-death single stone (same pallino).

### 5.5 Kiss rule

On **exact** pallino hit (100): remove opponent's current best stone from round (if any); placing stone becomes leader.

### 5.6 State

```text
roundIndex
pallino: PallinoTarget
stones: [Stone]
roundWins: [PlayerId: Int]
currentPlayerIndex
throwInRound
```

---

## 6. UI notes

- Pallino chip prominent center; stones listed with distance badges.
- Kiss animation on exact replacement.

---

## 7. Localization (draft)

| Key | EN (draft) |
|-----|------------|
| `play.rules.pallino.title` | Pallino |
| `play.rules.pallino.summary` | Alternate stones at the called pallino — closest wins. |
| `play.pallino.call` | Pallino: {target} |
| `play.pallino.kiss` | Kiss! Stone replaced |

---

## 8. Open questions

1. Weighted pallino toward player's weak segments (practice mode)?
2. 2v2 teams in v2?
