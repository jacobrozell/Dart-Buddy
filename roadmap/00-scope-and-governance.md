# Phase 00 - Scope and Governance Lock

## Objective
Lock what `1.0.0` means, remove ambiguity between specs, and define non-negotiable release gates before implementation acceleration.

## Specs Anchored
- `specs/README.md`
- `specs/SpecGovernance.md`
- `specs/TechStackSpec.md`
- `specs/FeatureFlagConfigSpec.md`
- `specs/ErrorModelSpec.md`
- `specs/FigmaBuildPlan.md`
- `specs/UIBlueprintSpec.md`

## Batch Workstreams
- **PM/Architecture lane**
  - Freeze `1.0.0` scope using spec baselines.
  - Record out-of-scope list (online/watch/vision/Firebase runtime).
  - Confirm module boundaries and dependency rules are accepted.
  - Establish UI fidelity rule: implementation should consider Figma documentation/mockups as guidance where accurate, but not as sole source of truth.
  - Publish explicit tie-break policy: authoritative specs win on conflicts; Figma artifacts are then reconciled.
- **Platform lane**
  - Confirm zero required runtime external SPM dependencies for `1.0.0`.
  - Create feature flag registry with all future capabilities disabled by default.
  - Confirm canonical error model and localization-key-based user messaging.
- **QA lane**
  - Establish release gate checklist references and ownership map.

## Deliverables
- `1.0.0` scope memo in repo docs.
- Accepted release gate checklist owner matrix.
- Flag default matrix by `Debug` / `Staging` / `Release`.
- UI guidance note defining how Figma artifacts are consumed during implementation and review.
- Manual verification operating model note (no CI/CD dependency during current execution window).
- `roadmap/AGENT-KICKOFF-BRIEF.md` reviewed and accepted as required pre-coding context.

## Exit Criteria
- No unresolved spec conflicts in authoritative files.
- `1.0.0` scope is explicitly signed off with a deferred list.
- Team agrees on common definitions for `critical`, `regression`, and release blockers.
- Starting agents confirm kickoff brief completion before coding.
