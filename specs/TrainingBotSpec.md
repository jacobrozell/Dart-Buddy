# Training Bot Specification

## Overview

A **Training Bot** is a persistent computer opponent linked 1:1 to a human player. Skill is derived from that player's mode-specific stats, calibrated slightly above their level, and snapshotted at each match start.

## Rules

| Topic | Decision |
|-------|----------|
| Linkage | One Training Bot per human (`linkedPlayerId`) |
| Eligibility | 5 completed games in the active mode (X01 vs Cricket evaluated separately) |
| Skill (X01) | `targetAvg = clamp(playerAvg * 1.04 + 2, min: playerAvg + 1.5, max: 92)` |
| Skill (Cricket) | `targetMPR = clamp(playerMPR * 1.05 + 0.10, min: playerMPR + 0.08, max: 3.8)` |
| Snapshot | `TrainingBotSkillSnapshot` JSON on `MatchParticipant.botSkillProfilePayload` |
| Preset bots | `botKind = preset`, `botDifficultyRaw` set |
| Training bots | `botKind = training`, `botDifficultyRaw` nil at match start |

## Persistence (SchemaV2)

- `PlayerRecord`: `botKindRaw`, `linkedPlayerId`
- `MatchParticipantRecord`: `botKindRaw`, `botSkillProfilePayload`

## Repository API

- `fetchTrainingBot(linkedTo:)`
- `createTrainingBot(for:)`
- `resolveTrainingBotSkill(for:mode:)`

## UI

- **Player Detail**: Training Partner section (progress, create, practice shortcuts)
- **Match Setup**: Add Bot menu → Training Partner section for created bots
- **Bot Detail**: Calibrated skill profile (not static tier table)

## Analytics

- `training_bot_created` (log event name; map via Firebase allowlist when wired)
- `training_bot_match_started`
