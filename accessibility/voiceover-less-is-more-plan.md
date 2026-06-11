# VoiceOver: less is more plan

**Date:** 2026-06-10  
**Goal:** Reduce audio fatigue during gameplay while keeping WCAG label quality on critical controls.

## Mental model

| Layer | Purpose | Examples |
|-------|---------|----------|
| **Announce** | Transient, automatic | Bust, leg won, checkout changed |
| **Focus** | One swipe = one thought | Active player card, pad keys, actions |
| **Explore** | Optional detail | Opponent cards, stats, history |

## P0 — Gameplay noise (implement first)

1. **Remove segment hint on every pad key** — `scoring.segment.hint` on all 20+ keys; button label is sufficient.
2. **Checkout single channel** — One combined VO element; keep `AccessibilityNotification` on change; hide per-dart pills from VO; remove redundant parent label stack.
3. **Score card trim** — Active: name, remaining, turn, visit darts only. Inactive: name + remaining only. Drop visit total 0, darts thrown, average, sets/legs during live play.
4. **Bust / leg won** — Announce only; hide feedback banners from VoiceOver (visual remains).

## P1 — Trim next

5. **Visit preview on pad** — Hide from VO (score card covers visit during entry).
6. **Modifier hints** — Keep armed hints only; drop unarmed double/triple hints.
7. **Roster / player row hints** — Remove `play.setup.playerRow.accessibilityHint` and `players.row.accessibilityHint`.
8. **Learn rules hint** — Remove `play.rules.learnButton.hint` (button label sufficient).

## Keep (working well)

- Combined score cards (one element per player)
- Spoken dart names (`Triple 20`, not `T20`)
- Decorative icons hidden
- Cricket columns `children: .ignore`
- History / summary combined row labels
- Armed modifier hints
- Destructive-action hints (delete game, undo last throw)

## Target copy

**Active score card:** `"{name}, {remaining} left. Your turn. Visit: {dart1}, {dart2}."`  
**Inactive score card:** `"{name}, {remaining} left."`  
**Checkout (focus):** `"Checkout: Triple 20, Double 16"` (announce on change only)  
**Pad keys:** Label only (`Triple 20`); no segment hint

## Verification

- `Tests/Accessibility/WCAGAccessibilityLabelTests.swift` — pad labels unchanged
- Manual VO: swipe count pad traversal; checkout spoken once on change; bust announcement without banner focus stop
- Update `accessibility/Manual_todo.md` when manual pass completes

## Status

- [x] P0 implemented (2026-06-10)
- [x] P1 implemented (2026-06-10)
- [x] Tests updated — `WCAGAccessibilityLabelTests` passed (2026-06-10)
- [ ] Manual VO pass (device audio; AX evidence in `wcag-2.1-aa/evidence/voiceover/x01-less-is-more-ax-spotcheck-2026-06-10.md`)

## Also applied (consistency pass)

- Transient feedback banners hidden from VO on Cricket, Killer, Shanghai, and Baseball when a matching `AccessibilityNotification` already fires
- Baseball stretch-gate banner remains VO-visible (no announcement duplicate)
