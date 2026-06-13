# Bot Opponent Specification

## 1. Purpose
Define preset computer opponents, shared bot turn generation (`DartBotEngine`), pacing, and mode support. Training Partner bots are specified in [`TrainingBotSpec.md`](TrainingBotSpec.md). User-defined custom bots are specified in [`CustomBotSpec.md`](CustomBotSpec.md).

---

## 2. MVP Scope

### In Scope (1.0.0)
- Five preset difficulty tiers: Very Easy, Easy, Medium, Hard, Pro
- On-demand creation of preset bot `PlayerRecord` rows from Play setup (Add Bot menu)
- X01 bot turns for all checkout and check-in modes supported by `X01Engine`
- Cricket bot turns when **Points On** and scoring mode is **Normal** or **Cut Throat**
- Staggered dart reveal pacing (Settings → bot pacing toggle)
- Bot participants in 2..N player matches; at least one human required

### Out of Scope (1.0.0)
- Cricket bots with **Points Off**
- In-match bot difficulty changes
- Custom user-defined preset tiers

---

## 3. Bot Kinds

| Kind | `botKindRaw` | Skill source | Spec |
|------|--------------|--------------|------|
| Preset | `preset` | `BotDifficulty` tier → `BotSkillProfile` | This spec |
| Training | `training` | Calibrated from linked human stats | `TrainingBotSpec.md` |
| Custom | `custom` | `CustomBotConfiguration` → `BotSkillProfile` | `CustomBotSpec.md` |

At match start, preset participants store `botDifficultyRaw`; training participants store `botSkillProfilePayload` snapshot and `botDifficultyRaw = nil`.

---

## 4. Preset Difficulty Tiers

`BotDifficulty` maps to localized display names and roster names (`bot.rosterNameFormat`).

Each tier defines (engine-internal):
- Scoring visit point range when not on a finish
- Checkout attempt probability
- Hit chances by intended multiplier (S/D/T)
- Triple preference on scoring segments
- Inner-bull aim chance (Hard/Pro)
- Master-in triple opener chance (Hard/Pro)
- Check-in hit boost (X01)
- Risky bust tolerance (via interpolated `BotSkillProfile`)

`BotDifficultyDisplayProfile` exposes human-readable visit/checkout ranges for bot detail UI.

---

## 5. Turn Generation (`DartBotEngine`)

Pure, deterministic given RNG seed. View models call engine → persist via `MatchTurnSubmitter`.

### X01
- Up to three darts per visit; respects remaining score, `X01CheckoutMode`, `X01CheckInMode`, check-in state
- Checkout attempts use tier/profile checkout chance
- Bust avoidance uses safe-scoring fallback unless `riskyBustChance` triggers

### Cricket (Points On)
- **Normal:** prefer highest open target for marks; scoring visits when overflow possible
- **Cut Throat:** prefer punish targets on opponents who still have the bed open; inflict points on closed beds when opponents remain open (`cutThroatPunishTargets`)

### Killer (preset only)
- **Pick phase:** random available segment 1–20; intend single; cricket-style resolution (miss/wrong-bed → natural rethrow)
- **Play phase:** up to 3 darts; pre-killer aims double on own number; post-killer targets lowest-lives opponent; easy tiers may wrong-bed to own double via `cricket.wrongBedChance`
- Reuses `profile.cricket` hit tables for double accuracy
- Setup validation: `setup.validation.killerBotsPresetOnly` (training/custom blocked)

### Shared resolution
- Intended dart → hit/miss resolution using profile hit tables + boosts
- Outputs `[DartInput]` consumed by mode engines like human input

---

## 6. UI Specification

## Play Setup — Add Bot
- Section lists preset tiers (creates + selects bot player)
- Training Partner section when eligible bots exist (`TrainingBotSpec.md`)
- Validation: `setup.validation.cricketBotUnsupported` when any bot selected and Cricket Points Off
- Validation: `setup.validation.requiresHuman` when all participants are bots

## In-Match
- Bot turns auto-run after human submit (or on bot’s turn at leg start)
- Dart stagger controlled by `BotTurnPacing` and Settings bot pacing preference
- Cricket closure transitions use `cricketClosureTransitionNanoseconds` delay before ready state
- Turn indicator shows bot name from participant snapshot

## Player Detail (preset bots)
- Static tier profile table from `BotDifficultyDisplayProfile`

---

## 7. Data Contract

Authoritative fields: `specs/SwiftData.md`, `specs/DataSchemaSpec.md`.

- `PlayerRecord.botKindRaw`, `botDifficultyRaw` (preset), `linkedPlayerId` (training only)
- `MatchParticipantRecord.botKindRaw`, `botDifficultyRaw`, `botSkillProfilePayload`

---

## 8. Preset tier reference (`BotDifficulty`)

Numeric values are defined in `Domain/Engines/DartBotEngine.swift` on `BotDifficulty` and exposed for UI via `displayProfile`. **Do not duplicate numbers in docs** — when tuning tiers, change code and re-verify this table’s semantics.

| Tier | X01 scoring visit (pts) | Checkout attempt | Notes |
|------|-------------------------|------------------|-------|
| Very Easy | 10–22 | 12% | Low triple/bull aim |
| Easy | 18–42 | 25% | |
| Medium | 22–38 | 40% | Default feel |
| Hard | 28–44 | 50% | Inner bull + master-in opener |
| Pro | 34–50 | 58% | Highest hit tables |

Cricket uses separate `cricketHitChance` / `cricketWrongBedChance` per tier (see `displayProfile.cricket`).

Bot detail UI renders `BotDifficultyDisplayProfile` (hit %, visit range, checkout %).

---

## 9. Testing

## Unit
- `DartBotEngineTests` — X01 checkout/check-in, Cricket normal/cut-throat targeting and punish scoring, Killer pick/play targeting
- `BotPlayerTests` — roster naming, creation
- `BotLongTermSimulationTests` (performance target, not CI scheme)

## UI
- `CricketMatchUITests.testCutThroatCricketBotMatchStartsAndBotThrows`
- Setup flows with bot add in `MatchSetupViewModelTests`

---

## 10. Accessibility verification
- Manual: [`match-setup.md`](../accessibility/wcag-2.1-aa/screens/match-setup.md) (Add Bot), in-match [`x01-match.md`](../accessibility/wcag-2.1-aa/screens/x01-match.md) / [`cricket-match.md`](../accessibility/wcag-2.1-aa/screens/cricket-match.md)

## 11. Analytics
§12 — `bot_turn_started` (log-only); match lifecycle events when bots in roster.

## 12. Verification
| Field | Value |
|-------|--------|
| **Last verified** | 2026-06-04 |
| **Commit** | `0c25396` |
| **Code** | `DartBotEngine.swift`, `BotDifficulty` |

---

## 13. Future Improvements
- Points Off Cricket bots
- Per-match difficulty adjustment
- Smarter opponent modeling (closure heatmaps, player-specific exploit)
