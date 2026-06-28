# Phase 06 Migration Safety Report

## Scope
- Validate schema/version baseline and bootstrap store recovery readiness.

## Current Baseline
- **`SchemaV1`** frozen at App Store **1.0.0** ship (`Schema.Version(1, 0, 0)`).
- **`SchemaV2`** for **1.1.0** — adds optional `instantBotTurnsEnabled` on `SettingsRecord`.
- **`DartsMigrationPlan`** — lightweight `V1 → V2` stage + CI disk-backed migration test.
- `ModelContainerFactory` opens at V2 with migration plan.
- `BootstrapStoreRecovery` handles open/migration failures at launch (no blocking recovery UI).

## Validation Evidence
- `SchemaV1ToV2MigrationTests` — V1 fixture store migrates to V2; settings preserved; `instantBotTurnsEnabled` defaults false.
- `SchemaV2BaselineTests` — fresh V2 store round-trip.
- Settings nil-default tests (`SettingsRecordMigrationTests`).
- Manual bootstrap store recovery smoke: **Pending local run**.
- Manual **1.0 App Store → 1.1 RC** upgrade on device: **Pending** (see [`1.1.0-ship-checklist.md`](../../docs/release/1.1.0-ship-checklist.md) §2).

## Recovery Behavior
- Open failure: backup (when possible), delete store, recreate container, continue bootstrap.
- Invariant repair failure: same recreation path.
- Exhausted recovery: in-memory fallback container so the app remains launchable.
- User-initiated full wipe: Settings → Reset All Local Data only.

## Risk Notes
- Automatic recreation loses local data when the store cannot be opened; faults are logged for observability.
- Never edit `SchemaV1.swift` after the `1.0.0` tag — all post-ship changes use new schema versions.

## Status
- Architecture readiness: **Pass** (V1 frozen + V2 migration wired)
- Operational execution readiness: **Partial** (manual upgrade + corrupt-store smoke still pending)

**Last updated:** 2026-06-27
