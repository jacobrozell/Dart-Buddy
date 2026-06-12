# End Sheet Game Specification

## 1. Purpose

Define **End Sheet** — a curling-inspired **2-player** match of **8 ends**. Players alternate **one dart per stone** at the house (bull). Inner/outer bull score as shots; single 25 is a guard. Points awarded per end using closest-shot logic.

**Status:** Planned (`party.endSheet`).  
**Brainstorm origin:** [`FutureIdeas/custom-games-brainstorm.md`](../../../FutureIdeas/custom-games-brainstorm.md) §13.

**Related specs:**
- [`MatchSpec.md`](../../MatchSpec.md) — lifecycle, resume, abandon
- [`ScoringInputSpec.md`](../../ScoringInputSpec.md) — per-dart entry
- [`MatchForfeitSpec.md`](../../MatchForfeitSpec.md) — end-score standings

---

## 2. Catalog metadata

| Field | Value |
|-------|-------|
| **Section** | Party |
| **UI template** | T — Territory aim (`territoryAim`) — new |
| **Stat kind** | `endsWon` (new; ends won, stones thrown, blanks) |
| **Ruleset (v1)** | `end_sheet_standard` |
| **Catalog id** | `party.endSheet` |
| **MatchType** | `endSheet` (when implemented) |

**Display name:** End Sheet  
**Marketing blurb:** "Eight ends at the house — guards, takeouts, and quiet tension."

---

## Player count

| Question | Answer |
|----------|--------|
| **Solo?** | No |
| **Minimum** | 2 |
| **Recommended** | 2 |
| **App maximum** | 2 (4-player teams v2) |

---

## 3. MVP Scope

### In scope (v1)

| Item | Default | Configurable |
|------|---------|--------------|
| Ends | **8** | 6 / 8 / 10 |
| Stones per end | **6 each** (12 total) | Fixed |
| Turn order | Alternate 1 dart | — |
| Hammer | Trailing player throws last in final end | On / off |
| Takeout | Inner bull removes one opponent outer bull shot | On / off |
| Scoring | Curling count — 1 pt per scoring shot beating opponent's best | — |
| Input | Bull-focused pad lock optional (house only) | Strict house / full board |
| Undo | Undo last stone | — |
| History | Ends won, total points | — |

### Stone roles

| Landing | Role |
|---------|------|
| Inner bull (50) | **Shot** — scores in count-back |
| Outer bull (25) | **Shot** — scores; beaten by any opponent inner bull |
| Single 25 (thin outer) | **Guard** — in house, never scores |
| Miss / other | **Burned** — out of play |

### Out of scope (v2)
- 4-player teams (2 stones each)
- Guard takeout with outer bull
- Physical stone positioning on wedge map

---

## 4. Product goals

| Goal | How End Sheet delivers |
|------|------------------------|
| **Alternate tension** | One dart = one stone |
| **Low scoring drama** | Most ends 0–1 points |
| **Sports authenticity** | Guards + takeouts without spatial tracking |
| **Dart Buddy exclusive** | End ledger + takeout UX |

---

## 5. Rules Engine (`EndSheetEngine`)

### 5.1 Config (`MatchConfigEndSheet`, payload v1)

| Field | Type | Default |
|-------|------|---------|
| `endCount` | Int | `8` |
| `hammerEnabled` | Bool | `true` |
| `takeoutEnabled` | Bool | `true` |
| `houseOnlyInput` | Bool | `true` |

### 5.2 End state

```text
End {
  stones: [Stone]  // ordered throw order
  points: [PlayerId: Int]
}
Stone {
  playerId
  type: shot_inner | shot_outer | guard | burned
  active: Bool      // false if taken out
}
```

### 5.3 Takeout

When `takeoutEnabled` and player lands **inner bull**: remove one opponent **active** `shot_outer` stone (player selects if multiple; auto oldest if timeout).

### 5.4 End scoring (v1 simplified curling)

1. Consider active **shots** only (inner/outer bull).
2. Find closest shot to button (inner bull = best).
3. Scoring player: owner of closest shot.
4. Points = count of scoring player's active shots that are **at least as good** as opponent's best shot.
5. Guards never score; if opponent has no shots, guards can deny "closest" only if scorer also has no shots → blank end.

### 5.5 Match win

Most total points after `endCount`. Tie → extra end with hammer rules.

---

## 6. UI notes

- End ledger: stone chips stacked by player color.
- Takeout prompt on inner bull hit.
- House ring highlight on pad when `houseOnlyInput`.

---

## 7. Localization (draft)

| Key | EN (draft) |
|-----|------------|
| `play.rules.endSheet.title` | End Sheet |
| `play.rules.endSheet.summary` | Alternate stones at the house — most points after eight ends. |
| `play.endSheet.end` | End {n} |
| `play.endSheet.blank` | Blank end |

---

## 8. Open questions

1. Single 25 guard — map to outer bull area or separate wedge?
2. Hammer in end 8 only or configurable?
