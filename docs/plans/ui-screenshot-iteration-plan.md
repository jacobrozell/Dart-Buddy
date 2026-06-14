# UI screenshot iteration plan

**Source:** Marketing + accessibility screenshot review (2026-06-13)  
**Goal:** Close every visual/layout issue found in repo screenshots without regressing WCAG evidence.

## How to use this doc

- Work **top to bottom** within each phase; later phases depend on shared tokens/helpers from earlier ones.
- Check boxes when merged; link PR or commit in the checkbox if helpful.
- Re-capture evidence listed under **Verification** when a phase completes.

## Phase 0 — Shared tokens & helpers

| ID | Issue | Fix | Files | Status |
|----|-------|-----|-------|--------|
| P0-1 | Visit preview slots invisible on dark background | Lighten `Brand.dartBox` (dark); add subtle stroke via `scoringPadVisitSlotStyle()` | `BrandTheme.swift`, `ScoringPadStyle.swift`, pad visit previews | [x] |
| P0-2 | Settings section footers scale to header size at AXXXL | `settingsSectionFooter()` → `.font(.footnote)` on all Settings footers | `SettingsRootView.swift` | [x] |

## Phase 1 — Layout bugs (P0 screenshots)

| ID | Issue | Fix | Files | Status |
|----|-------|-----|-------|--------|
| P1-1 | Players search bar overlaps first list row | Replace `safeAreaInset` + `List` with `VStack { header; List }` | `PlayersRootView.swift` | [x] |
| P1-2 | AXXXL setup: “Change” wraps, mode blurb clips | Accessibility layout stacks Change below mode card; allow vertical growth | `SetupHomeView.swift` | [x] |
| P1-3 | AXXXL X01 checkout pills truncate (“T…”) | Horizontal `ScrollView` for route row at AX sizes; tighter pill padding | `CheckoutSuggestionBanner.swift` | [x] |
| P1-4 | AXXXL Activity filters clip / resume banner overlaps | Larger `tabScrollBottomPadding`; AX period segments scroll horizontally | `GameplayLayout.swift`, `BrandControls.swift` | [x] |
| P1-5 | iPad X01: dead zone between scoreboard and pad | When `!scoreboardFillsRemainingHeight`, bottom-align scoreboard+pad block | `StandardMatchScoringBody.swift` | [x] |

## Phase 2 — Gameplay & list polish

| ID | Issue | Fix | Files | Status |
|----|-------|-----|-------|--------|
| P2-1 | Cricket pad empty cell beside MISS | Remove spacer column; equal-width BULL/MISS row | `CricketTapPad.swift` | [x] |
| P2-2 | Cricket active column: open marks black, closed marks tinted | Use player accent for marks ≥ 1 | `CricketMarkCell` in `CricketBoardColumns.swift` | [x] |
| P2-3 | X01 history card: loser score not dimmed | Apply winner/loser foreground to score column | `HistoryRootView.swift` (`MatchHistoryCard`) | [x] |
| P2-4 | Statistics table headers too faint | `Brand.textBodyOnCard` on compact table header row | `StatisticsRootView.swift` | [x] |
| P2-5 | Checkout pill hierarchy unclear | Highlight **first** dart in route as “up next” (green) | `CheckoutSuggestionBanner.swift` | [x] |
| P2-6 | Duplicate undo (header + pad) | Document as known; defer hiding header undo (needs UX sign-off) | — | deferred |

## Phase 3 — Hierarchy & consistency

| ID | Issue | Fix | Files | Status |
|----|-------|-----|-------|--------|
| P3-1 | Red START / Rematch reads destructive | START + Rematch → `PrimaryActionButton` accent `.green` | `SetupHomeView.swift`, `MatchSummaryScreen.swift` | [x] |
| P3-2 | Add Bot vs Add Players unequal width | Always `matchesSiblingHeight: true` on roster action buttons | `SetupHomeView+Roster.swift` | [x] |
| P3-3 | Onboarding welcome: empty vertical middle | Center hero content on phone (`minHeight` in `OnboardingStepChrome`) | `OnboardingStepChrome.swift` | [x] |
| P3-4 | Match summary iPad: content top-heavy | Center action stack in regular width (`MatchSummaryScreen`) | `MatchSummaryScreen.swift` | [x] |
| P3-5 | Settings mixed row styles (standalone vs grouped) | Defer — needs design pass | — | deferred |
| P3-6 | Settings iPad label-to-control distance | Already uses `readableRootContentWidth`; verify after P0-2 | — | verify on device |

## Phase 4 — Capture / copy follow-ups

| ID | Issue | Action | Status |
|----|-------|--------|--------|
| P4-1 | iPad cricket landscape rotated pad labels | Re-captured 2026-06-13 — verify visually in updated `ipad/…-cricket-match-*-landscape.png` | [x] |
| P4-2 | Settings theme footer vs System+light capture | Marketing light captures re-run; policy unchanged | [x] |
| P4-3 | History identical timestamps in demo seed | Accept for marketing; optional finer `endedAt` in seeder | optional |

## Verification

After Phases 0–3:

1. Unit: `GameplayLayoutTests`, `WCAGContrastTests` (dartBox), `CricketBoardLayoutTests` — **passed 2026-06-13**
2. UI: `WCAGAccessibilityUITests` AXXXL paths (setup, X01, Activity, Settings) — **manual / CI**
3. Re-run marketing capture scripts for touched screens:
   - `./Scripts/capture-marketing-screenshots.sh`
   - `./Scripts/capture-ipad-marketing-screenshots.sh`
4. Accessibility AXXXL matrix under `accessibility/screenshots/`.

**Completed 2026-06-13** — full pipeline (~28 min): marketing (iPhone + iPad, light + dark), accessibility (iPhone + iPad, portrait + landscape, light + dark), orientation matrix, Liquid Glass tabs, framed iPhone marketing, dynamic-type evidence sync.

## Changelog

| Date | Change |
|------|--------|
| 2026-06-13 | Initial plan from full-repo screenshot audit |
| 2026-06-13 | Implemented Phases 0–3 (code); Phase 4 capture tasks remain |
| 2026-06-13 | Re-captured all screenshot assets (198 PNGs across marketing + accessibility + WCAG evidence) |
