# X01 Match

| Field | Value |
|-------|-------|
| Screen ID | `x01-match` |
| Primary source | `Features/Play/X01/X01MatchScreen.swift`, `Features/Play/X01/DartNumberPad.swift` |
| Core flow | Yes |
| Last verified | 2026-06-01 |
| Screen status | `Partial` |

## Criterion checklist

| ID | Status | Implementation notes | Evidence |
|----|--------|----------------------|----------|
| P-1.1.1 | Pass | Checkout banner combined label; pad/score use spoken dart names | |
| P-1.3.1 | Pass | `PlayerScoreCard` single combined VO element | |
| P-1.3.2 | Partial | Expected order score cards → checkout → pad; manual VO pass pending | |
| P-1.3.4 | Untested | Dead space / landscape (`todo.md`) | |
| P-1.4.1 | Partial | Active player: green bar + name color + “Your turn” in label | |
| P-1.4.3 | Untested | Secondary stats `.caption` on card | |
| P-1.4.4 | Partial | Score 40pt / pad 17pt fixed; deferred to Phase 1 AXXXL | `snapshots/iphone17-match-x01-dark-axxxl-v3.png` (link only) |
| P-1.4.10 | Untested | ScrollView for multiple players | |
| P-1.4.11 | Untested | Pad key borders | |
| O-2.4.3 | Partial | Simulator AX tree: score card → pad; VO swipe order not logged | `evidence/voiceover/x01-ax-spotcheck-2026-06-02.md` |
| O-2.4.4 | Pass | Leave match, Undo last turn labels | |
| O-2.5.3 | Pass | Pad VO `Triple 20`; score card visit darts use `spokenAccessibilityName` | |
| DBX-TARGET-44 | Pass | Header 44×44; pad 52pt | |
| U-3.1.1 | Pass | `L10n.botThrowing` for banner label + visible text | |
| U-3.3.1 | Pass | `L10n.bustFeedback` banner + `AccessibilityNotification` on bust | |
| U-3.3.2 | Pass | Pad multiplier hints when armed; bot-turn pad hint when disabled | |
| R-4.1.2 | Pass | Pad labels/hints/traits; combined score card; identifiers retained | See `_shared-components.md` |
| DBX-CONTRAST-MODES | Partial | `evidence/contrast/brand-token-samples-2026-06-02.md`; matrix `evidence/orientation/` |

## Open work

- [x] Fix `DartNumberPad` labels (shared component)
- [x] Combined `PlayerScoreCard` VoiceOver summary
- [x] Announce bust / checkout changes (`AccessibilityNotification.Announcement`)
- [x] Turn indicator: active player in spoken label
- [ ] Dynamic Type on remaining score and pad
- [x] Disabled pad when bot plays: disabled trait + `play.x01.pad.disabledWhileBot` hint

## Verification log

| Date | Tester | Result | Notes |
|------|--------|--------|-------|
| 2026-06-01 | Agent | Partial | Code complete + unit test for spoken labels; manual VO script pending |
| 2026-06-02 | Agent | Partial | Simulator AX spot-check: pad/score labels Pass; announcements/bot turn VO pending (`evidence/voiceover/x01-ax-spotcheck-2026-06-02.md`) |
