# Lean 1.0 — Implementation Plan

Actionable plan to ship **Dart Buddy 1.0 Core Scorekeeper** with owner decisions locked.

**Status:** Approved scope · **Not yet implemented**  
**Target version:** `1.0.0`  
**Companion:** [`ongoing-release-plan.md`](ongoing-release-plan.md) · [`feature-inventory.md`](../feature-inventory.md) · [`todo.md`](todo.md)

---

## Locked decisions

| # | Decision | Choice |
|---|----------|--------|
| 1 | Release shape | **Lean 1.0** — hide untested surface; keep engines in repo |
| 2 | Locales | **English only** in app bundle + App Store listing |
| 3 | Telemetry | **Firebase Analytics + Crashlytics on** in Release (existing allowlist) |

---

## 1.0 product surface (what users see)

### In

| Area | Detail |
|------|--------|
| **Modes** | X01 (301/501) · Cricket Normal · Cricket Cut Throat |
| **Tabs** | Play · Players · Activity · Settings (**4 tabs**) |
| **Bots** | Preset difficulty only (Very Easy → Pro) |
| **Players** | CRUD, archive, delete, avatars |
| **Activity** | History + Statistics (merged segment picker) |
| **Settings** | Appearance, defaults, haptics, sound, bot pacing, reset, replay onboarding |
| **Rules** | Learn to play for X01 + Cricket only |
| **Locale** | English UI only |
| **Telemetry** | Analytics + Crashlytics (Release, real plist) |

### Hidden (code stays; re-enabled in 1.1+)

| Area | Re-enable in |
|------|--------------|
| Modes tab + 29-mode catalog | 1.3 |
| Party modes (Baseball, Killer, Shanghai) | 1.1 |
| Training Partner bots | 1.2 |
| Custom bots | 1.2 |
| Player export (DBPE) | 1.2 or backlog |
| App Intents / Siri | 1.4 (flag stays off) |
| de / es / nl bundled strings | 1.2+ (files stay in repo) |
| Turn-total TTS caller toggle | Visible but **default off** (already default) |

### Unchanged (no work)

- Deep link parser + router (not advertised; low exposure)
- App Store update prompt
- SwiftData SchemaV2 + migration path
- Buy Developer a Coffee link (owner can remove separately)

---

## Architecture: single gate

Add one file so 1.0 scope is not scattered across `#if` blocks.

### New file: `Support/Release/ProductSurface.swift`

```swift
/// Controls which product areas are reachable in this build.
/// Flip flags when promoting 1.1, 1.2, etc. See docs/release/lean-1.0-implementation-plan.md.
enum ProductSurface {
    /// Full catalog tab (Modes). Off for lean 1.0.
    static var showsModesTab: Bool { resolved(\.showsModesTab) }
    static var showsPartyModes: Bool { resolved(\.showsPartyModes) }
    static var showsTrainingBots: Bool { resolved(\.showsTrainingBots) }
    static var showsCustomBots: Bool { resolved(\.showsCustomBots) }
    static var showsPlayerExport: Bool { resolved(\.showsPlayerExport) }
    /// Bundled localizations. Lean 1.0: en only.
    static var bundledLocaleCodes: [String] { resolvedLocales() }

    // MARK: - 1.0 defaults (change per release slice)
    private static let lean1_0 = Configuration(
        showsModesTab: false,
        showsPartyModes: false,
        showsTrainingBots: false,
        showsCustomBots: false,
        showsPlayerExport: false,
        bundledLocaleCodes: ["en"]
    )

    /// Launch arg `-enable_full_product_surface` restores full UI for UI tests / dogfood.
    private static func resolved(_ keyPath: KeyPath<Configuration, Bool>) -> Bool {
        if ProcessInfo.processInfo.arguments.contains("-enable_full_product_surface") {
            return Configuration.full[keyPath: keyPath]
        }
        return lean1_0[keyPath: keyPath]
    }
}
```

**Why launch arg:** CI UI tests for Modes, party modes, Training Partner, and localized smoke tests keep passing without shipping hidden UI to App Store.

Document the arg in `specs/FeatureFlagConfigSpec.md` § Launch arguments.

---

## Implementation phases

### Phase 0 — Prep (½ day)

| Task | Owner | Done |
|------|-------|------|
| Create this plan + link from release README | — | [x] |
| Create tracking branch `release/lean-1.0` from `master` | Eng | [ ] |
| Record baseline: `xcodegen generate && xcodebuild test -scheme DartBuddyCI` green | Eng | [ ] |

---

### Phase 1 — ProductSurface + tab shell (1 day)

**Goal:** 4-tab app; no path to Modes catalog.

| # | Change | File(s) |
|---|--------|---------|
| 1.1 | Add `ProductSurface.swift` + unit tests | `Support/Release/`, `Tests/Unit/ProductSurfaceTests.swift` |
| 1.2 | Hide Modes tab when `!ProductSurface.showsModesTab` | `App/MainTabView.swift` |
| 1.3 | Remove **Change mode** button when Modes tab hidden; user picks X01/Cricket via setup chips + Settings default | `Features/Play/Setup/SetupHomeView.swift` |
| 1.4 | Guard deep-link / intent routes to `.modes` → fallback Play | `Support/DeepLinks/`, `Intents/Routing/IntentRoutingBridge.swift` |
| 1.5 | Block `applyPendingModeSelection` for party / unavailable catalog entries | `MatchSetupViewModel.swift` |
| 1.6 | Demote shipped party rows in catalog to `.planned` **or** gate `GameModeCatalog.available` via `ProductSurface` | `Features/Modes/GameModeCatalog.swift` |

**Acceptance**

- [ ] Release build: 4 tabs only; no Modes tab item
- [ ] Play setup shows X01/Cricket only; no Change mode → Modes navigation
- [ ] `dartbuddy://v1/tabs/modes` lands on Play (or Activity) without crash

---

### Phase 2 — Hide party + advanced bots (1 day)

**Goal:** Only preset bots in setup and player flows.

| # | Change | File(s) |
|---|--------|---------|
| 2.1 | Force `setupCategory = .standard`; ignore party pending selections | `MatchSetupViewModel.swift` |
| 2.2 | Hide Training Partner + Custom bot menu items when flags off | `Features/Play/Setup/SetupHomeView.swift` |
| 2.3 | Hide Training Partner section + export on Player Detail | `Features/Players/PlayerDetailView.swift` |
| 2.4 | Filter preset-only in Add Bot menu | `SetupHomeView.swift` / roster helpers |
| 2.5 | Restrict `GameRulesCatalog.supportedMatchTypes` to `.x01`, `.cricket` when party off | `Features/Play/Rules/GameRulesCatalog.swift` |
| 2.6 | Activity/Statistics mode filters: only show X01 + Cricket (or hide filter chips for unavailable types) | `Features/Activity/`, `Features/Statistics/` |

**Acceptance**

- [ ] Cannot start Baseball/Killer/Shanghai from any UI path
- [ ] Add Bot lists preset tiers only
- [ ] Player detail: no Export, no Create Training Partner
- [ ] Rules sheet: X01 + Cricket only

**Note:** Existing local data from TestFlight dogfood with party matches is OK — history can show old rows; filters should not offer starting new party games.

---

### Phase 3 — English-only bundle (½ day)

**Goal:** App Store + runtime English only; translation files remain for future releases.

| # | Change | File(s) |
|---|--------|---------|
| 3.1 | Bundle **only** `Resources/en.lproj/Localizable.strings` in `project.yml` | `project.yml` |
| 3.2 | Set `options: developmentLanguage: en` (XcodeGen) | `project.yml` |
| 3.3 | Add comment block in `project.yml` pointing here — re-add de/es/nl paths for 1.2 | `project.yml` |
| 3.4 | Keep `Resources/de|es|nl.lproj/` in repo; keep `LocalizationParityTests` in CI | no deletion |
| 3.5 | App Store Connect: **English (U.S.)** primary; no localized metadata for 1.0 | manual |
| 3.6 | Marketing screenshots: English device language only | `marketing-screenshots/` |

**Acceptance**

- [ ] Release archive: only `en.lproj` in bundle (verify `.app` contents)
- [ ] Device set to German still shows English (no de strings in bundle)
- [ ] CI parity tests still pass (test bundle / file system, not app bundle)

---

### Phase 4 — Telemetry confirm (¼ day)

**Goal:** No code change expected — verify config matches decision #3.

| # | Check | Expected |
|---|-------|----------|
| 4.1 | `enableFirebaseAnalytics` default Release | `true` (real plist) |
| 4.2 | `enableFirebaseCrashlytics` default Release | `true` |
| 4.3 | Privacy policy + App Store labels mention Analytics + Crashlytics | Match [`SecurityPrivacySpec.md`](../../specs/SecurityPrivacySpec.md) |
| 4.4 | UI tests / Debug use `-disable_firebase_analytics` | unchanged |

---

### Phase 5 — Tests & CI (1 day)

| # | Task |
|---|------|
| 5.1 | Add `ProductSurfaceTests` — defaults, launch-arg override |
| 5.2 | Add lean-1.0 UI smoke: `Lean1_0SmokeUITests` — 4 tabs, X01 + Cricket + Cut Throat start |
| 5.3 | Gate existing broad tests: prepend `-enable_full_product_surface` in tests that need Modes/party/training/localized UI |
| 5.4 | Files likely needing launch arg (audit): |
| | `ModesAndActivityUITests.swift` |
| | `WCAGAccessibilityUITests.swift` (Baseball/Shanghai cases) |
| | `PlayerDetailUITests.swift` (export, training partner) |
| | `MatchSetupUITests.swift` (training partner) |
| | `*LocalizationSmokeUITests.swift` (keep running against full surface **or** skip until 1.2 — **recommend skip in DartBuddyCI**, run nightly on `enable_full_product_surface` branch) |
| 5.5 | `DartBuddyCI` stays green on lean defaults |
| 5.6 | Nightly `DartBuddy` scheme: run full-surface suite with launch arg |

**Acceptance**

- [ ] `DartBuddyCI` green without launch arg
- [ ] Nightly full-surface green with `-enable_full_product_surface`

---

### Phase 6 — Docs & store copy (1 day)

| # | Document | Updates |
|---|----------|---------|
| 6.1 | [`README.md`](../../README.md) | 4 tabs; X01 + Cricket; English only; lean scope |
| 6.2 | [`feature-inventory.md`](../feature-inventory.md) | Mark hidden items **Partial (lean 1.0)** |
| 6.3 | [`ongoing-release-plan.md`](ongoing-release-plan.md) | Fill decision log |
| 6.4 | [`release_checklist.md`](release_checklist.md) | **Rewrite §1–§2:** Play · Players · Activity · Settings; add Cut Throat row; remove party mode steps |
| 6.5 | [`todo.md`](todo.md) | Scope Sprint D/E to lean matrix only |
| 6.6 | [`specs/AppStoreConnectSpec.md`](../../specs/AppStoreConnectSpec.md) | Subtitle/keywords: X01 & Cricket; no party mode claims |
| 6.7 | App Store description | No mention of Baseball, Modes catalog, Training Partner, localization |
| 6.8 | [`specs/LocalizationSpec.md`](../../specs/LocalizationSpec.md) | Note: de/es/nl shipped in repo but **not bundled until post-1.0** |

---

### Phase 7 — Device QA & submit (Sprint D + E from todo)

Run **only** the lean matrix before submit.

#### Lean 1.0 device matrix

| # | Flow | Pass |
|---|------|------|
| 1 | Cold launch → onboarding → land Play | [ ] |
| 2 | X01: setup → match → undo → summary → history detail | [ ] |
| 3 | Cricket Normal: full match | [ ] |
| 4 | Cricket Cut Throat: start + bot throws + summary | [ ] |
| 5 | Resume active match | [ ] |
| 6 | Players: create, archive, delete guard | [ ] |
| 7 | Preset bot in X01 + Cricket | [ ] |
| 8 | Activity: History segment + Statistics segment + filters | [ ] |
| 9 | Settings: toggle sound → relaunch persisted; reset all data | [ ] |
| 10 | AXXXL spot check: setup + X01 in-match | [ ] |
| 11 | Migration recovery smoke (if feasible) | [ ] |
| 12 | Release archive: Firebase + dSYM upload | [ ] |
| 13 | Confirm **no** Modes tab, party setup, export, training partner | [ ] |
| 14 | Device language de/fr/es → UI still English | [ ] |

**Exit:** [`QA-Signoff-RC1.md`](../../roadmap/release/QA-Signoff-RC1.md) **Go** · App Store submitted as `1.0.0`

---

## Roll-forward cheat sheet

When promoting features, flip `ProductSurface.lean1_0` → add `v1_1`, etc., or replace defaults:

| Release | Flip flags | Also |
|---------|------------|------|
| **1.1 Party Pack** | `showsPartyModes = true` | Device matrix + UI smoke for 3 party modes; party screenshots |
| **1.2 Smart Opponents** | `showsTrainingBots`, `showsCustomBots`, `showsPlayerExport` | Re-bundle de/es/nl optional |
| **1.3 Modes Catalog** | `showsModesTab = true` | Full catalog UI; 8 playable |
| **1.4 Shortcuts** | `enableAppIntents` default on | App Intents QA matrix |

---

## Risk register

| Risk | Mitigation |
|------|------------|
| UI tests break on lean defaults | `-enable_full_product_surface` + nightly full suite |
| Dogfood users lose party mode access | TestFlight release notes; data retained in history |
| Deep link to hidden tab | Router fallback to Play |
| Forgetting to update App Store copy | Phase 6 checklist |
| Localization parity drift while unbundled | Keep parity tests in CI against repo files |
| Statistics filters show ghost party modes | Phase 2.6 filter restriction |

---

## Effort estimate

| Phase | Days |
|-------|------|
| 0 Prep | 0.5 |
| 1 Tab shell | 1 |
| 2 Hide features | 1 |
| 3 English bundle | 0.5 |
| 4 Telemetry | 0.25 |
| 5 Tests/CI | 1 |
| 6 Docs/store | 1 |
| 7 Device QA | 2–3 |
| **Total engineering** | **~5–6 days** before App Store ops |

---

## Task checklist (copy to PR / issue)

```
Lean 1.0 implementation
- [ ] ProductSurface.swift + tests
- [ ] MainTabView: 4 tabs
- [ ] SetupHomeView: no Change mode / party / training / custom bots
- [ ] PlayerDetailView: hide export + training partner
- [ ] GameRulesCatalog: X01 + Cricket only
- [ ] Activity/Statistics filters scoped
- [ ] Deep link / intent guards
- [ ] project.yml: en-only bundle
- [ ] CI: lean default + nightly full surface
- [ ] release_checklist.md rewritten
- [ ] README + inventory + App Store copy
- [ ] Device QA matrix (lean)
- [ ] TestFlight → App Store 1.0.0
```

---

## Decision log

| Date | Decision | By |
|------|----------|-----|
| 2026-06-06 | Lean 1.0 scope | Owner |
| 2026-06-06 | English only | Owner |
| 2026-06-06 | Keep Analytics + Crashlytics | Owner |
| | Implementation start date | |
| | RC build number tagged | |
| | App Store submit date | |
