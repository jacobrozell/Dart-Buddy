# Crease Game Specification

## 1. Purpose

Define **Crease** — a **hockey shootout** between **2 players**. Five rounds of keeper-blocked doubles: keeper nominates a blocked double, shooter gets **one dart** at any other double for a goal.

**Status:** Planned (`party.crease`).  
**Brainstorm origin:** [`FutureIdeas/custom-games-brainstorm.md`](../../../FutureIdeas/custom-games-brainstorm.md) §15.

**Related specs:**
- [`FootballGameSpec.md`](FootballGameSpec.md) — doubles-as-goals family (different shape)
- [`MatchSpec.md`](../../MatchSpec.md) — lifecycle, resume, abandon
- [`Slap Shot`](../../../FutureIdeas/custom-games-brainstorm.md) — cut; Crease is MVP hockey custom mode

---

## 2. Catalog metadata

| Field | Value |
|-------|-------|
| **Section** | Party |
| **UI template** | T — Territory aim (`territoryAim`) |
| **Stat kind** | `shootoutConversion` (new; goals / rounds) |
| **Ruleset (v1)** | `crease_standard` |
| **Catalog id** | `party.crease` |
| **MatchType** | `crease` (when implemented) |

**Display name:** Crease  
**Marketing blurb:** "Five rounds. One dart. Pick the block — beat the keeper."

---

## Player count

| Question | Answer |
|----------|--------|
| **Solo?** | No |
| **Minimum** | 2 |
| **Recommended** | 2 |
| **App maximum** | 2 |

---

## 3. MVP Scope

### In scope (v1)

| Item | Default | Configurable |
|------|---------|--------------|
| Rounds | **5** per side (10 total shots) | 3 / 5 / 7 |
| Shooter darts | **1** per round | Fixed |
| Block rule | Keeper picks **one double** to block | — |
| Block history | Cannot repeat until **5 different** doubles blocked | Fixed |
| Goal | Double or triple on **unblocked** double | — |
| Bull | Counts as **D25** if not blocked | — |
| Tie | **Sudden death** — block + shot until broken | — |
| Roles | Alternate keeper/shooter each round | — |
| Undo | Undo last shot | — |
| History | Goals, conversion % | — |

### Out of scope (v1)
- Full-ice Slap Shot sim
- Team shootout (3 players)

---

## 4. Product goals

| Goal | How Crease delivers |
|------|---------------------|
| **Hard to score** | ~20% conversion is a good night |
| **Fast MVP** | Simpler than Slap Shot |
| **Blocker mind games** | Keeper history forces variety |
| **Dart Buddy exclusive** | Curated shootout ledger |

---

## 5. Rules Engine (`CreaseEngine`)

### 5.1 Config (`MatchConfigCrease`, payload v1)

| Field | Type | Default |
|-------|------|---------|
| `roundsPerSide` | Int | `5` |
| `blockVarietyRule` | Bool | `true` |

### 5.2 Round flow

1. **Keeper phase:** keeper selects `blockedDouble` from doubles 1–20 + D25, respecting variety rule.
2. **Shooter phase:** one dart.
3. **Resolve:**
   - Land on blocked double (any ring) → **save**, 0 goals.
   - Land double/triple on other double → **goal**, +1.
   - Miss or single → **miss**, 0 goals.
4. Swap roles; increment round.
5. After all rounds: higher goals wins; tie → sudden death (repeat block+shot).

### 5.3 Block history

Per keeper: `blockedHistory: Set<DoubleSegment>`.

If `blockVarietyRule` and `blockedHistory.count < 5`: cannot pick duplicate.

When `blockedHistory.count == 5`: reset set (may block any again).

### 5.4 State

```text
scores: [PlayerId: Int]
currentRound
phase: block | shoot
keeperId, shooterId
blockedHistory: [PlayerId: Set<DoubleSegment>]
shotLog[]
```

---

## 6. UI notes

- Shootout strip: ○ = goal, × = miss per round.
- Block picker: doubles grid with used doubles dimmed.
- Sudden death banner when tied after regulation.

---

## 7. Localization (draft)

| Key | EN (draft) |
|-----|------------|
| `play.rules.crease.title` | Crease |
| `play.rules.crease.summary` | Block a double, then bury one dart — five rounds each. |
| `play.crease.block` | Block a double |
| `play.crease.goal` | Goal! |

---

## 8. Open questions

1. Triple on blocked double — save or goal?
2. Include D25 in block pool by default?
