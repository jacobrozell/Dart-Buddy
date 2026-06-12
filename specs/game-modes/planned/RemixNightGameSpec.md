# Remix Night Game Specification

## 1. Purpose

Define **Remix Night** — a **tournament format preset** that composes **3 mini-legs** from existing shipped engines into one evening session with **leg-win scoring** and between-round rules recaps.

This is **not** the tournament platform — brackets, seeding, and multi-round progression live in [`TournamentSpec.md`](../../TournamentSpec.md). Remix Night is the quick-create **“random multi-mode leg-win event”** (no knockout bracket), comparable to a DartCounter multi-game session but mode-mixed by design.

**Status:** Planned (`party.remixNight`).  
**Brainstorm origin:** [`FutureIdeas/custom-games-brainstorm.md`](../../../FutureIdeas/custom-games-brainstorm.md) §8.

**Related specs:**
- [`TournamentSpec.md`](../../TournamentSpec.md) — **parent platform**; Remix Night is `format: remix_night`
- [`MatchSpec.md`](../../MatchSpec.md) — parent match session, leg handoff
- [`MatchSummarySpec.md`](../../MatchSummarySpec.md) — evening champion ceremony
- [`CampaignSpec.md`](../../CampaignSpec.md) — solo scripted arcs (Journey Gauntlet); different shape
- All **implemented** mode specs — leg sources

---

## 2. Catalog metadata

| Field | Value |
|-------|-------|
| **Section** | Party |
| **UI template** | O — Orchestrator (implements [`TournamentSpec.md`](../../TournamentSpec.md) `TournamentOrchestrator`; `format: remix_night`) |
| **Stat kind** | `remixAggregate` (round wins, total margin) |
| **Ruleset (v1)** | `remix_night_standard` |
| **Catalog id** | `party.remixNight` |
| **MatchType** | `remixNight` (when implemented) |

**Display name:** Remix Night  
**Marketing blurb:** "Three random games — one champion."

---

## Player count

| Question | Answer |
|----------|--------|
| **Solo?** | No |
| **Minimum** | 2 humans |
| **Recommended** | 2–4 |
| **App maximum** | 4 |

### Brainstorm
- Same roster across all three rounds — no re-pick between legs.
- Bot fill allowed only on rounds whose source mode supports bots (e.g. X01 leg).
- Product surface must gate rounds to **shipped** engines only in v1.

---

## 3. MVP Scope

### In scope (v1)

| Item | Default | Configurable |
|------|---------|--------------|
| Rounds per session | **3** | Fixed v1 |
| Round draw | **Random** from shipped pool | Curated preset (v2) |
| Scoring | **Most round wins** | Round wins (default) / total points (v2) |
| Tiebreaker | Sudden-death **1-leg 301** mini-round | — |
| Between rounds | TTS rules recap + one-screen cheat sheet | — |
| Round sources (v1) | X01, Cricket, Shanghai, Killer, Baseball | Expand as engines ship |
| Undo | Per underlying engine rules | — |
| History | Parent `MatchRecord` + child leg refs | — |

### v1 round pool (minimum bar)

| Source `MatchType` | Mini-round shape |
|--------------------|------------------|
| `x01` | Single leg **301** double-out |
| `cricket` | Standard cricket, first to close all + most points |
| `shanghai` | Shanghai on **7s**, one round |
| `killer` | Killer standard, first elimination |
| `baseball` | Full 9-inning or **3-inning** quick (chip) |

### Out of scope (v1)
- Planned-only engines (Fleet, Raid, etc.) in random pool
- Player-authored round order
- Online async remix
- Per-round different rosters
- Streak Wager / Wind Shift modifiers (v2 overlay)

---

## 4. Product goals

| Goal | How Remix Night delivers |
|------|--------------------------|
| **Catalog showcase** | One session touches multiple engines |
| **Party hook** | "House rules roulette" without learning three setups |
| **Retention** | Different remix each night — seeded optional (daily remix v2) |
| **Dart Buddy exclusive** | Only app with 5+ engines composable in one match |

---

## 5. Rules Engine (`RemixNightEngine`)

Thin coordinator — delegates scoring to child engines.

### 5.1 Config (`MatchConfigRemixNight`, payload v1)

| Field | Type | Default |
|-------|------|---------|
| `roundCount` | Int | `3` |
| `drawMode` | `random` \| `preset` | `random` |
| `presetId` | String? | `nil` |
| `scoringMode` | `roundWins` \| `aggregatePoints` | `roundWins` |
| `baseballInnings` | Int | `3` (quick) |

### 5.2 Session state

```text
roster: Participant[]
rounds[]: { index, sourceMatchType, childConfigSnapshot, childStateSnapshot, winnerId? }
roundWins: [ParticipantId: Int]
currentRoundIndex
phase: setup | inRound | betweenRounds | complete
```

### 5.3 Handoff protocol

1. **Setup:** pick roster once; draw 3 `MatchType` + configs from pool (no duplicate mode in one session v1).
2. **Start round N:** hydrate child engine from snapshot; present child UI template.
3. **Round complete:** record winner (or co-op skip); freeze child state; show recap interstitial (5s skippable).
4. **After round 3:** compute evening champion; summary screen lists all three results.

### 5.4 Tiebreaker

Equal round wins → inject sudden-death leg: `x01` 301, double-out, single leg; winner takes evening.

---

## 6. UI — Orchestrator chrome

| Screen | Content |
|--------|---------|
| **Draw reveal** | Slot-machine animation of three mode icons |
| **Between rounds** | "Round 2 of 3 — Cricket" + bullet rules + Continue |
| **Progress strip** | Persistent top bar: round wins per player |
| **Summary** | Podium + per-round cards linking to leg detail |

Child engines render inside `RemixRoundHost` container; back navigation disabled mid-round.

---

## 7. Localization (draft)

| Key | EN (draft) |
|-----|------------|
| `play.rules.remixNight.title` | Remix Night |
| `play.rules.remixNight.summary` | Three random games — most round wins takes the night. |
| `play.remix.draw.title` | Tonight's lineup |
| `play.remix.between.title` | Round {n} — {mode} |

---

## 8. History & stats

- Parent record stores `remixLegs: [MatchLegRef]`.
- Stat kind: evening wins, favorite round source (mode appearing in wins).

---

## 9. Open questions

1. Which shipped modes are mandatory in pool at 1.0 ship?
2. Allow duplicate modes in one session (e.g. two X01 legs with different starts)?
3. **Fold into Tournament quick-start only**, or keep standalone catalog row? See [`TournamentSpec.md`](../../TournamentSpec.md) §11.
4. Share `TournamentOrchestrator` interface with knockout tournaments — single implementation?
