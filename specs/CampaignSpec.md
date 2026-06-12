# Campaign Mode Specification

## 1. Purpose

Define **Journey** — Dart Buddy’s single-player campaign: progression UI, scripted matches against bots, star ratings, and local content — built on existing match engines without a second play stack.

**Related specs:** Bots — [`BotOpponentSpec.md`](BotOpponentSpec.md), [`CustomBotSpec.md`](CustomBotSpec.md). Match lifecycle — [`MatchSpec.md`](MatchSpec.md). Summary — [`MatchSummarySpec.md`](MatchSummarySpec.md). Stats (separate) — [`StatsSpec.md`](StatsSpec.md). Achievements (addon later) — [`AchievementsSpec.md`](AchievementsSpec.md). Daily engagement — [`DailyChallengeSpec.md`](DailyChallengeSpec.md). Reset — [`DeleteAllDataSpec.md`](DeleteAllDataSpec.md). R&D brief — [`FutureIdeas/campaign-mode.md`](../FutureIdeas/campaign-mode.md).

**Status:** Post-1.0 R&D — feature-flagged. Decisions in §16 and star rules (§8) are **directional** until implementation; nothing here blocks experimentation.

---

## 2. Product Positioning

| Principle | Rule |
|-----------|------|
| **Real matches** | Every stage runs through existing engines (`X01`, `Cricket`, party modes as content ships). |
| **Primary journey** | Campaign progress is **per install**; tied to one designated primary human player (§4). |
| **No free-play gating** | Campaign does **not** lock modes in Play/Modes tabs — all shipped modes stay available. Campaign is optional tutorial/ladder content. |
| **Separate stats** | Campaign matches are tagged; aggregates for Activity/Statistics exclude campaign by default (or use a dedicated filter). |
| **Unlimited retries** | v1: no lives, energy, or cooldown on stage failure. |
| **Local content** | Stages ship as bundled JSON; room for remote packs later. |
| **Analytics only** | Firebase Analytics events in v1 — no Auth/Firestore sync until a future phase. |
| **Generic boss** | v1 uses archetype bosses (e.g. “The Challenger”); named pro likenesses deferred. |

---

## 3. Scope by Phase

### Phase 1 — Ladder shell (MVP)
- Feature flag `enableCampaign`
- New **Journey** tab (central tab — placement open for debate; default proposal: 5th or 6th tab)
- `CampaignProgressRecord` + bundled Act 1 JSON (~5–10 X01 stages, 1 generic boss)
- Map/list UI, stage briefing, scripted start → existing match → campaign summary
- Stars: **1★ = win** only until star rules finalized (§8)
- Unlimited retries
- Primary player designation on **first Journey tab visit** (not app onboarding) — §4
- Delete all data clears campaign progress — [`DeleteAllDataSpec.md`](DeleteAllDataSpec.md) §6.6

### Phase 2 — Mode mix
- Cricket, Killer, Baseball, Shanghai stages using shipped engines
- Boss intro sheet (generic archetype)
- History filter: Campaign matches
- Campaign-specific achievements (addon to [`AchievementsSpec.md`](AchievementsSpec.md))

### Phase 3 — Polish & content
- 2★ / 3★ criteria per stage (§8)
- Side paths, replay for stars
- Historical scenario stages (prefilled leg state) — requires `MatchSpec` extension
- Campaign badge gallery integration — [`BadgesSpec.md`](BadgesSpec.md)
- Optional **Delete campaign data only** in Settings (separate from reset all)

### Phase 4 — Cloud (future)
- Firebase Auth + Firestore sync for primary player progress — separate spec amendment to [`FirebaseBackendAnalyticsSpec.md`](FirebaseBackendAnalyticsSpec.md)

### Out of scope (v1)
- Free-play mode unlock gates
- Real-player likeness bosses without legal review
- Export/import of campaign progress
- Figma-required gate before code (skipped per product decision)

---

## 4. Primary Player

### 4.1 Designation (deferred onboarding)
- **Do not** block app onboarding for primary player.
- On **first open of Journey tab**, if no primary exists:
  - Prompt: *“Who’s on this journey?”* — pick existing human or create name
  - Set exactly one `PlayerRecord` with `playerRole == .primary`
- **Migration:** On schema upgrade, optionally promote oldest non-bot human by `createdAt` to primary; others remain guests.

### 4.2 Rules
- One primary per install (enforced in repository)
- Campaign stages auto-bind **primary** as sole human; no roster picker
- Guest players: visible in free Play; **not** selectable in campaign
- Guest player detail: stats + matches; optional upsell copy that Journey is personal per device

### 4.3 Schema (conceptual — implement in `SwiftData.md`)

```swift
enum PlayerRole: String, Codable { case primary, guest }

// PlayerRecord additions (future schema version)
var playerRoleRaw: String?   // .primary | .guest

// CampaignProgressRecord
var primaryPlayerId: UUID
var stageStars: [String: Int]   // stageId → 0–3
var lastPlayedStageId: String?
var updatedAt: Date

// MatchRecord additions
var campaignStageId: String?
var isCampaignMatch: Bool
```

---

## 5. Navigation & IA

### 5.1 Journey tab
- Tab label (localized): **Journey**
- Icon: `map.fill` (or dartboard-path custom symbol — test at tab size)
- Root: `CampaignMapView` inside `NavigationStack`
- Feature-flagged off → tab hidden entirely

**Open for debate:** 5-tab vs 6-tab layout vs replacing an existing tab. Document final choice in [`NavigationSpec.md`](NavigationSpec.md) when implemented.

### 5.2 Routes (proposed)
- `CampaignRoute.map`
- `CampaignRoute.stageDetail(stageId)`
- `CampaignRoute.activeMatch` → delegates to existing `PlayRoute` with campaign context

### 5.3 Continue card
- **Separate** from Play home redesign — Journey tab owns “Continue” when a stage is in progress
- Optional: compact Journey promo on Play home **only** via explicit product decision later; not required for Phase 1

### 5.4 Deep links (future)
- `dartbuddy://v1/journey` → Journey tab
- `dartbuddy://v1/journey/stage/{id}` → stage briefing

---

## 6. Core Loop

1. Primary player opens Journey → map/list of stages
2. Tap available node → **stage briefing** (mode, rules, opponent, win condition, star goals)
3. **Start** → scripted match (primary vs bot)
4. **Win** → stars recorded, next node unlocked, campaign summary
5. **Loss** → retry unlimited; return to briefing or map

Campaign matches tagged `isCampaignMatch == true` + `campaignStageId` for history and stats separation.

---

## 7. Stage Content (bundled JSON)

**Location (proposed):** `Resources/Campaign/act1.json`

### 7.1 Stage document shape

```json
{
  "id": "act1.stage03",
  "actId": "act1",
  "displayOrder": 3,
  "title": "First 501",
  "matchType": "x01",
  "config": {
    "startScore": 501,
    "legsToWin": 1,
    "checkout": "doubleOut"
  },
  "opponent": {
    "kind": "preset",
    "difficulty": "easy"
  },
  "prerequisites": ["act1.stage02"],
  "starCriteria": [
    { "stars": 1, "rule": "win" },
    { "stars": 2, "rule": "tbd" },
    { "stars": 3, "rule": "tbd" }
  ],
  "isBoss": false
}
```

### 7.2 Boss stage (v1)

```json
{
  "id": "act1.boss01",
  "isBoss": true,
  "title": "The Challenger",
  "opponent": {
    "kind": "customMetrics",
    "displayName": "The Challenger",
    "metrics": { "x01Average": 55, "cricketMPR": 2.2 }
  },
  "intro": {
    "subtitle": "Act 1 Finale",
    "quote": "Finish strong."
  }
}
```

No real names or likenesses in v1.

**Difficulty scaling (roadmap):** v1 ships one generic boss per act with hand-tuned `CustomBotMetrics`. Later acts increase `x01Average` / `cricketMPR` and match format (legs, start score) — document per-act targets in JSON manifest `difficultyTier` when content pipeline matures. No named-pro roster until legal review.

### 7.3 Loader
- `CampaignContentLoader` validates JSON at launch; fail soft with empty act + diagnostic log
- Version field in manifest for future OTA packs

---

## 8. Star Rules (TBD — framework)

**v1 ship:** `1★ = win the match`. Store 0–3 per stage; display 2★/3★ slots as locked until rules defined.

**Future rule types (enumerate when ready):**

| Rule id | Description |
|---------|-------------|
| `win` | Win the match |
| `win_under_darts` | Win with total darts ≤ N |
| `win_legs_2_0` | Win 2–0 in legs |
| `checkout_at_least` | Checkout ≥ N |
| `no_bust` | Zero bust turns |
| `cricket_close_all_by_round` | Close all numbers by round N |

`CampaignStarEvaluator` — pure function: `(stage, match events) → earnedStars`. Unit-tested per rule.

**Replay:** Clearing a stage again may improve star count; store `max(stars)`.

---

## 9. Campaign Badges (Phase 2+)

Separate from generic achievements — optional collectibles (boss defeated, act cleared). Same `BadgeMedal` UI — [`BadgesSpec.md`](BadgesSpec.md). Persist in `PlayerBadgeRecord` (primary only). Not required for Phase 1.

---

## 10. Stats & History

### 10.1 Separation
- Campaign matches included in **match history** with Campaign badge on row
- **Statistics tab:** default filters exclude `isCampaignMatch` (or dedicated “Campaign” filter chip)
- **Player stats:** campaign matches excluded from free-play career stats unless user toggles “Include Journey”

### 10.2 Match summary
- `CampaignMatchSummaryView` extends [`MatchSummaryScreen`](../Features/Play/Shared/MatchSummaryScreen.swift): star reveal, **Next stage** / **Try again** / **Back to map**
- Generic achievement unlocks still follow [`AchievementsSpec.md`](AchievementsSpec.md) on same summary when applicable

---

## 11. UI (custom map + accessibility)

### 11.1 Map view
- Vertical path of stage nodes (primary layout)
- Node states: locked, available, in-progress, cleared (1–3 stars), boss variant
- `CampaignAccent` tokens — see brainstorm plan § UI

### 11.2 Accessibility fallback
- **Required:** `CampaignMapListFallback` — same data as vertical list rows at AXXXL Dynamic Type or when “Prefer list” accessibility setting is on (product may use system Dynamic Type threshold only)
- VoiceOver: stage number, mode, stars, availability

No Figma gate before implementation.

---

## 12. Feature Flags

| Flag | Default | Launch arg |
|------|---------|------------|
| `enableCampaign` | `false` | `-enable_campaign` |

See [`FeatureFlagConfigSpec.md`](FeatureFlagConfigSpec.md).

---

## 13. Delete & Reset

| Action | Campaign data |
|--------|----------------|
| **Reset all local data** | Clears `CampaignProgressRecord`, `PlayerBadgeRecord`, campaign flags on matches, primary role (fresh install state) |
| **Delete campaign only** (Phase 3) | Clears progress + badges; leaves players and free-play history |

Details: [`DeleteAllDataSpec.md`](DeleteAllDataSpec.md) §6.6.

---

## 14. Analytics

Allowlisted when implemented ([`FirebaseBackendAnalyticsSpec.md`](FirebaseBackendAnalyticsSpec.md)):
- `campaign_tab_opened`
- `campaign_stage_started` — `stage_id`, `match_type`
- `campaign_stage_completed` — `stage_id`, `stars`, `outcome` (win/loss)
- `campaign_primary_designated`

No PII; hash `primary_player_id` if needed.

---

## 15. Testing

| Layer | Cases |
|-------|-------|
| Content loader | Valid/invalid JSON |
| Progression | Prerequisite unlock chain |
| Star evaluator | Win → 1★ in v1 |
| Primary | Only primary starts campaign match |
| Reset | Progress cleared on reset all |
| Flags | Tab hidden when flag off |

---

## 16. Open Questions (tracked)

| # | Topic | Current lean |
|---|-------|--------------|
| 1 | Tab bar placement | New Journey tab; exact index TBD |
| 2 | Star rules 2★/3★ | Defer past Phase 1 |
| 3 | Play home Journey card | Defer — Journey tab owns continue |
| 4 | Campaign achievements | Phase 2 addon |
| 5 | Boss difficulty curve | Generic v1; per-act metrics roadmap in §7.2 |

---

## 17. Verification

| Field | Value |
|-------|--------|
| **Last verified** | 2026-06-11 |
| **Commit** | (spec authoring — no implementation yet) |
| **Code** | (planned) `Features/Campaign/`, `Resources/Campaign/` |
