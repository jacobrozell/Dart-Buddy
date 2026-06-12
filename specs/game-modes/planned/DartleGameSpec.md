# Dartle Game Specification

## 1. Purpose

Define **Dartle** — a daily puzzle where all players on a device share the same **6-segment sequence** (date-seeded). Complete the sequence in fewest darts within an **18-dart** cap.

**Status:** Planned (`practice.dartle`).  
**Brainstorm origin:** [`FutureIdeas/custom-games-brainstorm.md`](../../../FutureIdeas/custom-games-brainstorm.md) §12.

**Related specs:**
- [`CallAndHitGameSpec.md`](CallAndHitGameSpec.md) — sequence + hit reporting patterns
- [`SoloPracticeModesSpec.md`](../../SoloPracticeModesSpec.md) — solo platform
- [`HistorySpec.md`](../../HistorySpec.md) — daily attempt records
- [`MatchSummarySpec.md`](../../MatchSummarySpec.md) — share card

---

## 2. Catalog metadata

| Field | Value |
|-------|-------|
| **Section** | Practice |
| **UI template** | F — Sequence progress (`sequenceProgress`) |
| **Stat kind** | `dailyPuzzle` (new; darts used, perfect segments) |
| **Ruleset (v1)** | `dartle_standard` |
| **Catalog id** | `practice.dartle` |
| **MatchType** | `dartle` (when implemented) |

**Display name:** Dartle  
**Marketing blurb:** "Six targets. One puzzle. New board every day."

---

## Player count

| Question | Answer |
|----------|--------|
| **Solo?** | **Yes** |
| **Minimum** | 1 |
| **Recommended** | 1 (household compare on same device) |
| **App maximum** | 1 per attempt; multiple profiles may each play daily |

---

## 3. MVP Scope

### In scope (v1)

| Item | Default | Configurable |
|------|---------|--------------|
| Sequence length | **6** segments | Fixed v1 |
| Dart cap | **18** total | Fixed v1 |
| Ring rule | **Any ring** on segment counts | Fixed v1 |
| Daily seed | `YYYYMMDD` in local timezone | — |
| Target pool | Singles 1–20 + bull | Fixed |
| Input | Standard dart pad per dart | — |
| Grid UI | Wordle-style row per segment (hit/miss/extra darts) | — |
| Share card | "Dartle #{days} — solved in {n} darts" | — |
| History | One row per profile per calendar day | — |
| Undo | Undo last dart | — |

### Out of scope (v1)
- Online leaderboard / Game Center
- Ring-specific puzzles (must hit double on segment 3)
- Streak rewards beyond local display
- Unlimited practice seed (only daily puzzle v1)

---

## 4. Product goals

| Goal | How Dartle delivers |
|------|---------------------|
| **Daily retention** | Reason to open app without live play |
| **Local-first** | No server; seeded RNG |
| **Shareable** | Text card for group chats |
| **Dart Buddy exclusive** | Date-seeded dart sequence puzzle |

---

## 5. Rules Engine (`DartleEngine`)

### 5.1 Daily sequence generation

```text
seed = hash(YYYYMMDD + "dartle_v1")
sequence = drawWithoutReplacement(pool, count=6, rng=seed)
```

Pool: S1–S20 + bull (25 segments). No duplicate segments in one puzzle.

### 5.2 Play flow

1. Show empty 6-cell grid.
2. Player throws at **current** target (index 0 on start).
3. **Hit** (any ring on target segment): advance index; mark cell green with dart count for that cell.
4. **Miss**: mark attempt; continue throwing until hit or dart cap.
5. **Complete:** all 6 hit → score = total darts used (lower better).
6. **Fail:** 18 darts without completing → DNF (still log attempt).

### 5.3 State

```text
puzzleDate: LocalDate
sequence: [Segment]
currentIndex: Int
dartsUsed: Int
cellResults: [{ segment, dartsToHit, attempts }]
status: inProgress | solved | dnf
```

### 5.4 Household compare

Multiple profiles on one install: each gets independent attempt on same sequence; local "best on device today" badge.

---

## 6. UI notes

- Grid: 6 rows × columns for dart attempts (max 3 per row visual cap).
- Completed day: show grid replay read-only.
- Midnight rollover: new puzzle available.

---

## 7. Localization (draft)

| Key | EN (draft) |
|-----|------------|
| `play.rules.dartle.title` | Dartle |
| `play.rules.dartle.summary` | Hit six segments in order — today's puzzle is the same for everyone. |
| `play.dartle.share` | Dartle {date} — {n}/18 darts |
| `play.dartle.dnf` | Out of darts |

---

## 8. Open questions

1. Allow unlimited retries same day (practice) or one scored attempt?
2. `DailyChallengeSpec` merge vs standalone mode?
