**Estimated release:** `1.0`

# Custom Bot Specification

## 1. Purpose

Define **user-defined custom bots**: persistence, skill resolution across game-mode templates, match-start snapshots, and UI (simple + advanced). Preset bots remain in [`BotOpponentSpec.md`](BotOpponentSpec.md). Training Partner bots remain in [`TrainingBotSpec.md`](TrainingBotSpec.md).

**Implementation roadmap:** [`docs/plans/custom-bot-architecture-ui-plan.md`](../docs/plans/custom-bot-architecture-ui-plan.md)

---

## 2. MVP scope (1.0.0 — shipped direction)

### In scope

- Create custom bot from Play setup or Players → Add Bot
- **Simple configuration:** X01 3-dart average + Cricket MPR sliders
- Roster, badge, detail, edit name/avatar/color/notes
- X01 and Cricket matches (Normal + Cut Throat when Points On)
- `ProductSurface.showsCustomBots = true` in lean 1.0
- Skill resolution via `CustomBotSkillResolver` → `BotSkillProfile` snapshot at match start
- Engine: `DartBotEngine` profile-based generators (same as preset/training)

### Out of scope (1.0.0)

- Advanced per-stat facet editors (Phase B–C of architecture plan)
- Training Partner (separate spec; hidden in lean 1.0)
- Custom bots in Killer (preset-only validation remains)
- Share/import bot builds
- Mid-match skill changes

---

## 3. Bot kind

| Field | Value |
|-------|--------|
| `botKindRaw` | `custom` |
| Skill at match start | `botSkillProfilePayload` = `CustomBotSkillSnapshot` JSON |
| `botDifficultyRaw` | Encoded `CustomBotConfiguration` (v1: `custom:{x01}:{mpr}`) |

At match start: `botDifficultyRaw` on participant is **nil**; profile lives in payload snapshot.

---

## 4. Configuration (target model)

See architecture plan §5.4. Summary:

```swift
struct CustomBotConfiguration {
    var schemaVersion: Int
    var x01Average: Double       // 5…110
    var cricketMPR: Double       // 0.2…5.0
    var explicitProfile: BotSkillProfile?  // Advanced; nil = derive
    var scoringBehaviorTier: BotDifficulty? // optional anchor
}
```

**Canonical profile:** explicit profile, or merge of X01-interpolated and Cricket-interpolated slices (see plan).

### Encoding v1 (current)

```
custom:{x01Average}:{cricketMPR}
```

Example: `custom:30.0:1.25`

---

## 5. Skill resolution

### 5.1 Context

Resolution uses **`GameplayUITemplate`** from the mode catalog entry, not a per-mode switch (target — Phase A).

```swift
struct BotPlayContext {
    let matchType: MatchType
    let uiTemplate: GameplayUITemplate
}
```

### 5.2 Template policy (v1)

All templates receive the **same canonical** `BotSkillProfile` from configuration. `DartBotEngine` reads mode-appropriate slices (X01 checkout vs cricket marks vs baseball aim).

| Template | Shipped examples | Generator |
|----------|------------------|-----------|
| `checkoutScore` | X01 | `generateX01Turn` |
| `markBoard` | Cricket | `generateCricketTurn` |
| `inningPoints` | Baseball, Shanghai | `generateBaseballTurn` / `generateShanghaiTurn` |
| `livesElimination` | Killer | `generateKillerPick` / `generateKillerTurn` |

**Forward compatibility:** Custom bots created under v1 metrics must work in templates added later without migration.

### 5.3 Current implementation (pre–Phase A)

`CustomBotSkillResolver.profile(for: MatchType, metrics:)`:

- `.x01` → interpolate from `x01Average`
- `.cricket` → interpolate from `cricketMPR`
- `.baseball`, `.killer`, `.shanghai` → interpolate from `x01Average`

---

## 6. UI

### 6.1 Simple (1.0)

| Surface | Behavior |
|---------|----------|
| `CustomBotCreationSheet` | Name + two sliders |
| `CustomBotDetailView` | Edit sliders + read-only `BotDifficultyStatsSection` |
| `CustomBotBadge` | `Avg {x01} · {mpr} MPR` |

### 6.2 Advanced (planned)

- Segmented Simple / Advanced on detail only (not create sheet v1)
- Facet editors: `X01SkillFacet`, `CricketSkillFacet`, `AimSkillFacet`
- Preset anchor picker; reset to simple / reset to preset
- Footer: compatible templates list

---

## 7. Validation

| Rule | Key |
|------|-----|
| At least one human in match | `setup.validation.requiresHuman` |
| Cricket Points Off + any bot | `setup.validation.cricketBotUnsupported` |
| Killer + custom/training bot | `setup.validation.killerBotsPresetOnly` |
| Baseball/Shanghai + custom (party) | `setup.validation.baseballBotsPresetOnly` / `shanghaiBotsPresetOnly` when party shipped |

Lean 1.0: party modes hidden; X01/Cricket custom bots allowed.

---

## 8. Persistence

- `PlayerRecord`: `botKindRaw = custom`, `botDifficultyRaw` (v1 string or v2 JSON)
- Future `PlayerRecord.customBotPayload: Data?` (SchemaV3 — plan Phase E)
- `MatchParticipantRecord`: snapshot payload at start

Repository: `createCustomBot`, `updateCustomBotMetrics` (→ `updateCustomBotConfiguration` in Phase A).

---

## 9. Protocol stack (target)

| Protocol | Role |
|----------|------|
| `BotDescriptor` | Roster identity + `Codable` |
| `BotSkillResolving` | Configuration + `BotPlayContext` → `BotSkillProfile` |
| `BotMatchParticipantBuilding` | Profile → participant payload `Data` |

Custom bots use **`BotSkillFacet`** for advanced editing — not separate bot types per game mode.

Future kinds (e.g. campaign) add new `BotDescriptor` conformers; they do not fork custom bot storage.

---

## 10. Testing

| Area | Tests |
|------|-------|
| Metrics encode/decode | `CustomBotTests.swift` |
| Interpolator / resolver | `BotSkillProfileInterpolatorTests`, plan Phase A suite |
| Setup roster | `MatchSetupViewModelTests` |
| Lean UI smoke | `PartyPack1_1SmokeUITests` |
| Device | `release_checklist.md` §3 custom bot rows |

---

## 11. Analytics (optional)

Log `bot_kind=custom`, `custom_schema_version`, `match_type` on match start — no PII in skill values unless product approves.

---

## 12. Related specs

- [`BotOpponentSpec.md`](BotOpponentSpec.md) — preset tiers, `DartBotEngine`
- [`TrainingBotSpec.md`](TrainingBotSpec.md) — Training Partner
- [`SetupFlowSpec.md`](SetupFlowSpec.md) — Add Bot menu
- [`PlayerSpec.md`](PlayerSpec.md) — player detail
- [`SwiftData.md`](SwiftData.md) — schema migrations

---

## 13. Verification
| Field | Value |
|-------|--------|
| **Estimated release** | `1.0` |
| **Last verified** | 2026-06-11 |
| **Commit** | `340f788` |
| **Code** | `CustomBotViews.swift`, `CustomBotConfiguration.swift` |