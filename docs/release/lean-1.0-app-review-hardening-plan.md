# Lean 1.0 — App Review Hardening Plan

Actionable plan to close **review-facing leaks** and tighten the **1.0 product story** without gutting shipped-but-hidden code.

**Status:** Engineering complete · **Manual/metadata pending**  
**Target version:** `1.0.0`  
**Companion:** [`lean-1.0-implementation-plan.md`](lean-1.0-implementation-plan.md) · [`release_checklist.md`](release_checklist.md) · [`ongoing-release-plan.md`](ongoing-release-plan.md)

---

## Context

Lean 1.0 hides surface area via `ProductSurface` (`Support/Release/ProductSurface.swift`). The engines and screens for party modes, Training Partner bots, and the Modes catalog **stay in the repo** — only UI reachability changes. **Custom bots ship in 1.0** (preset + user-tuned metrics).

**Apple Review risk assessment (2026-06):**

| Concern | Risk | Action |
|---------|------|--------|
| Unreachable / compiled code | **Low** — not a rejection driver | No code deletion required |
| Launch arg `-enable_full_product_surface` | **Low** — not available in App Store builds | Document in internal runbook only |
| Visible “Coming Soon” catalog teasers | **Medium** — can feel beta-ish | Remove from 1.0 mode picker |
| Metadata vs actual surface | **High** if mismatched | Align screenshots + copy |
| Reachable leak paths (party resume, Training Partner) | **Medium** — reviewer can find | Fix in Phase 1 |

**Decision:** Keep `ProductSurface` and merge-forward release branches. **Do not** gut code or maintain parallel deleted-code forks for 1.1+.

---

## Goals

1. No reviewer-visible path to party modes or Training Partner in a Release App Store build (custom bots are intentional in 1.0).
2. Play setup mode picker shows **X01 + Cricket only** — no party/practice teaser rows in 1.0.
3. App Store metadata matches the 4-tab, core-scorekeeper story.
4. Release process uses a stabilization branch; `main` stays the integration line.

---

## Non-goals

- Deleting Baseball/Killer/Shanghai engines, screens, or tests.
- Removing `ProductSurface` or `-enable_full_product_surface` (CI/UI tests depend on it).
- Bundling de/es/nl for 1.0.
- Enabling App Intents for store builds.

---

## Phase 1 — Close leak paths (~½ day)

**Goal:** Every user-facing entry point respects `ProductSurface` in Release builds.

### 1.1 Custom bots in 1.0 (done)

| Item | Detail |
|------|--------|
| **Decision** | `ProductSurface.lean1_0.showsCustomBots = true` — custom bots are a shipped 1.0 feature. |
| **Files** | `Support/Release/ProductSurface.swift`, `Features/Play/Setup/SetupHomeView.swift`, `Features/Players/PlayersRootView.swift` |
| **Acceptance** | Play setup and Players → Add Bot expose custom bot creation; Training Partner remains hidden. |

### 1.2 Block resume into hidden match types

| Item | Detail |
|------|--------|
| **Problem** | `PlayHomeViewModel`, Activity resume, history resume, and deep-link resume can route into party-mode gameplay if persisted data exists. |
| **Approach** | Add `ProductSurface.isMatchTypeReachable(_:)` (or equivalent) mapping `MatchType` → bool. Party types require `showsPartyModes`. |
| **Files** | `Support/Release/ProductSurface.swift`, `Features/Play/Setup/PlayHomeViewModel.swift`, `Features/Play/Setup/PlayRootView.swift`, `Features/History/HistoryRootView.swift`, `App/MainTabView.swift` (Activity `onResumeActiveMatch`), `App/Navigation/AppRouteRouter.swift` (if resume deep link applies) |
| **UX when blocked** | Treat as no active match on Play home; hide or disable resume affordance in Activity/History with no crash. Optional copy: “This match type is not available in this version.” (only if a resume button would otherwise appear). |
| **Acceptance** | With seeded active baseball match in DB and `showsPartyModes == false`: no navigation to `BaseballMatchScreen`; Play home shows setup, not resume banner. |

### 1.3 Audit remaining `ProductSurface` gaps

Walk these files and confirm gates exist (fix any misses):

| Area | File(s) | Expected 1.0 behavior |
|------|---------|------------------------|
| Match setup bots | `Features/Play/Setup/SetupHomeView.swift` | Preset + custom ✓; no Training Partner ✓ |
| Player detail | `Features/Players/PlayerDetailView.swift` | No Training Partner, no export ✓ |
| Activity filters | `Features/Activity/ActivityModeFilter.swift` | X01 + Cricket only ✓ |
| Rules catalog | `Features/Play/Rules/GameRulesCatalog.swift` | X01 + Cricket only ✓ |
| Mode catalog availability | `Features/Modes/GameModeCatalog.swift` | Party filtered from `available` ✓ |
| Deep link to Modes tab | `App/Navigation/AppRouteRouter.swift` | Falls back to Play ✓ |
| Pending mode selection | `Features/Play/Setup/MatchSetupViewModel.swift` | Party ignored ✓ |

### 1.4 Tests

| Test | File |
|------|------|
| `ProductSurface.isMatchTypeReachable` unit tests | `Tests/Unit/ProductSurfaceTests.swift` |
| Play home ignores active party match when party hidden | `Tests/Unit/PlayHomeViewModelTests.swift` |
| Custom bot menu hidden when `showsCustomBots` false | `Tests/Unit/` (new or extend Players tests if view logic is testable via VM) |

**Phase 1 exit:** Manual smoke on Release build — cannot reach baseball, killer, shanghai, or Training Partner from any tab; custom bot create + X01/Cricket match passes.

---

## Phase 2 — Simplify visible 1.0 surface (~½ day)

**Goal:** Mode picker and Play setup present a **finished** core app, not a roadmap catalog.

### 2.1 Lean mode picker: standard modes only

| Item | Detail |
|------|--------|
| **Problem** | `GameModeCatalog.playSetupPickerSections()` surfaces party teasers (Baseball, Killer, Shanghai) and practice stubs with “Coming Soon” when `!showsPartyModes`. |
| **File** | `Features/Modes/GameModeCatalog.swift` |
| **Change** | When `!ProductSurface.showsPartyModes`, `playSetupPickerSections()` returns **only** the `.standard` section (X01, Cricket, and any other *shipped* standard entries — not `americanCricket` if still `.planned`). Do **not** append party or practice teaser sections. |
| **Re-enable** | When `showsPartyModes` flips true in 1.1+, restore current teaser/party section behavior. |
| **Acceptance** | Change mode sheet shows X01 + Cricket only; no “+N more coming” rows in 1.0. |

### 2.2 Confirm setup home copy

| Item | Detail |
|------|--------|
| **File** | `Features/Play/Setup/SetupHomeView.swift` |
| **Change** | Verify no party validation / “coming soon” hints appear in normal flow after 2.1. Remove dead `partyComingSoon` paths from default UX if they become unreachable. |
| **Acceptance** | Start match flow never surfaces party-related validation on a fresh install. |

### 2.3 Tests

| Test | Change |
|------|--------|
| `playSetupPickerSurfacesStandardModesAndTeasersWhenPartyHidden` | Rename + update expectations: **no** party/practice sections when party hidden. |
| UI tests using full surface | Unchanged — still pass `-enable_full_product_surface`. |

**Phase 2 exit:** Fresh-install Release walkthrough — reviewer sees 4 tabs, X01/Cricket only, no coming-soon mode grid.

---

## Phase 3 — Metadata & review notes (~1 day, mostly non-code)

**Goal:** App Store Connect record matches what the binary does.

### 3.1 Screenshots & preview

| Task | Owner |
|------|-------|
| Regenerate or select screenshots showing **Play, X01/Cricket match, Activity, Players, Settings** only | Design / owner |
| **Exclude** party modes, Modes tab, Training Partner (custom bots OK in copy/screenshots) | |
| iPad assets: same scope (runs but not marketed) | |
| Archive paths | `marketing-screenshots/` |

### 3.2 App Store copy

| Field | 1.0 content guidance |
|-------|----------------------|
| **Subtitle** | `X01 & Cricket Scorekeeper` (≤30 chars; no `free` / `no ads`) |
| **Description** | Lead with shipped modes; do **not** list Baseball/Killer/Shanghai as available |
| **Keywords** | darts, cricket, 501, 301, scorekeeper |
| **What’s New (1.0)** | Initial release — no “coming soon” mode list |

### 3.3 App Review notes (App Store Connect)

Include something like:

> Dart Buddy 1.0 is a core darts scorekeeper for X01 (301/501) and Cricket (Normal and Cut Throat). The app has four tabs: Play, Players, Activity, and Settings. Additional game modes are under development and are not exposed in this version.

### 3.4 Docs sync

| File | Update |
|------|--------|
| [`release_checklist.md`](release_checklist.md) | Add § “App Review hardening” checkbox block (see below) |
| [`lean-1.0-implementation-plan.md`](lean-1.0-implementation-plan.md) | Link to this plan; note teaser removal decision |
| [`README.md`](../README.md) | Confirm post-1.0 hidden list is accurate |

**Phase 3 exit:** App Store Connect draft reviewed side-by-side with Release build on device.

---

## Phase 4 — Release branch workflow (~¼ day setup)

**Goal:** Stabilize 1.0 without a gutted fork.

### Branch model

```
main                          ← integration; ProductSurface lean defaults
  └── release/1.0             ← cut before RC; cherry-picks + checklist only
        └── tag 1.0.0         ← Xcode Cloud / TestFlight / App Store
```

### Rules

1. **Do not delete** party/advanced-bot code on `release/1.0`.
2. Hardening PRs merge to `main` first, then cherry-pick to `release/1.0` if branch exists.
3. After App Store approval, merge `release/1.0` → `main` if any checklist-only commits diverged.
4. 1.1 work: flip `ProductSurface` flags on `main`, QA party matrix, ship — no reimplementation.

### Record in release checklist

| Field | Value |
|-------|-------|
| Branch | `release/1.0` |
| Git commit | (fill at RC) |
| Tag | `1.0.0` |

**Phase 4 exit:** Tagged RC built from known commit; branch recorded in checklist § Record.

---

## Phase 5 — Verification (~½ day)

### Automated

```bash
xcodegen generate
xcodebuild test -scheme DartBuddyCI -destination 'platform=iOS Simulator,name=iPhone 17'
```

- [ ] All unit tests green (including updated `ProductSurface` / catalog tests)
- [ ] UI tests with `-enable_full_product_surface` still green (nightly `DartBuddy` scheme)

### Manual — Release build on physical iPhone (no launch args)

| # | Step | Pass |
|---|------|------|
| 1 | Cold install → 4 tabs only | [ ] |
| 2 | Play → Change mode → X01 + Cricket only | [ ] |
| 3 | Full X01 + Cricket (Normal + Cut Throat) match each | [ ] |
| 4 | Players → Add Bot → preset only | [ ] |
| 5 | Player detail → no Export, no Create Training Partner | [ ] |
| 6 | Activity → filters X01 / Cricket / All only | [ ] |
| 7 | Rules (setup + onboarding) → X01 + Cricket only | [ ] |
| 8 | No path to Baseball / Killer / Shanghai | [ ] |

### App Review hardening sign-off

Add to [`release_checklist.md`](release_checklist.md) §0 or new subsection:

- [ ] Phase 1 leak paths closed (custom bots, party resume)
- [ ] Phase 2 mode picker shows standard modes only
- [ ] Phase 3 metadata matches binary (screenshots, description, review notes)
- [ ] Phase 4 RC tagged from `release/1.0` (or `main` at signed commit)
- [ ] This plan linked in PR / sign-off doc

---

## Task checklist (engineering)

| # | Task | Phase | Done |
|---|------|-------|------|
| 1 | Add `ProductSurface.isMatchTypeReachable` | 1 | [x] |
| 2 | Enable custom bots in lean 1.0 (`showsCustomBots`) | 1 | [x] |
| 3 | Filter party resume in Play home + Activity + History | 1 | [x] |
| 4 | Unit tests for reachability + resume filtering | 1 | [x] |
| 5 | Lean `playSetupPickerSections()` — standard only | 2 | [x] |
| 6 | Update `GameModeCatalogTests` | 2 | [x] |
| 7 | Screenshots + App Store copy | 3 | [ ] |
| 8 | App Review notes in Connect | 3 | [ ] |
| 9 | Update `release_checklist.md` + README links | 3 | [ ] |
| 10 | Cut `release/1.0`, tag `1.0.0` | 4 | [ ] |
| 11 | Manual Release smoke (§ Phase 5 table) | 5 | [ ] |

---

## Roll-forward (1.1+)

When shipping party modes:

1. Set `ProductSurface.Configuration.lean1_0.showsPartyModes = true` (or introduce `lean1_1` config slice).
2. Restore party sections in `playSetupPickerSections()` via existing `showsPartyModes` branch.
3. Run party device matrix from [`ongoing-release-plan.md`](ongoing-release-plan.md) §1.1.
4. Update App Store metadata: “Now with Baseball, Killer & Shanghai.”

No code reintroduction PR required.

---

## Decision log

| Date | Decision | Rationale |
|------|----------|-----------|
| 2026-06-11 | Keep code; harden reachability + UX | Apple unlikely to reject compiled hidden code; leaks and metadata are the real risk |
| 2026-06-11 | Remove mode-picker teasers for 1.0 | Cleaner “finished scorekeeper” story for review |
| 2026-06-11 | `release/1.0` branch, no gutted fork | Merge-forward beats parallel deleted-code RCs |
| 2026-06-11 | Custom bots in 1.0; Training Partner stays hidden | Same `DartBotEngine` path; better UX than hiding; weak device QA addressed in checklist |
