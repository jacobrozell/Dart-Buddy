# Baseball Match

| Field | Value |
|-------|-------|
| Screen ID | `baseball-match` |
| Primary source | `Features/Play/Baseball/BaseballMatchScreen.swift`, `Features/Play/Baseball/BaseballScoreboardView.swift` |
| Core flow | Yes |
| Last verified | 2026-06-04 |
| Screen status | `Partial` |

## Criterion checklist

| ID | Status | Implementation notes | Evidence |
|----|--------|----------------------|----------|
| P-1.1.1 | Partial | Header, scoreboard rows, pad locked segment; submit/undo identifiers | `WCAGAccessibilityUITests` party baseball smoke |
| P-1.3.1 | Partial | Scoreboard row combines name + runs; inning strip summary label | |
| P-1.3.2 | Partial | Scoreboard above pad; manual VO order pending | |
| P-1.3.4 | Untested | One-screen fit on phone | |
| P-1.4.1 | Partial | Runs as text; inning strip not color-only (labels per dot) | |
| P-1.4.3 | Partial | Dark gameplay shell; Inspector pass not logged | |
| P-1.4.4 | Untested | Dynamic Type on scoreboard | |
| P-1.4.10 | Untested | Scroll scoreboard on small heights | |
| P-1.4.11 | Partial | Pad keys 52pt; scoreboard display-only | |
| O-2.4.3 | Partial | AX structure OK; manual VO pending | |
| O-2.4.4 | Pass | Undo + submit localized labels | |
| O-2.5.3 | Partial | Locked segment hint; pad VO names | |
| DBX-TARGET-44 | Partial | Pad keys 52pt | |
| U-3.1.1 | Pass | Bot banner when preset bot turn | |
| U-3.3.1 | Pass | Turn announcement on submit | |
| U-3.3.2 | Partial | Stretch gate hint; perfect inning feedback | |
| R-4.1.2 | Pass | `baseball_submit`, `baseball_undo`, `baseball_match_header`, scoreboard row ids | |
| DBX-CONTRAST-MODES | Partial | Brand tokens on dark background | |

## Open work

- [ ] Manual VoiceOver pass (`accessibility/Manual_todo.md`)
- [ ] AXXXL + landscape scoreboard readability
- [ ] Inspector contrast pass on amber extra-inning badge

## Verification log

| Date | Tester | Result | Notes |
|------|--------|--------|-------|
| 2026-06-04 | Agent | Partial | Automated WCAG smoke for party → baseball path |
