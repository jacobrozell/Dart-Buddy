# Call & Hit — Data Schema Supplement

## 1. Purpose
Register SwiftData entities and migration notes for Call & Hit when promoting from planned → shipped. Authoritative migration policy: [`SwiftData.md`](../../SwiftData.md).

**Parent spec:** [`CallAndHitGameSpec.md`](CallAndHitGameSpec.md)  
**Status:** Planned

---

## 2. MatchType extension

```swift
// MatchType (conceptual)
case callAndHit = "callAndHit"
```

Register in:
- `MatchRecord.type` enum / raw storage
- `GameModeCatalog` entry `practice.callAndHit` → `.shipped` + `matchType: .callAndHit`
- `GameplayUITemplate.voiceDrill` (Template J)
- `ModeStatKind.practiceAccuracy`
- `ProductSurface.isMatchTypeReachable` when feature flag on
- `GameRulesCatalog`, `GameModeAccent`, history filters

---

## 3. Config payload

**Type:** `MatchConfigCallAndHit`  
**Envelope:** existing versioned `configPayload` on `MatchRecord` (same pattern as X01/Cricket).

| Field | Type | Notes |
|-------|------|-------|
| `version` | Int | `1` |
| `targetCount` | Int | 25, 50, or 100 |
| `dartsPerTarget` | Int | 1, 2, or 3 |
| `targetKind` | String | `single`, `double`, `triple` |
| `includeBull` | Bool | |
| `sessionPreset` | String? | `standard`, `sharp`, `blitz`, … |
| `calloutVoiceId` | String? | |
| `calloutsEnabled` | Bool | |

---

## 4. Snapshot payload

**Type:** `CallAndHitSnapshot` v1 — embedded in `MatchSnapshotRecord.snapshotPayload`.

| Field | Purpose |
|-------|---------|
| `targets` | Full ordered target sequence |
| `currentIndex` | Resume pointer |
| `results` | Parallel hit/miss outcomes |
| `longestHitStreakSoFar` | Denormalized for UI |

---

## 5. Events

**Table:** `CallAndHitTargetEventRecord` (name TBD — follow existing `*Event` naming)

| Column | Type |
|--------|------|
| `id` | UUID |
| `matchId` | UUID |
| `sequenceIndex` | Int |
| `targetKind` | String |
| `segment` | Int (1–20; 25 = bull) |
| `dartsAllowed` | Int |
| `outcome` | String (`hit`, `miss`) |
| `recordedAt` | Date |

Append-only; undo deletes last event row + rewinds snapshot (same pattern as other modes).

---

## 6. History card payload

Extend `MatchHistoryCardPayload` **version 2** (or mode-specific branch in v1 builder) with Call & Hit fields — see [`CallAndHitStatsSupplement.md`](CallAndHitStatsSupplement.md) §8.

---

## 7. Delete / reset inventory

Add to [`DeleteAllDataSpec.md`](../../DeleteAllDataSpec.md) §6 when shipping:
- `CallAndHitTargetEventRecord` (or equivalent)
- Recompute clears `practice.callAndHit` aggregates from `PlayerModeAggregate`

---

## 8. Migration bump checklist

1. Increment schema version in `SwiftData.md`
2. Lightweight migration or custom stage for new event entity
3. `RepositoryContractTests` + migration safety report row
4. No backfill required (new mode only)

---

## 9. Verification
| Field | Value |
|-------|--------|
| **Status** | Planned |
