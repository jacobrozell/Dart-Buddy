# Shanghai Match

| Field | Value |
|-------|-------|
| Screen ID | `shanghai-match` |
| Primary source | `Features/Play/Shanghai/ShanghaiMatchScreen.swift`, `ShanghaiScoreboardView.swift` |
| Core flow | Yes (party mode; hidden in lean 1.0 via `ProductSurface`) |
| Last verified | 2026-06-11 |
| Screen status | `Partial` |

## Criterion checklist

| ID | Status | Implementation notes | Evidence |
|----|--------|----------------------|----------|
| P-1.1.1 | Partial | Header, round strip, scoreboard rows, pad locked segment; submit/undo identifiers | `WCAGAccessibilityUITests` party paths when enabled |
| P-1.3.1 | Partial | Scoreboard row combines name + points; round strip summary label | |
| P-1.3.2 | Partial | Scoreboard → round strip → pad; manual VO order pending | |
| P-1.3.4 | Untested | One-screen fit on phone | |
| P-1.4.1 | Partial | Round dots + spoken strip label; Shanghai feedback banner | |
| P-1.4.3 | Partial | Dark gameplay shell; Inspector pass not logged | |
| P-1.4.4 | Untested | Dynamic Type on scoreboard and round strip | |
| P-1.4.10 | Untested | Scroll scoreboard on small heights | |
| P-1.4.11 | Partial | Pad keys 52pt; scoreboard display-only | |
| O-2.4.3 | Partial | AX structure OK; manual VO pending | |
| O-2.4.4 | Pass | Undo + submit localized labels | |
| O-2.5.3 | Partial | Pad VO names; bot-turn pad hint when disabled | |
| DBX-TARGET-44 | Partial | Pad keys 52pt | |
| U-3.1.1 | Pass | Bot banner when preset bot turn | |
| U-3.3.1 | Pass | Turn announcement on submit | |
| U-3.3.2 | Partial | Goal reminder + Shanghai achievement feedback | |
| R-4.1.2 | Pass | `shanghai_match_header`, `shanghai_undo`, `shanghai_round_strip`, `shanghai_scoreboard_row_*`, `shanghai_scoring_hint`, `shanghai_goal_reminder`, `shanghai_shanghai_feedback` | |
| DBX-CONTRAST-MODES | Partial | Brand tokens on dark background | |

## Open work

- [ ] Manual VoiceOver pass (`accessibility/Manual_todo.md`)
- [ ] AXXXL + landscape round strip readability
- [ ] Confirm submit control identifier when `DartNumberPad` is embedded

## Verification log

| Date | Tester | Result | Notes |
|------|--------|--------|-------|
| 2026-06-11 | Agent | Partial | Tracker added; code audit of identifiers and loading labels |
