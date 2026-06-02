# Agent Kickoff Brief (Read Before Coding)

Purpose: prevent retroactive architecture fixes by forcing shared context intake before any feature implementation.

## Mandatory Read Set (in order)
1. `specs/README.md`
2. `specs/SpecGovernance.md`
3. `specs/ArchitectureSpec.md`
4. `specs/TechStackSpec.md`
5. `specs/SwiftData.md`
6. `specs/DataSchemaSpec.md`
7. `specs/RepositorySpec.md`
8. `specs/LoggingSpec.md`
9. `specs/ErrorModelSpec.md`
10. `specs/UIBlueprintSpec.md`
11. `specs/UIImplementationSpec.md`
12. `specs/archive/FigmaBuildPlan.md` (guidance only; archived)

## Non-Negotiables to Establish Early
- **SwiftData versioning from day one**
  - `SchemaV1` explicit baseline.
  - Migration plan scaffold in place before feature tables grow.
  - Container factory centralized (runtime/tests/previews use same path).
- **Custom logger from day one**
  - `AppLogger` abstraction only; no scattered `print`.
  - Console sink and redaction policy live before broad feature work.
  - Key lifecycle categories wired early: persistence, migration, scoring, settings/reset.
- **Repository boundaries before UI feature scale**
  - No direct SwiftData access from views.
  - Repositories return typed DTOs/errors.
- **Error and localization discipline**
  - User-visible failures map from typed errors to localization keys.

## Implementation Order Guardrail
- Do not start large screen implementation until Phase 01 foundations are in place.
- If a feature requires changing persistence contracts, update schema/versioning/migration and tests in the same change window.

## Figma Use Rule
- Use Figma as a visual guideline where accurate.
- Do not treat Figma as canonical behavior source when incomplete or inconsistent.
- If there is conflict, authoritative written specs win.

## Pre-Implementation Checklist (must pass)
- [ ] Mandatory read set completed.
- [ ] SwiftData versioning baseline and migration scaffolding created.
- [ ] Custom logger abstraction + console sink integrated.
- [ ] Repository interfaces in place for targeted feature area.
- [ ] Typed error mapping + localization key path confirmed.
- [ ] Feature spec and UI contract references identified for the task.
