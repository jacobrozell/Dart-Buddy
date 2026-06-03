# History List

| Field | Value |
|-------|-------|
| Screen ID | `history-list` |
| Primary source | `Features/History/HistoryRootView.swift` |
| Core flow | No (tab) |
| Last verified | 2026-06-02 |
| Screen status | `Partial` |

## Criterion checklist

| ID | Status | Implementation notes | Evidence |
|----|--------|----------------------|----------|
| P-1.1.1 | Pass | Row combined `accessibilitySummary` | |
| P-1.3.1 | Pass | `List` / scroll semantics | |
| P-1.3.2 | Partial | Filters before list; manual VO pending | |
| P-1.3.4 | Untested | | |
| P-1.4.1 | Pass | Win/loss not color-only | |
| P-1.4.3 | Untested | | |
| P-1.4.4 | Untested | | `snapshots/iphone17-history-dark-axxxl-v1.png` (link only) |
| P-1.4.10 | Untested | | |
| P-1.4.11 | Untested | | |
| O-2.4.3 | Partial | Code complete; manual VO pending | |
| O-2.4.4 | Pass | Filter menu, resume, load more labels | |
| O-2.5.3 | Pass | Filter label includes current player | |
| DBX-TARGET-44 | Pass | Load more, empty CTA min heights | |
| U-3.1.1 | Pass | L10n | |
| U-3.3.1 | N/A | | |
| U-3.3.2 | N/A | | |
| R-4.1.2 | Pass | IDs + row/filter/resume labels | |
| DBX-CONTRAST-MODES | Partial | `evidence/contrast/brand-token-samples-2026-06-02.md` |

## Open work

- [x] VoiceOver: filter menu, resume, load more (code)
- [ ] Manual VoiceOver pass
- [ ] AXXXL list row layout

## Verification log

| Date | Tester | Result | Notes |
|------|--------|--------|-------|
| 2026-06-02 | Agent | Partial | Code complete; tab AX not re-run (use `-seed_demo` manual) |
