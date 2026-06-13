# Killer Match

| Field | Value |
|-------|-------|
| Screen ID | `killer-match` |
| Primary source | `Features/Play/Killer/KillerMatchScreen.swift`, `KillerScoreboardView.swift`, `KillerNumberGridView.swift` |
| Core flow | Yes (party mode; hidden in lean 1.0 via `ProductSurface`) |
| Last verified | 2026-06-11 |
| Screen status | `Partial` |

## Criterion checklist

| ID | Status | Implementation notes | Evidence |
|----|--------|----------------------|----------|
| P-1.1.1 | Partial | Header, scoreboard rows, number grid, pad locked segment; submit/undo identifiers | `WCAGAccessibilityUITests` party paths when enabled |
| P-1.3.1 | Partial | Scoreboard row combines name + lives; number grid spoken labels per assignment state | |
| P-1.3.2 | Partial | Pick phase: grid above pad; play phase: scoreboard above pad; manual VO order pending | |
| P-1.3.4 | Untested | One-screen fit on phone | |
| P-1.4.1 | Partial | Killer badge + lives text; grid states not color-only (spoken labels) | |
| P-1.4.3 | Partial | Dark gameplay shell; Inspector pass not logged | |
| P-1.4.4 | Untested | Dynamic Type on scoreboard and grid | |
| P-1.4.10 | Untested | Scroll scoreboard on small heights | |
| P-1.4.11 | Partial | Pad keys 52pt; grid cells tappable | |
| O-2.4.3 | Partial | AX structure OK; manual VO pending | |
| O-2.4.4 | Pass | Undo + submit localized labels | |
| O-2.5.3 | Partial | Number grid VO names; pad disabled hint when bot plays | |
| DBX-TARGET-44 | Partial | Pad keys 52pt | |
| U-3.1.1 | Pass | Bot banner when preset bot turn | |
| U-3.3.1 | Pass | Turn / phase announcements | |
| U-3.3.2 | Partial | Pick-phase reminders; killer badge feedback | |
| R-4.1.2 | Pass | `killer_submit`, `killer_undo`, `killer_match_header`, `killer_number_grid_*`, `killer_scoreboard_row_*` | |
| DBX-CONTRAST-MODES | Partial | Brand tokens on dark background | |

## Open work

- [ ] Manual VoiceOver pass — pick phase vs play phase (`accessibility/Manual_todo.md`)
- [ ] AXXXL + landscape scoreboard and number grid readability
- [ ] Inspector contrast pass on killer badge / eliminated states

## Verification log

| Date | Tester | Result | Notes |
|------|--------|--------|-------|
| 2026-06-11 | Agent | Partial | Tracker added; code audit of identifiers and loading labels |
