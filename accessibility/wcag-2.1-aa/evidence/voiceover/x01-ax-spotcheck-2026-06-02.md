# X01 match — Simulator AX tree spot-check

**Date:** 2026-06-02  
**Device:** iPhone 16e Simulator (UDID `F9608032-0964-43C2-8D67-C0687F27FA35`)  
**Build:** Debug via XcodeBuildMCP `build_run_sim`  
**Launch args:** `-ui_test_reset -seed_players`  
**Method:** ios-simulator MCP `ui_find_element` / `ui_tap` (not VoiceOver audio)

## Flow exercised

1. Setup: select Alice + Bob → START  
2. X01 board: inspect pad + active score card  
3. Arm TRIPLE → verify `pad_20` label  
4. Score Triple 20 → verify combined score card label  
5. Arm DOUBLE → verify `pad_25` → Double Bull  
6. Re-run after fix: `pad_0` → Miss

## Results

| Check | AXUniqueId / search | AXLabel / outcome | Pass |
|-------|---------------------|-------------------|------|
| Leave match | `chevron.left` | Leave match | ✓ |
| Score card combined | `scoreCard_active` | `Alice, 501 remaining. Your turn. Visit total 0…` | ✓ |
| Visit darts spoken | `scoreCard_active` (after T20) | `…Visit darts Triple 20. Visit total 60…` | ✓ |
| Pad 20 (single) | `pad_20` | `20` + segment hint | ✓ |
| Pad 20 (triple armed) | `pad_20` | `Triple 20` | ✓ |
| Triple modifier armed | `pad_triple` | `Triple` + hint `Next number will be tripled.` | ✓ |
| Double modifier | `pad_double` | `Double` + hints | ✓ |
| Bull single | `pad_25` | `Outer Bull` | ✓ |
| Bull double armed | `pad_25` | `Double Bull` | ✓ |
| Miss key | `pad_0` | `Miss` (was `0` before fix) | ✓ |
| Undo | `pad_undo` | (not re-fetched; label in code: Undo last turn) | — |

## Not covered (manual VoiceOver)

- Focus order / swipe traversal (`O-2.4.3`)  
- Live announcements (bust, checkout, leg won)  
- Bot turn: pad disabled hint + `Bot throwing…` banner  
- Match summary reduce motion + header/stats VO  
- Checkout banner at low remaining

## Fix applied during audit

- `pad_0` used visible `0` as AX label; now uses `Miss` via `DartInput.padKeyAccessibilityLabel(segmentValue: 0, …)`.
