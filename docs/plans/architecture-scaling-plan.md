# Architecture & Scaling Plan

**Drafted:** 2026-06-14
**Audience:** Senior iOS engineer executing locally with Xcode
**Status:** Proposal — sequencing and acceptance criteria below

This plan turns the scaling concerns surfaced in the architecture audit into ordered, executable work. Every item lists the target files, a concrete refactor shape, the test guardrails that must exist **before** the change lands, and an estimated diff size. Items are grouped into tiers by risk class: do the lower tiers first, because they establish the safety nets the higher tiers depend on.

The architecture is fundamentally sound — Clean Architecture / MVVM with SwiftData, no singletons, strong actor/`Sendable` discipline, ~194 test files, 100% SwiftUI. This plan is about scaling the codebase past 1.0 without the existing pain points (feature multiplicity, monolithic files, no module enforcement) compounding.

---

## 0. Quality gates (do this first)

Land these before any of the larger refactors. They turn risky changes into safe changes by making regressions loud at PR time.

### 0.1 Round-trip Codable test for `MatchEventPayload`

**Why:** `MatchEventPayload` (Domain/Services/MatchLifecycleService.swift:3) is the persisted JSON shape for every event in every historical match in users' SwiftData stores. Any refactor that drifts the encoding silently corrupts history. We currently have no fixture-based test that asserts the wire format byte-for-byte.

**What to add:** `Tests/Domain/MatchEventPayloadFixtureTests.swift`
- One golden JSON fixture per case (26 fixtures).
- Decode → re-encode → assert equal to fixture (canonicalized: sorted keys, stable date format).
- Construct a payload value → encode → assert equal to fixture.
- Run under Swift Testing; tag `@Suite("persistence-format")` so it's surfaced separately in CI.

**Estimate:** 1 day. ~300 lines of fixtures + 60 lines of test harness.

**Acceptance:** Renaming a single `CodingKey` in `MatchEventPayload` causes a red test in <2 s.

### 0.2 Lint rule: no cross-layer imports

**Why:** The project is a single XcodeGen target (project.yml). Features can technically `import` Persistence types directly with no compiler complaint. Today's discipline is convention only.

**What to add:** A SwiftLint custom rule, or a script invoked from `Scripts/` and the pre-commit hook (.githooks/pre-commit), that fails when:
- Anything under `Features/` references types defined in `Persistence/Schemas/`
- Anything under `Domain/` references SwiftUI

**Estimate:** ~2 hours. Pure script.

**Acceptance:** A test PR that adds `import SwiftData` in a Features file fails CI.

### 0.3 File-length budget

**Why:** 17 files >500 LOC today. The audit ranked the worst at 1456 lines. Without a soft cap, new code drifts further.

**What to add:** Extend `.swiftlint.yml`:
```yaml
file_length:
  warning: 500
  error: 800
type_body_length:
  warning: 400
  error: 600
function_body_length:
  warning: 60
  error: 100
```
Then run `swiftlint --strict` in CI. The existing oversized files will need to be in a temporary `excluded:` list — that list is the punch list for the rest of this plan.

**Estimate:** 1 hour to configure + tracking issue per excluded file.

### 0.4 Snapshot of current architecture metrics

**Why:** Refactors should *visibly* move metrics. Capture today's baseline.

**What to add:** `Scripts/ArchitectureSnapshot/snapshot.swift` that prints:
- Lines per top-level directory (App, Domain, Data, Features, Persistence, DesignSystem)
- Files >500 LOC, ranked
- `@Published` property count per ViewModel
- `@MainActor` / `actor` / `@Observable` / `ObservableObject` usage counts

Commit baseline output to `docs/metrics/2026-06-baseline.txt`. Re-run after each tier.

**Estimate:** Half a day. Pure tooling.

---

## Tier 1 — Persistence-critical refactors

### 1.1 Split `MatchEventPayload` into per-mode coders

**Target:** `Domain/Services/MatchLifecycleService.swift:3-232` (the `MatchEventPayload` enum and its hand-rolled `Codable`).

**Problem:** 26 cases × 3 places (case decl, `CodingKeys`, `Kind`, `init(from:)`, `encode(to:)`) = ~230 lines of mechanical switch-on-kind. Adding a new mode means touching 5 spots in one file; missing one is a silent serialization bug.

**Proposed shape:**
```swift
public protocol MatchEventBody: Codable, Equatable, Sendable {
    static var kind: MatchEventKind { get }
}

public enum MatchEventKind: String, Codable, CaseIterable, Sendable {
    case x01Turn, cricketTurn, baseballTurn, killerPick, killerTurn, ...
}

public enum MatchEventPayload: Codable, Equatable, Sendable {
    case x01Turn(X01TurnEvent)
    // ... unchanged cases ...

    private enum CodingKeys: String, CodingKey { case kind, body }

    public init(from decoder: any Decoder) throws { /* dispatch via registry */ }
    public func encode(to encoder: any Encoder) throws { /* dispatch via registry */ }
}
```

**Wire format change:** Old format is `{"kind": "x01Turn", "x01": {...}}` — 26 distinct keys, one per case. New format would be `{"kind": "x01Turn", "body": {...}}` — single discriminator + single body key.

**This is a breaking change to persisted data.** Two paths:

**1.1a — Keep the old format, just simplify the dispatch internally.** Lower risk. Build a `[Kind: (decoder/encoder closures)]` table and replace the giant switches with table lookups. Wire format unchanged. Cuts ~150 lines.

**1.1b — Migrate to the cleaner `{kind, body}` format.** Requires a migration: when reading old envelopes, accept *either* shape (look for `body` key first, fall back to the per-mode key). Run for one release, then drop the legacy branch. Cleaner long-term.

**Recommendation:** Do **1.1a** in this tier. Defer 1.1b to a future cleanup release with a deprecation window. The win is 90% the same and the risk is dramatically lower.

**Test guardrails:** 0.1 (round-trip fixtures) MUST be in place. After the refactor, all 26 fixtures must pass unchanged.

**Diff estimate:** ~150 lines deleted, ~80 added. Single file.

**Acceptance:** 0.1's fixture tests pass. SwiftData round-trip integration test (read a v1 match, replay events, write a snapshot, read back, assert equal) passes.

### 1.2 Extract `MatchRuntimeState` projection helpers

**Target:** `Domain/Services/MatchLifecycleService.swift:248-284` — `MatchRuntimeState` has 22 optional per-mode state fields (`x01State`, `cricketState`, …, `raidState`).

**Problem:** Anywhere downstream that needs "the state for the current mode" has to switch over `MatchType` and reach into the right optional. This logic is duplicated.

**Proposed shape:** Add an extension that exposes a single `currentModeState` projection and a generic update helper:
```swift
extension MatchRuntimeState {
    func modeState<S>(_ kp: KeyPath<Self, S?>) -> S? { self[keyPath: kp] }
    mutating func setModeState<S>(_ kp: WritableKeyPath<Self, S?>, _ value: S) { self[keyPath: kp] = value }
}
```
Plus a `MatchType` → `WritableKeyPath` table so call sites don't switch.

**Risk:** Low — pure additive helper. Migrate one call site at a time.

**Diff estimate:** ~40 lines added in MatchLifecycleService.swift, ~5-10 lines deleted per migrated call site.

### 1.3 Extract `MatchLifecycleService` logic into mode-scoped namespaces

**Target:** `Domain/Services/MatchLifecycleService.swift:298-1456` — the service body.

**Problem:** One enum with ~50 static methods covering all 26 modes. Hard to find anything; adding a mode means scrolling.

**Proposed shape:** Per-mode submodules:
```
Domain/Services/MatchLifecycle/
    MatchLifecycleService.swift           (core: create, finish, undo, snapshot scheduling)
    X01Lifecycle.swift                    (applyX01Turn, undoX01Turn, etc.)
    CricketLifecycle.swift
    ... (one per mode)
```

Each submodule is an `extension MatchLifecycleService { ... }` so the public surface is unchanged.

**Risk:** Low — pure file split, no semantics change. Each file compiles independently.

**Diff estimate:** 1456-line file becomes ~300 + 26 files of ~40 lines each. No net new code.

**Acceptance:** All existing tests pass unchanged. No public API change.

---

## Tier 2 — `MatchSetupViewModel` decomposition

**Target:** `Features/Play/Setup/MatchSetupViewModel.swift` (937 lines, 60+ `@Published` properties).

**Problem:** Single ViewModel owns the setup state for all 26 modes simultaneously. Every change to one mode's setup triggers SwiftUI invalidation across views that consume any other mode's state. Cognitive cost of adding a new mode is huge.

### 2.1 Inventory + audit (preparation, no refactor yet)

Generate a table: each `@Published` property → which views read it → which modes it applies to. Capture in `docs/plans/setup-vm-property-map.md`. Without this, the decomposition is guesswork.

**Estimate:** Half a day.

### 2.2 Introduce per-mode setup state structs

Each mode that has unique setup options (X01 leg/set count, Cricket rules, Killer player count, etc.) gets:
```swift
struct X01SetupState: Equatable {
    var startingScore: X01StartingScore = .threeOhOne
    var legs: Int = 1
    var sets: Int = 1
    var doubleIn: Bool = false
    var doubleOut: Bool = true
}
```

**Risk:** Low if done as *additive* — the new structs sit alongside the existing `@Published` props initially. The parent VM publishes `var x01: X01SetupState` instead of 5 individual props. Migrate one mode at a time.

### 2.3 Move setup state into per-mode child ViewModels owned by per-mode setup views

Endgame: `MatchSetupViewModel` only owns shared state (player roster, selected mode). When the user picks X01, the X01-specific setup view is initialized with its own `X01SetupViewModel` (or just a `@State` `X01SetupState` if no async logic is needed).

**Risk:** Medium — requires the property map from 2.1 to be accurate. Test via existing UI tests (the setup-flow tests in `Tests/UITests/`).

**Diff estimate:** -500 lines from `MatchSetupViewModel.swift`, +400 across 26 small mode-specific files. Net win: smaller surface, faster SwiftUI invalidation.

**Acceptance:** Every setup UI test still passes. Snapshot tests of the setup screens show no visual diff.

### 2.4 Stretch: build the "Start Match" command as a value

Today the VM exposes a `startMatch()` method that's a closure over its entire state. Cleaner: `MatchSetupViewModel` produces a `MatchStartCommand` value (mode + config + participants), and a separate `MatchStartCoordinator` consumes it. Decouples setup from match creation; lets us write the coordinator tests without booting a setup view.

---

## Tier 3 — Concurrency modernization

### 3.1 Migrate ViewModels to `@Observable`

**Targets:** All `ObservableObject`-conforming VMs in `Features/Play/*/`, `Features/Activity/`, `Features/Players/`, `Features/Settings/`. Roughly 35 files.

**Why:** `@Observable` (iOS 17) does property-level invalidation tracking, not class-level. Saves SwiftUI from re-running view bodies that don't actually depend on the changed property. For a game in progress (state changes 3 times per visit × hundreds of visits), this is a measurable win.

**Mechanical change:**
```swift
@MainActor
final class X01MatchViewModel: ObservableObject {
    @Published var state: X01State
}
```
becomes
```swift
@MainActor @Observable
final class X01MatchViewModel {
    var state: X01State
}
```
View consumers change from `@ObservedObject var vm: X01MatchViewModel` to `var vm: X01MatchViewModel` (with `let` if not assigned), or `@Bindable var vm: ...` if they need bindings.

**Risk:** Medium. The migration is mechanical but every view consuming a VM needs the consumer side updated. Plan to migrate **one feature at a time**, not all 35 in one PR.

**Order:**
1. `Features/Activity/` (lowest cross-coupling — HistoryListViewModel, StatisticsViewModel)
2. `Features/Players/`
3. `Features/Settings/`
4. `Features/Play/` per-mode (last — biggest surface, validate on `X01` first as a pattern).

**Acceptance:** Per feature: existing tests pass; manual smoke + instruments trace shows fewer view body invocations.

### 3.2 Audit `Task { }` lifetimes

Run a grep for fire-and-forget `Task {`. The audit didn't find leaks, but the recent ActivityRootView edits (`filterTask`, `loadMoreTask`, `statsLoadTask`) are state-managed cancellable tasks — that's the right pattern. Codify it:
- Lint rule: bare `Task { ... }` inside a `View` body is a warning; should be either `.task { }` (lifecycle-bound) or assigned to a stored cancellable.

### 3.3 Strict-concurrency build target

Add a build setting `SWIFT_STRICT_CONCURRENCY = complete` to a *secondary* scheme (not the main one). Treat warnings as a backlog. Fix them feature-by-feature.

**Estimate:** Pure scheme config (15 min). The backlog of warnings is the actual work.

---

## Tier 4 — Modularization (SPM packages)

**Why:** One XcodeGen target = no enforced layer boundaries (item 0.2 helps but is convention). SPM packages turn convention into compile-time. Also: faster incremental builds, faster tests, ability to develop features in isolation.

### 4.1 Extract `DesignSystem` as a Swift package

**Easiest win, do first.** `DesignSystem/` has 32 components, no dependencies on Domain or Persistence. Move it under `Packages/DesignSystem/`, define `Package.swift` with no targets that depend on app code, expose `Brand`, `DS`, components as public API.

**Acceptance:** App still builds. `Tests/DesignSystemTests` (if any) move into the package.

**Estimate:** 1 day. Mostly mechanical — move files, add `public` to types, add `Package.swift`.

### 4.2 Extract `Domain` as a package

Larger but the highest architectural payoff. Domain has no SwiftUI imports today (per audit) and depends only on Foundation + a logger protocol. Once extracted:
- Features must `import Domain` to reach engines, services, value types.
- Persistence must `import Domain` to know what to persist.
- Compiler enforces the dependency direction. No more "Features importing Persistence" worry.

**Watch out for:** `MatchEventPayload`'s Codable types. They're Domain values but the persistence layer encodes/decodes them. Keep encoding in Domain (it's a value-level concern), keep the *storage* (SwiftData `@Model`) in Persistence.

**Estimate:** 3-4 days.

### 4.3 Extract `Persistence` as a package

After 4.2. Depends on `Domain`. Exposes only repository protocols + a factory; SwiftData `@Model` types stay internal.

**Estimate:** 2-3 days.

### 4.4 Per-feature packages (optional, post-1.x)

Each `Features/<Name>/` becomes a package depending on `Domain`, `DesignSystem`. Most aggressive option. Only worth it if the team grows or if module compile times become a bottleneck. Document the option; don't do it yet.

---

## Tier 5 — Engine refactors

### 5.1 `FleetEngine.swift` (876 lines) and `DartBotEngine.swift` (790 lines)

**Problem:** Each is a single type holding both **state mutation** and **decision logic**. Hard to unit-test the decision logic in isolation.

**Proposed shape (Fleet):**
- `FleetEngine` — orchestrator, owns `FleetState`, exposes `apply(event:)`.
- `FleetPlacementResolver` — pure functions: given a board + candidate placement, return validity.
- `FleetSonarStrategy` — pure functions for sonar reveal math.
- `FleetDartScoring` — pure functions for dart→hit resolution.

Likewise for `DartBotEngine`:
- `DartBotEngine` — orchestrator that selects a strategy per game mode.
- `DartBotAimingModel` — accuracy distribution math.
- Per-mode strategy objects (`X01BotStrategy`, `CricketBotStrategy`, …) implementing a single `BotStrategy` protocol with `nextDart(state:) -> DartIntent`.

**Risk:** Medium. The bot engine is exercised by extensive existing tests (`DartBotIntegrationTests:1213 lines`, `LongTermSimulationTests:571 lines`). Run them after every extraction.

**Diff estimate:** Each engine goes from 1 file × 800-900 lines → 4-6 files × 100-200 lines each. Net code roughly equal; testability vastly improved.

**Acceptance:** All bot integration tests pass with identical results. Long-term simulation results (win rates per skill level) remain within 1% of baseline.

### 5.2 Extract decision logic into pure functions

While doing 5.1, identify any decision logic that doesn't actually need the engine's state and pull it out as a top-level pure function. These become trivially unit-testable and reusable.

---

## Tier 6 — View hygiene

Lower priority than the architectural work, but cumulatively meaningful.

### 6.1 `MatchSummaryScreen.swift` (571 lines)
Extract per-section subviews (header, per-player breakdown, achievements row, share sheet trigger) as private structs. Pure mechanical — same risk profile as the `PlayMatchRouteView` refactor already shipped.
**Estimate:** Half a day.

### 6.2 `CustomBotViews.swift` (496 lines)
Multiple unrelated bot-configuration views in one file. Split per view.
**Estimate:** 2 hours.

### 6.3 `ActivityRootView.swift` (511 lines)
Re-evaluated during this session: not as bad as the line count suggests (143 lines are an already-separated `StatisticsTablesContent`, 16 are an enum; the actual root view body is 78 lines). **Leave it for now** unless future work makes the parent thinner.

### 6.4 `PlayMatchRouteView.swift`
**Done** (this session, commit `662697d`). Down from 609 to 371 lines. Generic `MatchRouteHost<VM, Content>` replaces 17 boilerplate wrapper structs.

---

## Tier 7 — Test coverage strengthening

Test coverage is already strong (35K+ lines, 194 files, Swift Testing, dedicated accessibility + localization suites). Gaps to close:

### 7.1 Persistence schema migration smoke
For each old `SchemaV*` baseline, keep a serialized fixture store and assert it loads cleanly under the current model graph. Today schemas are versioned but migration outcomes aren't fixture-asserted.

### 7.2 Performance regression budget
For the gameplay loop's hot path (dart entry → state update → SwiftUI invalidation), add an XCTest performance test with a fixed iteration count. Catch the @Observable migration's win, and any future regression.

### 7.3 Memory growth test for long matches
Long sets/legs sessions retain a growing `events: [MatchEventEnvelope]` array. Add a test that runs 500 visits and asserts the snapshot mechanism is actually reducing memory pressure as intended.

---

## Sequencing summary

| Order | Item | Tier | Risk | Effort |
|------|------|------|------|--------|
| 1 | Round-trip fixture tests for `MatchEventPayload` | 0.1 | Low | 1 day |
| 2 | Cross-layer import lint | 0.2 | Low | 2 hr |
| 3 | File-length budget in SwiftLint | 0.3 | Low | 1 hr |
| 4 | Architecture metrics snapshot tool | 0.4 | Low | 0.5 day |
| 5 | `MatchEventPayload` table-driven dispatch (1.1a) | 1 | Med | 1 day |
| 6 | `MatchLifecycleService` per-mode file split | 1.3 | Low | 1 day |
| 7 | `MatchRuntimeState` projection helpers | 1.2 | Low | 0.5 day |
| 8 | `DesignSystem` → SPM package | 4.1 | Low | 1 day |
| 9 | `MatchSetupViewModel` property map | 2.1 | Low | 0.5 day |
| 10 | Engine extractions (Fleet, DartBot) | 5.1 | Med | 3-4 days |
| 11 | View hygiene (Summary, CustomBot) | 6.1, 6.2 | Low | 1 day |
| 12 | `@Observable` migration, feature by feature | 3.1 | Med | 1 week |
| 13 | `Domain` → SPM package | 4.2 | High | 3-4 days |
| 14 | `Persistence` → SPM package | 4.3 | High | 2-3 days |
| 15 | `MatchSetupViewModel` decomposition | 2.2-2.4 | Med-High | 1 week |
| 16 | Strict concurrency on secondary scheme | 3.3 | Low | ongoing |
| 17 | Performance + memory test additions | 7.2, 7.3 | Low | 1 day |

**Total estimated effort:** ~5-6 engineer-weeks if done seriously. The first four items (Tier 0) are gating: do not skip them.

---

## Risk register

| Risk | Likelihood | Mitigation |
|------|-----------|------------|
| `MatchEventPayload` wire-format drift corrupts user history | Medium without 0.1; near zero with it | Fixture tests in 0.1 + chosen 1.1a path keeps wire format identical |
| `@Observable` migration introduces unexpected SwiftUI re-render behavior | Medium | Migrate one feature at a time; instruments trace before/after; per-feature PR |
| SPM extraction breaks Xcode preview / debug builds | Medium | Extract `DesignSystem` first as a proving ground; document local-package setup in `CONTRIBUTING.md` |
| `MatchSetupViewModel` decomposition regresses setup UX | Medium | UI tests + snapshot tests must be green before each step; 2.1 inventory is non-skippable prep |
| Engine refactors change bot win-rate distributions | Low (logic is preserved) | Long-term simulation test budget (5.1 acceptance) |
| Strict concurrency reveals latent Sendable bugs | High (it's designed to) | Use secondary scheme; backlog warnings rather than blocking main |

---

## Out of scope (deliberately deferred)

- **TCA / Composable Architecture migration** — current MVVM is healthy; rewriting state management for its own sake is not justified.
- **Module-per-feature packages (4.4)** — premature at current team size.
- **Replacing SwiftData with GRDB / CoreData** — SwiftData's limitations haven't bitten this codebase yet. Revisit if migrations or schema evolution become painful.
- **UIKit interop layer** — no current need; SwiftUI-only is working.

---

## Definitions used

- **Persistence-critical:** A refactor whose failure mode is silent data loss or corruption of existing users' SwiftData stores.
- **Risk: Low:** Mechanical change, fully covered by existing tests, blast radius ≤ one file.
- **Risk: Medium:** Touches multiple files; relies on test guardrails added earlier in this plan.
- **Risk: High:** Cross-cutting (build system, module graph); requires staged rollout.

---

## Tracking

Each tier should land as its own PR (or PR series). Reference this plan in the PR description with the tier number, e.g., "Tier 1.1a — `MatchEventPayload` table-driven dispatch". Update the **Sequencing summary** table here as items ship.
