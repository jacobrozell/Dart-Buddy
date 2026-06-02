# WCAG 2.1 AA rollup

**Last updated:** 2026-06-01  
**Overall release status:** `Not compliant` — evidence matrix incomplete (`roadmap/release/QA-Signoff-RC1.md`).

## Screen status

| Screen | Required criteria | Pass | Partial | Fail | Untested | Blocked | Screen status |
|--------|-------------------|------|---------|------|----------|---------|---------------|
| [play-home](screens/play-home.md) | 12 | 7 | 5 | 0 | 0 | 0 | Partial |
| [match-setup](screens/match-setup.md) | 12 | 9 | 3 | 0 | 0 | 0 | Partial |
| [x01-match](screens/x01-match.md) | 14 | 8 | 6 | 0 | 0 | 0 | Partial |
| [cricket-match](screens/cricket-match.md) | 14 | 10 | 4 | 0 | 0 | 0 | Partial |
| [match-summary](screens/match-summary.md) | 12 | 4 | 7 | 0 | 1 | 0 | Partial |
| [history-list](screens/history-list.md) | 12 | 7 | 5 | 0 | 0 | 0 | Partial |
| [history-detail](screens/history-detail.md) | 12 | 1 | 4 | 0 | 7 | 0 | Partial |
| [statistics](screens/statistics.md) | 12 | 2 | 4 | 0 | 6 | 0 | Partial |
| [players-list](screens/players-list.md) | 12 | 6 | 6 | 0 | 0 | 0 | Partial |
| [player-detail](screens/player-detail.md) | 12 | 1 | 3 | 0 | 8 | 0 | Partial |
| [player-edit](screens/player-edit.md) | 12 | 2 | 3 | 0 | 7 | 0 | Partial |
| [settings](screens/settings.md) | 12 | 6 | 6 | 0 | 0 | 0 | Partial |
| [migration-recovery](screens/migration-recovery.md) | 12 | 6 | 6 | 0 | 0 | 0 | Partial |
| [_shared-components](screens/_shared-components.md) | 8 | 2 | 5 | 1 | 0 | 0 | Partial |

*Counts are manual estimates from the initial audit; update row counts when a screen file changes.*

## Criterion hotspots (fix once, help many screens)

| Criterion ID | Global status | Primary fix |
|--------------|---------------|-------------|
| P-1.4.4 | Partial | Semantic type / `@ScaledMetric` on gameplay typography |
| R-4.1.2 | Partial | X01 pad/score card Pass; Cricket pad + DS primitives still open |
| P-1.4.3 | Untested | Contrast audit on `Brand.textSecondary` and secondary chrome |
| DBX-REDUCE-MOTION | Partial | Summary celebration gated; evidence folder still empty |
| U-3.1.1 | Partial | Finish localization pass (`todo.md`) |
| P-1.3.4 | Untested | Landscape + iPad layout verification |

## Evidence checklist (release)

- [ ] VoiceOver — core flow script (`evidence/README.md`)
- [ ] Dynamic Type — AXXXL on setup, X01, Cricket, history, settings
- [ ] Contrast — light + dark samples logged
- [ ] Orientation — 4 combinations per `specs/SmokeTestChecklist.md`
- [ ] Reduce Motion — summary screen

## Changelog

| Date | Change |
|------|--------|
| 2026-06-01 | Initial tracker from codebase audit |
| 2026-06-01 | Phase 0: X01 pad/score card, live announcements, match summary reduce motion + VO |
| 2026-06-02 | Phase 0.3 Cricket: pad/column/mark labels, closure announcement, nav contrast; AX spot-checks |
| 2026-06-02 | Phase 2 start: setup/home, history, players, settings, migration recovery labels |
