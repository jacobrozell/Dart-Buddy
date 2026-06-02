# Play Home

| Field | Value |
|-------|-------|
| Screen ID | `play-home` |
| Primary source | `Features/Play/PlayRootView.swift`, `SetupHomeView.swift` |
| Core flow | Yes |
| Last verified | 2026-06-02 |
| Screen status | `Partial` |

## Criterion checklist

| ID | Status | Implementation notes | Evidence |
|----|--------|----------------------|----------|
| P-1.1.1 | Pass | Resume/recent rows have combined labels | `evidence/voiceover/setup-home-ax-spotcheck-2026-06-02.md` |
| P-1.3.1 | Pass | Setup stack in `SetupHomeView` | |
| P-1.3.2 | Partial | Resume → mode → chips → START → roster; manual VO pending | |
| P-1.3.4 | Untested | Landscape layout | |
| P-1.4.1 | Pass | Text + buttons for actions | |
| P-1.4.3 | Untested | Dark brand surfaces | |
| P-1.4.4 | Untested | No AXXXL evidence | |
| P-1.4.10 | Untested | | |
| P-1.4.11 | Untested | | |
| O-2.4.3 | Partial | AX order plausible; manual VO pending | |
| O-2.4.4 | Pass | Resume, recent games, add players labeled | |
| O-2.5.3 | Pass | Visible chip text in AX label | |
| DBX-TARGET-44 | Pass | START 56pt; chips 48pt | |
| U-3.1.1 | Pass | L10n for home/setup strings | |
| U-3.3.1 | N/A | | |
| U-3.3.2 | N/A | | |
| R-4.1.2 | Pass | `resumeMatchButton`, recent row labels | |
| DBX-CONTRAST-MODES | Untested | | |

## Open work

- [x] VoiceOver labels: resume card, recent list (code)
- [ ] Manual VoiceOver pass (`accessibility/Manual_todo.md`)
- [ ] AXXXL layout check

## Verification log

| Date | Tester | Result | Notes |
|------|--------|--------|-------|
| 2026-06-02 | Agent | Partial | AX spot-check with `-seed_demo`; manual VO pending |
