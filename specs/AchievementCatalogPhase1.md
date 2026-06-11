# Achievement Catalog — Phase 1 (Locked Manifest)

## 1. Purpose

Authoritative **Phase 1** achievement list: stable IDs, evaluation predicates, hook timing, and incremental rules. Implements the product slice described in [`AchievementsSpec.md`](AchievementsSpec.md) §8.

**Related:** Full long-term catalog — [`FutureIdeas/achievements.md`](../FutureIdeas/achievements.md). Campaign-only progression — [`CampaignSpec.md`](CampaignSpec.md) Phase 2 (`db.campaign.*`). Presentation — [`BadgesSpec.md`](BadgesSpec.md).

**Status:** Product-locked for Phase 1 implementation.

---

## 2. Scope

### In Phase 1 manifest (this document)
- **22 achievements** — first steps, scoring, finishing, consistency, milestones (see §4)
- X01-only for scoring/finishing rules; first steps / consistency / milestones apply to **any** completed match where the human participated
- Evaluation contract (§5) and shared eligibility (§3)

### Generic vs campaign-only (locked)

| Layer | IDs | Counts in Journey? |
|-------|-----|-------------------|
| **Generic** (this manifest) | `db.play.*`, `db.visit.*`, `db.streak.*`, … | **Yes** — campaign matches count toward generic unlocks |
| **Campaign progression** (separate) | `db.campaign.*` — act cleared, boss defeated, stage stars | **Campaign only** — ships with [`CampaignSpec.md`](CampaignSpec.md) Phase 2; not duplicated here |

### Phase 2+ roadmap (§12)

Mode wins, bot-tier beats (including volume vs a tier), party/Cricket expansions — drafted but **not** Phase 1.

### Phase 3+ (deferred)

Hidden / novelty achievements — see §12.3 and [`FutureIdeas/achievements.md`](../FutureIdeas/achievements.md) Tier C.

---

## 3. Shared Eligibility

All rows in §4 inherit these rules (see [`AchievementsSpec.md`](AchievementsSpec.md) §4):

| Rule | Behavior |
|------|----------|
| **Human only** | Evaluate per human participant (`isBot == false`). Bot darts/wins never count. |
| **Completed matches** | Match-level and streak rules require `MatchRecord.status == completed`. Abandoned matches do not advance volume/streak counters. |
| **Campaign matches** | **Included** for all generic Phase 1 achievements. Journey wins, 180s, volume, and streaks count. Campaign-specific `db.campaign.*` achievements are additive and evaluated separately. |
| **Multi-human** | Each human on the roster earns independently. |
| **Undo (summary)** | Re-evaluate from event history after **Undo last throw** reopens a completed match; revoke unlocks no longer satisfied. |
| **Timezone** | Calendar-day streaks use **device local** midnight boundaries. |
| **Minimum darts (averages)** | Match average rules require **≥ 9 human darts thrown** in that match (3 full visits). Below threshold → rule not satisfied (avoids 1-dart flukes). |

---

## 4. Phase 1 Catalog

**Legend:** **Hook** = when evaluator runs · **Inc** = incremental (`progressPercent` 0–100 until threshold)

### 4.0 First steps (onboarding)

Easy unlocks for early match-summary moments — meaningful gameplay, not tab/meta friction.

| ID | Name (en) | Hook | Inc | Predicate |
|----|-----------|------|-----|-----------|
| `db.play.first` | First Match | match complete | — | Human participated in **first** completed match (`completedMatchesPlayed == 1` after this match). |
| `db.win.first` | First Win | match complete | — | Human’s **first** completed match win (any mode). |
| `db.dart.first_t20` | Treble Twenty | turn accepted | — | First human dart with segment **20** and multiplier **triple** (T20). Any mode with dart events. |

### 4.1 Scoring

| ID | Name (en) | Hook | Inc | Predicate |
|----|-----------|------|-----|-----------|
| `db.avg.match_60` | Sharp Shooter | match complete | — | Human `x01Average3Dart ≥ 60` in this match (formula: [`StatsSpec.md`](StatsSpec.md) §4). X01 only. Min 9 darts (§6.4). |
| `db.avg.match_80` | Elite Average | match complete | — | Same with threshold **≥ 80**. X01 only. Min 9 darts. |
| `db.visit.180` | Maximum | turn accepted | — | Human X01 visit: `appliedTotal == 180`. |
| `db.visit.180_20` | Maximum Machine | turn accepted | ✓ 20 | Lifetime count of human X01 visits with `appliedTotal == 180` **≥ 20**. |
| `db.visit.180_100` | Century of Maximums | turn accepted | ✓ 100 | Same count **≥ 100**. |

### 4.2 Finishing

| ID | Name (en) | Hook | Inc | Predicate |
|----|-----------|------|-----|-----------|
| `db.checkout.100_plus` | Big Checkout | turn accepted | — | Human X01 visit: `didCheckout == true` **and** `startRemaining >= 100`. |
| `db.checkout.150_plus` | Huge Checkout | turn accepted | — | Same with `startRemaining >= 150`. |
| `db.checkout.rate_50` | Closer | match complete | — | **§6.1** — ≥ **3** checkout attempts, success rate **≥ 50%**, human **wins** X01 match. |
| `db.checkout.rate_100` | Perfect Finisher | match complete | — | **§6.1** — ≥ **3** checkout attempts, success rate **== 100%**, human **wins** X01 match. |

### 4.3 Consistency

| ID | Name (en) | Hook | Inc | Predicate |
|----|-----------|------|-----|-----------|
| `db.streak.win_3` | Hot Streak | match complete | — | **3 consecutive completed match wins** for this human. Any mode. §6.2. |
| `db.streak.days_3` | Three-Day Thrower | match complete | — | **3 consecutive calendar days** each with ≥ 1 completed match (human participated). §6.3. |
| `db.streak.days_7_consecutive` | Weekly Regular | match complete | — | **7 consecutive calendar days** with ≥ 1 completed match each. |
| `db.streak.days_30_consecutive` | Daily Darter | match complete | ✓ 30 | **30 consecutive calendar days** with ≥ 1 completed match each. Progress = `currentStreakDays / 30 × 100`. |

### 4.4 Milestones

| ID | Name (en) | Hook | Inc | Predicate |
|----|-----------|------|-----|-----------|
| `db.legs.win_100` | Leg Legend | match complete | ✓ 100 | Lifetime human **legs won** across all modes **≥ 100**. |
| `db.play.10` | Getting Started | match complete | ✓ 10 | Lifetime completed matches played (human participated) **≥ 10**. |
| `db.play.50` | Regular | match complete | ✓ 50 | Same **≥ 50**. |
| `db.play.100` | Dedicated | match complete | ✓ 100 | Same **≥ 100**. |
| `db.play.250` | Veteran | match complete | ✓ 250 | Same **≥ 250**. |
| `db.play.500` | Hall of Famer | match complete | ✓ 500 | Same **≥ 500**. |

**Games played tiers (locked):** 10 → 50 → 100 → 250 → 500. Low implementation cost — single counter, five incremental thresholds.

**Leg win counting:** Increment `legsWon` when a leg completes in this human’s favor. Single-leg match win = **1 leg won**.

---

## 5. Evaluation Contract

### 5.1 Input: `AchievementEvaluationContext`

```
matchId: UUID
matchType: MatchType
matchStatus: MatchStatus
isCampaignMatch: Bool
participants: [ParticipantSnapshot]
humanPlayerIds: [UUID]

latestTurn: TurnEvent?
allTurnEvents: [TurnEvent]

lifetimeCounters: LifetimeCounters     // per playerId — §5.2
```

### 5.2 `LifetimeCounters` (per human player)

| Field | Used by |
|-------|---------|
| `completedMatchesPlayed` | `db.play.first`, `db.play.*` |
| `matchWins` | `db.win.first` |
| `hasHitT20` | `db.dart.first_t20` |
| `legsWon` | `db.legs.win_100` |
| `lifetime180Visits` | `db.visit.180_20`, `db.visit.180_100` |
| `consecutiveMatchWins` | `db.streak.win_3` |
| `consecutiveCalendarDaysPlayed` | `db.streak.days_*` |
| `lastPlayedCalendarDay` | calendar streak boundaries |

### 5.3 Hook timing

| Hook | When | Achievements |
|------|------|--------------|
| **Turn accepted** | Human dart entry committed + persisted | `db.dart.first_t20`, `db.visit.180`, `db.visit.180_*`, `db.checkout.100_plus`, `db.checkout.150_plus` |
| **Match complete** | Transition to `completed` (before summary UI) | All match-level rows |

### 5.4 Output: `AchievementDelta`

```
playerId, achievementId, kind: unlock | progressUpdate | revoke
progressPercent: Int?
unlockedAt: Date?
```

---

## 6. Predicate Details

### 6.1 Checkout rate — minimum 3 attempts (critical rule)

`db.checkout.rate_50` and `db.checkout.rate_100` **must not unlock** unless the human had **at least three (3) checkout attempts** in that X01 match. This is a hard gate — rate is irrelevant below 3 attempts.

#### What counts as one checkout attempt

One **attempt** = one human X01 visit where **all** of:

1. `startRemaining <= 170` (player is on a finish),
2. At least **one dart was thrown** in the visit,
3. The visit is a genuine finish try (not skipped / not impossible leave per engine rules).

**Success** = that visit has `didCheckout == true`.

#### Rate formula

```
attempts = count(visits matching attempt definition)
successes = count(those visits where didCheckout == true)
rate = successes / attempts   (only defined when attempts >= 3)
```

#### Additional requirements (both rate achievements)

- Match type **X01** only.
- Human must be the **match winner**.
- Match status **completed**.

#### Explicit will-NOT-unlock examples

| Scenario | Attempts | Successes | Rate | Unlocks? |
|----------|----------|-----------|------|----------|
| 2/2 made, won match | **2** | 2 | 100% | **No** — fewer than 3 attempts |
| 1/1 made, won match | **1** | 1 | 100% | **No** |
| 3/6 made, won match | 3 | 3 | 50% | **`db.checkout.rate_50` only** |
| 3/3 made, won match | 3 | 3 | 100% | **`db.checkout.rate_100`** (also satisfies 50%) |
| 4/4 made, **lost** match | 4 | 4 | 100% | **No** — must win |
| 5/10 made, won match | 5 | 5 | 50% | **`db.checkout.rate_50` only** |
| 0 attempts (opponent closed out in team format N/A for 1v1 bot) | 0 | 0 | — | **No** |

**UI copy hint:** Description strings should mention “at least 3 finish attempts in the match” so players understand why a perfect 2/2 leg does not qualify.

### 6.2 Win streak

- +1 on human match win; reset to **0** on loss.
- **Tie / no winner:** reset streak.
- Multi-leg: **match** outcome only.

### 6.3 Calendar-day streak

- Each completed match (human participated) marks that **local calendar day**.
- Same day again: no extra increment.
- Consecutive next day: +1 to streak.
- Gap ≥ 1 day: reset to **1** (today still counts).

### 6.4 Match average (60+ / 80+)

```
x01Average3Dart = (totalX01PointsScored / totalDartsThrown) * 3
```

Require `totalDartsThrown >= 9`. Bust scoring per [`StatsSpec.md`](StatsSpec.md).

---

## 7. Summary Presentation

| Event | Show on match summary |
|-------|----------------------|
| New unlock this session | Yes |
| Incremental threshold crossed | Yes — when crossing **10 / 50 / 100 / 250 / 500** games, **20 / 100** 180s, **100** legs, or **30** calendar days |
| Progress without threshold | No — gallery ring only |

---

## 8. Localization Keys

`achievement.{id}.name` / `.description` — dots → underscores (e.g. `achievement.db_play_250.name`).

Locales: `en`, `de`, `es`, `nl`.

---

## 9. Testing (evaluator fixtures)

| Case | Assert |
|------|--------|
| First completed match | `db.play.first` |
| First win | `db.win.first` |
| First T20 dart | `db.dart.first_t20` |
| 8 darts, 100 avg | No `db.avg.match_60` |
| 12 darts, 60 avg | Unlock `db.avg.match_60` |
| **2/2 checkout, win** | **No rate achievements** |
| **3/3 checkout, win** | `db.checkout.rate_100` |
| **3/6 checkout, win** | `db.checkout.rate_50` only |
| 4/4 checkout, **loss** | No rate achievements |
| Campaign match win | Counts toward `db.win.first`, `db.play.*`, streaks |
| 249 → 250th game | `db.play.250` on summary |
| Bot-only match | Zero deltas |

---

## 10. Resolved product decisions

| Topic | Decision |
|-------|----------|
| Onboarding trio | **In Phase 1** (§4.0) |
| Campaign generic eligibility | **Included**; `db.campaign.*` separate |
| Games played tiers | **10 / 50 / 100 / 250 / 500** |
| Checkout rate min attempts | **3** — hard gate (§6.1) |
| Match average min darts | **9** |
| Tie / no-winner | Resets win streak |

---

## 11. Verification

| Field | Value |
|-------|--------|
| **Last verified** | 2026-06-11 |
| **Commit** | (spec authoring) |
| **Code** | (planned) `Domain/Achievements/AchievementDefinition.swift` |

---

## 12. Phase 2+ roadmap (draft — not Phase 1)

Implement after Phase 1 ships. IDs align with [`FutureIdeas/achievements.md`](../FutureIdeas/achievements.md).

### 12.1 Mode wins

| ID | Predicate |
|----|-----------|
| `db.mode.x01_win` | Win a completed X01 match |
| `db.mode.cricket_win` | Win a completed Cricket match |
| `db.mode.both` | At least one X01 win **and** one Cricket win (lifetime flags) |
| `db.mode.party_win` | Win Baseball, Killer, or Shanghai (when shipped) |

### 12.2 Bot-tier beats

Bot-tier achievements apply when a **human wins** a **completed** match that included at least one qualifying bot opponent. Rules below supersede the old “preset-only, exact tier” draft.

#### 12.2.1 Tier ladder (locked)

Preset tiers have a fixed order:

```
veryEasy < easy < medium < hard < pro
```

**Ladder credit:** A win against effective tier **T** counts as beating **T and every lower tier** for **one-time** unlocks (`db.bot.beat_very_easy` … `db.bot.beat_pro`).

| Effective opponent tier | One-time unlocks granted on win |
|-------------------------|----------------------------------|
| `veryEasy` | veryEasy |
| `easy` | veryEasy, easy |
| `medium` | veryEasy, easy, medium |
| `hard` | veryEasy, easy, medium, hard |
| `pro` | all five |

Example: beat a **Hard** preset bot in a 1v1 → unlock `beat_very_easy`, `beat_easy`, `beat_medium`, and `beat_hard` in one summary (if not already unlocked).

**Volume counters** (`db.bot.beat_easy_10`, future `beat_hard_10`, etc.) use **ladder eligibility** but **+1 per match max** — see §12.2.3.

#### 12.2.2 Multi-bot matches (e.g. 1 human + 5 bots)

Dart Buddy supports N-player matches with multiple bot opponents at different tiers. On human **match win**:

1. Resolve **effective tier** for each qualifying bot opponent (§12.2.4).
2. Let **`maxOpponentTier`** = highest tier among those bots (by ladder order).
3. Apply **ladder credit** from **`maxOpponentTier`** only — **not** once per bot in the roster.

**Example:** 1 human + Very Easy, Easy, Medium, Hard, Pro bots → human wins → `maxOpponentTier = pro` → all five one-time bot beats credit **once** (same as beating Pro in a 1v1).

**Example:** 1 human + two Easy bots + one Medium bot → human wins → `maxOpponentTier = medium` → credits through medium (not double-count Easy twice).

**Loss:** No bot-tier credit, regardless of roster composition.

**Multi-human:** Each human winner (if multiple winners impossible in current engines — single `winnerPlayerId`) gets independent evaluation. In 2-human + bots free-for-all, only the winning human receives bot-tier credit.

#### 12.2.3 One-time vs volume rules

| Achievement kind | Rule |
|------------------|------|
| **One-time** (`db.bot.beat_*`) | On win, unlock every tier **≤ `maxOpponentTier`** not yet unlocked. |
| **Volume** (`db.bot.beat_easy_10`, …) | On win, if **`maxOpponentTier` ≥ target tier**, increment that volume counter by **1** (once per match). Beating Hard counts toward `beat_easy_10` because Hard ≥ Easy. |
| **`db.bot.beat_all`** | Lifetime: for each preset tier T, at least one win where **`maxOpponentTier` ≥ T**. A single Pro win satisfies all five. |

Volume achievements do **not** add +1 per bot in the roster and do **not** cascade +1 into every lower volume counter in one match (only the counters whose threshold tier is ≤ `maxOpponentTier` each get +1 — for `beat_easy_10` only that one counter matters).

#### 12.2.4 Effective tier resolution (`BotAchievementTierResolver`)

Evaluate from **`MatchParticipant` snapshot at match start** (stored on the completed session — never re-read live `PlayerRecord` after the match).

| Bot kind | Qualifies? | Effective tier |
|----------|------------|----------------|
| **Preset** (`botKindRaw == preset`) | Yes | `botDifficultyRaw` → `BotDifficulty` |
| **Custom** (`botKindRaw == custom`) | Yes | §12.2.5 — mapped from configuration / snapshot |
| **Training** (`botKindRaw == training`) | **No** | Excluded — mirrors a linked human’s skill; not ladder content |
| **Human** | No | — |
| **Legacy bot** (only `botDifficultyRaw`, no kind) | Yes | Treat as preset |

If no qualifying bot opponents → no bot-tier achievements for that match.

#### 12.2.5 Custom bots

Custom bots **do** count toward bot-tier achievements. Map skill to a preset tier using the same anchors as [`BotSkillProfileInterpolator`](../Domain/Engines/BotSkillProfileInterpolator.swift):

| Tier | X01 3-dart avg anchor | Cricket MPR anchor |
|------|----------------------|-------------------|
| veryEasy | 20 | 0.85 |
| easy | 29 | 1.25 |
| medium | 61 | 1.85 |
| hard | 75 | 2.45 |
| pro | 88 | 3.05 |

**Algorithm:**

1. Load `CustomBotConfiguration` from participant snapshot (payload / encoded config captured at match start).
2. Compute `tierX01` = highest tier whose X01 anchor is **≤** `configuration.x01Average`.
3. Compute `tierMPR` = highest tier whose MPR anchor is **≤** `configuration.cricketMPR`.
4. **Effective tier** = **max(`tierX01`, `tierMPR`)** by ladder order (use the harder of the two — a bot with Pro X01 but Easy MPR credits as Pro).
5. If `configuration.scoringBehaviorTier` is set, **effective tier** = max(step 4, `scoringBehaviorTier`) — optional floor/anchor from advanced editor.

**Examples:**

| Custom sliders | tierX01 | tierMPR | Effective |
|----------------|---------|---------|-----------|
| 30 avg / 1.25 MPR | easy | easy | easy |
| 75 avg / 1.0 MPR | hard | veryEasy | **hard** |
| 40 avg / 2.5 MPR | easy | hard | **hard** |

**Campaign boss** (`customMetrics` in stage JSON): same resolver using stage `x01Average` / `cricketMPR` — counts like a custom bot for generic bot achievements **and** campaign badges separately.

**Implementation:** Denormalized on `MatchParticipant.botEffectiveTierRaw` and `SchemaV2.MatchParticipantRecord.botEffectiveTierRaw` at match start via `BotParticipantFactory` + `BotAchievementTierResolver`. Evaluators read the snapshot; `BotAchievementTierResolver.effectiveTier(for:)` falls back for legacy rows.

#### 12.2.6 Catalog

| ID | Hook | Inc | Predicate |
|----|------|-----|-----------|
| `db.bot.beat_very_easy` | match complete | — | Win; **`maxOpponentTier` ≥ veryEasy** (ladder may have already unlocked via higher tier) |
| `db.bot.beat_easy` | match complete | — | Win; **`maxOpponentTier` ≥ easy** |
| `db.bot.beat_easy_10` | match complete | ✓ 10 | Win; **`maxOpponentTier` ≥ easy**; lifetime count **≥ 10** |
| `db.bot.beat_medium` | match complete | — | Win; **`maxOpponentTier` ≥ medium** |
| `db.bot.beat_hard` | match complete | — | Win; **`maxOpponentTier` ≥ hard** |
| `db.bot.beat_pro` | match complete | — | Win; **`maxOpponentTier` ≥ pro** |
| `db.bot.beat_all` | match complete | — | Lifetime wins cover every tier via ladder (§12.2.3) |

#### 12.2.7 Testing fixtures

| Scenario | Expected |
|----------|----------|
| 1v1 win vs Hard preset | One-time unlock through Hard; `beat_easy_10` +1 |
| 1 human + 5 tiers, human wins | Same as beating Pro once |
| 1 human + 5 tiers, human loses | No bot credit |
| Win vs custom 75/1.0 avg | Effective hard; same as Hard preset |
| Win vs Training Partner | No bot-tier credit |
| Win vs human only | No bot-tier credit |
| 2/2 wins vs Medium, then 8 vs Hard | `beat_easy_10` at 10 (Hard ≥ Easy each time) |

See also: [`BotOpponentSpec.md`](BotOpponentSpec.md), [`CustomBotSpec.md`](CustomBotSpec.md).

### 12.3 Hidden achievements (Phase 3+)

Ship with `hidden: true` in definition — locked silhouette until unlock. Examples:

| ID | Predicate |
|----|-----------|
| `db.visit.177` | X01 visit `appliedTotal == 177` |
| `db.bust.then_180` | Bust in match, later score 180 same match |
| `db.win.nine_dart_leg` | Win X01 leg in ≤ 9 darts |
| `db.visit.180_x3_match` | Three 180s in one X01 match |
| `db.avg.match_90` | Match avg ≥ 90 (min 9 darts) |
| `db.play.1000` | 1,000 completed matches (incremental, hidden) |

Full list: [`FutureIdeas/achievements.md`](../FutureIdeas/achievements.md) Tier C.

### 12.4 Campaign-only (`db.campaign.*`)

Owned by [`CampaignSpec.md`](CampaignSpec.md) Phase 2 — examples:

- `db.campaign.act1_clear` — complete Act 1
- `db.campaign.boss_defeat.{stageId}` — defeat boss stage
- `db.campaign.stars.{n}` — earn N total stars

Generic and campaign achievements may both unlock on the same campaign match summary.
