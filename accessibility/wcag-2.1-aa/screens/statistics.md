# Statistics

| Field | Value |
|-------|-------|
| Screen ID | `statistics` |
| Primary source | `Features/Statistics/StatisticsRootView.swift`, `StatsChartViews.swift` |
| Core flow | No (tab) |
| Last verified | 2026-06-02 |
| Screen status | `Partial` |

## Criterion checklist

| ID | Status | Implementation notes | Evidence |
|----|--------|----------------------|----------|
| P-1.1.1 | Pass | Charts + tables expose label/value summaries | |
| P-1.3.1 | Pass | Filters, tables, chart sections | |
| P-1.3.2 | Partial | Manual VO order pending | |
| P-1.3.4 | Untested | | |
| P-1.4.1 | Pass | Text metrics | |
| P-1.4.3 | Untested | Axis `textSecondary` | |
| P-1.4.4 | Untested | | |
| P-1.4.10 | Untested | | |
| P-1.4.11 | Untested | | |
| O-2.4.3 | Partial | Manual VO pending | |
| O-2.4.4 | Pass | Filter menu, partial banner, empty CTA | |
| O-2.5.3 | Pass | Filter + chip labels match visible text | |
| DBX-TARGET-44 | Pass | Segments, load-more/CTA heights | |
| U-3.1.1 | Pass | L10n | |
| U-3.3.1 | N/A | | |
| U-3.3.2 | N/A | | |
| R-4.1.2 | Pass | `statsPlayerFilterMenu`, tables, charts, banner | |
| DBX-CONTRAST-MODES | Untested | | |

## Open work

- [x] VoiceOver labels on filters and partial-match banner
- [x] Trend chart value includes dates (`stats.trend.accessibilityPointFormat`)
- [x] `StatTable` row combined labels
- [ ] Manual VoiceOver pass
- [ ] AXXXL on stat cards

## Verification log

| Date | Tester | Result | Notes |
|------|--------|--------|-------|
| 2026-06-02 | Agent | Partial | Code complete; manual VO pending |
