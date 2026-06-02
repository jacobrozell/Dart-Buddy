# Cricket match — Simulator AX tree spot-check

**Date:** 2026-06-02  
**Device:** iPhone 16e Simulator  
**Launch args:** `-ui_test_reset -seed_players`  
**Method:** ios-simulator MCP `ui_find_element` / `ui_tap`

## Flow

Setup → Cricket mode → Alice + Bob → START → inspect board + pad.

## Results

| Check | Result | Pass |
|-------|--------|------|
| Active column `cricket_column_active` | `Alice, score 0. Your turn` | ✓ |
| Pad `cricket_20` (single) | `20` + segment hint | ✓ |
| Pad `cricket_20` (triple armed) | `Triple 20` | ✓ |
| Pad `cricket_miss` | `Miss` | ✓ |
| Pad `cricket_triple` | `Triple` + hints | ✓ |
| Mark cell | `20, Open` | ✓ |

## Not covered (manual — see `accessibility/Manual_todo.md`)

- VoiceOver focus order and closure announcement audio  
- Bot turn pad disabled + banner  
- Nav title contrast visual check (code: dark toolbar scheme)  
- 3× tap close target → `20, Closed`
