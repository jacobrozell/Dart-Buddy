# Stats Specification

## 1. Purpose
Define stat computation, storage strategy, and chart-readiness for MVP and future Swift Charts expansion.

---

## 2. Product Constraints
- MVP surfaces simple stats in Players and History
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

## 9. Future Improvements (Post-1.0.0)
- Swift Charts dashboards:
  - X01 average trend over time
  - win rate trend
  - checkout efficiency by mode
  - Cricket closure pace and points per round
- Percentile comparisons across local player pool
- Forecast-style trend smoothing
