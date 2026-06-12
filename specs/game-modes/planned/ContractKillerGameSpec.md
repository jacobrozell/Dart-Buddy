# Contract Killer Game Specification

## 1. Purpose

Define **Contract Killer** — standard **Killer** elimination with a **hidden contract** dealt to each player at start. Fulfilling a contract grants a bonus (steal life or immunity). Contracts reveal at game end or on fulfillment.

**Status:** Planned (`party.contractKiller`).  
**Brainstorm origin:** [`FutureIdeas/custom-games-brainstorm.md`](../../../FutureIdeas/custom-games-brainstorm.md) §7.

**Related specs:**
- [`KillerGameSpec.md`](../implemented/KillerGameSpec.md) — elimination engine, killer assignment
- [`WhisperCricketGameSpec.md`](WhisperCricketGameSpec.md) — hidden per-player payload patterns
- [`MatchSpec.md`](../../MatchSpec.md) — lifecycle, resume, abandon

---

## 2. Catalog metadata

| Field | Value |
|-------|-------|
| **Section** | Party |
| **UI template** | D — Lives elimination (`livesElimination`) + secret card |
| **Stat kind** | `contractFulfillment` (new; contracts completed) |
| **Ruleset (v1)** | `contract_killer_standard` |
| **Catalog id** | `party.contractKiller` |
| **MatchType** | `contractKiller` (when implemented) |

**Display name:** Contract Killer  
**Marketing blurb:** "Killer with a secret mission — fulfill it for immunity or a steal."

---

## Player count

| Question | Answer |
|----------|--------|
| **Solo?** | No |
| **Minimum** | **3** |
| **Recommended** | 3–6 |
| **App maximum** | 6 |

---

## 3. MVP Scope

### In scope (v1)

| Item | Default | Configurable |
|------|---------|--------------|
| Base rules | **Killer** standard | Fixed |
| Contracts per player | **1** | Fixed |
| Contract pool | **8** archetypes (§5.2) | Expand v2 |
| Reward | **Steal 1 life** from target OR **immunity** (chip) | Fixed |
| Reveal | On fulfillment (public) + all at game end | — |
| Bots | Preset bots with hidden contracts | — |
| Undo | Per Killer rules | — |
| History | Contracts fulfilled, winner | — |

### Out of scope (v1)
- Multiple active contracts
- Contract trading
- Online hidden contracts across devices

---

## 4. Product goals

| Goal | How Contract Killer delivers |
|------|------------------------------|
| **Party depth** | Secret missions on familiar Killer |
| **Replay** | Different contracts each night |
| **Low engine cost** | Killer + payload |
| **Dart Buddy exclusive** | Structured secret objectives |

---

## 5. Rules Engine (`ContractKillerEngine`)

Extends `KillerEngine` with contract layer.

### 5.1 Config (`MatchConfigContractKiller`, payload v1)

| Field | Type | Default |
|-------|------|---------|
| `killerConfig` | `MatchConfigKiller` | standard defaults |
| `rewardType` | `stealLife` \| `immunity` | `stealLife` |

### 5.2 Contract archetypes (v1 pool)

| Id | Text (draft) | Condition |
|----|--------------|-----------|
| `eliminate_left` | Eliminate player on your left without becoming killer first | Target eliminated while condition true |
| `survive_one` | Survive with exactly 1 life when someone else wins | End state check |
| `triple_self` | Hit your own number with a triple | During play |
| `first_blood` | Take first life off any opponent | First kill credit |
| `no_killer` | Win without ever becoming killer | End state |
| `bull_kill` | Eliminate someone with a bull hit | Kill event |
| `three_mark` | Close your number in one visit (3 marks) | Single visit |
| `last_standing_alt` | Be last non-winner with 2+ lives | End state (chaos) |

### 5.3 Deal

At match start: shuffle pool; deal one contract per player (hidden UI).

### 5.4 Fulfillment

On condition met:
1. Mark contract fulfilled; reveal to table.
2. Apply reward: `stealLife` → choose opponent (UI), −1 life; `immunity` → token absorbs next life loss once.

### 5.5 State extension

```text
contracts: [ParticipantId: Contract]
fulfilled: Set<ParticipantId>
immunityTokens: [ParticipantId: Int]
```

Base Killer state unchanged.

---

## 6. UI notes

- Contract card in setup (face-down until peek — optional house rule off in v1).
- Fulfillment: full-screen reveal animation.
- End game: gallery of all contracts.

---

## 7. Localization (draft)

| Key | EN (draft) |
|-----|------------|
| `play.rules.contractKiller.title` | Contract Killer |
| `play.rules.contractKiller.summary` | Killer with a secret contract — fulfill it for a steal or immunity. |
| `play.contract.fulfilled` | Contract fulfilled! |
| `play.contract.reveal` | Secret contracts |

---

## 8. Open questions

1. Immunity vs steal default reward?
2. Bot contract evaluation — cheat or simulate?
