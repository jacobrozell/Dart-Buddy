# Stats Specification

## 1. Purpose
Define stat computation, storage strategy, and chart-readiness for MVP and future Swift Charts expansion.

---

## 2. Product Constraints
- MVP surfaces simple stats in Players, History, and the Statistics tab (UI: [`StatisticsTabSpec.md`](StatisticsTabSpec.md))
- Must capture enough raw data now to avoid schema rework later
- No cloud sync in 1.0.0
- All calculations must be deterministic from local events

---

## 3. Data Strategy

## Source of Truth
- Immutable turn and dart events are authoritative.
- Aggregates are cacheable/derivable, never authoritative.

## Storage Layers
1. **Raw events** (mandatory)
2. **Materialized aggregates** (optional cache for UI performance)

## Recompute Policy
- Recompute affected player aggregates when a match completes.
- Invalidate/recompute if undo affects completed-state transition.
- Provide full rebuild utility for integrity checks.

---

## 4. MVP Metrics

## Player-Level
- `matchesPlayed`
- `matchesWon`
- `x01Average3Dart`
- `cricketWins`
- `lastPlayedAt`

## Match-Level Summary
- Winner
- Duration
- Key mode-specific numbers

## Canonical Formula Notes
- `x01Average3Dart = (totalX01PointsScored / totalDartsThrown) * 3`
- Exclude bust-applied zero effect from scored points, but include thrown darts if recorded
- Round and display formatting must be consistent across app surfaces

---

## 5. Chart-Ready Event Schema Requirements
- Turn-level and dart-level events are both required.
- Include time dimensions (`timestamp`, `dayBucket`) for trend charting.
- Keep mode context (`matchType`, `checkoutMode`) for split-series charts.
- Preserve player identity via stable IDs and participant snapshots.

Recommended aggregate tables:
- `PlayerDailyAggregate`
- `PlayerModeAggregate`
- `CheckoutAggregate`

---

## 6. Swift Architecture
- `StatsService` in `Domain` layer:
  - Pure functions for stat formulas
  - Deterministic reducers from events -> metrics
- `StatsRepository` in `Data` layer:
  - Reads raw events
  - Stores/returns aggregate cache
- `StatsViewModel` in feature layers:
  - Consumes DTOs; no formula logic in UI

---

## 7. Data Integrity Rules
- Never mutate historical event payloads.
- Undo is represented by removing/reversing last accepted event and recomputing.
- If cache conflicts with event stream, event stream wins.

---

## 8. Testing

## Unit
- Formula correctness for X01 and Cricket summary metrics
- Boundary cases (zero darts, zero points, all busts)

## Integration
- Match completion updates player stats
- Archive/delete player does not corrupt historical aggregate reads
- Full aggregate rebuild matches incremental results

---

## 9. Accessibility verification
- Statistics tab UI: [`StatisticsTabSpec.md`](StatisticsTabSpec.md) and [`statistics.md`](../accessibility/wcag-2.1-aa/screens/statistics.md)

## 10. Verification
| Field | Value |
|-------|--------|
| **Last verified** | 2026-06-04 |
| **Commit** | `0c25396` |
| **Code** | `StatsService.swift`, `MatchStatsLoader.swift` |

---

## 11. Future Improvements (Post-1.0.0)
- Swift Charts dashboards:
  - X01 average trend over time
  - win rate trend
  - checkout efficiency by mode
  - Cricket closure pace and points per round
- Percentile comparisons across local player pool
- Forecast-style trend smoothing

---

## 12. Multi-Mode Stat Model (catalog scale)

As the catalog grows toward the full set in
[`GameModeCatalog`](../Features/Modes/GameModeCatalog.swift), the MVP X01/Cricket
metrics do not generalize (no 3-dart average for a grid game, no checkout % for
a solo doubles drill). Design rationale and wireframes:
[`docs/full-game-catalog-ui.md`](../docs/full-game-catalog-ui.md) §6a.

### Three altitudes, one engine
The **same** computation feeds three homes, each already in the app:
1. **Single match** → `MatchSummaryScreen` / history detail.
2. **Per player × per mode** → **`PlayerDetailView`** — the home for advanced,
   mode-specific stats (per-mode breakdown section). See
   [`PlayerSpec.md`](PlayerSpec.md).
3. **Aggregate / trends** → Statistics segment (cross-mode comparables;
   per-mode deep dive when filtered to one mode).

### `StatKind` contract
Each mode declares a `statKind` (on its `GameModeCatalogEntry`) naming the metric
family it produces: `checkout`, `marks`, `innings`, `lives`, `sequence`,
`soloScore`, `goals`, `boardClaim`, `roleScore`. UI renders **only** the matching
card set, so a mode never shows a metric it can't compute. `StatsService` gains
one deterministic reducer per `statKind`.

### Storage
- Extend `PlayerModeAggregate` (§5) to be **keyed by catalog `id`** (not only
  `MatchType`, so the planned, type-less modes fit) with a `statKind`-shaped
  payload.
- Recompute/integrity rules (§3, §7) are unchanged: raw events remain
  authoritative; only **shipped** modes produce aggregates.

### Cross-mode display
- "All games" / multi-mode filters show **per-mode mini-summaries**, never a
  forced single average across incompatible metrics.
- Match Summary and Player/Statistics cards are driven by the same `statKind` so
  the three altitudes cannot diverge.
