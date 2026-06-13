# Custom Bot — Architecture & UI Long-Term Plan

Verbose execution plan for **user-defined custom bots**: protocol design, persistence, template-aware skill resolution across 29+ game modes, and phased UI.

**Status:** Approved direction · **Partially implemented** (lean 1.0 ships simple custom bots)  
**Authoritative feature rules:** [`specs/CustomBotSpec.md`](../../specs/CustomBotSpec.md)  
**Companion:** [`specs/BotOpponentSpec.md`](../../specs/BotOpponentSpec.md) · [`specs/TrainingBotSpec.md`](../../specs/TrainingBotSpec.md) · [`docs/full-game-catalog-ui.md`](../full-game-catalog-ui.md) · [`docs/release/ongoing-release-plan.md`](../release/ongoing-release-plan.md)

---

## 1. Executive summary

Custom bots today are **two sliders** (X01 3-dart average + Cricket MPR) encoded in `botDifficultyRaw`, resolved per `MatchType` via a small switch, and snapshotted into `MatchParticipant.botSkillProfilePayload` at match start. That works for 1.0 X01/Cricket and will largely work when party modes return in 1.1 — but it **will not scale** to 29 catalog modes, advanced per-stat editing, or future bot *kinds* (campaign bosses, scripted tutors).

This plan introduces:

1. A **bot protocol stack** — identity, skill resolution, match snapshotting — with **kind-specific payloads** (`preset`, `training`, `custom`, future kinds).
2. **`CustomBotConfiguration`** — versioned persistence replacing metrics-only storage, optional explicit `BotSkillProfile`, and **skill facets** for Advanced UI (not per-mode bot types).
3. **`BotSkillProfileResolver`** — template-based resolution keyed on `GameplayUITemplate`, not a growing `MatchType` switch.
4. **Phased UI** — Simple create (1.0) → Advanced edit (1.0.x–1.2) → facet editors grouped by template family → polish & simulation tools.

**Critical invariant:** A custom bot created in 1.0 must play **Baseball in 1.1** (and future template-compatible modes) **without user reconfiguration or data migration**, using stored configuration + template rules.

---

## 2. Problem statement

### 2.1 What works today

| Area | Implementation |
|------|----------------|
| Storage | `botDifficultyRaw = "custom:{x01Avg}:{cricketMPR}"` on `PlayerRecord` |
| Resolution | `CustomBotSkillResolver.profile(for: MatchType, metrics:)` |
| Match start | `CustomBotSkillSnapshot` → `MatchParticipant.botSkillProfilePayload` |
| In-match | `DartBotEngine` reads frozen `BotSkillProfile` from participant |
| UI | Two sliders in create sheet + detail; read-only `BotDifficultyStatsSection` preview |
| 1.0 product | `ProductSurface.showsCustomBots = true`; Training Partner still hidden |

Party modes already map to X01-derived profiles:

```swift
case .baseball, .killer, .shanghai:
    return BotSkillProfileInterpolator.profile(forX01Average: metrics.x01Average, ...)
```

### 2.2 What breaks at scale

| Risk | Why |
|------|-----|
| `MatchType` switch | 29 modes → unmaintainable; 24 planned modes have no `MatchType` yet |
| Metrics-only storage | Advanced UI cannot persist checkout %, hit chances, etc. |
| Per-mode bot types | User expects one roster identity across X01, Baseball, Around the Clock |
| Divergent X01 vs Cricket resolution | Same bot gets different full profiles per mode today (by design); must stay predictable when templates multiply |
| Engine slice coupling | Baseball reads `x01` tier + `cricket` hit/miss fields; mark-board modes read `cricket.*`; document and stabilize |

### 2.3 User expectations

- **Casual:** “Set strength like a 45-average player” — two knobs.
- **Power:** “Tune checkout rate and triple preference” — many knobs, one bot.
- **Long-term:** “I created this bot in 1.0; it should work in new modes automatically.”

---

## 3. Goals and non-goals

### 3.1 Goals

- **G1** — One custom bot identity works across all **template-compatible** shipped modes without migration.
- **G2** — Extensible **bot kind** model (`custom` today; `campaign` etc. later) sharing match-start contracts.
- **G3** — **Template-based** skill resolution (`GameplayUITemplate`) aligned with [`GameModeCatalog`](../../Features/Modes/GameModeCatalog.swift).
- **G4** — **Versioned** `CustomBotConfiguration` with backward decode of `custom:x:y`.
- **G5** — **Simple + Advanced** UI; Advanced edits canonical skill, not 29 mode tabs.
- **G6** — Match-start **snapshot** unchanged (in-progress matches stable).
- **G7** — Full unit + device coverage per phase.

### 3.2 Non-goals (this program)

- Per-mode custom bot types (`CustomX01Bot`, `CustomBaseballBot`, …).
- Per-mode override panels in UI (29 × N sliders).
- Mid-match skill changes.
- Cloud sync / share codes for bot builds (future backlog).
- Replacing `DartBotEngine` as the runtime throw generator.
- Training Partner redesign (separate spec; may share interpolator/types).

---

## 4. Architecture principles

1. **`BotSkillProfile` is the engine lingua franca** — all bot kinds resolve to it (or a successor) at match start.
2. **Persist configuration, snapshot profile** — player row stores intent; participant row stores frozen skill for the match.
3. **Templates, not modes** — new catalog mode adds catalog row + engine + **one resolver line**, not custom-bot migration.
4. **Facets, not species** — checkout rate is an `X01SkillFacet`, not a new `BotKind`.
5. **Merge, don’t fork** — canonical profile = merge(X01-derived slice, Cricket-derived slice, optional explicit overrides).
6. **Protocol + enum box** — Swift `Codable` storage uses `StoredBotConfiguration` enum, not `[any BotDescriptor]`.

---

## 5. Type system (target)

### 5.1 Layer diagram

```
┌─────────────────────────────────────────────────────────────┐
│  UI (SwiftUI)                                                │
│  Simple sliders · Advanced facet editors · Preview           │
└───────────────────────────┬─────────────────────────────────┘
                            │
┌───────────────────────────▼─────────────────────────────────┐
│  CustomBotConfiguration (persisted)                          │
│  schemaVersion · simple targets · explicitProfile? · facets?  │
└───────────────────────────┬─────────────────────────────────┘
                            │ resolvedCanonicalProfile()
┌───────────────────────────▼─────────────────────────────────┐
│  BotSkillProfileResolver                                     │
│  (configuration, BotPlayContext{ matchType, uiTemplate })    │
└───────────────────────────┬─────────────────────────────────┘
                            │
┌───────────────────────────▼─────────────────────────────────┐
│  BotSkillProfile → CustomBotSkillSnapshot (match start)      │
└───────────────────────────┬─────────────────────────────────┘
                            │
┌───────────────────────────▼─────────────────────────────────┐
│  DartBotEngine (per-template generators)                     │
└─────────────────────────────────────────────────────────────┘
```

### 5.2 Core protocols

#### `BotDescriptor` — roster identity + persistence contract

```swift
/// Any computer opponent stored as a Player row.
protocol BotDescriptor: Codable, Sendable {
    var botKind: BotKind { get }
}
```

**Concrete types (not further subclassed by game mode):**

| Type | `BotKind` | Payload |
|------|-----------|---------|
| `PresetBotDescriptor` | `.preset` | `BotDifficulty` |
| `TrainingBotDescriptor` | `.training` | `UUID` linkedPlayerId + repository resolution |
| `CustomBotDescriptor` | `.custom` | `CustomBotConfiguration` |
| `CampaignBotDescriptor` (future) | `.campaign` | TBD stage/script payload |

#### `BotSkillResolving` — configuration → runtime profile

```swift
struct BotPlayContext: Sendable, Equatable {
    let matchType: MatchType
    let uiTemplate: GameplayUITemplate
}

protocol BotSkillResolving {
    associatedtype Configuration: Sendable
    func skillProfile(
        configuration: Configuration,
        context: BotPlayContext
    ) -> BotSkillProfile
}
```

`CustomBotDescriptor` conforms. `PresetBotDescriptor` ignores context (tier profile). `TrainingBotDescriptor` may vary by template weighting in future.

#### `BotMatchParticipantBuilding` — snapshot encoding

```swift
protocol BotMatchParticipantBuilding {
    func skillSnapshotPayload(
        profile: BotSkillProfile,
        context: BotPlayContext
    ) throws -> Data
}
```

Unifies `CustomBotSkillSnapshot.encode`, `TrainingBotSkillSnapshot.encode`, etc.

### 5.3 Stored configuration box

```swift
enum StoredBotConfiguration: Codable, Sendable {
    case preset(BotDifficulty)
    case training(TrainingBotStoredState)
    case custom(CustomBotConfiguration)
    // case campaign(CampaignBotConfiguration)
}
```

**Player row mapping (transition):**

| Phase | `botKindRaw` | Payload field |
|-------|--------------|---------------|
| Now | `custom` | `botDifficultyRaw = custom:x:y` |
| Phase A | `custom` | `botDifficultyRaw = customV2:{json}` or new `customBotPayload: Data?` (SchemaV3) |
| Steady | `custom` | SchemaV3 `customBotPayload` preferred; raw string legacy decode |

### 5.4 `CustomBotConfiguration`

```swift
struct CustomBotConfiguration: Codable, Sendable, Equatable {
    static let currentSchemaVersion = 2

    var schemaVersion: Int

    // MARK: Simple path (always populated for display + migration)
    var x01Average: Double
    var cricketMPR: Double

    // MARK: Advanced path
    /// When non-nil, used as canonical profile base instead of interpolator-only merge.
    var explicitProfile: BotSkillProfile?

    /// Optional facet overrides applied after merge (Phase C+).
    var facetOverrides: CustomBotFacetOverrides?

    /// Anchors discrete scoring heuristics in DartBotEngine (`scoringBehaviorTier`).
    var scoringBehaviorTier: BotDifficulty?
}
```

**Canonical profile algorithm:**

```
if let explicit = explicitProfile {
    profile = explicit
} else {
    x01Slice = interpolate(x01Average)
    cricketSlice = interpolate(cricketMPR)
    profile = merge(x01: x01Slice.x01, cricket: cricketSlice.cricket, tier: scoringBehaviorTier)
}
if let facets = facetOverrides {
    facets.apply(to: &profile)
}
return profile
```

Matches today’s `combinedDisplayProfile` semantics but produces a **single** stored-engine profile.

### 5.5 Skill facets (Advanced UI building blocks)

**Do not** create `CustomX01Bot` types. Use facets:

```swift
protocol BotSkillFacet: Codable, Sendable {
    static var supportedTemplates: Set<GameplayUITemplate> { get }
    mutating func apply(to profile: inout BotSkillProfile)
    static func extract(from profile: BotSkillProfile) -> Self
}
```

| Facet | Editable fields (display profile) | Templates that consume |
|-------|-----------------------------------|----------------------|
| `X01SkillFacet` | visit min/max, S/D/T hit %, checkout, miss, bust, triple pref, check-in boost, inner bull, master-in | `checkoutScore`, parts of others |
| `CricketSkillFacet` | S/D/T hit %, off-board miss, wrong bed | `markBoard` |
| `AimSkillFacet` | shared aim / tier behavior (wraps `scoringBehaviorTier` + open-bed chances) | `inningPoints`, `sequenceProgress`, `livesElimination` |
| `EngineTuningFacet` (internal/hidden Phase E) | safe-finish buffers, cricket triple/double on open | engine-only; optional expert mode |

`CustomBotFacetOverrides` holds optional facet structs; nil fields mean “derive from simple targets.”

### 5.6 Template resolver table (authoritative)

Resolver returns **full** `BotSkillProfile`; each `DartBotEngine` API reads relevant slices.

| `GameplayUITemplate` | Catalog examples | Resolution policy (v1) | Engine entry points |
|--------------------|------------------|------------------------|---------------------|
| `checkoutScore` | X01, Knockout, 51 By 5's | `canonicalProfile` | `generateX01Turn` |
| `markBoard` | Cricket, Mickey Mouse, Mulligan | `canonicalProfile` | `generateCricketTurn` |
| `inningPoints` | Baseball, Shanghai, Golf | `canonicalProfile` | `generateBaseballTurn`, `generateShanghaiTurn` |
| `livesElimination` | Killer, Nine Lives, Follow the Leader | `canonicalProfile` | `generateKillerPick/Turn` |
| `sequenceProgress` | Around the Clock, Grand National | `canonicalProfile` (v1); may add `AimSkillFacet` weighting later | TBD generators |
| `soloChallenge` | Bob's 27, Halve-It | `canonicalProfile` | TBD |
| `phaseRace` | Football | `canonicalProfile` | TBD |
| `boardState` | Prisoner, Tic-Tac-Toe | `canonicalProfile` (v1 fallback) | TBD |
| `roleSplit` | Scam, Snooker | `canonicalProfile` (v1 fallback) | TBD |

**v1 policy:** All templates receive the **same canonical profile** from configuration. Engines already read different slices. When a new template needs bespoke tuning, add a **template-specific weighting function** — not new persisted bot types.

**Adding a mode (checklist):**

1. Catalog entry with `uiTemplate`
2. Match engine + UI screen
3. `DartBotEngine` generators (or reuse existing)
4. Confirm resolver row (usually `canonicalProfile`)
5. Unit: `CustomBotConfiguration` + template → profile smoke
6. Unit/integration: bot simulation for new template
7. **No** `PlayerRecord` migration

---

## 6. Persistence and migration

### 6.1 Encoding versions

| Version | Format | Decode |
|---------|--------|--------|
| v1 (shipped 1.0) | `custom:{x01}:{mpr}` | `CustomBotConfiguration(schemaVersion: 1, x01Average:, cricketMPR:, explicitProfile: nil)` |
| v2 | `customV2:` + JSON `CustomBotConfiguration` | Full structure |
| v3 (optional) | `PlayerRecord.customBotPayload: Data?` | Same JSON; clears legacy string |

### 6.2 Schema migration (SwiftData)

| Schema | Change |
|--------|--------|
| V2 (current) | `botDifficultyRaw` only |
| V3 (proposed) | `PlayerRecord.customBotPayload: Data?` for custom bots; `botDifficultyRaw` retained for preset |

Migration `V2→V3`:

- For `botKindRaw == custom`: parse `botDifficultyRaw` → encode `customBotPayload`; keep raw for rollback read.
- Preset/training unchanged.

### 6.3 Match participant snapshots

Keep `CustomBotSkillSnapshot`:

```swift
struct CustomBotSkillSnapshot: Codable {
    let profile: BotSkillProfile      // frozen for this match
    let x01Average: Double            // display + analytics
    let cricketMPR: Double
    let configurationSchemaVersion: Int // optional Phase B+
}
```

In-progress matches **never** re-resolve from player row.

### 6.4 Repository API changes

| Method | Phase | Notes |
|--------|-------|-------|
| `createCustomBot(name:metrics:)` | Now | Keep; delegate to `createCustomBot(name:configuration:)` |
| `createCustomBot(name:configuration:)` | A | Primary |
| `updateCustomBotConfiguration(id:configuration:)` | A | Replaces `updateCustomBotMetrics` |
| `decodeCustomBotConfiguration(player:)` | A | Central decode v1/v2/v3 |

---

## 7. UI architecture

### 7.1 Design constraints

- **Create flow stays fast** — name + simple targets (≤30 seconds).
- **Advanced is edit-only** initially — avoid 15 sliders on first create.
- **Preview is mandatory** — reuse `BotDifficultyStatsSection`; live update as sliders move.
- **No per-mode tabs** — group facets by **X01 / Cricket / Aim** with template compatibility footers.
- **Accessibility** — every slider has label, value, hint; VO reads derived stats.

### 7.2 Screen map

| Surface | Phase | Content |
|---------|-------|---------|
| `CustomBotCreationSheet` | Now | Name + `CustomBotMetricsEditor` (2 sliders) |
| `CustomBotDetailView` | B+ | Simple/Advanced segmented control |
| `CustomBotAdvancedEditor` (new) | B | Facet editors + preset anchor picker |
| `BotDifficultyStatsSection` | Now | Read-only preview; becomes live mirror |
| Players list `CustomBotBadge` | C | Show avg/MPR or “Custom tuned” |
| Play setup Add Bot menu | Now | Create + pick existing custom bots |

### 7.3 Simple mode (shipped baseline)

- X01 3-dart average slider `5…110`
- Cricket MPR slider `0.2…5.0`
- Footer explaining auto-behavior in other modes
- Live `BotDifficultyStatsSection` below sliders

### 7.4 Advanced mode (target)

```
┌────────────────────────────────────────┐
│ [ Simple ]  [ Advanced ]               │
├────────────────────────────────────────┤
│ Based on preset: [ Medium ▼ ]          │  ← sets scoringBehaviorTier
│ [ Reset to simple targets ]            │
├────────────────────────────────────────┤
│ X01                                    │
│   Scoring visit range    [min] [max]   │
│   Hit chance S / D / T   ───●───       │
│   Checkout attempt       ───●───       │
│   ...                                  │
│ Cricket                                │
│   Hit chance S / D / T   ───●───       │
│   Wrong bed              ───●───       │
│ Aim (Baseball, Shanghai, …)            │
│   Scoring behavior tier  [ Medium ▼ ]  │
├────────────────────────────────────────┤
│ Preview (BotDifficultyStatsSection)    │
│ "Used in: X01, Cricket, Baseball, …"   │
└────────────────────────────────────────┘
```

**Actions:**

- **Reset to simple** — clears `explicitProfile` and facet overrides; re-derive from avg/MPR.
- **Reset to preset** — fill from `BotDifficulty.*.skillProfile`.
- **Save** — writes `CustomBotConfiguration` v2+.

### 7.5 UI ↔ model binding

| UI control | Writes to |
|------------|-----------|
| X01 avg slider (Simple) | `configuration.x01Average`; clears explicit if “linked” |
| MPR slider (Simple) | `configuration.cricketMPR` |
| Advanced stat slider | `explicitProfile` or facet override |
| Preset picker | `scoringBehaviorTier` + optional profile seed |

**Debounce:** preview updates on slider change (no save until Save).

---

## 8. Phased implementation

### Phase 0 — Documentation & alignment (½ day) ✅

| Task | Done |
|------|------|
| This plan + `specs/CustomBotSpec.md` | [x] |
| Link from `specs/README.md`, `BotOpponentSpec.md` | [x] |
| Align `ongoing-release-plan.md` custom bot row | [x] |

**Exit:** Team agrees template resolver is the scaling mechanism.

---

### Phase A — Configuration model & decoder (3–4 days)

**Goal:** Introduce `CustomBotConfiguration` without UI change; 100% backward compatible decode.

| # | Task | Files |
|---|------|-------|
| A1 | Add `CustomBotConfiguration`, `CustomBotConfigurationCodec` (v1/v2) | `Domain/Models/` |
| A2 | Add `BotPlayContext`, `BotSkillProfileResolver` (template table) | `Domain/Services/` |
| A3 | Refactor `CustomBotSkillResolver` to delegate to resolver | replace `MatchType` switch |
| A4 | `MatchSetupViewModel` uses resolver with `catalogEntry.uiTemplate` | `MatchSetupViewModel.swift` |
| A5 | Repository: `create/update` configuration APIs | `SwiftDataPlayerRepository.swift` |
| A6 | Unit tests: v1 round-trip, v2 JSON, template table for all shipped `MatchType`s | `Tests/Unit/` |
| A7 | Regression: existing `CustomBotTests`, setup VM tests, baseball simulation | CI |

**Acceptance:**

- [ ] All existing custom bot tests green
- [ ] `custom:30:1.25` decodes identically before/after
- [ ] Baseball/Killer/Shanghai resolution unchanged for metrics-only bots
- [ ] New test: `templateResolver_sameConfig_allShippedTemplates_succeeds`

**Release:** Can ship silently in 1.0.x — no user-visible change.

---

### Phase B — Advanced UI shell (4–5 days)

**Goal:** Simple/Advanced toggle on `CustomBotDetailView`; Advanced shows read-only expanded stats first, then editable.

| # | Task | Files |
|---|------|-------|
| B1 | `CustomBotEditorMode` segmented Simple / Advanced | `CustomBotViews.swift` |
| B2 | `CustomBotAdvancedEditor` scaffold | new view |
| B3 | Preset anchor picker → `scoringBehaviorTier` | Advanced |
| B4 | Wire Save → `updateCustomBotConfiguration` | `PlayerDetailView`, `PlayersListViewModel` |
| B5 | “Reset to simple” / “Reset to preset” | Advanced |
| B6 | Copy: footer explaining cross-mode behavior | `en.lproj` |
| B7 | Unit tests for configuration merge / reset | `Tests/Unit/` |
| B8 | Device smoke: edit custom bot → X01 + Cricket match | `release_checklist.md` |

**Acceptance:**

- [ ] Simple path unchanged from 1.0
- [ ] Advanced saves v2 configuration
- [ ] Preview matches engine profile for X01 and Cricket

**Release:** 1.0.x or 1.2 — product call (`ongoing-release-plan`).

---

### Phase C — Facet editors (5–7 days)

**Goal:** Editable Advanced sliders for all `BotDifficultyDisplayProfile` fields.

| # | Task | Files |
|---|------|-------|
| C1 | `X01SkillFacet`, `CricketSkillFacet`, `AimSkillFacet` | `Domain/Models/BotSkillFacets.swift` |
| C2 | `CustomBotFacetOverrides` apply/extract | same |
| C3 | `BotStatSliderRow` component (reusable) | `DesignSystem/` |
| C4 | Replace read-only rows with sliders in Advanced | `CustomBotAdvancedEditor` |
| C5 | `explicitProfile` sync when any facet changes | configuration merge |
| C6 | WCAG: VO labels per slider | accessibility tests |
| C7 | Simulation tests: weak/strong custom profiles produce expected visit distributions | `Tests/Unit/` |

**Acceptance:**

- [ ] User can set checkout rate independently of avg slider
- [ ] Simple sliders still work; switching to Advanced shows derived values
- [ ] Reset to simple clears facet overrides

---

### Phase D — Protocol stack & `StoredBotConfiguration` (3–4 days)

**Goal:** Formalize bot kind protocols; unify match-start snapshot building.

| # | Task | Files |
|---|------|-------|
| D1 | `BotDescriptor`, `BotSkillResolving`, `BotMatchParticipantBuilding` | `Domain/Bots/` |
| D2 | `StoredBotConfiguration` enum + player decode/encode | `Domain/Models/` |
| D3 | `BotParticipantFactory` used by `MatchSetupViewModel` | replaces inline bot branch |
| D4 | Preset + training paths adopt factory (no behavior change) | refactor |
| D5 | Tests: factory produces identical participants to current code | parity tests |

**Acceptance:**

- [ ] `MatchSetupViewModel` bot block <30 lines via factory
- [ ] Parity tests for preset, training, custom

**Release:** Internal refactor; safe in any patch.

---

### Phase E — SchemaV3 payload column (2–3 days)

**Goal:** Move custom JSON off `botDifficultyRaw` string.

| # | Task | Files |
|---|------|-------|
| E1 | `SchemaV3` + `customBotPayload` on `PlayerRecord` | `Persistence/` |
| E2 | Migration plan + lightweight migration test | `DartsMigrationPlan` |
| E3 | Write both fields during transition; read payload first | repository |
| E4 | Document in `SwiftData.md` | spec |

**Acceptance:**

- [ ] Upgrade test: v1 string → open app → play match → no data loss
- [ ] New bots write payload column

---

### Phase F — New mode rollout playbook (ongoing)

**Goal:** Repeatable checklist for each catalog mode.

Per new mode:

1. Engine + UI shipped
2. Add catalog entry `uiTemplate`
3. Resolver row (usually default canonical)
4. `DartBotEngine` bot tests with custom profile fixtures
5. One device smoke: custom bot full match
6. Update `CustomBotSpec.md` template table if slice usage differs

**Party pack 1.1 (Baseball, Killer, Shanghai):**

- [ ] Verify metrics-only custom bots in device matrix
- [ ] No migration
- [ ] Optional: mention in Advanced UI “Aim” facet footer

---

### Phase G — Polish & power tools (backlog)

| Item | Notes |
|------|-------|
| Import/export bot build | JSON `CustomBotConfiguration` share |
| Monte Carlo preview | “Expected 3-dart average” from profile |
| Duplicate bot | Clone configuration |
| Expert engine tuning facet | Hidden behind debug or “expert mode” |
| Campaign bot kind | New `BotDescriptor` implementation |

---

## 9. Testing strategy

### 9.1 Unit (every phase)

| Suite | Covers |
|-------|--------|
| `CustomBotConfigurationCodecTests` | v1/v2/v3 encode/decode |
| `BotSkillProfileResolverTests` | each template + edge metrics |
| `CustomBotFacetTests` | apply/extract round-trip |
| `BotParticipantFactoryTests` | parity with legacy match setup |
| `CustomBotSkillResolverTests` | backward compat aliases |

### 9.2 Integration

- Custom bot → start X01 match → bot turns → complete leg
- Custom bot → Cricket Cut Throat → bot turn
- Resume match with custom bot participant

### 9.3 UI / device

| Test | Phase |
|------|-------|
| `Lean1_0SmokeUITests.testLeanAddBotMenuOffersCustomBotCreation` | Now |
| Create custom bot → X01 match (checklist) | B |
| Custom bot → Cricket match (checklist) | B |
| Advanced slider edit → match behavior spot-check | C |
| Party custom bot (baseball) when `showsPartyModes` | F / 1.1 |

### 9.4 Simulation

Extend `BotBaseballSimulationTests` pattern:

- Fixed seed + profile → visit total distribution monotonic vs stronger profile
- Run for each shipped template

---

## 10. Release alignment

| Release | Custom bot deliverables |
|---------|-------------------------|
| **1.0.0** (shipped direction) | Simple UI; `showsCustomBots`; metrics v1; template resolver for 5 `MatchType`s |
| **1.0.x** | Phase A silently; bugfixes |
| **1.1 Party pack** | Phase F verification for baseball/killer/shanghai; no migration |
| **1.2** | Phase B–C Advanced UI; Training Partner still separate |
| **1.3 Modes tab** | No custom bot changes required; catalog scale stress-test |
| **2.x** | Phase G; campaign bot kind |

Update [`docs/release/ongoing-release-plan.md`](../release/ongoing-release-plan.md) when Phase B ships.

---

## 11. Risk register

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Advanced UI overwhelms casual users | Medium | Medium | Simple default; Advanced opt-in |
| explicitProfile diverges from simple sliders | Medium | High | Clear reset actions; show both summaries |
| New template needs different resolver logic | High | Medium | Template table + tests per mode |
| `botDifficultyRaw` string size limits | Low | Medium | SchemaV3 payload column |
| Existential protocol Codable pain | Medium | High | `StoredBotConfiguration` enum box only |
| Baseball feels wrong for MPR-tuned bots | Known | Low | Document; Aim facet Phase C |
| Migration corrupts custom bots | Low | Critical | Dual-read; migration tests; backup export later |

---

## 12. Open questions

| # | Question | Owner | Default if unresolved |
|---|----------|-------|------------------------|
| 1 | Ship Advanced UI in 1.0.x or 1.2? | Product | 1.2 |
| 2 | SchemaV3 in same PR as Phase A or defer to E? | Eng | Defer until Advanced saves v2 JSON |
| 3 | Show template compatibility list in UI? | Design | Yes, footnote in Advanced |
| 4 | Allow custom bots in Killer (preset-only rule today)? | Product | Keep preset-only for Killer |
| 5 | Expert engine facet visible to users? | Product | Hidden until 2.x |

---

## 13. Task master checklist

| Phase | Description | Status |
|-------|-------------|--------|
| 0 | Docs & alignment | [x] plan |
| A | Configuration + template resolver | [ ] |
| B | Advanced UI shell | [ ] |
| C | Facet editors | [ ] |
| D | Protocol stack & factory | [ ] |
| E | SchemaV3 payload | [ ] |
| F | Per-mode rollout playbook | [ ] |
| G | Polish / campaign kind | [ ] |

---

## 14. Decision log

| Date | Decision | Rationale |
|------|----------|-----------|
| 2026-06-11 | Custom bots ship in lean 1.0 (simple UI) | Same engine path; differentiator vs preset-only |
| 2026-06-11 | Template resolver, not per-mode bot types | 29 modes; one roster identity |
| 2026-06-11 | Facets for checkout/MPR tuning, not `CustomX01Bot` | Avoid N bot species |
| 2026-06-11 | `BotSkillProfile` remains engine contract | All generators already profile-based |
| 2026-06-11 | Simple create, Advanced on detail | Fast setup; depth when needed |

---

## 15. References (code)

| Symbol | Path |
|--------|------|
| `CustomBotMetrics` | `Domain/Models/CustomBotMetrics.swift` |
| `CustomBotSkillResolver` | `Domain/Services/CustomBotSkillResolver.swift` |
| `BotSkillProfile` | `Domain/Engines/BotSkillProfile.swift` |
| `BotSkillProfileInterpolator` | `Domain/Engines/BotSkillProfileInterpolator.swift` |
| `DartBotEngine` | `Domain/Engines/DartBotEngine.swift` |
| `GameplayUITemplate` | `Features/Modes/GameModeCatalog.swift` |
| `CustomBotViews` | `Features/Players/CustomBotViews.swift` |
| `BotDifficultyStatsSection` | `Features/Players/PlayerVisualViews.swift` |
| Match start snapshot | `Features/Play/Setup/MatchSetupViewModel.swift` |
