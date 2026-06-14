**Estimated release:** `1.2`

# Training Bot Specification

## 1. Purpose
Define **Training Partner** bots: persistent opponents calibrated from a linked human player’s stats, slightly above their skill, snapshotted at each match start.

Preset tier bots are in [`BotOpponentSpec.md`](BotOpponentSpec.md).

---

## 2. MVP Scope

### In Scope (1.0.0)
- One training bot per human (`linkedPlayerId`)
- Eligibility: **5 completed games** in the active mode (X01 and Cricket counted separately)
- Create from Player Detail; add to roster from Play setup
- Skill resolution from `PlayerStatBreakdown` at match start
- X01 and Cricket matches (including Cut Throat when Points On)

### Out of Scope
- Multiple training bots per human
- Mid-season skill rebalancing during an in-progress match
- Cloud-synced training profiles

---

## 3. Rules

| Topic | Decision |
|-------|----------|
| Linkage | One Training Bot per human (`linkedPlayerId`) |
| Eligibility | `TrainingBotEligibilityService.requiredGames = 5` per mode |
| Skill (X01) | `targetAvg = clamp(playerAvg × 1.04 + 2, min: playerAvg + 1.5, max: 92)` |
| Skill (Cricket) | `targetMPR = clamp(playerMPR × 1.05 + 0.10, min: playerMPR + 0.08, max: 3.8)` |
| Zero-history fallback | Easy bumped profile (X01 avg 24 / Cricket MPR 1.35) |
| Snapshot | `TrainingBotSkillSnapshot` JSON → `MatchParticipant.botSkillProfilePayload` |
| `botKind` | `training`; `botDifficultyRaw` nil at match start |
| Engine | `DartBotEngine` uses `BotSkillProfile` from snapshot, not tier table |

Interpolator: `BotSkillProfileInterpolator` maps target avg/MPR to full profile.

---

## 4. Persistence

Schema details: [`SwiftData.md`](SwiftData.md).

- `PlayerRecord`: `botKindRaw = training`, `linkedPlayerId`
- `MatchParticipantRecord`: `botKindRaw`, `botSkillProfilePayload`

## Repository API (`PlayerRepository`)
- `fetchTrainingBot(linkedTo:)`
- `createTrainingBot(for:)`
- `resolveTrainingBotSkill(for:mode:)` — uses stats breakdown + `TrainingBotSkillResolver`

---

## 5. UI Specification

## Player Detail — Training Partner section
- Progress toward 5 games (mode-aware copy)
- Create training bot when eligible
- Practice shortcuts (prefill Play setup with bot + mode)

## Play Setup — Add Bot menu
- **Training Partner** section lists created training bots not yet in roster
- `accessibilityIdentifier`: `training_bot_add_setup`

## Bot detail / roster
- Display name from `TrainingBotNaming`
- Calibrated skill profile (not static `BotDifficulty` table)

---

## 6. Analytics

Log event names (add to [`FirebaseBackendAnalyticsSpec.md`](FirebaseBackendAnalyticsSpec.md) §12 allowlist when enabling Firebase):
- `training_bot_created`
- `training_bot_match_started`

---

## 7. Testing

## Unit
- `TrainingBotRepositoryTests`
- `TrainingBotSkillResolver` / eligibility via stats breakdown tests

## UI
- `-seed_demo` launch args for eligibility states (`DemoSeeder`)
- Training bot add in setup helpers (`UITestMatchSetupHelpers.addTrainingPartner`)

---

## 8. Accessibility verification
- Manual: [`player-detail.md`](../accessibility/wcag-2.1-aa/screens/player-detail.md), [`match-setup.md`](../accessibility/wcag-2.1-aa/screens/match-setup.md)
- Identifiers: `training_bot_create`, `training_bot_eligibility_progress`, `training_bot_add_setup`

## 9. Verification
| Field | Value |
|-------|--------|
| **Estimated release** | `1.2` |
| **Last verified** | 2026-06-04 |
| **Commit** | `0c25396` |
| **Code** | `TrainingBotSkillResolver.swift`, `PlayerDetailView` TrainingPartnerSection |

---

## 10. Future Improvements
- Re-calibrate skill automatically after N new completed games
- Training bot in Points Off Cricket