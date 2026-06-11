# Player Export / Import Specification (DBPE)

## 1. Purpose

Define **Dart Buddy Player Export (DBPE) v1** — a versioned, import-ready JSON bundle for sharing a player's identity, referenced players, and full completed match history.

Export is user-initiated only (see `specs/SecurityPrivacySpec.md` §3). Import UI and write paths are deferred; this spec defines the canonical format so export and future import stay aligned.

---

## 2. Format

| Property | Value |
|----------|-------|
| Name | Dart Buddy Player Export (DBPE) |
| Version | `1` (`dbpeVersion`) |
| Encoding | UTF-8 JSON |
| File extension | `.dartbuddy.json` |
| MIME type | `application/json` |
| Key ordering | Sorted keys (deterministic export) |
| Dates | ISO-8601 UTC (`exportedAt`, entity timestamps) |

---

## 3. Top-level envelope

| Field | Required | Type | Notes |
|-------|----------|------|-------|
| `dbpeVersion` | yes | `Int` | Format version; **1** only for now |
| `producer` | yes | `String` | Exporter bundle ID, e.g. `com.jacobrozell.DartBuddy` |
| `producerVersion` | yes | `String` | App semver at export time |
| `exportedAt` | yes | `String` | ISO-8601 UTC timestamp |
| `persistenceSchemaVersion` | yes | `String` | SwiftData schema version, e.g. `2.0.0` |
| `anchorPlayerId` | yes | `UUID` | Player whose history is exported |
| `player` | yes | `PlayerExportRecord` | Anchor player identity |
| `referencedPlayers` | yes | `[PlayerExportRecord]` | Other identities referenced by match participants |
| `matches` | yes | `[MatchExportBundle]` | Complete match bundles (may be empty) |

---

## 4. `PlayerExportRecord`

Mirrors `PlayerSummary` (`Domain/Models/RepositoryModels.swift`):

| Field | Type |
|-------|------|
| `id` | `UUID` |
| `name` | `String` |
| `isArchived` | `Bool` |
| `isBot` | `Bool` |
| `botDifficultyRaw` | `String?` |
| `botKindRaw` | `String?` |
| `linkedPlayerId` | `UUID?` |
| `avatarStyleRaw` | `String?` |
| `preferredColorToken` | `String?` |
| `notes` | `String?` |
| `createdAt` | `String` (ISO-8601) |
| `updatedAt` | `String` (ISO-8601) |

---

## 5. `MatchExportBundle`

Each completed match where `anchorPlayerId` is a participant. Exports the **full match**, not anchor-only turns.

| Field | Type | Source |
|-------|------|--------|
| `match` | `MatchExportRecord` | All `MatchSummary` fields |
| `configPayload` | `String?` | Base64 of `MatchRecord.configPayload` |
| `participants` | `[MatchParticipantExportRecord]` | All participants for the match |
| `events` | `[MatchEventExportRecord]` | All events, ordered by `eventIndex` |
| `snapshot` | `MatchSnapshotExportRecord?` | Latest snapshot or `null` |

Nested record shapes mirror `MatchSummary`, `MatchParticipantSummary`, `MatchEventSummary`, and `MatchSnapshotSummary`. Binary fields (`configPayload`, `eventPayload`, `snapshotPayload`, `botSkillProfilePayload`) are base64 strings in JSON.

Inner blob semantics follow `specs/DataSchemaSpec.md` §5 (`payloadVersion` inside decoded payloads).

---

## 6. Export invariants

Enforced at export time and re-validated on import:

1. Only `status == completed` matches are included.
2. Event indices are contiguous `0..<N` per match.
3. All participants for each exported match are included (multi-player integrity).
4. `anchorPlayerId` appears in at least one participant row for every match (implicit via export filter).
5. `referencedPlayers` excludes the anchor; includes every distinct `playerId` from participants that resolves to a known player record.

---

## 7. Validation (`PlayerExportValidator`)

Structural checks (no payload decoding):

| Rule | Failure |
|------|---------|
| Unknown `dbpeVersion` | Reject — user key `players.detail.export.error` |
| Missing required envelope fields | Reject |
| Anchor `player.id` ≠ `anchorPlayerId` | Reject |
| Any match `status != completed` | Reject |
| Event indices not contiguous | Reject |
| Empty `participants` on a match | Reject |

Unknown `dbpeVersion` must never be silently imported.

---

## 8. Third-party import policy (v1)

- Accept files **only** if `dbpeVersion` is supported and structural validation passes.
- `producer` is informational — not a whitelist gate in v1.
- Partial, ad-hoc CSV/JSON is rejected.
- Apps emitting DBPE v1 verbatim are compatible.

---

## 9. Future import (out of scope)

Documented for format design; not implemented in the export-only pass:

- **Import UI** — file picker, preview, confirm
- **`PlayerImportService`** — insert matches preserving UUIDs, player ID remapping, active-match conflict handling
- **Repository import APIs** — e.g. `importCompletedMatch(bundle:)` transactional write
- **UUID collision strategy** — skip-existing vs merge (TBD)
- **CSV summary export** — optional human-readable derivative from the same bundle

---

## 10. Testing

- Unit: bundle encode/decode round-trip, validator edge cases
- Integration: export seeded demo player includes all participants and events
- UI: `playerDetail_export` accessibility identifier present on human player detail

---

## 11. Verification
| Field | Value |
|-------|--------|
| **Last verified** | 2026-06-11 |
| **Commit** | `340f788` |
| **Code** | `PlayerExportService.swift`, `PlayerDetailView.swift` |

---

## 12. Related specs

- [`PlayerSpec.md`](PlayerSpec.md) — player detail UI, export entry point
- [`SecurityPrivacySpec.md`](SecurityPrivacySpec.md) §3 — user-initiated export policy
