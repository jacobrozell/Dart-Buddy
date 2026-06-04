# Data Schema Specification

## 1. Purpose
Define canonical persisted entities, relationships, and invariants for app features.

This spec complements `specs/SwiftData.md` (versioning/migration policy).

---

## 2. Canonical Entities

**1.0 ship baseline:** `SchemaV2` in `Persistence/Schemas/SchemaV2.swift` (see `specs/SwiftData.md` §15).

- `PlayerRecord` — bot fields: `botKindRaw`, `linkedPlayerId` (training partner)
- `MatchRecord`
- `MatchParticipantRecord` — bot fields: `botKindRaw`, `botSkillProfilePayload`
- `MatchSnapshotRecord`
- `MatchEventRecord`
- `SettingsRecord` — bot prefs: `botStaggerEnabled?`, `botDartHapticsEnabled?`

**Post-1.0 only** (not in 1.0 schema):

- `PlayerDailyAggregateRecord`
- `PlayerModeAggregateRecord`

---

## 3. Entity Ownership
- `MatchRecord` owns participants, snapshots, and events via `matchId`.
- `PlayerRecord` is referenced by participants/events but history must survive player archiving/deletion.
- Snapshot display fields on participants are required for stable history rendering.

---

## 4. Invariants
- Event index is contiguous and monotonic per match.
- Completed match has `endedAt` and winner metadata.
- In-progress match has valid current-turn pointers.
- Match data remains readable even with missing player foreign references.

---

## 5. Payload Rules
- Config/snapshot/event blobs must include `payloadVersion`.
- Payload decoders must support at least previous version.
- Unknown payload versions fail gracefully with recoverable UI messaging.
- Reserve optional metadata keys now for future multi-device inputs:
  - `originDeviceType` (`iphone`, `watch`)
  - `originDeviceSessionId`

---

## 6. Deletion and Retention
- Player hard delete blocked when referenced by history.
- Archiving preferred over deleting identities.
- Match/event data immutable after completion.
- Settings reset can wipe all local data only after explicit confirmation.

---

## 7. Indexing and Performance
- Index by `matchId`, `playerId`, `statusRaw`, `startedAt`, `endedAt`.
- Keep history list fields denormalized on match for quick list rendering.

---

## 8. Testing
- Invariant validator tests
- Contiguous event index tests
- Payload compatibility tests across versions
