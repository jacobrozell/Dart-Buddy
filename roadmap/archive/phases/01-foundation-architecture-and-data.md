# Phase 01 - Foundation: Architecture, Persistence, and Platform Core

## Objective
Build the production skeleton so all feature agents can ship without refactors: app shell boot, schema/versioning, repositories, logging, settings seed, and migration safety.

## Specs Anchored
- `specs/ArchitectureSpec.md`
- `specs/AppShellSpec.md`
- `specs/SwiftData.md`
- `specs/DataSchemaSpec.md`
- `specs/RepositorySpec.md`
- `specs/LoggingSpec.md`
- `specs/SecurityPrivacySpec.md`

## Batch Workstreams
- **Data lane**
  - Implement explicit `SchemaV1` + migration plan + container factory.
  - Implement canonical entities and invariants (`eventIndex`, snapshot safety, immutable completed matches).
  - Add migration boot failure recovery contract hooks.
- **Repository lane**
  - Implement `PlayerRepository`, `MatchRepository`, `StatsRepository`, `SettingsRepository` contracts.
  - Enforce typed errors and no SwiftData model leakage into feature layers.
- **App core lane**
  - Wire app startup sequence (container, defaults seed, settings resolution).
  - Implement console-first structured logging with redaction policy.
  - Add global migration recovery route support.

## Deliverables
- Production-ready persistence layer with deterministic migration path.
- Repository test doubles/in-memory adapters for feature tests.
- App logger abstraction and day-1 console sink integrated at core lifecycle points.

## Exit Criteria
- Migration smoke from previous local store passes.
- No direct SwiftData usage from views.
- Invariant tests pass for schema and repository contracts.
- Recovery path exists for migration failure (retry/export/reset).
