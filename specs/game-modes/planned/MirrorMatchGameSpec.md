# Mirror Match Game Specification

## 1. Purpose

Define **Mirror Match** — solo or practice sparring against a **ghost bot** built from the player's own recent X01 or Cricket history (averages, checkout %, wedge tendencies), not a generic difficulty tier.

**Status:** Planned (`practice.mirrorMatch`).  
**Brainstorm origin:** [`FutureIdeas/custom-games-brainstorm.md`](../../../FutureIdeas/custom-games-brainstorm.md) §3.

**Related specs:**
- [`BotOpponentSpec.md`](../../BotOpponentSpec.md) — `CustomBotConfiguration`, ghost participant
- [`X01GameSpec.md`](../implemented/X01GameSpec.md) — checkout leg shape
- [`CricketSpec.md`](../implemented/CricketSpec.md) — mark leg shape
- [`HistorySpec.md`](../../HistorySpec.md) — source sessions for ghost build
- [`SoloPracticeModesSpec.md`](../../SoloPracticeModesSpec.md) — solo platform
- [`CampaignSpec.md`](../../CampaignSpec.md) — Journey mirror stages (optional)

---

## 2. Catalog metadata

| Field | Value |
|-------|-------|
| **Section** | Practice |
| **UI template** | A or B — `checkoutScore` / `markBoard` (base mode selected) |
| **Stat kind** | `ghostDelta` (new; margin vs ghost, improvement %) |
| **Ruleset (v1)** | `mirror_match_standard` |
| **Catalog id** | `practice.mirrorMatch` |
| **MatchType** | `mirrorMatch` (when implemented) |

**Display name:** Mirror Match  
**Marketing blurb:** "Beat yesterday's you."

---

## Player count

| Question | Answer |
|----------|--------|
| **Solo?** | **Yes** — primary shape (1 human vs ghost) |
| **Minimum** | 1 human |
| **Recommended** | 1 |
| **App maximum** | 1 human + 1 ghost |

---

## 3. MVP Scope

### In scope (v1)

| Item | Default | Configurable |
|------|---------|--------------|
| Base mode | **X01** | X01 / Cricket |
| X01 start | **501** | 301 / 501 / 701 |
| Legs | **Best of 3** | 1 / 3 / 5 |
| Ghost source | Last **10** completed matches of same base mode | 5 / 10 / 20 |
| Ghost fallback | Preset **Challenger** bot if <3 source matches | — |
| Ghost models | 3-dart average, checkout %, segment hit weights | — |
| Post-match | Delta card: checkout %, average, legs won vs ghost | — |
| History | Full `MatchRecord` + ghost profile snapshot id | — |

### Out of scope (v1)
- Ghost from another player's stats
- Live "shadow throw" visualization
- Mirror Fleet / Mirror Raid
- Cloud ghost sync

---

## 4. Product goals

| Goal | How Mirror Match delivers |
|------|---------------------------|
| **Data moat** | Uses local history competitors don't retain |
| **Personal progression** | Ghost updates as player improves |
| **Low novelty risk** | Underlying rules are familiar X01/Cricket |
| **Journey fodder** | "Beat your ghost" stage objectives |

---

## 5. Rules Engine (`MirrorMatchEngine`)

Coordinator + child engine + ghost policy.

### 5.1 Config (`MatchConfigMirrorMatch`, payload v1)

| Field | Type | Default |
|-------|------|---------|
| `baseMode` | `x01` \| `cricket` | `x01` |
| `x01Start` | Int | `501` |
| `legCount` | Int | `3` (best of) |
| `sourceMatchCount` | Int | `10` |
| `ghostProfileId` | UUID? | built at match start |

### 5.2 Ghost build (`GhostProfileBuilder`)

From last N `MatchRecord` of `baseMode`:

| Signal | Use |
|--------|-----|
| `threeDartAverage` | Bot visit mean |
| `checkoutPercentage` | Finish attempt success |
| `segmentHistogram` | Weighted target selection |
| `bustRate` | X01 bust simulation |

Persist snapshot on match record for reproducibility.

### 5.3 Match flow

1. Build ghost profile at setup.
2. Run child engine (`X01Engine` / `CricketEngine`) with human + `GhostBotParticipant`.
3. Ghost throws via `DartBotEngine` using profile weights (not preset tier).
4. On complete: compute deltas vs ghost's historical stats; show improvement card.

### 5.4 Win condition

Beat ghost on legs (X01) or points/marks (Cricket) per base mode rules.

---

## 6. UI notes

- Ghost avatar uses player's profile photo with ghost overlay.
- Side-by-side stat strip: You vs Ghost (historical vs live).
- Summary: "You improved checkout by {n}% vs your ghost."

---

## 7. Localization (draft)

| Key | EN (draft) |
|-----|------------|
| `play.rules.mirrorMatch.title` | Mirror Match |
| `play.rules.mirrorMatch.summary` | Spar against a bot built from your own recent games. |
| `play.mirror.ghostLabel` | Your ghost |
| `play.mirror.delta.checkout` | Checkout {delta}% vs ghost |

---

## 8. Open questions

1. Catalog row vs Journey-only entry?
2. Minimum source matches before ghost is "trusted"?
3. Cricket ghost: mark aggression model details?
