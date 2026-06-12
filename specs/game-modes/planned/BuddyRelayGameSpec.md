# Buddy Relay Game Specification

## 1. Purpose

Define **Buddy Relay** — a **3+ player** party mode with rotating asymmetric roles: **Caller** (sees target), **Thrower** (phone face-down, hears target), and **Judges** (tap landed segment). Roles rotate each round; first to **N** successful hits wins.

**Status:** Planned (`party.buddyRelay`).  
**Brainstorm origin:** [`FutureIdeas/custom-games-brainstorm.md`](../../../FutureIdeas/custom-games-brainstorm.md) §5.

**Related specs:**
- [`EchoGameSpec.md`](EchoGameSpec.md) — voice-only overlap (Echo is 2p duel)
- [`GuidedPlayCompanionSpec.md`](../../GuidedPlayCompanionSpec.md) — judge tap UI
- [`CalloutVoicesSpec.md`](../../CalloutVoicesSpec.md) — TTS for thrower
- [`MatchSpec.md`](../../MatchSpec.md) — lifecycle, resume, abandon

---

## 2. Catalog metadata

| Field | Value |
|-------|-------|
| **Section** | Party |
| **UI template** | R — Role split (`roleSplit`) — new |
| **Stat kind** | `roleRelay` (new; hits, challenges) |
| **Ruleset (v1)** | `buddy_relay_standard` |
| **Catalog id** | `party.buddyRelay` |
| **MatchType** | `buddyRelay` (when implemented) |

**Display name:** Buddy Relay  
**Marketing blurb:** "Caller, thrower, judges — rotate every round."

---

## Player count

| Question | Answer |
|----------|--------|
| **Solo?** | No |
| **Minimum** | **3** |
| **Recommended** | 4–6 |
| **App maximum** | 6 |

### Role math

| Players | Caller | Thrower | Judges |
|---------|--------|---------|--------|
| 3 | 1 | 1 | 1 |
| 4 | 1 | 1 | 2 |
| 5 | 1 | 1 | 3 (majority) |
| 6 | 1 | 1 | 4 (majority) |

---

## 3. MVP Scope

### In scope (v1)

| Item | Default | Configurable |
|------|---------|--------------|
| Win target | **10** successful hits | 5 / 10 / 15 |
| Targets | Random doubles | Singles / Doubles / Mixed |
| Darts per round | **3** max | 1 / 3 |
| Judge resolution | **Majority** segment tap | — |
| Challenge | Once per player per match — re-throw | — |
| Role rotation | Clockwise each round | — |
| TTS | Optional for thrower | On / off |
| Pass-and-play | Single device handoff between roles | Primary v1 |
| History | Hits, challenges used | — |

### Out of scope (v1)
- Multi-device sync (pass-and-play only)
- Points for judges
- Bot judges

---

## 4. Product goals

| Goal | How Buddy Relay delivers |
|------|--------------------------|
| **Pub party** | 3+ asymmetric roles |
| **Social chaos** | Majority judge disagreements |
| **Guided Play bridge** | Thrower experience like blind play |
| **Dart Buddy exclusive** | Multi-role single match |

---

## 5. Rules Engine (`BuddyRelayEngine`)

### 5.1 Config (`MatchConfigBuddyRelay`, payload v1)

| Field | Type | Default |
|-------|------|---------|
| `hitsToWin` | Int | `10` |
| `targetKind` | `doubles` \| `singles` \| `mixed` | `doubles` |
| `maxDartsPerRound` | Int | `3` |
| `ttsEnabled` | Bool | `true` |

### 5.2 Round flow

1. Assign roles from roster order.
2. Caller sees target; optionally TTS to thrower.
3. Thrower throws (up to `maxDartsPerRound`).
4. Judges tap landed **segment** (honor + majority).
5. **Hit:** majority segment matches target (ring ignored v1) → +1 hit for team... **scoring player** = thrower gets personal hit count toward win.
6. **Miss:** no point.
7. **Challenge:** any judge or thrower may challenge once — re-throw round; if still miss, challenger loses 1 future hit (v1: no penalty, just re-throw).
8. Rotate roles clockwise.

### 5.3 Win

First thrower to `hitsToWin` successful hits wins match.

### 5.4 State

```text
participants[]
roles: { callerId, throwerId, judgeIds[] }
hits: [ParticipantId: Int]
targetPool
currentTarget
challengeUsed: [ParticipantId: Bool]
```

---

## 6. UI notes

- **Caller:** target card + "Announce" button.
- **Thrower:** dark screen + speaker icon; optional haptic on call.
- **Judge:** segment grid tap; show other judges' taps after lock-in.
- Privacy handoff curtain between role screens (pass-and-play).

---

## 7. Localization (draft)

| Key | EN (draft) |
|-----|------------|
| `play.rules.buddyRelay.title` | Buddy Relay |
| `play.rules.buddyRelay.summary` | Caller speaks, thrower listens, judges decide — first to ten hits wins. |
| `play.relay.role.caller` | Caller |
| `play.relay.role.thrower` | Thrower |
| `play.relay.role.judge` | Judge |

---

## 8. Open questions

1. Individual thrower wins vs team score?
2. Multi-device roles in v2?
