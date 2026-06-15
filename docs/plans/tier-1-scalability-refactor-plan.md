# Tier 1 Scalability Refactor Plan

**Status:** Phase 0 complete · Phase 1 in progress (coordinator + pilot handlers)  
**Created:** 2026-06-14  
**Updated:** 2026-06-15  
**Goal:** Reduce linear-growth hotspots so adding game mode #26 touches **4 new files** (setup config, lifecycle handler, thin VM, screen) instead of **4 central files**.

**Context:** Architecture review (2026-06-14) identified four Tier 1 refactors. This plan sequences them with a strangler pattern — one mode per PR where possible, no behavior changes, existing tests as gates.

**Related docs:** [`specs/ArchitectureSpec.md`](../../specs/ArchitectureSpec.md) · [`docs/ios-code-audit.md`](../ios-code-audit.md) · [`docs/plans/release-build-view-decomposition-plan.md`](release-build-view-decomposition-plan.md) (setup UI shell — done)

---

## Agent query (copy-paste)

Use this prompt to begin Tier 1 work in a fresh session:

```
Begin Tier 1 scalability refactor — Phase 0 (centralized test fakes) on Dart Buddy.

## Read first
- `docs/plans/tier-1-scalability-refactor-plan.md` (authoritative plan)
- `Tests/Unit/MatchSetupViewModelTests.swift` lines ~1129–1622 (canonical inline fakes to extract)
- `Tests/Unit/Support/` (existing fixtures: `MatchSummaryFixtures.swift`, `CricketTestHelpers.swift`)

## Your task — Phase 0 only
1. Create shared test support under `Tests/Unit/Support/`:
   - `FakeRepositories.swift` — configurable `FakePlayerRepository`, `FakeMatchRepository`, `FakeSettingsRepository`, `FakeStatsRepository`
   - `FakeRepositoryBuilders.swift` — specialized variants now duplicated across tests (`ActiveConflictMatchRepository`, `ParticipantCapturingMatchRepository`, `SnapshotOnlyActiveConflictRepository`, etc.) as builder methods or thin subclasses
   - `MatchTestFixtures.swift` — `makePlayer`, `makeSetupViewModel`, other helpers currently private in `MatchSetupViewModelTests`
2. Migrate `MatchSetupViewModelTests.swift` first (drop from ~1,622 lines to tests-only).
3. Migrate `PlayHomeViewModelTests.swift`, `AppRouteRouterTests.swift`, then 3–5 high-traffic VM test files.
4. Delete private fake definitions as each file migrates.

## Constraints
- **No behavior changes** — refactors only; same test assertions.
- **Do not start** Phase 1 (lifecycle plugins), Phase 2 (VM core), or Phase 3 (setup registry) in this session unless Phase 0 is fully complete and tests are green.
- **Do not commit** unless I ask. Run unit tests to verify.
- Follow existing Swift Testing style (`@Test`, `.tags(...)`).
- Specialized repository behaviors use configurable hooks/closures on shared fakes — avoid 8 near-duplicate `FakeMatchRepository` actors.

## Exit criteria (Phase 0)
- [ ] `MatchSetupViewModelTests.swift` under ~500 lines
- [ ] Zero `private actor FakeMatchRepository` outside `Tests/Unit/Support/`
- [ ] Unit test suite passes

## References
- Hotspots: `MatchSetupViewModel.swift` (~961 lines), `MatchLifecycleService.swift` (~1,456 lines), 22 `*MatchViewModel.swift` files
- `MatchTurnSubmitter` in `Features/Play/Shared/MatchTurnSupport.swift` — existing shared match plumbing
- `Support/State/*SetupPreferences.swift` — future Phase 3 inputs
```

---

## 1. Goals & success criteria

| Initiative | Today | Target | Done means |
|------------|-------|--------|------------|
| **4. Test fakes** | Fakes duplicated in 30+ test files; `MatchSetupViewModelTests` ~1,622 lines | Shared `Tests/Unit/Support/` fakes | New VM test needs zero new repository boilerplate |
| **2. Lifecycle plugins** | `MatchLifecycleService` ~1,456 lines, 20 `submit*Turn` + giant `applyEvent` | Thin coordinator + per-mode handlers | New mode = new handler file, not central switch edits |
| **3. Match VM core** | 22 VMs ~330–610 lines, ~70% identical scaffolding | ~80 lines mode-specific + shared core | New standard mode VM is mostly UI + engine call |
| **1. Setup registry** | `MatchSetupViewModel` ~961 lines, ~50 `@Published` fields | Coordinator + per-mode config types | New mode = new `*SetupConfiguration`, not VM field sprawl |

**North-star metric:** Adding mode #26 touches 4 new files instead of 4 central files.

---

## 2. Recommended order

```
Phase 0 ──► Phase 1 ──► Phase 2 ──► Phase 3
(fakes)     (lifecycle)  (VM core)    (setup)
```

| Phase | Initiative | Why this order |
|-------|------------|----------------|
| **0** | Test fakes | Low risk, high velocity; protects every subsequent refactor |
| **1** | Lifecycle plugins | Highest coupling hotspot; VMs and history depend on it |
| **2** | Match VM core | Builds on `MatchTurnSubmitter`; easier once lifecycle handlers exist |
| **3** | Setup registry | UI-heavy; overlaps Phase 2 but safest after 1.1 ship pressure eases |

**Ship gate (1.1):** Complete Phase 0 fully. Start Phase 1 with 2–3 pilot modes only. Defer Phases 2–3 bulk migration until post-TestFlight unless there is slack.

---

## 3. Phase 0 — Centralized test fakes (~2–3 days)

### Deliverables

```
Tests/Unit/Support/
├── FakeRepositories.swift
├── FakeRepositoryBuilders.swift
├── MatchTestFixtures.swift
└── (existing) MatchSummaryFixtures.swift, CricketTestHelpers.swift
```

### Design

- Configurable fakes via init parameters and optional closure hooks (`onAppendEvent`, `activeMatchSnapshot`, etc.).
- Specialized behaviors as builder methods: `FakeMatchRepository.activeConflict()`, `.capturingParticipants()`, etc.
- Keep existing test assertions unchanged — only swap imports/instantiation.

### Migration steps

1. Extract fakes from `MatchSetupViewModelTests.swift` (~lines 1129–1622) as canonical set.
2. Migrate `PlayHomeViewModelTests`, `AppRouteRouterTests`, then high-traffic VM tests.
3. Delete private fakes file-by-file; run full unit suite after each batch.

### Exit criteria

- [x] `MatchSetupViewModelTests` tests-only (inline fakes removed; ~1,126 lines — test volume, not boilerplate)
- [x] Zero `private actor FakeMatchRepository` outside `Tests/Unit/Support/` (specialized corrupt-snapshot / failing-undo fakes remain intentionally)
- [x] CI unit tests green

---

## 4. Phase 1 — Match lifecycle plugins (~2–3 weeks, incremental)

### Target architecture

```
Domain/Match/Lifecycle/
├── MatchLifecycleCoordinator.swift    # appendAndProject, replay, undo (shared)
├── MatchLifecycleHandler.swift        # protocol
├── Handlers/
│   ├── GolfMatchLifecycleHandler.swift
│   ├── GrandNationalMatchLifecycleHandler.swift
│   ├── FleetMatchLifecycleHandler.swift   # multi-event
│   ├── RaidMatchLifecycleHandler.swift
│   └── …
└── MatchLifecycleHandlerRegistry.swift
```

### Handler protocol (sketch)

```swift
protocol MatchLifecycleHandler {
    func submitTurn(
        session: MatchLifecycleSession,
        input: MatchTurnInput,
        timestamp: Date
    ) throws -> MatchLifecycleSession

    func replayEvent(
        _ envelope: MatchEventEnvelope,
        session: MatchLifecycleSession
    ) throws -> MatchLifecycleSession
}
```

Fleet/Raid: one handler per mode that internally switches on sub-event types.

### Migration strategy

1. Extract shared kernel — move `appendAndProject`, `rebuildSession`, undo helpers into `MatchLifecycleCoordinator` without behavior change.
2. Keep public API stable — `MatchLifecycleService.submitGolfTurn(...)` delegates to registry (one-liner). No VM changes yet.
3. **Pilot modes:** Golf → Grand National → Knockout.
4. **Standard batch:** remaining modes from `Scripts/generate_play_match_route_view.py` `STANDARD_MODES`.
5. **Special modes last:** Killer (pick + turn), Baseball, Shanghai, X01, Cricket, Fleet, Raid.

### Per-mode checklist

- [ ] Handler file + unit tests (replay round-trip via `rebuildSession`)
- [ ] `submit*Turn` delegates to handler
- [ ] `applyEvent` case delegates to handler
- [ ] `MatchLifecycleServiceTests` still pass
- [ ] Delete inlined method body from `MatchLifecycleService`

### Exit criteria

- [ ] `MatchLifecycleService.swift` under ~300 lines
- [ ] `MatchEventPayload` enum unchanged (persistence contract — do not split in v1)
- [ ] Parameterized replay test: submit → encode → rebuild → assert runtime equality per mode

### Risk notes

Replay parity is the main footgun. Do **not** refactor `MatchEventPayload` coding in v1.

---

## 5. Phase 2 — Shared match VM core (~2–3 weeks, incremental)

### What to extract (standard modes)

| Shared | Mode-specific |
|--------|---------------|
| `session`, `enteredDarts`, `selectedMultiplier`, `isBotPlaying` | Scoreboard row mapping |
| `MatchTurnSubmitter` wiring | Engine submit closure |
| `loadSessionIfNeeded`, `onAppear`/`onDisappear` | Post-turn state (`holeCompleteFeedback`, etc.) |
| `reconcileAfterSummaryUndo`, bot playback loop | Bot turn generator |
| `undoLastDart` / `undoLastTurn` | Pad constraints (`lockedSegment`) |
| `MatchPlaySessionHost` conformance | Header copy / a11y labels |

**Defer:** X01, Cricket (turn-total caller, legacy patterns), Fleet, Raid (non-standard flows).

### Target architecture

```
Features/Play/Shared/
├── MatchSessionController.swift
├── MatchSessionController+Bot.swift
├── MatchSessionController+Undo.swift
├── StandardMatchViewModel.swift       # protocol + default impls
└── MatchTurnSubmitter.swift           # existing
```

Use **composition** (`MatchSessionController` owned by thin mode VM), not inheritance.

### Migration order

1. Extract from **Golf** (cleanest `MatchTurnSubmitter` user).
2. Migrate `STANDARD_MODES` from route generator one at a time.
3. Party/special: Killer, Baseball, Shanghai.
4. Defer X01, Cricket, Fleet, Raid.

### Exit criteria

- [ ] 16+ standard mode VMs under ~150 lines each
- [ ] All `*MatchViewModelTests` green
- [ ] No UI test contract changes (`pad_*`, `match_exit`, etc.)

---

## 6. Phase 3 — Setup config registry (~2–3 weeks, incremental)

### Problem today

- VM `@Published` fields duplicate `Support/State/*SetupPreferences.swift`
- `currentConfig` switch (~lines 705–837 in `MatchSetupViewModel.swift`) assembles `MatchConfigPayload`
- `persistLastUsedSetup()` mirrors the same mode list

### Target architecture

```
Support/State/Setup/
├── MatchSetupConfiguration.swift
├── MatchSetupRegistry.swift
├── X01SetupConfiguration.swift
├── GolfSetupConfiguration.swift
└── …
```

### Protocol (sketch)

```swift
protocol MatchSetupConfiguration: ObservableObject {
    var matchType: MatchType { get }
    func loadFromPersistence()
    func saveToPersistence()
    func buildMatchConfig() -> MatchConfigPayload
    func validationErrors() -> [String]
}
```

### VM after refactor (~200 lines)

Global state only: roster, `setupCategory`, `selectedCatalogMatchType`, `isSubmitting`. Per-mode state lives in configuration types; `currentConfig` comes from `activeConfiguration.buildMatchConfig()`.

### UI binding

`Setup{Mode}OptionChips.swift` binds to concrete configuration type via `SetupOptionsHost(configuration:)` — not the god VM. Build on decomposed `SetupHomeView` structure from release-build view plan.

### Migration order

1. Modes with existing `*SetupPreferences`: Golf, Knockout, Fleet, Raid
2. Party: Baseball, Killer, Shanghai
3. X01, Cricket (settings defaults integration)
4. Remaining standard modes

Extend `PersistedSetupPreferences` to all modes (today only 4 conform in `PersistedSetupPreferences.swift`).

### Exit criteria

- [ ] `MatchSetupViewModel` under ~250 lines
- [ ] `currentConfig` switch deleted
- [ ] `MatchSetupViewModelTests` pass

---

## 7. Cross-cutting rules

1. **One mode per PR** where possible.
2. **No behavior changes** — refactors only.
3. **Test gate after every PR:** unit suite green; spot UI smoke if touching setup/match screens.
4. **Keep public APIs stable** during migration — thin wrappers until all call sites moved.
5. **Out of scope for Tier 1:** `MatchEventPayload` redesign, `HistoryDetailViewModel` extractors, route codegen expansion, SPM split, `AchievementHooks` injection (Tier 2 unless touching `MatchTurnSubmitter.persistProgress`).

---

## 8. Effort summary

| Phase | Calendar time | PR count (est.) |
|-------|---------------|-----------------|
| 0 — Test fakes | 2–3 days | 3–5 |
| 1 — Lifecycle plugins | 2–3 weeks | 15–20 |
| 2 — Match VM core | 2–3 weeks | 12–18 |
| 3 — Setup registry | 2–3 weeks | 12–18 |

**Total:** ~6–8 weeks steady pace; ~4 weeks with parallelization.

---

## 9. First sprint (2 weeks)

| Day | Work |
|-----|------|
| 1–2 | Phase 0: `FakeRepositories.swift` + migrate `MatchSetupViewModelTests` |
| 3 | Phase 0: migrate 5 more test files; CI green |
| 4–5 | Phase 1: extract `MatchLifecycleCoordinator` kernel |
| 6–8 | Phase 1: pilot handlers — Golf, Grand National, Knockout |
| 9–10 | Phase 2 spike: `MatchSessionController` from Golf VM |

---

## 10. Progress tracker

| Phase | Status | Notes |
|-------|--------|-------|
| 0 — Test fakes | **Complete** | `FakeRepositories.swift`, `FakeRepositoryBuilders.swift`, `MatchTestFixtures.swift`; 35+ test files migrated. Remaining inline fakes are domain-specific (stats loader pagination, corrupt snapshots, player-list blocking). |
| 1 — Lifecycle plugins | **In progress** | `MatchLifecycleCoordinator` extracted; pilot handlers: Golf, Knockout, Grand National. |
| 2 — Match VM core | Not started | |
| 3 — Setup registry | Not started | |

Update this table when phases complete or ship gates change.
