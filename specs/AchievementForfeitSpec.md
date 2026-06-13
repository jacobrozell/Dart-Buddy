# Achievement — Forfeit & Sportsmanship

## 1. Purpose

Define **local achievements tied to Save & Forfeit** ([`MatchForfeitSpec.md`](MatchForfeitSpec.md)): eligibility when `MatchStatus.forfeited`, the incremental **“conceded x times”** ladder, wins **by** forfeit, and a brainstorm catalog for Phase 2+ / hidden novelty.

**Related:** [`AchievementsSpec.md`](AchievementsSpec.md) · [`AchievementCatalogPhase1.md`](AchievementCatalogPhase1.md) · [`MatchForfeitSpec.md`](MatchForfeitSpec.md) · [`StatsSpec.md`](StatsSpec.md) · [`MatchSummarySpec.md`](MatchSummarySpec.md) · [`FutureIdeas/achievements.md`](../FutureIdeas/achievements.md)

**Status:** Product draft — ships **after** local achievements Phase 1 and **after** forfeit is live. Not in Phase 1 manifest. Requires `enableAchievements` + forfeit in production.

---

## 2. Design principles

| Principle | Rule |
|-----------|------|
| **Light tone** | Conceder achievements use self-deprecating copy (“Called it quits”, “Bar’s closing”) — not punishment or red badges. |
| **Opt-in humor** | Conceder volume milestones may be **hidden** until unlock so casual players are not nudged to forfeit. |
| **Stats ≠ wins** | Forfeited matches count toward **games played** and dart stats ([`StatsSpec.md`](StatsSpec.md)); they do **not** count as natural **wins** for `db.win.*` / checkout / streak achievements. |
| **Human only** | Same as [`AchievementsSpec.md`](AchievementsSpec.md) §4 — bots never initiate forfeit; bot participants never earn forfeit achievements. |
| **Deliberate forfeit only** | Only `status == forfeited` with persisted `forfeitedByPlayerId`. **Abandoned** matches never count. |
| **No summary spam** | [`MatchForfeitSpec.md`](MatchForfeitSpec.md) §9.3: **no** achievement unlocks on forfeit summary in **1.0 forfeit ship**; this spec enables them when achievements Phase 2+ lands. |

---

## 3. Match status eligibility matrix

| Status | Games played (`db.play.*`) | Natural win (`db.win.*`, streaks) | Forfeit conceder (`db.forfeit.*`) | Win by forfeit (`db.win.by_forfeit.*`) |
|--------|------------------------------|-----------------------------------|-----------------------------------|----------------------------------------|
| `completed` | Yes | Yes (if winner) | No | No |
| `forfeited` | Yes | **No** | Yes (if `forfeitedByPlayerId == player`) | Yes (if `winnerPlayerId == player`) |
| `abandoned` | No | No | No | No |
| `inProgress` | No | No | No | No |

**Solo X01 forfeit:** `winnerPlayerId == nil` — conceder gets `db.forfeit.*` volume; no win-by-forfeit row.

**Multi-human forfeit:** Only the player selected as **forfeiting** in the picker gets conceder credit. Other humans who agreed to end the match but were not the designated forfeiter do **not** get conceder increments (avoids double-count in 3+ player bar games).

---

## 4. Evaluation hooks

| Hook | When | Achievements |
|------|------|--------------|
| **Match forfeited** | After `MatchForfeitSupport.persistForfeit` succeeds; `status → forfeited` | All §5–§6 rows |
| **Not on turn** | Forfeit does not append scoring events | No visit/dart achievements at forfeit moment |

**Context fields** (extend `AchievementEvaluationContext`):

```
forfeitedByPlayerId: UUID?
winnerPlayerId: UUID?
forfeitResolution: automatic | user_picked   // analytics parity with MatchForfeitSpec
eventCount: Int                              // gate “meaningful” forfeit (≥ 1, same as UI)
```

**Undo:** Forfeit summary hides undo ([`MatchForfeitSpec.md`](MatchForfeitSpec.md) §8.6). No revocation path for forfeit unlocks in v1 of this catalog.

---

## 5. Locked catalog — conceder (incremental)

**Namespace:** `db.forfeit.*` · **Hook:** match forfeited · **Subject:** human where `forfeitedByPlayerId == playerId`

| ID | Name (en) | Inc | Threshold | Hidden | Description (en) |
|----|-----------|-----|-----------|--------|------------------|
| `db.forfeit.first` | Called It | — | 1 | No | Concede your first match with Save & Forfeit. Stats saved. |
| `db.forfeit.5` | Time to Go | ✓ 5 | 5 lifetime | No | Save & Forfeit five times. |
| `db.forfeit.10` | Last Call | ✓ 10 | 10 | **Yes** | Ten graceful exits. |
| `db.forfeit.25` | Regular at Closing | ✓ 25 | 25 | **Yes** | Twenty-five forfeited matches. |
| `db.forfeit.50` | Bar Stamp Card | ✓ 50 | 50 | **Yes** | Fifty times you ended early and kept the darts. |

**Counter:** `lifetimeMatchesForfeitedAsConceder` — increment **once per match** when this human is `forfeitedByPlayerId`.

**Minimum play gate (recommended):** Require `eventCount >= 1` (same as forfeit UI). Zero-event abandon path excluded automatically.

**Localization keys:** `achievement.db_forfeit_10.name`, `achievement.db_forfeit_10.description` (dots → underscores per [`AchievementCatalogPhase1.md`](AchievementCatalogPhase1.md) §8).

**App Store Connect points:** 5 / 10 / 15 / 25 / 40 / 50 (incremental tiers).

---

## 6. Locked catalog — win by forfeit

**Namespace:** `db.win.by_forfeit.*` · **Hook:** match forfeited · **Subject:** human where `winnerPlayerId == playerId`

| ID | Name (en) | Inc | Threshold | Hidden | Description (en) |
|----|-----------|-----|-----------|--------|------------------|
| `db.win.by_forfeit.first` | Walkover | — | 1 | No | Win when your opponent conceded. |
| `db.win.by_forfeit.10` | Still Counts | ✓ 10 | 10 | No | Ten wins by forfeit. |
| `db.win.by_forfeit.25` | Uncontested | ✓ 25 | 25 | **Yes** | Twenty-five forfeit wins. |

**Does not** increment `db.win.first`, `db.streak.win_*`, or `db.mode.*_win` — separate ladder so natural wins stay meaningful.

**Bot opponent:** Allowed — human beat bot via bot cannot forfeit, but human vs human + human vs bot (human wins when human concedes) both qualify when human is `winnerPlayerId`.

---

## 7. Brainstorm — situational & social

Ship Phase 2+ after conceder / win-by-forfeit ladders prove fun. Predicates assume forfeit metadata on `MatchRecord` + session snapshot.

### 7.1 Multi-player & picker flow

| ID | Name (en) | Predicate | Notes |
|----|-----------|-----------|-------|
| `db.forfeit.3p_concede` | Third Wheel | Human is `forfeitedByPlayerId` in match with **≥ 3** participants | Bar league drop-out |
| `db.forfeit.group_end` | Table Vote | Any human initiates forfeit in **≥ 4** player match | Counts once per match for initiator only |
| `db.forfeit.judge` | Tiebreaker | Human selected `winnerPlayerId` via **user_picked** resolution ([`MatchForfeitSpec.md`](MatchForfeitSpec.md) §7.2) | Once per match |
| `db.forfeit.saved_the_table` | Saved the Table | Forfeit with **≥ 2** other humans still in standings (3+ player, you concede, someone else wins) | Rewards ending a stuck game |

### 7.2 “Meaningful partial” play

| ID | Name (en) | Predicate | Notes |
|----|-----------|-----------|-------|
| `db.forfeit.after_legs` | Mid-Match Exit | Forfeit X01/Cricket after **≥ 1 leg** completed (`legsWon` sum > 0) | Not first-visit bail |
| `db.forfeit.deep_in` | Deep Before Sleep | Forfeit when **≥ 50%** of human darts in match are thrown vs average match length for mode | Needs baseline table |
| `db.forfeit.with_points` | Something on the Board | Forfeit with **≥ 30** human points scored (X01 applied totals) or **≥ 5** cricket marks | “We played for real” |

### 7.3 Ironic / hidden (Tier C)

| ID | Name (en) | Predicate | Hidden |
|----|-----------|-----------|--------|
| `db.forfeit.after_180` | Maximum Then Minimum | Score **180** then forfeit **same match** | Yes |
| `db.forfeit.after_bust` | Bust and Bail | **Bust** then forfeit same X01 match | Yes |
| `db.forfeit.one_dart` | One and Done | Forfeit with exactly **1** event (one visit) | Yes |
| `db.forfeit.never_100` | Finisher’s Honor | **100** completed wins without ever being `forfeitedByPlayerId` | Yes |
| `db.forfeit.same_day_both` | Full Circle | **Win by forfeit** and **concede** on the **same calendar day** | Yes |
| `db.forfeit.bot_witness` | Bot Saw That | Concede in match with **≥ 1 bot** and **≥ 1 human** | Yes |

### 7.4 Mode-flavored (when party modes + achievements align)

| ID | Mode | Predicate |
|----|------|-----------|
| `db.forfeit.baseball_runs` | Baseball | Forfeit with **≥ 5** cumulative runs |
| `db.forfeit.killer_lives` | Killer | Concede while still **≥ 2** lives |
| `db.forfeit.shanghai_lead` | Shanghai | Concede while **leading** cumulative points |
| `db.forfeit.cricket_close` | Cricket | Concede after closing **≥ 3** targets |

### 7.5 Anti-patterns — do **not** ship

| Idea | Why skip |
|------|----------|
| “Forfeit **without** scoring” | Encourages empty forfeit; UI hides Save & Forfeit at `eventCount == 0` |
| “Forfeit **more than** opponent” race | Toxic in multi-player |
| “Fastest forfeit” (time-based) | Rewards throwaway games |
| Achievements on **abandon** | Abandon has no stats contract |
| Shame badges visible on profile | Hidden-only or omit |

---

## 8. Presentation

| Surface | Behavior |
|---------|----------|
| **Match summary (forfeit)** | When achievements enabled: show **Achievements** section like natural completion ([`MatchSummarySpec.md`](MatchSummarySpec.md)), but **no** trophy animation — reuse forfeit banner chrome |
| **Profile / Badges** | Conceder medals use **amber/neutral** palette, not gold — [`BadgesSpec.md`](BadgesSpec.md) |
| **History row** | No achievement hint on list; detail optional “Unlocked Walkover this session” |

Copy tone examples:

- `db.forfeit.first.description` — “You ended a match early and kept your stats. Sometimes that’s the right call.”
- `db.win.by_forfeit.first.description` — “Your opponent conceded. A win is a win.”

---

## 9. Data model extensions

Add to `LifetimeCounters` ([`AchievementCatalogPhase1.md`](AchievementCatalogPhase1.md) §5.2):

| Field | Used by |
|-------|---------|
| `lifetimeMatchesForfeitedAsConceder` | `db.forfeit.*` |
| `lifetimeWinsByForfeit` | `db.win.by_forfeit.*` |
| `hasEverForfeitedAsConceder` | `db.forfeit.never_100` (inverse) |
| `lifetimeForfeitJudgePicks` | `db.forfeit.judge` |

Recompute from history: include `status == forfeited` rows; read `forfeitedByPlayerId` / `winnerPlayerId` from `MatchSummary` ([`SchemaV3`](SwiftData.md)).

---

## 10. Analytics

Add when implemented ([`FirebaseBackendAnalyticsSpec.md`](FirebaseBackendAnalyticsSpec.md)):

| Event | Parameters |
|-------|------------|
| `achievement_unlocked` | existing + `match_status=forfeited` when hook is forfeit |
| `achievement_forfeit_milestone` | `achievement_id`, `conceder_count` or `win_by_forfeit_count` |

---

## 11. Testing

| Case | Assert |
|------|--------|
| First conceder forfeit | `db.forfeit.first` |
| 5th conceder forfeit | `db.forfeit.5` progress / unlock |
| Win when opponent forfeits | `db.win.by_forfeit.first`; **not** `db.win.first` |
| Abandoned match | No forfeit achievements |
| `eventCount == 0` | Cannot forfeit — no delta |
| Solo forfeit | Conceder only; no win-by-forfeit |
| 3p: Carol concedes | Only Carol gets conceder +1 |
| Bot-only match | Zero deltas |

---

## 12. Rollout

| Phase | Deliverable |
|-------|-------------|
| **Forfeit ship (1.0)** | No achievement hooks on summary ([`MatchForfeitSpec.md`](MatchForfeitSpec.md)) |
| **Achievements Phase 1** | No forfeit rows — natural completion only |
| **Achievements Phase 2b** | §5 conceder ladder + §6 win-by-forfeit |
| **Achievements Phase 3** | §7 hidden / situational subset |

Promote brainstorm rows to locked manifest only after playtesting copy and hidden flags.

---

## 13. Cross-spec updates

| Spec | Change |
|------|--------|
| [`AchievementsSpec.md`](AchievementsSpec.md) | §4.2 — forfeited match rules; §8 Phase 2b pointer |
| [`AchievementCatalogPhase1.md`](AchievementCatalogPhase1.md) | §12.5 — summary table + link here |
| [`MatchForfeitSpec.md`](MatchForfeitSpec.md) | §9.3 — link to this spec for post-1.0 achievements |
| [`FutureIdeas/achievements.md`](../FutureIdeas/achievements.md) | Forfeit category in catalog |
| [`StatsSpec.md`](StatsSpec.md) | Confirm forfeited ∈ games played (already via forfeit spec) |

---

## 14. Verification

| Field | Value |
|-------|--------|
| **Last verified** | 2026-06-11 |
| **Commit** | (spec authoring — no implementation) |
| **Depends on** | `MatchForfeitSpec` shipped, `enableAchievements`, `PlayerAchievementRecord` |
