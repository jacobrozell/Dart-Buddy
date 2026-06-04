# Statistics Tab Specification

## 1. Purpose
Define the **Statistics** tab UI: filters, tables, charts, and partial-match handling. Stat formulas and aggregate policy live in [`StatsSpec.md`](StatsSpec.md).

---

## 2. MVP Scope

### In Scope (1.0.0)
- Dedicated tab (third position in `MainTabView`)
- Mode segment: X01 | Cricket
- Period segment: Today | 7d | 30d | All
- Player filter: All players | single player
- Per-player games table (wins, averages, mode-specific columns)
- X01: average / highest tables, bar chart, optional trend chart (single-player filter)
- Cricket: MPR-oriented columns, sector hit aggregation chart
- Partial-stats banner when in-progress match contributes to aggregates
- Empty state with **Start a Match** CTA (delegates to Play tab)

### Out of Scope
- Cross-device benchmarks
- Export / share stats sheet
- Full Swift Charts dashboard suite (post-1.0 in `StatsSpec.md`)

---

## 3. Architecture

| Piece | Location |
|-------|----------|
| View | `Features/Statistics/StatisticsRootView.swift` |
| VM | `StatisticsViewModel` |
| Loader | `Domain/Services/MatchStatsLoader.swift` |
| Charts | `Features/Statistics/StatsChartViews.swift` |

Repositories: `MatchRepository`, `StatsRepository`, `PlayerRepository` (read-only).

---

## 4. Filter Behavior

### Mode (`MatchType`)
- Reloads all sections; trend chart only for X01

### Period
| Value | Cutoff |
|-------|--------|
| `today` | Start of local calendar day |
| `d7` | Now − 7 days |
| `d30` | Now − 30 days |
| `all` | No cutoff |

### Player filter
- `nil` — all participants in matching completed matches (plus partial active logic)
- `UUID` — matches where that player participated
- Invalid archived/deleted filter id clears to All

Player menu includes archived players for historical stats.

---

## 5. Data Loading

`MatchStatsLoader.load(request:)` returns completed-match stat inputs for the filter set.

**Partial active match:** If `fetchActiveMatch()` matches current mode, period, and player filter, its in-progress stats are merged into rows and `includesPartialActiveMatch = true`. Banner copy explains totals may change when the match completes.

**Abandoned matches:** Excluded (same as History — `status = completed` only).

---

## 6. UI Sections and tables

Section order in `StatisticsRootView` (top → bottom):

1. Title + mode segment (`statsTitle`, X01 / Cricket)
2. Period segment (`today`, `7d`, `30d`, `all`)
3. Player filter menu (`statsPlayerFilterMenu`)
4. Partial banner (`statsPartialMatchBanner`) when `includesPartialActiveMatch`
5. Loading / empty / data blocks below

### Games table (always)
| Column key | Row field |
|------------|-----------|
| `stats.games` | `row.games` |
| `stats.wins` | `row.wins` |
| `stats.column.winsPercent` | `row.winPercent` formatted `%.0f%%` |

### X01-only blocks (`mode == .x01`)
| Block | Columns / chart |
|-------|-----------------|
| Average / Highest | `stats.threeDartAverage`, `stats.column.highest` → `average3Dart`, `highestScore` |
| Average chart | Horizontal bar per player (`AverageChart`) |
| Trend chart | Shown when `showsTrendChart` (`playerFilter != nil` && `trendPoints.count >= 2`) |
| Legs / checkout | `stats.column.legs`, `stats.checkouts`, `stats.column.bestCO` |

### Shared blocks (both modes)
| Block | Columns |
|-------|---------|
| Points | `stats.points` → `row.points` |
| Throws | `stats.throws`, `stats.doublePercent`, `stats.triplePercent` |

### Cricket-only
| Block | Content |
|-------|---------|
| MPR table | `stats.mpr`, `stats.marks`, `stats.rounds` |
| Sector hits | `stats.hitsInSector` chart — `sectorHits` sorted by `StatsSectorOrder` |

### Empty / loading
- `ProgressView` when `isLoading && rows.isEmpty`
- Empty: `statsEmptyTitle`; **Start Match** CTA only when `playerFilter == nil`, `period == .all`, and `onStartMatch` provided

---

## 7. Known Product Edge Cases

| Case | Behavior |
|------|----------|
| Bot with 0 completed games but in-progress visit | May show non-zero averages via partial banner — product decision in `docs/release/todo.md` |
| No players | Empty state |
| Filter yields zero rows | Empty state (not error) |

---

## 8. Testing

## Unit
- `StatisticsViewModelTests` — period cutoffs, partial active flag, filter

## Integration
- `MatchStatsLoaderTests`, `MatchStatsLoaderCatalogTests`

## UI
- Tab navigation smoke includes Statistics root
- WCAG identifiers on segments and tables

---

## 9. Accessibility verification
- Manual: [`accessibility/wcag-2.1-aa/screens/statistics.md`](../accessibility/wcag-2.1-aa/screens/statistics.md)
- Automated: `statsPlayerFilterMenu`, `statsPartialMatchBanner`, segment controls in WCAG UI tests

## 10. Analytics
No dedicated Analytics events; product health inferred from `match_completed` + stats usage (future).

## 11. Verification
| Field | Value |
|-------|--------|
| **Last verified** | 2026-06-04 |
| **Commit** | `0c25396` |
| **Code** | `StatisticsRootView.swift`, `StatisticsViewModel.swift` |

---

## 12. Future Improvements
- Swift Charts trend suite per `StatsSpec.md`
- Exclude bots from table until N completed games
- iPad two-column stats layout
