# Achievements Specification

## 1. Purpose

Define **local, profile-attributed achievements** for Dart Buddy: eligibility rules, evaluation hooks, persistence, unlock presentation, and a migration path to Game Center later.

**Related specs:** Profile presentation — [`BadgesSpec.md`](BadgesSpec.md). Post-match surface — [`MatchSummarySpec.md`](MatchSummarySpec.md). Stats inputs — [`StatsSpec.md`](StatsSpec.md). Campaign (separate reward layer) — [`CampaignSpec.md`](CampaignSpec.md). Future Game Center catalog — [`FutureIdeas/achievements.md`](../FutureIdeas/achievements.md). Reset — [`DeleteAllDataSpec.md`](DeleteAllDataSpec.md).

**Status:** Post-1.0 R&D — feature-flagged until implementation. Product rules below are **directional** until implementation locks them; Game Center reporting is **out of scope** for the first ship.

---

## 2. Product Positioning

| Principle | Rule |
|-----------|------|
| **Local first** | Achievements persist in SwiftData per `PlayerRecord`; no sign-in, no cloud sync in v1. |
| **Meaningful gameplay** | Unlock from dart events, match outcomes, and skill milestones — not tab opens, rematches, or other meta UI friction. |
| **Humans only** | Bot participants never earn achievements. Human-entered darts and human wins only. |
| **Guests included** | Any human `PlayerRecord` (including guests) can earn local achievements on this device. |
| **Incremental** | Volume milestones (games played, lifetime T20s, etc.) use progress counters with threshold unlock. |
| **Modes at ship time** | Light achievement set per **shipped** game mode (X01, Cricket, and each party mode as it ships). |
| **Campaign later** | Campaign-specific achievements (`db.campaign.*`) ship with [`CampaignSpec.md`](CampaignSpec.md) — not in the first achievements slice. |
| **Game Center later** | Add-on **on top of** local achievements — never a parallel system. Local stats/progress drive GC updates (§10). |

---

## 3. Scope

### In scope (Phase 1 — local achievements)
- Achievement definitions (ID, thresholds, mode scope, hidden flag)
- Pure `AchievementEvaluator` from turn/match events
- Per-player unlock + progress persistence
- Evaluation hooks after human turn accepted and on match completed
- Unlock presentation on [`MatchSummaryScreen`](MatchSummarySpec.md) only (not in-match)
- Revocation when **Undo last throw** reopens a completed match
- Feature flag `enableAchievements` (default `false`)
- Unit tests for evaluator + eligibility

### In scope (later phases — still local)
- Expanded catalog per shipped mode (see [`FutureIdeas/achievements.md`](../FutureIdeas/achievements.md) for ID namespace)
- Hidden achievements
- Retroactive backfill scan on first enable (optional polish)

### Out of scope (separate specs / future)
- Game Center auth, `GKAchievement` reporting, App Store Connect setup — future spec phase
- Campaign stars and campaign badges — [`CampaignSpec.md`](CampaignSpec.md)
- Leaderboards
- Online / cross-device sync
- Export/import of achievement progress — deferred

---

## 4. Eligibility Rules

### 4.1 Human participant
- Achievement evaluation runs only for participants where `isBot == false`.
- Mixed human+bot matches: humans can still unlock; bots are ignored.
- Bot-only sessions: no achievements evaluated.

### 4.2 Match context
- **Free Play** matches: full generic achievement catalog applies.
- **Campaign** matches: generic dart/mode achievements may apply unless a future campaign rule opts out; campaign-specific achievements are evaluated separately when Campaign ships.
- Abandoned matches: no match-level achievements; partial visit achievements already granted stand unless undone.

### 4.3 Guest vs primary (future Campaign)
- No distinction for **local** achievements in Phase 1 — all human players on the roster are eligible.
- When Game Center ships: recommend syncing only the **primary** player’s unlocks to `GKLocalPlayer`; guest local unlocks remain device-local (product decision locked in §10).

---

## 5. Architecture

```
Domain/Achievements/
  AchievementDefinition.swift     // id, threshold, mode, hidden, incremental
  AchievementProgress.swift       // playerId, achievementId, percent, unlockedAt
  AchievementEvaluator.swift      // pure: events + context → [AchievementDelta]

Data/Repositories/
  AchievementRepository.swift     // load/save progress per player

Features/Achievements/
  AchievementUnlockCoordinator.swift  // match-end batch, summary payload
```

**Hook points**
1. **After human turn accepted** — visit/dart achievements (T20, 180, ton-up, cricket marks).
2. **On match transition to `completed`** — wins, margins, mode wins, volume increments.
3. **On undo from summary** — re-evaluate or revoke achievements that depended on the reverted state (§7).

Domain engines and view models call an `AchievementService` protocol; tests inject mocks.

---

## 6. Data Model (conceptual)

Link to authoritative schema when implemented: [`SwiftData.md`](SwiftData.md), [`DataSchemaSpec.md`](DataSchemaSpec.md).

### `PlayerAchievementRecord` (proposed)
| Field | Type | Notes |
|-------|------|-------|
| `id` | UUID | Row id |
| `playerId` | UUID | FK → `PlayerRecord` |
| `achievementId` | String | Stable `db.*` id |
| `unlockedAt` | Date? | `nil` = in progress only |
| `progressPercent` | Int | 0–100 for incremental |
| `sourceMatchId` | UUID? | Last match that advanced progress |

**Cascade:** Deleting a player removes their achievement rows. **Reset all data** clears all achievement rows — see [`DeleteAllDataSpec.md`](DeleteAllDataSpec.md) §6.6.

### Incremental counters
- Store `progressPercent` locally; on unlock set `unlockedAt`.
- Full recount from event history allowed for integrity repair (same pattern as [`StatsSpec.md`](StatsSpec.md) recompute).

---

## 7. Unlock Presentation & Undo

### 7.1 Match summary (only surface)
- Extend [`MatchSummaryScreen`](../Features/Play/Shared/MatchSummaryScreen.swift) with an **Achievements** section when one or more achievements newly unlocked or crossed a progress milestone this session.
- Show: medal thumbnail, name, short description; incremental items may show “47 / 50 games”.
- **Do not** show mid-match banners or toasts during live scoring.
- Respect **Reduce Motion** — no staggered star-style animation requirement; simple fade/slide acceptable.

### 7.2 Undo last throw interaction
[`MatchSummarySpec.md`](MatchSummarySpec.md) allows undo to reopen a completed match.

**Required behavior:**
1. When summary appears, compute `pendingUnlocks` from final completed state.
2. If user taps **Undo last throw** and match returns to in-progress:
   - **Revoke** any unlock whose conditions are no longer met after revert.
   - Remove revoked rows from `PlayerAchievementRecord` (or clear `unlockedAt` and restore progress).
3. If match is completed again, re-run evaluator — same achievement may re-unlock on summary.

**Implementation note:** Prefer **re-evaluate from events** after undo rather than optimistic unlock on first completion, so revocation stays correct for compound achievements (e.g. “win without busting”).

---

## 8. Initial Catalog (Phase 1 — locked manifest)

**Authoritative Phase 1 list:** [`AchievementCatalogPhase1.md`](AchievementCatalogPhase1.md) — **22 achievements** with exact predicates, hook timing, and incremental rules.

Full long-term catalog: [`FutureIdeas/achievements.md`](../FutureIdeas/achievements.md). Phase 2+ roadmap (mode wins, bot beats, hidden): manifest §12.

| Category | Phase 1 IDs (summary) | Modes |
|----------|----------------------|-------|
| First steps | `db.play.first`, `db.win.first`, `db.dart.first_t20` | Any |
| Scoring | `db.avg.match_60`, `db.avg.match_80`, `db.visit.180`, `db.visit.180_20`, `db.visit.180_100` | X01 |
| Finishing | `db.checkout.100_plus`, `db.checkout.150_plus`, `db.checkout.rate_50`, `db.checkout.rate_100` | X01 |
| Consistency | `db.streak.win_3`, `db.streak.days_3`, `db.streak.days_7_consecutive`, `db.streak.days_30_consecutive` | Any |
| Milestones | `db.legs.win_100`, `db.play.10`, `db.play.50`, `db.play.100`, `db.play.250`, `db.play.500` | Any |

**Campaign:** generic Phase 1 achievements count in Journey matches; `db.campaign.*` progression achievements ship separately ([`CampaignSpec.md`](CampaignSpec.md) Phase 2).

**Phase 2+ (not Phase 1):** mode wins, bot-tier beats, party/Cricket expansions, hidden novelty, meta/tab opens.

Add 2–4 achievements per newly shipped mode when promoting `game-modes/planned/` → `implemented/`.

---

## 8.1 Phased rollout (all phases)

Ship order: **achievements before campaign-specific achievements** ([`CampaignSpec.md`](CampaignSpec.md) Phase 2).

| Phase | Deliverable | Catalog scope |
|-------|-------------|---------------|
| **1** | Local evaluator + `PlayerAchievementRecord` + summary unlocks + profile gallery | Meaningful slice (§8); X01 + Cricket |
| **2** | Party-mode achievements as each mode ships; expanded Tier B from [`FutureIdeas/achievements.md`](../FutureIdeas/achievements.md) | Per shipped `MatchType` |
| **3** | Hidden achievements; retroactive backfill on first enable; polish + undo/revoke hardening | Tier C subset |
| **4** | Game Center bridge — ASC setup, sandbox QA, `GameCenterAchievementService` | Report primary-player unlocks; guests stay local-only (§10) |
| **5** | Campaign achievements (`db.campaign.*`) | Addon with Campaign Phase 2 — not before |

---

## 9. Feature Flags & Rollout

| Flag | Default | Notes |
|------|---------|-------|
| `enableAchievements` | `false` | Gates evaluator hooks and summary UI |
| Launch arg | `-enable_achievements` | Dogfood / UI tests |

Hidden until ready unless actively implementing or testing. See [`FeatureFlagConfigSpec.md`](FeatureFlagConfigSpec.md).

---

## 10. Future — Game Center Bridge (add-on layer)

Game Center **will** ship eventually. It is **not** a separate achievement system — it is a **reporting and sync layer** built on top of the local implementation in this spec.

### 10.1 Source of truth

| Layer | Role |
|-------|------|
| **Local** (`PlayerAchievementRecord` + event history) | Authoritative — unlocks, incremental progress, undo/revoke |
| **Game Center** (`GKAchievement`) | Mirror — reflects local state for the signed-in Apple ID |

Local achievements work fully with Game Center **signed out**. GC adds platform trophies and cross-device unlock visibility for eligible players only.

### 10.2 Sync model

`GameCenterAchievementSync` (name TBD) **reads local state** and updates Game Center — never the reverse.

**Inputs (same as local evaluator):**
- `PlayerAchievementRecord` rows for the sync target player
- Optional full recount from match/event history via `AchievementEvaluator` + [`StatsSpec.md`](StatsSpec.md) reducers (integrity repair, retroactive catch-up)

**When to sync:**
1. **On local unlock** — after match completion or incremental threshold crossed, queue `GKAchievement` report if GC authenticated.
2. **On Game Center sign-in** — scan local records (and/or recompute from history) for primary player; batch-report unlocks and incremental percents with `showsCompletionBanner = false` for catch-up.
3. **On demand** — Settings “Sync achievements” (optional) re-runs reconciliation.

**Algorithm (conceptual):**
```
for each achievementId in catalog:
  local = PlayerAchievementRecord / evaluator recount
  if local.unlocked or local.progressPercent > gcReportedPercent:
    report to GKAchievement (percent or 100%)
    persist gcLastReportedPercent locally (avoid duplicate spam)
```

Offline: queue reports; retry when network + GC available. GC never creates local unlocks the evaluator would reject.

### 10.3 Who syncs to Game Center

- **Primary player** (when designated): eligible for GC sync on signed-in device.
- **Guest players:** local unlocks remain on device only; **do not** report to `GKLocalPlayer`.
- **Bots:** never (same as local §4).

### 10.4 Implementation notes

- Reuse same `achievementId` strings (`db.*`) in App Store Connect.
- `GameCenterAchievementService` protocol — injected alongside `AchievementService`; domain stays GameKit-free.
- Sign-in UX: separate spec (not this document).
- **App Store Connect:** create achievements with exact `db.*` IDs when Phase 4 starts — checklist in [`FutureIdeas/achievements.md`](../FutureIdeas/achievements.md) § App Store Connect.
- **Sandbox QA:** device + sandbox Game Center account — [`FutureIdeas/achievements.md`](../FutureIdeas/achievements.md) § Testing strategy.

---

## 11. Testing

| Layer | Approach |
|-------|----------|
| Evaluator | Swift Testing — fixture turn/match events → expected unlock set |
| Eligibility | Bot-only match → zero unlocks |
| Undo | Complete match → unlock → undo → assert revocation |
| Reset | `resetAllLocalData` clears `PlayerAchievementRecord` |
| Integration | Mock `AchievementService` in `MatchSummaryViewModel` |

---

## 12. Analytics

Allowlisted events (add to [`FirebaseBackendAnalyticsSpec.md`](FirebaseBackendAnalyticsSpec.md) when implemented):
- `achievement_unlocked` — `achievement_id`, `match_type` (no player names)
- `achievement_progress` — optional milestone crossings for incremental (e.g. 50%)

---

## 13. Verification

| Field | Value |
|-------|--------|
| **Last verified** | 2026-06-11 |
| **Commit** | (spec authoring — no implementation yet) |
| **Code** | (planned) `Domain/Achievements/`, `MatchSummaryScreen.swift` |
