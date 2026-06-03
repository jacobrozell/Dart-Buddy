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
  - `specs/UIImplementationSpec.md` (authoritative)
- Localization and string key policy:
  - `specs/LocalizationSpec.md` (authoritative)
- Feature behavior:
  - Feature specs (`X01GameSpec`, `CricketSpec`, `PlayerSpec`, etc.) are authoritative only for feature UX/rules.
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

---

## 5. Agent Safety Checklist
Before implementation:
1. Confirm there is no conflict with authoritative specs.
2. If conflict exists, resolve spec conflict first.
3. Document assumptions in PR notes when spec is silent.
