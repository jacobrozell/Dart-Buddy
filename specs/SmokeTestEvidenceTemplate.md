# Smoke Test Evidence Template (PR/CI)

Copy this into PR descriptions when running manual smoke tests.  
Attach screenshots for each required artifact.

## Build Info

- Commit:
- Branch:
- Build command:
- Device(s):
- Theme(s):
- Content size:
- Tester:
- Date:

## Result Summary

- Overall result: `PASS` / `FAIL`
- Blocking issues found:
  - None / (list)

## Checklist

- [ ] App launch + tab navigation stable (all five tabs)
- [ ] Player creation works (`Smoke Alice`, `Smoke Bob`, `Smoke Carol`)
- [ ] X01 match start, submit turn, undo
- [ ] Cricket match start, submit turn, undo
- [ ] History list/filter/detail loads correctly
- [ ] Statistics tab loads; mode filter responds
- [ ] Settings changes persist after relaunch
- [ ] Accessibility spot check passes (`AXXXL`)

## Required Screenshots

- [ ] `players-created.png` (Players list with smoke users)
- [ ] `x01-in-match.png` (X01 screen after at least one interaction)
- [ ] `cricket-in-match.png` (Cricket screen after at least one interaction)
- [ ] `history-detail.png` (History detail header + timeline visible)
- [ ] `settings-persistence.png` (Changed setting visible after relaunch)
- [ ] `accessibility-setup-or-match.png` (AXXXL screen showing usable UI)

## Notes Per Flow

### Players

- Outcome:
- Notes:

### X01

- Outcome:
- Notes:

### Cricket

- Outcome:
- Notes:

### History/Stats

- Outcome:
- Notes:

### Settings

- Outcome:
- Notes:

### Accessibility

- Outcome:
- Notes:

## Follow-Ups

- Ticket links:
- Owner:
- Target fix version:
