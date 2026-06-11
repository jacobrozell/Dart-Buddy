# X01 match — less-is-more AX spot-check

**Date:** 2026-06-10  
**Scope:** VoiceOver less-is-more pass (implemented 2026-06-10)  
**Method:** Code review + build verification (manual VO audio still required)

## Expected AX behavior after changes

| Element | Before | After |
|---------|--------|-------|
| `scoreCard_active` | Name, remaining, turn, visit, visit total 0, sets/legs, darts, average | Name, remaining, turn, visit darts only |
| `scoreCard` (inactive) | Full stats dump | Name, remaining only |
| `checkoutSuggestion` | Parent label + per-dart pills + footnote | Single combined label; cycle button separate |
| `pad_20` | `20` + segment hint | `20` label only |
| `pad_triple` (armed) | `Triple` + armed hint | Unchanged |
| `pad_triple` (idle) | `Triple` + unarmed hint | `Triple` label only |
| `dart_visit_preview` | Spoken visit when darts entered | Hidden from VO |
| `bustBanner` / `legWonBanner` | Focusable text | Hidden from VO; announcement only |

## Manual VO still required

- Swipe count through pad (should be ~50% less hint repetition)
- Checkout route spoken once on score change (announcement), not per pill
- Bust: announcement without extra banner stop
