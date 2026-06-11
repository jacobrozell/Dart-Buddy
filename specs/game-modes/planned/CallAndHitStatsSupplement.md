# Call & Hit — Statistics Supplement

## 1. Purpose
Define how Call & Hit sessions feed **Player detail**, **Activity → Statistics**, and **Match Summary** at the three altitudes described in [`StatsSpec.md`](../../StatsSpec.md) §12.

**Parent spec:** [`CallAndHitGameSpec.md`](CallAndHitGameSpec.md)  
**Status:** Planned  
**Stat kind (catalog):** `practiceAccuracy` (new `ModeStatKind` case at implementation)

---

## 2. Why a new stat kind

| Existing kind | Why not for Call & Hit |
|---------------|------------------------|
| `sequence` | Around the Clock measures completion order/time, not hit % |
| `soloScore` | Bob's 27 uses running point total vs par |
| `checkout` | No remaining score or checkout % |

**`practiceAccuracy`** — hit rate, streaks, segment weakness — comparable **only across sessions with identical config fingerprint**.

---

## 3. Config fingerprint

Personal bests and trend lines group sessions by:

```
fingerprint = hash(targetKind, includeBull, dartsPerTarget, targetCount)
```

Examples:
- `singles_bull_3x_50`
- `doubles_noBull_1x_25`

**Do not** compare 68% at 3 darts with 52% at 1 dart on the same chart series.

---

## 4. Per-session metrics (Match Summary + history detail)

| Metric | Formula | Display |
|--------|---------|---------|
| `hits` | count of `outcome == hit` | `34` |
| `misses` | count of `outcome == miss` | `16` |
| `accuracy` | `hits / (hits + misses)` | `68%` |
| `longestHitStreak` | max consecutive hits | `7` |
| `weakestSegment` | segment with lowest hit rate (min 3 appearances) | `D3 — 2/5` |
| `strongestSegment` | segment with highest hit rate (min 3 appearances) | `T20 — 4/5` |
| `duration` | `endedAt - startedAt` | standard match duration |

### Per-segment breakdown
`[Segment: (hits, attempts)]` for all segments that appeared in the shuffled sequence.

---

## 5. Player-level aggregates (`PlayerModeAggregate`)

Keyed by catalog id `practice.callAndHit` + config fingerprint.

| Field | Description |
|-------|-------------|
| `sessionsCompleted` | count |
| `lifetimeHits` / `lifetimeAttempts` | sum across sessions |
| `lifetimeAccuracy` | derived |
| `bestAccuracy` | max single-session accuracy (same fingerprint) |
| `bestStreak` | max longestHitStreak |
| `lastSessionAt` | date |
| `segmentRolling` | optional JSON map for heatmap (last N sessions) |

**Recompute:** on match complete from `CallAndHitTargetEvent` stream; same policy as [`StatsSpec.md`](../../StatsSpec.md) §3.

---

## 6. Statistics tab (Activity segment)

When mode filter = **Call & Hit** (or Practice group expanded):

### Sections (top → bottom)
1. **Summary row** — sessions, overall accuracy (current fingerprint or "all configs" with disclaimer)
2. **Accuracy trend** — line chart, one point per completed session (same fingerprint only when filtered)
3. **Segment heatmap** — 1–20 grid (+ bull) colored by lifetime hit % for selected fingerprint
4. **Recent sessions table** — date, config chip, accuracy, streak

### Partial active match
If in-progress Call & Hit matches filter: banner per [`StatisticsTabSpec.md`](../../StatisticsTabSpec.md) §5 — show provisional `hits / attempts so far`.

### Empty state
"No Call & Hit sessions yet" + CTA navigates to Modes → Call & Hit (not Play home in v1).

---

## 7. Player detail section

New block under per-mode breakdown when player has ≥1 Call & Hit session:

```text
Call & Hit
  Best (Singles · 3 darts · 50)   72%
  Last session                     68% · 2 days ago
  [View all practice stats →]      → Statistics filtered
```

Fingerprint selector: segmented **Singles | Doubles | Triples** + menu for darts/count.

---

## 8. History list card chips

Per [`CallAndHitGameSpec.md`](CallAndHitGameSpec.md) §8 — `MatchHistoryCardPayload` v1 fields:

```json
{
  "accuracyPercent": 68,
  "hits": 34,
  "targetCount": 50,
  "targetKind": "single",
  "dartsPerTarget": 3
}
```

---

## 9. Cross-mode "All games" filter

Show Call & Hit as a **mini card** with last accuracy — never blend into X01 average table.

---

## 10. Testing

- Aggregate rebuild matches incremental after 10 synthetic sessions
- Fingerprint isolation: two configs don't share personal best
- Partial in-progress merge in `MatchStatsLoader`
- Heatmap handles segments with <3 attempts (gray / hidden)

---

## 11. Verification
| Field | Value |
|-------|--------|
| **Status** | Planned |
