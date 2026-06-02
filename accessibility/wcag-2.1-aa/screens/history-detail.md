# History Detail (Game Statistics)

| Field | Value |
|-------|-------|
| Screen ID | `history-detail` |
| Primary source | `Features/History/MatchHistoryDetailScreen.swift` |
| Core flow | No (tab) |
| Last verified | 2026-06-02 |
| Screen status | `Partial` |

## Criterion checklist

| ID | Status | Implementation notes | Evidence |
|----|--------|----------------------|----------|
| P-1.1.1 | Pass | Charts via `StatsChartViews`; result card summary | |
| P-1.3.1 | Pass | Result card + stat tables + sector section | |
| P-1.3.2 | Partial | Manual VO pending | |
| P-1.3.4 | Untested | | |
| P-1.4.1 | Pass | Text stats + FINISHED badge | |
| P-1.4.3 | Untested | | |
| P-1.4.4 | Partial | `largeTitle` fixed weight; AXXXL not verified | |
| P-1.4.10 | Untested | ScrollView | |
| P-1.4.11 | Untested | | |
| O-2.4.3 | Partial | Manual VO pending | |
| O-2.4.4 | Pass | Delete label + hint; timeline toggle value | |
| O-2.5.3 | Pass | `L10n.historyGameStatistics` title | |
| DBX-TARGET-44 | Pass | Delete button large control | |
| U-3.1.1 | Pass | L10n title, delete alert | |
| U-3.3.1 | Pass | Error state + retry | |
| U-3.3.2 | N/A | | |
| R-4.1.2 | Pass | Result, delete, timeline IDs + labels | |
| DBX-CONTRAST-MODES | Untested | | |

## Open work

- [x] Localize title and delete confirmation (already L10n)
- [x] Destructive delete: accessibility label + hint
- [x] Result card combined accessibility label
- [ ] Manual VoiceOver pass

## Verification log

| Date | Tester | Result | Notes |
|------|--------|--------|-------|
| 2026-06-02 | Agent | Partial | Code complete; manual VO pending |
