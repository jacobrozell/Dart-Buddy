# Players List

| Field | Value |
|-------|-------|
| Screen ID | `players-list` |
| Primary source | `Features/Players/PlayersRootView.swift` |
| Core flow | No (tab) |
| Last verified | 2026-06-02 |
| Screen status | `Partial` |

## Criterion checklist

| ID | Status | Implementation notes | Evidence |
|----|--------|----------------------|----------|
| P-1.1.1 | Pass | Row combined label; avatar on chip | |
| P-1.3.1 | Pass | `List` + sections | |
| P-1.3.2 | Partial | Search before list; manual VO pending | |
| P-1.3.4 | Untested | iPad empty state layout | |
| P-1.4.1 | Pass | | |
| P-1.4.3 | Untested | | |
| P-1.4.4 | Untested | | |
| P-1.4.10 | Untested | | |
| P-1.4.11 | Untested | | |
| O-2.4.3 | Partial | Manual VO pending | |
| O-2.4.4 | Pass | Search label; row summary | |
| O-2.5.3 | Pass | Search + row labels | |
| DBX-TARGET-44 | Partial | List rows system height | |
| U-3.1.1 | Pass | L10n | |
| U-3.3.1 | Partial | Delete blocked message | |
| U-3.3.2 | Pass | `players_searchField` label | |
| R-4.1.2 | Pass | Search + `player_row_*` labels | |
| DBX-CONTRAST-MODES | Untested | | |

## Open work

- [x] Search field label + identifier
- [x] Row accessibility: name + bot/record/archived
- [ ] Manual VoiceOver: swipe delete/archive
- [ ] AXXXL layout

## Verification log

| Date | Tester | Result | Notes |
|------|--------|--------|-------|
| 2026-06-02 | Agent | Partial | Code complete; manual VO pending |
