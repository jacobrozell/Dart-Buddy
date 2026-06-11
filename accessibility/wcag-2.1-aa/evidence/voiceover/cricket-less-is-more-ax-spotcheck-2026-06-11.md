# Cricket match — less-is-more AX spot-check

**Date:** 2026-06-11  
**Plan:** `accessibility/voiceover-less-is-more-plan.md`  
**Method:** Code review + build verification (manual VO audio still required)

## Expected AX behavior after changes

| Element | Before | After |
|---------|--------|-------|
| `cricket_column` / `cricket_column_active` | Name, score, darts thrown, marks per round, turn | Name, score, optional “Your turn” only |
| Inactive columns | Full stats dump per swipe | Name + score only |
| Pad keys | Unchanged | Unchanged (`Triple 20`, `Miss`, etc.) |
| Closure / board updated | Announcement + banner | Unchanged |

## Manual VO still required

- [ ] Mid-game board: swipe columns after 3+ visits — labels should not repeat darts/marks on every column
- [ ] Active column still announces turn state without nested child elements speaking separately
- [ ] Mark state (open/closed) remains available on pad or target focus, not lost with shorter column labels
- [ ] Portrait and landscape: column order and pad focus order unchanged from 2026-06-02 spot-check
