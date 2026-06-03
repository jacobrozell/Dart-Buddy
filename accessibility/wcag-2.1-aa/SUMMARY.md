# WCAG 2.1 AA rollup

**Last updated:** 2026-06-02  
**Overall release status:** `Not compliant` — engineering pass complete on all MVP screens; **manual VoiceOver / AXXXL** still required (`accessibility/Manual_todo.md`). Contrast token audit + 4-way orientation matrix captured 2026-06-02.

## Screen status

| Screen | Required criteria | Pass | Partial | Fail | Untested | Blocked | Screen status |
|--------|-------------------|------|---------|------|----------|---------|---------------|
| [play-home](screens/play-home.md) | 12 | 7 | 5 | 0 | 0 | 0 | Partial |
| [match-setup](screens/match-setup.md) | 12 | 9 | 3 | 0 | 0 | 0 | Partial |
| [x01-match](screens/x01-match.md) | 14 | 8 | 6 | 0 | 0 | 0 | Partial |
| [cricket-match](screens/cricket-match.md) | 14 | 10 | 4 | 0 | 0 | 0 | Partial |
| [match-summary](screens/match-summary.md) | 12 | 4 | 7 | 0 | 1 | 0 | Partial |
| [history-list](screens/history-list.md) | 12 | 7 | 5 | 0 | 0 | 0 | Partial |
| [history-detail](screens/history-detail.md) | 12 | 9 | 3 | 0 | 0 | 0 | Partial |
| [statistics](screens/statistics.md) | 12 | 8 | 4 | 0 | 0 | 0 | Partial |
| [players-list](screens/players-list.md) | 12 | 6 | 6 | 0 | 0 | 0 | Partial |
| [player-detail](screens/player-detail.md) | 12 | 8 | 4 | 0 | 0 | 0 | Partial |
| [player-edit](screens/player-edit.md) | 12 | 9 | 3 | 0 | 0 | 0 | Partial |
| [settings](screens/settings.md) | 12 | 6 | 6 | 0 | 0 | 0 | Partial |
| [migration-recovery](screens/migration-recovery.md) | 12 | 6 | 6 | 0 | 0 | 0 | Partial |
| [_shared-components](screens/_shared-components.md) | 8 | 5 | 2 | 1 | 0 | 0 | Partial |

*All 13 MVP screens: **zero Required Fail** in code scope. `DBX-DESIGN-SYSTEM` remains Fail on `_shared-components` (post-MVP). Screens stay **Partial** until manual VO/contrast/AXXXL evidence.*

## Criterion hotspots (fix once, help many screens)

| Criterion ID | Global status | Primary fix |
|--------------|---------------|-------------|
| P-1.4.4 | Partial | Semantic type / `@ScaledMetric` on gameplay typography |
| P-1.4.3 | Partial | Token audit `evidence/contrast/brand-token-samples-2026-06-02.md`; CTA large-text |
| DBX-CONTRAST-MODES | Partial | Primary surfaces pass; Settings light native vs brand tabs |
| DBX-REDUCE-MOTION | Partial | Summary gated; manual evidence pending |
| DBX-DESIGN-SYSTEM | Fail | DesignSystem default a11y API (post-MVP) |
| P-1.3.4 / P-1.4.10 | Partial | 4-way matrix `evidence/orientation/` (setup + X01) |

## Evidence checklist (release)

- [ ] VoiceOver — core + tab flows (`accessibility/Manual_todo.md`)
- [ ] Dynamic Type — AXXXL on setup, X01, Cricket, history, settings
- [x] Contrast — light + dark samples logged (`evidence/contrast/brand-token-samples-2026-06-02.md`)
- [x] Orientation — 4 combinations (`evidence/orientation/README.md`)
- [ ] Reduce Motion — summary screen (Settings check)

## Changelog

| Date | Change |
|------|--------|
| 2026-06-01 | Initial tracker from codebase audit |
| 2026-06-01 | Phase 0: X01 pad/score card, live announcements, match summary reduce motion + VO |
| 2026-06-02 | Phase 0.3 Cricket; AX spot-checks |
| 2026-06-02 | Phase 2: all tab + setup screens — labels/IDs; no Required Fail on screen trackers |
| 2026-06-02 | P4: brand contrast samples + 4-way orientation matrix; light marketing raw set |
