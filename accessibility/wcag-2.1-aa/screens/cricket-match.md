# Cricket Match

| Field | Value |
|-------|-------|
| Screen ID | `cricket-match` |
| Primary source | `Features/Play/Cricket/CricketMatchScreen.swift`, `Features/Play/Cricket/CricketBoardView.swift` |
| Core flow | Yes |
| Last verified | 2026-06-02 |
| Screen status | `Partial` |

## Criterion checklist

| ID | Status | Implementation notes | Evidence |
|----|--------|----------------------|----------|
| P-1.1.1 | Pass | Mark cells `20, Open` / `Closed`; pad full dart names | `evidence/voiceover/cricket-ax-spotcheck-2026-06-02.md` |
| P-1.3.1 | Pass | Active column combined header; mark cells labeled per target | |
| P-1.3.2 | Partial | Board above pad; manual VO order pending | |
| P-1.3.4 | Untested | One-screen fit on phone (`todo.md`) | |
| P-1.4.1 | Pass | Marks + text + localized mark states | |
| P-1.4.3 | Partial | `toolbarColorScheme(.dark)` on nav bar; Inspector pass not logged | |
| P-1.4.4 | Untested | Board `minimumScaleFactor` only | `snapshots/iphone17-match-cricket-dark-axxxl-v2.png` (link only) |
| P-1.4.10 | Untested | Scroll grid on small heights | |
| P-1.4.11 | Partial | Mark glyph 26×26 display; scoring via 52pt pad keys | |
| O-2.4.3 | Partial | AX structure OK; manual VO pending | |
| O-2.4.4 | Pass | Undo, Enter labels; Cancel uses `L10n.cancel` | |
| O-2.5.3 | Pass | Pad VO `Triple 20`, `Miss`; visible `20` on key | |
| DBX-TARGET-44 | Pass | Pad keys 52pt; grid cells are display-only | |
| U-3.1.1 | Pass | Bot banner `L10n.botThrowing`; board updated localized | |
| U-3.3.1 | Pass | `boardUpdated` banner + announcement on closure | |
| U-3.3.2 | Pass | Pad multiplier hints; closure text + announcement | |
| R-4.1.2 | Pass | Column, pad, mark labels; identifiers retained | |
| DBX-CONTRAST-MODES | Partial | `evidence/contrast/brand-token-samples-2026-06-02.md` |

## Open work

- [x] Fix navigation title contrast (toolbar dark scheme)
- [x] Target pad spoken labels (`CricketTapPad`)
- [x] VoiceOver: active player column context
- [x] Announce closure transitions
- [ ] AXXXL + landscape pin active row (`todo.md`)
- [ ] Manual VoiceOver pass (`accessibility/Manual_todo.md`)

## Verification log

| Date | Tester | Result | Notes |
|------|--------|--------|-------|
| 2026-06-02 | Agent | Partial | Simulator AX spot-check; manual VO pending (`evidence/voiceover/cricket-ax-spotcheck-2026-06-02.md`) |
