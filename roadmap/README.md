# Roadmap

**Status:** 1.0 MVP implementation complete. Remaining work is QA evidence and App Store ops — see [`docs/release/todo.md`](../docs/release/todo.md).

## Active release artifacts

| Doc | Role |
|-----|------|
| [`docs/release/todo.md`](../docs/release/todo.md) | Current sprint and ship blockers |
| [`docs/release/release_checklist.md`](../docs/release/release_checklist.md) | **Master runbook** — device QA, App Store, Reddit launch |
| [`roadmap/release/QA-Signoff-RC1.md`](release/QA-Signoff-RC1.md) | RC Go/No-Go matrix and evidence |
| [`roadmap/release/Launch-Day-Runbook.md`](release/Launch-Day-Runbook.md) | Launch-day ops |
| [`roadmap/release/Rollback-and-Hotfix-Criteria.md`](release/Rollback-and-Hotfix-Criteria.md) | Hotfix gates |
| [`roadmap/reports/`](reports/) | Phase 06–07 execution evidence (migration, privacy, performance) |
| [`specs/ReleaseGateChecklist.md`](../specs/ReleaseGateChecklist.md) | ~10 min pre-tag gate |
| [`specs/SmokeTestChecklist.md`](../specs/SmokeTestChecklist.md) | ~20 min smoke pass |

## Scope (shipped in 1.0)

Local-first iOS app: X01 + Cricket (Normal and Cut Throat, including bot matches with Points On), Training Partner bots, players, **Statistics**, history, settings, migration recovery, UI localization (`en` / `de` / `es` / `nl` via system locale), Release-only Firebase Analytics + Crashlytics (see `specs/FirebaseBackendAnalyticsSpec.md`).

**Deferred post-1.0:** online play, Apple Watch companion, vision auto-scoring, Firebase Auth/Firestore, full UI automation matrix.

## Historical planning

Phase plans, agent kickoff brief, and one-time audits live in [`roadmap/archive/`](archive/README.md).

Spec-to-phase mapping (historical): [`roadmap/SPEC-TO-PHASE-MAPPING.md`](SPEC-TO-PHASE-MAPPING.md).
