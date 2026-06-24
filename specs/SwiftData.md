# SwiftData Versioning Specification

## 1. Purpose
Define a long-term, low-risk SwiftData versioning and migration strategy from v1.0.0 onward so schema changes remain safe, testable, and reversible in practice.

---

## 2. Goals and Non-Goals

### Goals
- Ship v1 with explicit versioning (no implicit "unversioned" baseline).
- Support additive and breaking schema changes through repeatable migration stages.
- Preserve user match history and in-progress match integrity across app updates.
- Keep migration code understandable for future contributors.

### Non-Goals (MVP)
- Cloud sync conflict resolution.
- Cross-platform shared persistence layer outside iOS/macOS SwiftData.
- Encryption-at-rest custom layer (defer until compliance requires it).

---

## 3. High-Level Strategy
- Use `VersionedSchema` from day one, starting at `SchemaV1`.
- All model changes must land in a **new schema version** (`SchemaV2`, `SchemaV3`, ...).
- Define a single `SchemaMigrationPlan` that includes every adjacent stage (`V1 -> V2`, `V2 -> V3`, ...).
- Prefer lightweight migrations for additive changes.
- Use custom migration stages for:
  - rename or split/merge fields
  - enum/raw value changes
  - relationship cardinality changes
  - data normalization/backfill
  - deleting columns/tables that still contain meaningful data

---

## 4. Versioning Policy

### App Version vs Schema Version
- App release uses semantic versioning (`1.2.0`, `2.0.0`).
- Persistence uses monotonic integer schema versions (`V1`, `V2`, `V3`).
- A single app version may introduce at most one schema version bump unless required by emergency fixes.

### Compatibility Rules
- New app must migrate from any previously supported schema listed in migration plan.
- App must fail fast if store version is newer than bundled schema (no automatic downgrade).
- Never remove migration stages that are still needed by supported upgrade paths.

### Deprecation Window
- Keep migration support for at least last 2 major app lines or 18 months (whichever is longer).

---

## 5. Initial Baseline (SchemaV1)

Create explicit baseline schema immediately, even before first App Store release.

### V1 Entities (minimum)
- `PlayerRecord`
  - `id: UUID`
  - `name: String`
  - `isArchived: Bool`
  - `createdAt: Date`
  - `updatedAt: Date`

- `MatchRecord`
  - `id: UUID`
  - `typeRaw: String` (`x01`, `cricket`)
  - `statusRaw: String` (`notStarted`, `inProgress`, `completed`, `abandoned`)
  - `startedAt: Date`
  - `endedAt: Date?`
  - `winnerPlayerId: UUID?`
  - `configPayload: Data` (versioned, codable payload)
  - `currentTurnPlayerId: UUID?`
  - `currentLegIndex: Int`
  - `currentSetIndex: Int`
  - `eventCount: Int`
  - `createdAt: Date`
  - `updatedAt: Date`

- `MatchParticipantRecord`
  - `id: UUID`
  - `matchId: UUID`
  - `playerId: UUID?` (nullable for deleted/archived edge safety)
  - `turnOrder: Int`
  - `displayNameAtMatchStart: String`
  - `avatarStyleAtMatchStart: String?`

- `MatchSnapshotRecord`
  - `id: UUID`
  - `matchId: UUID`
  - `snapshotVersion: Int`
  - `snapshotPayload: Data`
  - `updatedAt: Date`

- `MatchEventRecord`
  - `id: UUID`
  - `matchId: UUID`
  - `eventIndex: Int` (strict monotonic per match)
  - `eventTypeRaw: String`
  - `eventPayload: Data`
  - `createdAt: Date`

- `SettingsRecord` (or `AppStorage` in MVP with migration bridge)
  - `id: UUID`
  - `appearanceModeRaw: String`
  - `hapticsEnabled: Bool`
  - `soundEnabled: Bool`
  - `defaultMatchTypeRaw: String`
  - `defaultX01StartScore: Int`
  - `defaultCheckoutModeRaw: String`
  - `defaultLegsToWin: Int`
  - `defaultSetsEnabled: Bool`
  - `updatedAt: Date`

Implementation note:
- Persist enums as explicit raw strings to reduce migration fragility.
- Store complex game state in versioned payloads (`configPayload`, `eventPayload`, `snapshotPayload`) with their own `payloadVersion`.

---

## 6. Required Project Structure

Recommended file layout:
- `Persistence/Schemas/SchemaV1.swift`
- `Persistence/Schemas/SchemaV2.swift` (future)
- `Persistence/Migrations/DartsMigrationPlan.swift`
- `Persistence/ModelContainerFactory.swift`
- `Persistence/PayloadCoders/*.swift`

### Baseline Migration Types
- `enum SchemaV1: VersionedSchema`
- `enum DartsMigrationPlan: SchemaMigrationPlan`
- `ModelContainer` built with:
  - all schema versions
  - migration plan
  - explicit store URL
  - predictable config for app + tests

---

## 7. Migration Design Rules (Must Follow)

### 7.1 Additive Changes (Lightweight)
Allowed without custom logic:
- add optional property
- add new model with no required backfill on existing models
- add relationship that can be nil initially

### 7.2 Breaking Changes (Custom Stage Required)
Requires explicit migration code:
- rename property/model
- make optional property required
- change raw enum values
- split one field into multiple fields
- merge fields
- change relationship delete rules or uniqueness assumptions

### 7.3 Data Integrity Invariants
Must hold after any migration:
- `MatchEventRecord.eventIndex` remains contiguous per `matchId`.
- Completed matches keep immutable summary fields.
- In-progress matches remain resumable from latest valid snapshot + events.
- Participant display snapshot remains readable even if linked player removed.
- No orphan records for known hard references (`matchId` ownership chain).

---

## 8. Payload Versioning (Inside Data Blobs)

Because match config/events are stored as `Data`, payload versioning is mandatory.

Each payload must include:
- `payloadVersion: Int`
- stable top-level keys
- backward decoding path (at least N-1)

Rules:
- Never reuse payload version numbers.
- If decoding old payload fails, attempt targeted repair transform once.
- If still failing, mark record recoverable-corrupt and keep non-destructive fallback UI.

---

## 9. Container Boot and Failure Handling

Startup sequence (`AppBootstrapper` → `BootstrapStoreRecovery`):

1. Build container with migration plan.
2. Attempt migration on launch in foreground-safe path.
3. On success, run lightweight post-migration validation checks (event index repair).
4. On open/migration failure:
   - log structured fault telemetry (`bootstrap_store_open_failed`, `bootstrap_store_recreated`, etc.)
   - backup SQLite store when possible (`bootstrap_store_backed_up`)
   - recreate store and continue bootstrap — **no blocking recovery UI**
5. If recreation fails, fall back to in-memory container so the app remains launchable.

Hard rules:
- Never silently wipe a store without logging and backup attempt.
- User-initiated full wipe is Settings → **Reset All Local Data** only — see [`DeleteAllDataSpec.md`](DeleteAllDataSpec.md).

Implementation: `Persistence/BootstrapStoreRecovery.swift`.

---

## 10. Implementation Blueprint (for Next Agent)

### Step 1 - Define SchemaV1
- Add `VersionedSchema` with explicit `versionIdentifier`.
- Move all persisted models into nested `SchemaV1` model types.

### Step 2 - Define Migration Plan
- Add `DartsMigrationPlan.schemas = [SchemaV1.self]` initially.
- Add placeholder for future stages with comments and checklist.

### Step 3 - Container Factory
- Centralize container creation in one factory type.
- Ensure all app entry points (previews/tests/runtime) use the factory.

### Step 4 - Seed + Validation
- Seed defaults (settings) only when no existing record.
- Add post-launch validator for core invariants.

### Step 5 - Test Harness
- Build migration test helper that:
  - creates store at older schema
  - injects representative fixtures
  - opens with newer schema + plan
  - verifies invariants

---

## 11. Testing Strategy

## Unit (Swift Testing)
- Payload encode/decode for each payload version.
- Event index continuity validator.
- Default settings seeding idempotency.

## Migration Integration (Swift Testing)
- `V1 -> V2` lightweight case.
- `V1 -> V2` custom transformation case.
- Corrupt payload fallback path does not crash and preserves readable history metadata.

## Future UI/End-to-End (XCUITest, post-UI-lock)
- App upgrade simulation with preloaded old store.
- In-progress match resumes after migration.
- Completed history list remains visible and ordered.

---

## 12. Operational Guardrails
- Add migration duration metric and success/failure counters.
- Log old schema -> new schema pair for every migration run.
- Alert on repeated migration failures for same app version.
- Include "store schema version" in bug report diagnostics.

---

## 13. PR Checklist for Any Schema Change
- Added new `SchemaVx` file.
- Updated `DartsMigrationPlan.schemas`.
- Added adjacent migration stage.
- Added/updated migration tests with realistic fixtures.
- Verified invariants pass after migration.
- Documented payload version bumps (if any).
- Added release note entry for persistence changes.

---

## 14. Future Enhancements
- Optional iCloud/CloudKit sync with conflict policy by entity type.
- Background migration preflight on app update.
- Store compaction/cleanup policy for old snapshots/events.
- Formal data export/import format with schema manifest.

---

## 15. Schema 1.0.0 Freeze (Dart Buddy)

**Ship baseline:** `SchemaV2` (`Schema.Version(2, 2, 0)`), wired in `ModelContainerFactory` and `Persistence/SchemaLock.swift`.

**Platform:** iOS **18.0+** deployment target (`project.yml`) — required for SwiftData `#Index` on hot query fields.

**Supported upgrade path at launch:** `SchemaV1` → `SchemaV2_0_0` → `SchemaV2_1_0` → `SchemaV2` via `DartsMigrationPlan` (custom bot-kind backfill + lightweight column/index adds).

### Frozen at 1.0 (do not change in place)

| Entity | Notes |
|--------|--------|
| `PlayerRecord` | Includes `botKindRaw`, `linkedPlayerId`, optional `playerRoleRaw` (campaign) |
| `MatchRecord` | Includes `historyCardPayload`, `isCampaignMatch`, `campaignStageId` (2.2.0); `#Index` on status/dates/type |
| `MatchParticipantRecord` | Includes `botKindRaw`, `botSkillProfilePayload` |
| `MatchSnapshotRecord` | Unchanged since V1 |
| `MatchEventRecord` | Unchanged since V1 |
| `SettingsRecord` | `botStaggerEnabled` / `botDartHapticsEnabled` stay **optional**; repository maps `nil` → `true` |

### Intentionally optional / runtime-defaulted

- Bot-related raw fields on players and participants (preset kind inferred when difficulty present).
- Settings bot toggles (legacy stores without columns).
- `playerId` on participants (history survives player delete/archive).

### Deferred past 1.0 (not in SwiftData schema)

- `PlayerDailyAggregateRecord`, `PlayerModeAggregateRecord` (`specs/DataSchemaSpec.md` §2).
- Cloud sync, encryption-at-rest, aggregate cache tables.

### Payload versions (separate from schema version)

| Blob | Current version | Location |
|------|-----------------|----------|
| X01 config | `1` | `MatchConfigX01.payloadVersion` |
| Cricket config | `2` | `MatchConfigCricket.currentPayloadVersion` |
| Baseball config | `1` | `MatchConfigBaseball.currentPayloadVersion` |
| Match snapshot wrapper | `1` | `MatchLifecycleModels` |
| History list card | `1` | `MatchHistoryCardPayload.currentPayloadVersion` |
| Event payloads | per `eventTypeRaw` | engines + coders |

Payload bumps do **not** require `SchemaV3` unless new **columns** or **models** are added.

### Pre-release checklist (schema freeze)

- [ ] No open `SchemaV3` work; all 1.0 fields live in `SchemaV2.swift`.
- [ ] `DartsMigrationPlan` includes every schema still needed for upgrade (`V1`, `V2`).
- [ ] `Tests/Unit/SchemaV1ToV2MigrationTests.swift` passes (serialized suite).
- [ ] Device migration smoke logged in `roadmap/reports/Phase06-Migration-Safety-Report.md`.
- [ ] Release notes mention persistence only if beta users had pre-V2 builds.

### After 1.0 ships

Any column rename, required-field promotion, or new entity → add `SchemaV3.swift`, register in `DartsMigrationPlan`, add `V2 → V3` stage + tests. Never edit `SchemaV2` types in place for shipped users.
