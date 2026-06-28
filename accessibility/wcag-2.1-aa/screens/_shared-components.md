# Shared components

Cross-screen UI that affects multiple WCAG rows. Update here when fixing pad, board, or design-system primitives.

| Component | Source | Used on |
|-----------|--------|---------|
| `DartNumberPad` | `Features/Play/X01/DartNumberPad.swift` | `x01-match` |
| `CricketBoardView` / `CricketMarkCell` | `Features/Play/Cricket/CricketBoardView.swift` | `cricket-match` |
| `CricketTapPad` | `Features/Play/Cricket/CricketBoardView.swift` | `cricket-match` |
| `BrandSegmented` | `DesignSystem/Components/BrandControls.swift` | setup, history, statistics |
| `StatTable` | `Features/Statistics/StatTable.swift` | statistics, history-detail |
| `SectorHitsChart` / trend charts | `Features/Statistics/StatsChartViews.swift` | history-detail, statistics, player-detail |
| `Brand` tokens | `DesignSystem/Tokens/BrandTheme.swift` | all dark gameplay surfaces |

## Criterion checklist

| ID | Status | Notes |
|----|--------|-------|
| P-1.1.1 | Pass | Pad, charts, tables expose spoken summaries |
| P-1.4.1 | Pass | Marks, traits, non-color state on pickers |
| P-1.4.3 | Untested | `Brand.textSecondary` at 55% white |
| P-1.4.4 | Partial | Gameplay fixed fonts; Phase 1 AXXXL |
| R-4.1.2 | Pass | Pad, segmented, tables, charts labeled |
| O-2.5.3 | Pass | Full dart names on pads |
| DBX-TARGET-44 | Pass | Pad 52pt; avatar/color pickers ≥ 44pt |
| DBX-DESIGN-SYSTEM | Fail | No default a11y API on DS primitives (post-MVP) |

## Open work

- [x] `DartNumberPad` / `CricketTapPad` labels and hints
- [x] `BrandSegmented` selected trait
- [x] `StatTable` row labels
- [x] Trend chart dates in accessibility value
- [x] Loading `ProgressView` spinners carry `L10n.loading` label (match screens, summary, history, statistics, player detail)
- [ ] Replace fixed gameplay font sizes with scaled styles
- [ ] DesignSystem: default a11y props on primitives

## Verification log

| Date | Tester | Result | Notes |
|------|--------|--------|-------|
| 2026-06-02 | Agent | Partial | All shared gameplay/tab components labeled in code |
| 2026-06-06 | Agent | Partial | Unlabeled loading `ProgressView` spinners across 12 sites now expose `common.loading` (R-4.1.2 / P-1.1.1) |
