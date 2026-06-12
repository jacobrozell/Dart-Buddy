# Cerberus Game Specification

## 1. Purpose

Define **Cerberus** — cooperative PvE where **2–3 humans** each damage an assigned **boss head** (segments 20, 16, 12) per round. When any head is destroyed, Cerberus **bites** the shared team life pool.

**Status:** Planned (`party.cerberus`).  
**Brainstorm origin:** [`FutureIdeas/custom-games-brainstorm.md`](../../../FutureIdeas/custom-games-brainstorm.md) §36.

**Related specs:**
- [`RaidGameSpec.md`](RaidGameSpec.md) — co-op boss UI, team summary, enrage patterns
- [`BotOpponentSpec.md`](../../BotOpponentSpec.md) — Cerberus as non-throwing boss entity
- [`MatchSpec.md`](../../MatchSpec.md) — lifecycle, resume, abandon
- [`CricketSpec.md`](../implemented/CricketSpec.md) — close damage on assigned segment

---

## 2. Catalog metadata

| Field | Value |
|-------|-------|
| **Section** | Party |
| **UI template** | G + `roleSplit` — tri-head boss + role assignment |
| **Stat kind** | `bossRaid` (extends; heads cleared, bites survived) |
| **Ruleset (v1)** | `cerberus_standard` |
| **Catalog id** | `party.cerberus` |
| **MatchType** | `cerberus` (when implemented) |

**Display name:** Cerberus  
**Marketing blurb:** "Three heads. Three assignments. Don't let the team pool hit zero."

---

## Player count

| Question | Answer |
|----------|--------|
| **Solo?** | **Yes** — 1 human rotates all three heads (suboptimal but supported) |
| **Minimum** | 1 human |
| **Recommended** | **3** humans (one head each) |
| **App maximum** | 3 humans |

### Brainstorm
- At 2 humans: heads shared round-robin assignment.
- Boss never throws darts in v1.

---

## 3. MVP Scope

### In scope (v1)

| Item | Default | Configurable |
|------|---------|--------------|
| Heads | **20, 16, 12** | Fixed |
| HP per head | **15** | 10 / 15 / 20 |
| Team life pool | **12** | 9 / 12 / 15 |
| Damage (assigned head only) | Close = **5**, double = **3**, single = **1** | Fixed v1 |
| Bite on head kill | Team pool **−3** | 2 / 3 / 4 |
| Turn structure | All humans throw full visit each round | — |
| Role assignment | Auto-assign heads 1:1 at 3p; rotate at 2p | — |
| Undo | Undo last dart | — |
| History | Co-op summary | — |

### Out of scope (v1)
- 4+ humans
- Boss attacks / enrage phases (Raid handles that)
- Per-head abilities (poison, shield)

---

## 4. Product goals

| Goal | How Cerberus delivers |
|------|------------------------|
| **Role clarity** | "I'm on 16!" — MMO raid feel |
| **Second PvE shape** | Different from Raid phases — spatial assignment |
| **Optimal at 3** | Pub trio nights |
| **Dart Buddy exclusive** | Tri-bar boss + round roles |

---

## 5. Rules Engine (`CerberusEngine`)

### 5.1 Config (`MatchConfigCerberus`, payload v1)

| Field | Type | Default |
|-------|------|---------|
| `headHP` | Int | `15` |
| `teamPoolMax` | Int | `12` |
| `biteDamage` | Int | `3` |

### 5.2 Heads

```text
Head {
  segment: 20 | 16 | 12
  hp: Int
  assignedHeroId: ParticipantId?
}
```

### 5.3 Round flow

1. Assign heads (3p: fixed mapping; 2p: each player has primary + secondary head alternating).
2. Each hero throws 3-dart visit.
3. Only darts on **assigned head segment** deal damage (any ring per damage table).
4. Unassigned heads: 0 damage from that hero's darts.
5. **Close** (3 marks on segment in one round cumulative — use cricket mark counter per head): applies 5 damage once when third mark achieved.
6. When head `hp <= 0`: trigger **Bite** — `teamPool -= biteDamage`; head removed from board.
7. **Win:** all heads 0 before `teamPool <= 0`.
8. **Lose:** `teamPool <= 0`.

### 5.4 Solo rule

One human assigned all three heads; all their hits count on respective segments.

### 5.5 State

```text
heads[]
teamPool
assignments: [ParticipantId: HeadSegment]
roundIndex
markProgress: [HeadSegment: Int]  // cricket marks toward close
```

---

## 6. UI notes

- Three HP bars labeled 20 / 16 / 12 with hero name chips.
- Round start: role cards slide to each player color.
- Bite: screen shake + pool bar flash.

---

## 7. Localization (draft)

| Key | EN (draft) |
|-----|------------|
| `play.rules.cerberus.title` | Cerberus |
| `play.rules.cerberus.summary` | Assign a head each round — kill all three before the team falls. |
| `play.cerberus.bite` | Cerberus bites! −{n} team life |
| `play.cerberus.assigned` | Your head: {segment} |

---

## 8. Open questions

1. Use cricket marks for "close" or raw hit count only?
2. Extract shared co-op platform from Raid first?
