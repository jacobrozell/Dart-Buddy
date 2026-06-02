# History Detail (Game Statistics)

| Field | Value |
|-------|-------|
| Screen ID | `history-detail` |
| Primary source | `Features/History/MatchHistoryDetailScreen.swift` |
| Core flow | No (tab) |
| Last verified | — |
| Screen status | `Partial` |

## Criterion checklist

| ID | Status | Implementation notes | Evidence |
|----|--------|----------------------|----------|
| P-1.1.1 | Partial | Charts via `StatsChartViews` when shown | |
| P-1.3.1 | Untested | Stat tables structure | |
| P-1.3.2 | Untested | | |
| P-1.3.4 | Untested | | |
| P-1.4.1 | Pass | Text stats | |
| P-1.4.3 | Untested | | |
| P-1.4.4 | Untested | `largeTitle` fixed weight | |
| P-1.4.10 | Untested | ScrollView | |
| P-1.4.11 | Untested | | |
| O-2.4.3 | Untested | | |
| O-2.4.4 | Partial | Delete uses alert; title hardcoded English | |
| O-2.5.3 | Untested | | |
| DBX-TARGET-44 | Untested | Delete button | |
| U-3.1.1 | Fail | `"Game Statistics"`, delete alert English | |
| U-3.3.1 | Partial | Error state + retry | |
| U-3.3.2 | N/A | | |
| R-4.1.2 | Partial | Chart IDs; no screen-level labels | |
| DBX-CONTRAST-MODES | Untested | | |

## Open work

- [ ] Localize title and delete confirmation (`todo.md`)
- [ ] Destructive delete: accessibility hint on consequence
- [ ] Verify chart accessibility values when sector section visible

## Verification log

| Date | Tester | Result | Notes |
|------|--------|--------|-------|
