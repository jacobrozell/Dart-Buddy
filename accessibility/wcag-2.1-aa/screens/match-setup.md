# Match Setup

| Field | Value |
|-------|-------|
| Screen ID | `match-setup` |
| Primary source | `Features/Play/SetupHomeView.swift` |
| Core flow | Yes |
| Last verified | 2026-06-02 |
| Screen status | `Partial` |

## Criterion checklist

| ID | Status | Implementation notes | Evidence |
|----|--------|----------------------|----------|
| P-1.1.1 | Pass | Chips expose title + value in AX label | `evidence/voiceover/setup-home-ax-spotcheck-2026-06-02.md` |
| P-1.3.1 | Pass | Chips + roster list | |
| P-1.3.2 | Partial | START vs roster; manual VO pending | |
| P-1.3.4 | Untested | | |
| P-1.4.1 | Pass | Selection checkmarks + selected trait on roster | |
| P-1.4.3 | Untested | Red START semantics | |
| P-1.4.4 | Partial | `minimumScaleFactor` on chips; AXXXL not verified | `snapshots/iphone17-setup-dark-axxxl-fix2.png` (link only) |
| P-1.4.10 | Untested | | |
| P-1.4.11 | Untested | Option chips | |
| O-2.4.3 | Partial | AX spot-check OK | |
| O-2.4.4 | Pass | START, chips, roster, mode pill | |
| O-2.5.3 | Pass | `Points, 501` style labels | |
| DBX-TARGET-44 | Pass | START 56pt; chips ≥ 48pt | |
| U-3.1.1 | Pass | L10n chip/roster strings | |
| U-3.3.1 | Partial | Validation errors as text | |
| U-3.3.2 | Pass | Chip labels + roster hint + START disabled hint | |
| R-4.1.2 | Pass | `setup_*`, `select_*`, `startMatchButton` + labels | |
| DBX-CONTRAST-MODES | Partial | `evidence/contrast/brand-token-samples-2026-06-02.md` |

## Open work

- [x] Add accessibility labels on option chips
- [x] Roster row: label + selected state + hint
- [ ] Verify AXXXL without clipping START or chips
- [ ] Landscape: roster below tab bar issue (`todo.md`)
- [ ] Manual VoiceOver pass

## Verification log

| Date | Tester | Result | Notes |
|------|--------|--------|-------|
| 2026-06-02 | Agent | Partial | AX spot-check; chips/roster/mode/START hint |
