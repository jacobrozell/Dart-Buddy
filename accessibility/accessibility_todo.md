# Accessibility long-term plan (WCAG 2.1 AA)

Strategic backlog for reaching and **maintaining** WCAG 2.1 Level AA on Dart Buddy.

| Artifact | Role |
|----------|------|
| `specs/AccessibilitySpec.md` | Requirements (what “done” means) |
| `accessibility/wcag-2.1-aa/` | Per-screen + per-criterion **status** and evidence |
| `accessibility/accessibility_todo.md` | **This file** — phased work plan |
| `todo.md` § 1.0 QA sign-off | Release accessibility evidence (links here for detail) |

**Current baseline (2026-06-02):** All 13 MVP screens have **zero Required Fail** in code; screens remain **Partial** until manual evidence (`accessibility/Manual_todo.md`, `wcag-2.1-aa/SUMMARY.md`).

---

## Target end state

1. **Core flows** (setup → X01 or Cricket → summary) pass all **Required** criteria in `wcag-2.1-aa/criteria.md` with logged evidence.
2. **All MVP tab screens** at `Pass` on Required criteria in their screen tracker files.
3. **Shared components** enforce accessibility by default (`DesignSystem` + pad/board/charts).
4. **Every PR** that touches UI completes `specs/UIReviewChecklist.md` §6–7 or explicitly defers with a tracker link.
5. **Regression:** smoke protocol includes VoiceOver + AXXXL + 4-way appearance; optional UI tests for key identifiers.

---

## Phases overview

| Phase | Goal | Exit criterion |
|-------|------|----------------|
| **0 — Release blockers** | Fix known Fail/Partial items on gameplay path | Core flow matrix in `QA-Signoff-RC1.md` accessibility = Pass |
| **1 — Verify core AA** | Manual proof for setup + both match modes + summary | Evidence folder complete for core flow; `SUMMARY.md` core screens Pass |
| **2 — Full MVP AA** | Tabs + global routes at Required Pass | All 13 screen files `Screen status: Pass` |
| **3 — Hardening** | Design system, automation, process | DBX-DESIGN-SYSTEM Pass; identifier smoke tests in CI |
| **4 — Sustain** | No drift on new features | PR gate + quarterly re-audit |

Phases are sequential for **first App Store quality gate**, but Phase 3 engineering can start in parallel once Phase 0 pad/score-card work lands.

---

## Phase 0 — Release blockers (P0)

*Unblock “defensible AA” on the paths you ship.*

### 0.1 Shared gameplay components (highest leverage)

Track in: `wcag-2.1-aa/screens/_shared-components.md`

- [x] **DartNumberPad** — `accessibilityLabel` per key: full dart name (`Triple 20`, `Double bull`, `Miss`) including active DOUBLE/TRIPLE modifier in label or hint (`Features/Play/DartNumberPad.swift`).
- [x] **DartNumberPad** — `accessibilityHint` on modifier keys when armed (e.g. “Next number will be tripled”).
- [x] **PlayerScoreCard** — Single combined element: name, remaining, active turn, visit darts (spoken, not only `T20`), sets/legs, average (`X01MatchScreen.swift`).
- [x] **Live feedback** — Announce bust, checkout suggestion change, leg win (`AccessibilityNotification` on `X01MatchScreen`); manual VO verification pending.

**Validates:** R-4.1.2, O-2.5.3, U-3.3.2, spec §4 scoring labels.

### 0.2 X01 match screen

Track in: `wcag-2.1-aa/screens/x01-match.md`

- [x] Wire pad + score card fixes from 0.1.
- [x] Localize / label `Bot throwing…` banner (`L10n.botThrowing` + combined VO label).
- [x] Disabled pad when bot plays: disabled trait + `play.x01.pad.disabledWhileBot` hint.
- [ ] VoiceOver script: leave match → undo → score 3 darts → bust → checkout banner.

### 0.3 Cricket match screen

Track in: `wcag-2.1-aa/screens/cricket-match.md`

- [x] **Cricket nav title contrast** — `toolbarColorScheme(.dark)` + visible bar on `Brand.background` (`CricketMatchScreen`).
- [x] Target pad buttons: spoken labels via `DartInput.padKeyAccessibilityLabel` on `CricketTapPad`; grid cells read-only (pad is 52pt).
- [x] Active column: combined header accessibility label (`CricketBoardView`).
- [x] Closure transition: banner + `AccessibilityNotification` on `.closureTransition`; manual VO pending.

### 0.4 Match summary

Track in: `wcag-2.1-aa/screens/match-summary.md`

- [x] **Reduce Motion** — Gate celebration on `@Environment(\.accessibilityReduceMotion)` (`MatchSummaryScreen`).
- [x] Combined header / stats table VoiceOver summary.

### 0.5 Evidence minimum for ship

Track in: `wcag-2.1-aa/evidence/`

- [ ] VoiceOver notes: `setup → x01 → summary` and `setup → cricket → summary`.
- [ ] AXXXL screenshots: setup, x01, cricket (link or copy from `snapshots/*-axxxl-*`).
- [ ] Update `roadmap/release/QA-Signoff-RC1.md` accessibility rows to Pass with file paths.

**Phase 0 done when:** `x01-match`, `cricket-match`, `match-summary`, `_shared-components` have no `Fail` on Required criteria and core flow evidence exists.

---

## Phase 1 — Verify core flow AA (P0 / P1)

*Turn “we think it works” into criterion-level Pass rows.*

### 1.1 Manual verification pass

- [ ] Run `specs/SmokeTestChecklist.md` accessibility section (AXXXL + VoiceOver).
- [ ] Per screen: fill **Verification log** in `match-setup.md`, `play-home.md`, core match files.
- [ ] Fix issues found; set criterion cells to `Pass` only with date + device in Evidence column.

| Check | Screens | Criterion IDs |
|-------|---------|---------------|
| Focus order | setup, x01, cricket | O-2.4.3, P-1.3.2 |
| Meaningful sequence | x01, cricket | P-1.3.2 |
| Label in name | setup chips, cricket pad | O-2.5.3 |
| Error identification | setup, x01 bust | U-3.3.1 |

### 1.2 Contrast audit (core surfaces only)

- [ ] Sample with Accessibility Inspector: `Brand.textSecondary` on `Brand.card` / `background`.
- [ ] Secondary stats on X01 card (caption).
- [ ] Amber bot banner on dark background.
- [ ] Document pass/fail in `wcag-2.1-aa/evidence/contrast/`; adjust tokens if fail.

**Validates:** P-1.4.3, P-1.4.11, DBX-CONTRAST-MODES (gameplay dark).

### 1.3 Dynamic Type (core only)

- [ ] AXXXL: remaining score and pad remain usable (may require layout work from `todo.md` X01 dead space / card legibility).
- [ ] Introduce scaled typography helper (see Phase 3.1) at least on pad + remaining score.

**Validates:** P-1.4.4 on core flow.

**Phase 1 done when:** `SUMMARY.md` shows core flow screens (`play-home`, `match-setup`, `x01-match`, `cricket-match`, `match-summary`) as `Pass` for all Required criteria.

---

## Phase 2 — Full MVP AA (P1)

*Extend proof to every tab and global route.*

### 2.1 Layout and orientation (feeds WCAG, not only UX)

Linked `todo.md` items — complete before signing P-1.3.4 / P-1.4.10:

- [ ] iPad / landscape layouts.
- [ ] Cricket one-screen fit (phone); X01 layout dead space.
- [ ] Setup flow roster / START / tab bar ordering.
- [ ] 4-way matrix evidence: portrait/landscape × light/dark per `specs/SmokeTestChecklist.md` → `evidence/orientation/`.

### 2.2 Tab screens (engineering + verify)

| Screen | Key work | Tracker |
|--------|----------|---------|
| History list | VO: filter, resume, load more | `history-list.md` — [x] labels; manual VO open |
| History detail | Delete alert a11y; chart sections | `history-detail.md` — [x] labels; manual VO open |
| Statistics | Filter controls; trend value includes dates | `statistics.md` — [x] labels; manual VO open |
| Players list | Search label; row summary; swipe actions | `players-list.md` — [x] labels; manual VO open |
| Player detail | Stat tiles + recent matches VO | `player-detail.md` — [x] labels; manual VO open |
| Player edit | TextField label; 44pt color swatches | `player-edit.md` — [x] labels; manual VO open |
| Settings | Reset destructive flow VO | `settings.md` — [x] reset ID/label; manual VO open |
| Migration recovery | Recovery CTAs VO | `migration-recovery.md` — [x] IDs/labels; manual VO open |
| Play home | Resume / start VO | `play-home.md` — [x] labels; manual VO open |
| Match setup | Chip labels; AXXXL roster | `match-setup.md` — [x] chips/roster; manual VO open |

### 2.3 Theme and appearance cohesion

- [ ] **Theme cohesion** — Settings vs Play when user prefers dark (`todo.md`) — DBX-CONTRAST-MODES across app.
- [ ] Re-run contrast audit on **light** settings surfaces and **dark** play surfaces.

**Phase 2 done when:** All 13 screen trackers `Screen status: Pass`; `SUMMARY.md` **Overall release status** → `Compliant (MVP scope)`; evidence checklist in `SUMMARY.md` fully checked.

---

## Phase 3 — Hardening (P1 / P2)

*Prevent regressions; reduce per-screen bespoke work.*

### 3.1 Typography and scaling policy

- [ ] Add `DesignSystem` text style wrappers or `@ScaledMetric` for gameplay sizes (pad, score, cricket grid).
- [ ] Ban new fixed `.font(.system(size:))` in `Features/` except icons (lint or code review rule).
- [ ] Document allowed scale clamps (`minimumScaleFactor` limits) in `specs/DesignSystemSpec.md`.

**Validates:** P-1.4.4 globally.

### 3.2 DesignSystem accessibility contract

- [ ] `PrimaryActionButton`, `StatChip`, `ErrorBanner` with default label, hint, identifier (`todo.md`).
- [ ] `BrandControls` / chips: expose selected state in accessibility value.
- [ ] PR template: “uses DS component” → a11y props not reimplemented ad hoc.

**Validates:** R-4.1.2, DBX-DESIGN-SYSTEM.

### 3.3 Automation (post–UI-lock)

- [x] XCTest: assert `accessibilityIdentifier` presence on `startMatchButton`, `pad_20`, `scoreCard_active`, settings toggles (`UITests/WCAGAccessibilityUITests.swift`).
- [x] Tag tests `@Tag(.accessibility)` (`Tests/FoundationTests/WCAGAccessibilityLabelTests.swift`).
- [ ] Optional: snapshot tests at **Large** and **AXXXL** content size for core screens.

### 3.4 VoiceOver scripts (repeatable QA)

- [ ] Check in `evidence/voiceover/core-flow-x01.md` and `core-flow-cricket.md` step lists (copy from smoke checklist).
- [ ] Add destructive paths: settings reset, delete game, abandon match.

**Phase 3 done when:** New screens default to DS components; CI catches missing identifiers on core controls; quarterly audit is script-only.

---

## Phase 4 — Sustain (ongoing)

### 4.1 Process

- [ ] Every UI PR: `UIReviewChecklist` §6–7 checked or N/A with tracker link.
- [ ] On merge: update relevant `wcag-2.1-aa/screens/*.md` rows if behavior changed.
- [ ] Release: `SUMMARY.md` + `QA-Signoff` accessibility cannot be Pending.

### 4.2 Quarterly re-audit (30–60 min)

- [ ] Re-run core VoiceOver scripts on latest build.
- [ ] Spot-check AXXXL on one gameplay screen.
- [ ] Review new criterion failures from Apple OS or WCAG interpretation changes.

### 4.3 Post-MVP backlog (not required for 1.0 AA)

| Item | WCAG / product note |
|------|---------------------|
| Apple Watch companion | Out of MVP scope (`specs/AppleWatchCompanionSpec.md`) |
| WCAG 2.2 AA (e.g. 2.5.8 Target Size AA) | Evaluate when raising standard |
| Full Keyboard / Switch Control audit | iPad + external keyboard |
| RTL layout | If localization expands beyond LTR |
| Increased Contrast / Bold Text | iOS system settings interaction audit |
| UI test full traversal | Expensive; after identifier coverage stable |

---

## Workstreams ↔ `todo.md` crosswalk

These product tasks are **accessibility dependencies** — schedule with Phase 1–2:

| `todo.md` item | WCAG impact |
|----------------|-------------|
| iPad / landscape layouts | P-1.3.4, P-1.4.10 |
| Accessibility pass (tracker) | All Phase 0–2 |
| Cricket nav title contrast | P-1.4.3 |
| X01 layout dead space / card legibility | P-1.4.4 |
| Theme cohesion | DBX-CONTRAST-MODES |
| Reduce Motion on summary | DBX-REDUCE-MOTION |
| DesignSystem primitives | R-4.1.2, DBX-DESIGN-SYSTEM |
| Cricket closure highlight | P-1.4.1, announcements |
| Unify match exit chrome | O-2.4.4 consistency |

---

## Suggested timeline (indicative)

| Window | Focus |
|--------|--------|
| **Sprint A** | Phase 0.1–0.4 (pad, score card, reduce motion, cricket contrast) |
| **Sprint B** | Phase 1 (VO scripts, contrast + AXXXL evidence, core Pass rows) |
| **Sprint C–D** | Phase 2 layout + tab screens + orientation matrix |
| **Ongoing** | Phase 3 DS + automation; Phase 4 on every release |

Adjust to release date; **do not ship 1.0** with Phase 0 open on core gameplay.

---

## Definition of done (WCAG 2.1 AA — MVP)

- [ ] `accessibility/wcag-2.1-aa/SUMMARY.md` → Overall: **Compliant (MVP scope)**.
- [ ] Zero `Fail` on **Required** criteria for core flow screens.
- [ ] Evidence checklist in `SUMMARY.md` complete (VoiceOver, AXXXL, contrast, orientation, reduce motion).
- [ ] `roadmap/release/QA-Signoff-RC1.md` accessibility section Pass with links.
- [ ] `specs/ReleaseGateChecklist.md` accessibility steps signed.
- [ ] Hotfix criteria document accessibility regression as P0 (`Rollback-and-Hotfix-Criteria.md`).

---

## How to use this file day to day

1. Pick the **current phase**; work top to bottom within it.
2. When a checkbox ships, update the matching **screen/criterion** file under `wcag-2.1-aa/`.
3. Move completed phase sections to a **Changelog** at the bottom (optional) or mark phase header with ✅ date.
4. Keep **one source of truth for status**: tracker tables = Pass/Fail; this file = planned work only.

### Changelog

| Date | Change |
|------|--------|
| 2026-06-01 | Initial long-term plan |
| 2026-06-01 | Phase 0.1–0.2, 0.4: X01 pad/score card, announcements, summary reduce motion + VO |
| 2026-06-03 | Contrast audit (P-1.4.3): added `Brand.redAccent` (white-text CTA/error banner now 4.80:1, was 3.94/3.47); added `Brand.inkOnBright` for labels on bright fills (armed DOUBLE/TRIPLE pad keys, cricket ENTER, setup chips, empty-state Start CTAs — dark mode was 1.85–2.97:1, now 6–10:1); bot-turn + partial-stats banners and `StatusBadge` converted to tinted pills (amber/accent on light surfaces was ~1.6–2.9:1). Evidence regenerated in `evidence/contrast/`; Swift regression tests added in `Tests/FoundationTests/WCAGContrastTests.swift`. |
