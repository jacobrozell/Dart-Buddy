# Duo + dynamic layout release

**Status:** Draft  
**Created:** 2026-10-15  
**Goal:** Ship a layout release that follows the window, not the device. iPhone Duo (inner and outer display) and resizable iPad (Split View, Stage Manager, Slide Over) should get the same scoring, setup, and list chrome as a full-screen iPad of the same size.

**Version:** **1.3.0**, after **1.2.0** ships. Confirmed 2026-10-28. 1.2 stays locked (10 modes, Training Partner, German, export). Modes Catalog moves to **1.4**.

**Reference pass:** Puzzle Buddy [`ongoing/iphone-duo-1.1.0.md`](../../../PuzzleBuddy/ongoing/iphone-duo-1.1.0.md) — size classes for chrome, no idiom, no orientation.

**Last updated:** 2026-10-28

---

## Why this is its own release

`GameplayLayout` still treats “iPad” as `UIDevice.current.userInterfaceIdiom == .pad`. That was the right fix when Plus / Pro Max landscape reported the same **regular** width as iPad. It is the wrong fix now:

| Surface | Idiom | Typical size classes | What the app does today |
|---------|-------|----------------------|-------------------------|
| iPhone portrait | phone | compact × regular | Phone shell. Correct. |
| iPhone Pro Max landscape | phone | regular × compact | Phone landscape, because `isPad` is false. Correct for a short phone. |
| iPhone Duo, folded | phone | compact × regular | Phone shell. Correct if the outer display stays phone-sized. |
| iPhone Duo, open | phone | often regular × regular or regular × compact | **Phone shell.** Wide inner display is ignored wherever a helper requires `isPad`. |
| iPad full screen | pad | regular × regular / compact | iPad helpers. |
| iPad Split View / Stage Manager, narrow | pad | compact width | **Still “iPad”.** Portrait/landscape helpers key off idiom + vertical size class, so a phone-width window can get tablet pad widths (300–420pt). |

Analytics may keep idiom (`ClientEnvironment.deviceClass`). Layout must not.

---

## Scan — issues to fix in this release

### 1. Idiom gates block Duo and ignore window size

`defaultIsPad` in [`GameplayLayout.swift`](../../DesignSystem/Components/GameplayLayout.swift) feeds:

- `contentMaxWidth` — 920pt column only when regular **and** pad. Duo regular width stretches to infinity.
- `usesWideSetupHomeLayout` — two-pane setup only on pad. Duo stays single column.
- `usesWidePlayerScoreCardLayout` — wide score cards only on pad.
- `usesLandscapeIPhoneOnlyMatchScoringLayout` / `usesLandscapeIPadMatchScoringLayout` — compact height is split by idiom, and **horizontal size class is discarded**.
- `usesLandscapeIPhoneMatchSummaryLayout` — same split.

### 2. One helper already ignores idiom, so Duo and Pro Max disagree

`usesIPadPortraitMatchScoringLayout` is `horizontal == .regular && vertical == .regular` with **no** `isPad`. A Duo inner display in that size class takes the “iPad portrait” pad width (420pt) while setup and lists still use the phone path.

### 3. Sidebar API is dead; docs still specify it

`usesSideBySideBottomScoringRegion` and `usesIPadSideBySideScoringPad` **always return false**. Comments say pads span full width and dense sidebars are future work.

These still describe the old 3-player sidebar:

- [`docs/gameplay-layout-modes.md`](../gameplay-layout-modes.md)
- [`.cursor/rules/gameplay-layout-size-classes.mdc`](../../.cursor/rules/gameplay-layout-size-classes.mdc)

`usesIPadMainShell` always returns false and should be deleted with its call sites, not kept “for tests.”

### 4. Fixed pad widths do not fit a resizable window

| Token | Width | Risk |
|-------|-------|------|
| `regularWidthScoringPadWidth` | 420 | Overflows a ~700pt Duo column or a half-width iPad |
| `iPadLandscapeScoringPadWidth` | 300 | Same, once height is compact but width is only modestly regular |
| `landscapeScoringPadWidth` | 252 | Fine on phones; too rigid as the only compact-height pad |

### 5. List screens are phone columns with side margins

Play, Players, Activity, Modes, summary, and onboarding call `contentMaxWidth`. On a full iPad that is a centered 920pt column ([`ux-design-review.md`](../ux-design-review.md) D8). On Duo it is uncapped. Neither is “use the window.”

### 6. Out of scope (do not pull in)

- NavigationSplitView master-detail for Activity / Players (D8). Revisit only if a screen is still a sparse column after width bands land.
- Duo cover-only UI, pose / ReservedRegion APIs, multi-scene, App Store Duo badge.
- New modes, Training Partner, or 1.2 product surface.
- Changing analytics `interfaceOrientation` / `deviceClass` keys.

---

## Layout rules (replace the idiom rule)

Decide from **container width**, **vertical size class**, and **Dynamic Type**. Pass width in from the view (`GeometryReader` / `containerRelativeFrame` on the scene). Do not read `UIScreen.main.bounds`.

| Band | When | Shell |
|------|------|-------|
| **Compact** | Width under ~600pt, or accessibility Dynamic Type | Current phone stack. Full-width pad. Single-column setup and lists. |
| **Regular, short** | Compact vertical size class and width can hold a pad plus a readable column (~240 + ~320) | Landscape match: active band on top; pad column width = `clamp(width × 0.38, 220…300)`. If the remainder is under ~320pt, stack the pad full width (today’s phone landscape fallback). |
| **Regular, tall** | Regular vertical size class and width ≥ ~700pt | Setup two-pane. Match pad column = `clamp(width × 0.34, 260…420)` beside the scoreboard **only when** the scoreboard keeps ≥ ~320pt. Otherwise full-width pad under the scoreboard (current shipped behavior). |
| **Readable column** | Regular width, non-match screens | `min(max(width × 0.94, 680), 1020)` — same idea as Puzzle Buddy `AdaptiveLayout.contentMaxWidth`. Drop the `isPad` requirement. |

Player count stays a **content** input (pin the active X01 card at 3+), not a device input. Do not turn the sidebar back on solely because `playerCount >= 3` on an iPad.

Accessibility layouts (AX1–AX5) keep winning over every wide-band choice.

---

## Screens to reconsider

Work top-down. Each screen gets one predicate and one width function. Views should not branch on idiom.

| Screen | Current | Target |
|--------|---------|--------|
| **Match shell** (`MatchScoringBody`, `SideBySideMatchBody`, X01 / Cricket / party match screens) | Idiom + fixed pad widths; sidebar helpers hardcoded off | Width-band pad. One code path for Duo, iPad, and phone. |
| **Play setup** | Two-pane only if `isPad` | Two-pane on regular-tall band. Single column on compact and AX. |
| **Match summary** | Landscape split is phone-idiom only; grid already uses regular width | Short-height summary follows the short band, not idiom. |
| **Players, Activity, Modes, Settings** | 920pt if pad, else full bleed | Shared readable-column modifier. |
| **Onboarding** | `usesIPadMainShell()` (always false) plus pad max width | Same readable column. Delete the dead shell flag. |

Party match screens that only set `matchContentMaxWidth` (already `.infinity`) stay on `MatchScoringBody`. Do not add per-mode layout forks.

---

## Phases

### 0 — Baseline matrix

Record size class + container width (do not trust idiom) on:

- iPhone 17 portrait and landscape
- iPhone 17 Pro Max landscape (regular × compact — must stay a phone stack)
- iPhone Duo simulator: outer, inner, fold/unfold mid-match and mid-setup
- iPad 13" portrait, landscape, 1/2 Split View, Stage Manager window about phone width

Capture one X01 match (2 players and 4) and Play setup per row. This is the before picture; no product change yet.

### 1 — Predicates

- Add container-width parameters to `GameplayLayout`. Default width only in tests.
- Stop calling `UIDevice` from layout helpers.
- Delete `usesIPadMainShell` and the always-false sidebar predicates **or** redefine sidebar as “remainder width ≥ 320” (preferred: redefine, one function, no idiom).
- Rewrite `GameplayLayoutTests` around bands: Pro Max landscape `(regular, compact, width: ~440–500)` stays stacked; Duo / iPad `(regular, regular, width: ≥ 700)` can go two-pane; narrow iPad `(compact, regular, width: ~400)` stays stacked.

### 2 — Match + setup

- `MatchScoringBody` sizes the pad from the band, not `regularWidthScoringPadWidth` constants.
- Setup two-pane uses the tall regular band.
- Fold/unfold and Split View resize must not clip the pad or the start button. No new sheets.

### 3 — Columns + docs

- Readable width on tab roots, summary, onboarding.
- Rewrite [`gameplay-layout-modes.md`](../gameplay-layout-modes.md) and [`.cursor/rules/gameplay-layout-size-classes.mdc`](../../.cursor/rules/gameplay-layout-size-classes.mdc) so they match the code.
- Note D8: master-detail stays deferred; this release only stops letterboxing and overflow.

### 4 — Ship bar

- Unit tests for every band above, including the Pro Max false-friend case.
- Simulator smoke: Duo inner match + setup; iPad half-width match (pad not wider than the window); Pro Max landscape regression.
- Rotation or a phone-width resize does not drop the in-progress visit. Score targets stay thumb-sized ([`solo-companion.md`](../../roadmap/solo-companion.md)).
- No Connect Duo screenshots or badge in this version.
- Release notes: layout on iPhone Duo and iPad multitasking. No new modes.

---

## Open decision

If 1.2 RC slips and Duo inner display clips a live match, cherry-pick **Phase 1–2 for X01 + Cricket + setup only** onto `release/1.2.0`. Do not start Modes Catalog in that cherry-pick.
