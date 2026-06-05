# Spec Governance

## 1. Purpose
Prevent spec drift, duplication conflicts, and ambiguous ownership so implementation agents have one clear source of truth.

---

## 2. Source-of-Truth Map
- Persistence models and migration policy:
  - `specs/SwiftData.md` (authoritative)
  - `specs/DataSchemaSpec.md` (authoritative invariants)
- Architecture boundaries and dependency rules:
  - `specs/ArchitectureSpec.md` (authoritative)
- Runtime dependencies and framework choices:
  - `specs/TechStackSpec.md` (authoritative)
- Logging API, schema, and sink strategy:
  - `specs/LoggingSpec.md` (authoritative)
- Firebase backend and analytics rollout policy:
  - `specs/FirebaseBackendAnalyticsSpec.md` (authoritative)
- Accessibility compliance:
  - `specs/AccessibilitySpec.md` (authoritative)
- UI wireframes and behavior contracts:
  - `specs/UIBlueprintSpec.md` (authoritative)
- UI screen state/event/data implementation contracts:
  - `specs/UIImplementationSpec.md` (cross-screen conventions + §3 index only; per-screen behavior in feature specs)
- Localization and string key policy:
  - `specs/LocalizationSpec.md` (authoritative)
- Feature behavior:
  - Feature specs in [`specs/README.md`](README.md) § Feature Specs are authoritative for feature UX/rules (e.g. `PlayHomeSpec`, `BotOpponentSpec`, `TrainingBotSpec`, `StatisticsTabSpec`, `MigrationRecoverySpec`).
- Migration recovery UX (not schema policy):
  - `specs/MigrationRecoverySpec.md` (authoritative)
- Cross-cutting test policy:
  - `specs/TestPlanSpec.md` (authoritative)
- Swift Testing tag taxonomy and CI filtering policy:
  - `specs/SwiftTestingTagsSpec.md` (authoritative)
- App Store branding, naming, and metadata policy:
  - `specs/AppStoreConnectSpec.md` (authoritative)
- Feature flag and runtime configuration policy:
  - `specs/FeatureFlagConfigSpec.md` (authoritative)
- Canonical error taxonomy and mapping policy:
  - `specs/ErrorModelSpec.md` (authoritative)

If two specs disagree, the authoritative spec above wins.

---

## 3. Duplication Rules
- Do not duplicate full persistence field lists across multiple specs.
- Feature specs may include conceptual data snippets only with explicit link back to schema specs.
- Prefer references over restating large sections.

### 3.1 Repo-level documentation (non-spec)
| Doc | Owns | Do not copy into |
|-----|------|------------------|
| `README.md` | Repo entry, build steps, doc-role index | Feature specs, `docs/release/todo.md` |
| `docs/release/todo.md` | Current sprint, 1.0 blockers, post-1.0 deferrals | README roadmaps, `roadmap/` phase files |
| `docs/release/release_checklist.md` | Full device QA + App Store + launch marketing runbook | Spec checklists (abbrev only) |
| `roadmap/` | Phase delivery history and release runbooks | `docs/release/todo.md` (link only) |
| `roadmap/archive/` | Historical phase plans and one-time audits | Active docs above |
| `accessibility/accessibility_todo.md` | A11y engineering phases | `Manual_todo.md` |
| `accessibility/Manual_todo.md` | Human verification steps | `accessibility_todo.md`, `wcag-2.1-aa/SUMMARY.md` |
| `accessibility/wcag-2.1-aa/` | Per-screen/criterion status + evidence links | `specs/AccessibilitySpec.md` (requirements only) |
| `FutureIdeas/` | Post-1.0 feature assessments (Game Center, play reminders, …) | `docs/release/todo.md` (one-line links only) |
| `FutureIdeas/backlog.md` | Post-1.0 product backlog (short ideas) | `docs/release/todo.md` |
| `FutureIdeas/achievements.md` | Game Center deep-dive | `docs/release/todo.md` |
| `FutureIdeas/play-reminders.md` | Local play reminder notifications | `docs/release/todo.md` |

Full table with QA gates: [`README.md`](../README.md#documentation-map).

---

## 4. Change Management Rules
- Any schema field change must update:
  - `specs/SwiftData.md`
  - `specs/DataSchemaSpec.md`
  - impacted feature spec references
- Any architecture boundary change must update:
  - `specs/ArchitectureSpec.md`
  - `specs/RepositorySpec.md` if contracts are affected
- Any dependency decision change must update:
  - `specs/TechStackSpec.md`
- Any logging API/schema/sink strategy change must update:
  - `specs/LoggingSpec.md`
- Any Firebase service adoption or backend plan change must update:
  - `specs/FirebaseBackendAnalyticsSpec.md`
- Any accessibility requirement change must update:
  - `specs/AccessibilitySpec.md`
- Any screen-level UX flow, wireframe, or behavior contract change must update:
  - `specs/UIBlueprintSpec.md`
- Any screen-level state/event/data contract change must update:
  - `specs/UIImplementationSpec.md`
- Any localization/string policy change must update:
  - `specs/LocalizationSpec.md`
- Any test tag catalog/profile change must update:
  - `specs/SwiftTestingTagsSpec.md`
- Any App Store naming/branding/metadata change must update:
  - `specs/AppStoreConnectSpec.md`
- Any feature flag/config contract change must update:
  - `specs/FeatureFlagConfigSpec.md`
- Any error taxonomy or mapping contract change must update:
  - `specs/ErrorModelSpec.md`
- Any user-visible feature behavior change must update the matching feature spec in [`specs/README.md`](README.md) § Feature Specs and bump that spec’s **Verification** table (date + commit).
- Any new Firebase Analytics or Crashlytics event must update:
  - `specs/FirebaseBackendAnalyticsSpec.md` §12
  - `Support/Logging/FirebaseAnalyticsEventMapping.swift` and/or `FirebaseCrashlyticsEventMapping.swift`
  - mapping unit tests

---

## 4.1 Pull request rules (feature + telemetry)

1. **Behavior change** → update the authoritative feature spec; do not only update `UIImplementationSpec` or `UIBlueprintSpec`.
2. **New screen or tab** → add row to `UIImplementationSpec.md` §3 index + feature spec + optional `accessibility/wcag-2.1-aa/screens/<screen>.md`.
3. **New localization keys** → all four `Localizable.strings` files (`LocalizationSpec.md` §7).
4. **New Analytics/Crashlytics event** → §12 catalog + allowlist + tests (same PR).
5. **Schema change** → `SwiftData.md` + `DataSchemaSpec.md` + affected feature specs (no full field dumps in feature specs).

---

## 5. Feature spec coverage checklist

Audit after major releases or quarterly. Set **Last verified** to audit date and **Commit** to `git rev-parse --short HEAD`.

| Feature area | Spec | Primary code paths |
|--------------|------|-------------------|
| Play home | `PlayHomeSpec.md` | `PlayHomeViewModel`, `SetupHomeView` (resume) |
| Match setup | `SetupFlowSpec.md` | `MatchSetupViewModel`, setup chip extensions |
| Quick add player | `QuickAddPlayerSpec.md` | `QuickAddPlayerScreen`, `PendingMatchPlayerSelections` |
| Scoring input | `ScoringInputSpec.md` | `ScoringInputPad`, shared gameplay chrome |
| Match lifecycle | `MatchSpec.md` | `MatchLifecycleService`, repositories |
| Match summary | `MatchSummarySpec.md` | `MatchSummaryScreen`, `MatchSummaryViewModel` |
| X01 | `X01GameSpec.md` | `X01Engine`, `X01MatchViewModel` |
| Cricket | `CricketSpec.md` | `CricketEngine`, `CricketMatchViewModel` |
| Scoring input | `ScoringInputSpec.md` | `ScoringInputPad`, dart entry |
| Preset bots | `BotOpponentSpec.md` | `DartBotEngine`, `BotDifficulty` |
| Training bots | `TrainingBotSpec.md` | `TrainingBotSkillResolver`, Player Detail |
| Players | `PlayerSpec.md` | `PlayersRootView`, `PlayerDetailView` |
| History | `HistorySpec.md` | `HistoryRootView`, detail screen |
| Stats math | `StatsSpec.md` | `StatsService`, aggregates |
| Statistics tab | `StatisticsTabSpec.md` | `StatisticsRootView`, `StatisticsViewModel` |
| Settings | `SettingsSpec.md` | `SettingsRootView`, `SettingsViewModel` |
| Migration recovery | `MigrationRecoverySpec.md` | `MigrationRecoveryView`, `AppBootstrapper` |
| App shell | `AppShellSpec.md` | `DartBuddyApp`, `MainTabView` |
| Telemetry | `FirebaseBackendAnalyticsSpec.md` §12 | `Firebase*EventMapping.swift` |

---

## 6. Agent Safety Checklist
Before implementation:
1. Confirm there is no conflict with authoritative specs.
2. If conflict exists, resolve spec conflict first.
3. Document assumptions in PR notes when spec is silent.
4. After implementation, update feature spec + §5 checklist row if behavior changed.
