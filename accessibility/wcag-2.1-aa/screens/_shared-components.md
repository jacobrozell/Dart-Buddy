# Shared components

Cross-screen UI that affects multiple WCAG rows. Update here when fixing pad, board, or design-system primitives.

| Component | Source | Used on |
|-----------|--------|---------|
| `DartNumberPad` | `Features/Play/DartNumberPad.swift` | `x01-match` |
| `CricketBoardView` / `CricketMarkCell` | `Features/Play/CricketBoardView.swift` | `cricket-match` |
| `CricketInputPad` | `Features/Play/CricketBoardView.swift` | `cricket-match` |
| `SectorHitsChart` / trend charts | `Features/Statistics/StatsChartViews.swift` | `history-detail`, `statistics` |
| `BrandControls` | `Features/Components/BrandControls.swift` | setup, settings chips |
| `Brand` tokens | `DesignSystem/Tokens/BrandTheme.swift` | all dark gameplay surfaces |

## Criterion checklist

| ID | Status | Notes |
|----|--------|-------|
| P-1.1.1 | Partial | Pad keys use full dart names via `DartInput.padKeyAccessibilityLabel`; charts unchanged |
| P-1.4.1 | Partial | Cricket mark glyphs + VO labels; pad multiplier uses color + spoken state |
| P-1.4.3 | Untested | `Brand.textSecondary` at 55% white |
| P-1.4.4 | Partial | Pad/score card still use fixed `.system(size:)`; Phase 1 AXXXL pass |
| R-4.1.2 | Pass | Pad: label, hint, selected trait on DOUBLE/TRIPLE; identifiers retained |
| O-2.5.3 | Pass | VO says `Triple 20` / `Double Bull` (`DartInput` + pad labels) |
| DBX-TARGET-44 | Pass | Pad `minHeight: 52` |
| DBX-DESIGN-SYSTEM | Fail | No default a11y API on DS primitives (out of Phase 0 scope) |

## Open work

- [x] `DartNumberPad`: `accessibilityLabel` per key including multiplier state (see `specs/AccessibilitySpec.md` §4)
- [x] `DartNumberPad`: announce DOUBLE/TRIPLE selection state in label or hint
- [x] `PlayerScoreCard` (in `X01MatchScreen.swift`): combined accessibility element + summary label
- [ ] Replace fixed gameplay font sizes with scaled styles
- [ ] DesignSystem: `PrimaryActionButton`, chips with built-in labels/identifiers

## Verification log

| Date | Tester | Result | Notes |
|------|--------|--------|-------|
| 2026-06-01 | Agent | Partial | Code complete: pad labels/hints, `DartInput.spokenAccessibilityName`; manual VO + AXXXL pending |
| 2026-06-02 | Agent | Partial | Simulator AX: Triple 20, Double Bull, Miss on `pad_0`; see `evidence/voiceover/x01-ax-spotcheck-2026-06-02.md` |
