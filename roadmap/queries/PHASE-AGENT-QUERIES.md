# Autonomous Agent Queries (Step-by-Step)

Use these prompts in order. Replace nothing unless your scope changes.

---

## 00 - Scope and Governance Lock

```text
Implement roadmap Phase 00 for DartsScoreboard.

Read first:
- roadmap/AGENT-KICKOFF-BRIEF.md
- roadmap/00-scope-and-governance.md
- specs/README.md
- specs/SpecGovernance.md
- specs/TechStackSpec.md
- specs/FeatureFlagConfigSpec.md
- specs/ErrorModelSpec.md
- specs/FigmaBuildPlan.md
- specs/UIBlueprintSpec.md

Rules:
- Figma is guidance only (incomplete); authoritative written specs win on conflicts.
- Manual verification only for now.
- No CI/CD setup work.
- No XCTest UI automation work.

Deliver:
1) concise scope lock memo
2) explicit deferred list (post-1.0)
3) tie-break policy note (specs > Figma)
4) kickoff checklist confirmation for starting agents

Return:
- files changed
- unresolved ambiguities
- recommended next query (Phase 01)
```

## 01 - Foundation, Architecture, Data, Logger

```text
Implement roadmap Phase 01 foundations for DartsScoreboard.

Read first:
- roadmap/AGENT-KICKOFF-BRIEF.md
- roadmap/01-foundation-architecture-and-data.md
- specs/ArchitectureSpec.md
- specs/AppShellSpec.md
- specs/SwiftData.md
- specs/DataSchemaSpec.md
- specs/RepositorySpec.md
- specs/LoggingSpec.md
- specs/SecurityPrivacySpec.md
- specs/ErrorModelSpec.md

Non-negotiables:
- Explicit SwiftData SchemaV1 + migration plan scaffold + ModelContainerFactory.
- Custom logger from day one (AppLogger + Console sink + redaction policy).
- Repository protocol boundaries before feature-heavy UI work.
- No direct SwiftData calls from views.

Implement:
1) root app/module skeleton
2) persistence baseline and migration wiring
3) logger abstraction/sink wiring
4) repository interfaces + typed errors
5) app bootstrap with startup hooks and migration-recovery placeholder

Return:
- files created/updated
- done vs TODO
- risks
- recommended next query (Phase 02)
```

## 02 - Core Engines and Match Lifecycle

```text
Implement roadmap Phase 02 for deterministic game/lifecycle behavior.

Read first:
- roadmap/02-core-engines-and-match-lifecycle.md
- specs/MatchSpec.md
- specs/SetupFlowSpec.md
- specs/X01GameSpec.md
- specs/CricketSpec.md
- specs/ScoringInputSpec.md
- specs/StatsSpec.md

Implement:
1) X01Engine and CricketEngine MVP rules
2) match lifecycle transitions (create/progress/complete/resume)
3) turn/dart event payload handling + replay determinism
4) snapshot checkpoint strategy
5) baseline stats reducers and aggregate recompute utility

Test focus:
- bust/checkout/closure/overflow/undo boundaries
- resume determinism from snapshot + tail events

Return:
- behavior completed
- tests added/passing manually
- open edge cases
- recommended next query (Phase 03)
```

## 03 - App Shell, Navigation, Setup

```text
Implement roadmap Phase 03 app flow plumbing.

Read first:
- roadmap/03-app-shell-navigation-and-setup.md
- specs/AppShellSpec.md
- specs/NavigationSpec.md
- specs/SetupFlowSpec.md
- specs/UIBlueprintSpec.md
- specs/UIImplementationSpec.md

Implement:
1) root tab shell with per-tab typed routes
2) Play Home states (with/without active match, no players, error)
3) single-active resume logic
4) setup form, sticky start CTA, validation, quick-add path hook
5) route safety rules (no mutable blobs in route params)

Return:
- routes/screens bootstrapped
- validation/resume behavior status
- manual verification notes
- recommended next query (Phase 04)
```

## 04 - Feature Batches (Gameplay, Players, History, Settings)

```text
Implement roadmap Phase 04 feature completion.

Read first:
- roadmap/04-feature-batches-gameplay-players-history-settings.md
- specs/UIBlueprintSpec.md
- specs/UIImplementationSpec.md
- specs/PlayerSpec.md
- specs/HistorySpec.md
- specs/SettingsSpec.md
- specs/ScoringInputSpec.md

Implement:
1) X01 gameplay screen states and interactions
2) Cricket gameplay board and interactions
3) Players list/detail/edit with archive and guarded delete
4) History list/detail with filters and fallback identity logic
5) Settings + migration recovery flows

Rules:
- keep behavior aligned to written specs first
- use Figma as visual guidance where accurate

Return:
- screen contract coverage status
- gaps by screen/state
- recommended next query (Phase 05)
```

## 05 - UI System and Fidelity Lock

```text
Implement roadmap Phase 05 UI fidelity/sign-off.

Read first:
- roadmap/05-ui-system-and-fidelity-lock.md
- specs/DesignSystemSpec.md
- specs/UIReviewChecklist.md
- specs/AccessibilitySpec.md
- specs/LocalizationSpec.md
- specs/FigmaBuildPlan.md
- specs/UIBlueprintSpec.md
- specs/UIImplementationSpec.md

Important:
- Figma is guidance only; use finalized/correct frames and document gaps.
- manual verification is required continuously (Phases 03-05).

Implement/verify:
1) semantic token usage consistency
2) accessibility labels/hints and non-color cues
3) portrait/landscape + light/dark matrix pass evidence
4) localization key usage for user-facing strings
5) Figma-vs-implementation review notes with known Figma gaps

Return:
- checklist pass/fail by screen
- remaining visual P0/P1 issues
- recommended next query (Phase 06)
```

## 06 - Quality Hardening and Release Ops Prep

```text
Implement roadmap Phase 06 hardening.

Read first:
- roadmap/06-quality-hardening-and-release-operations.md
- specs/TestPlanSpec.md
- specs/SwiftTestingTagsSpec.md
- specs/PerformanceSpec.md
- specs/ReleaseOpsSpec.md
- specs/SecurityPrivacySpec.md
- specs/LoggingSpec.md

Constraints:
- manual/local verification only (no CI/CD implementation)
- XCTest UI automation remains out of scope

Implement/verify:
1) complete required unit + integration coverage
2) align test tags to canonical taxonomy
3) validate MVP regression matrix manually
4) capture performance measurements against targets
5) finalize release artifacts (QA signoff template, migration report template, rollback criteria)

Return:
- manual test and perf report
- release readiness status
- recommended next query (Phase 07)
```

## 07 - RC, Launch Readiness, Post-Launch Plan

```text
Implement roadmap Phase 07 release-candidate and launch prep.

Read first:
- roadmap/07-rc-launch-and-post-launch.md
- specs/ReleaseOpsSpec.md
- specs/AppStoreConnectSpec.md
- specs/TestPlanSpec.md
- specs/AccessibilitySpec.md
- specs/LocalizationSpec.md
- roadmap/reports/Phase05-UI-Fidelity-Report.md
- roadmap/reports/Phase06-Manual-Test-Report.md
- roadmap/reports/Phase06-Performance-Report.md
- roadmap/reports/Phase06-Migration-Safety-Report.md
- roadmap/reports/Phase06-Security-Privacy-Checklist.md
- roadmap/release/Release-Notes-Template.md
- roadmap/release/QA-Signoff-Template.md
- roadmap/release/Rollback-and-Hotfix-Criteria.md

Current context to honor:
- Phases 01-06 scaffolding exists in code; many checks are prepared but still need real local/device execution evidence.
- UI automation is still out of scope; manual verification is required.
- Figma remains guidance-only when conflicting with written specs.
- No Firebase runtime dependency may be introduced.
- Keep typed error/logging/migration safety conventions already implemented.

Implement/verify:
1) Execute RC checklist manually and complete all pending evidence in the QA template.
2) Run exploratory core-flow verification on local/device:
   - setup -> X01 -> summary
   - setup -> cricket -> summary
   - resume active match
   - undo paths
   - players archive/delete guard
   - history list/detail
   - settings reset flow
3) Run migration smoke pass and finalize recovery-path readiness assessment (retry/export/reset).
4) Collect and record performance measurements against MVP targets (launch, submitTurn, resumeMatch, history first paint) using current instrumentation.
5) Validate App Store metadata/assets truthfulness and privacy/compliance values against specs.
6) Finalize launch runbook and hotfix triage flow using release templates.
7) Propose first post-launch patch priorities based on observed RC findings.

Check:
- category/pricing/compliance values align with specs
- no launch blockers in core flows/accessibility/migration/performance/security

Important:
- Do not claim pass for checks that are not actually executed.
- If local execution is blocked by environment/tooling, provide exact unblock steps and mark status as pending.

Return:
- go/no-go recommendation with rationale
- blocker list (P0/P1) with owners and next actions
- launch-day action list
- completed evidence index (what file/report was updated for each gate)
```

## 08 - Post-Launch Stabilization (Week 1-2)

```text
Implement immediate post-launch stabilization for DartsScoreboard 1.0.x.

Read first:
- roadmap/07-rc-launch-and-post-launch.md
- roadmap/release/Launch-Day-Runbook.md
- roadmap/release/Rollback-and-Hotfix-Criteria.md
- roadmap/release/Release-Notes-Template.md
- roadmap/reports/Phase07-RC-Launch-Readiness-Report.md
- roadmap/reports/Phase06-Performance-Report.md
- roadmap/reports/Phase06-Security-Privacy-Checklist.md
- specs/ReleaseOpsSpec.md
- specs/AppStoreConnectSpec.md

Context to honor:
- Do not widen scope beyond 1.0.x stabilization.
- Preserve local-first/no-ads/no-IAP constraints for 1.0.x.
- No Firebase runtime dependency introduction.

Implement/verify:
1) Build a ranked 1.0.x patch backlog from confirmed launch/RC findings (P0/P1/P2 with owner + risk + user impact).
2) Create a daily launch-week operations log template and initialize Day-0/Day-1 entries.
3) Finalize hotfix decision protocol run sheet (rollback vs hotfix) with ownership and timing SLA.
4) Prepare `1.0.1` release notes draft from confirmed fixes only (no speculative claims).
5) Record unresolved evidence gaps and explicit closure plan with target dates.

Check:
- no unresolved P0 without owner and immediate action
- each planned patch maps to a validated issue, not speculation
- release notes remain truthful to implemented behavior

Important:
- Do not claim incidents, metrics, or user reports that were not observed.
- If no live telemetry/review data exists yet, mark related sections as pending and define exact collection steps.

Return:
- prioritized 1.0.x patch board
- launch-week monitoring template + initialized entries
- hotfix readiness status
- recommended next query (Phase 09 or roadmap closure)
```
