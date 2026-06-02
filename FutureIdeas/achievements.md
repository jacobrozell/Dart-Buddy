# Game Center Achievements — Assessment & Catalog

Assessment for [todo.md](../todo.md) item: *Add Game Center support with achievements*.

---

## Executive summary

| Dimension | Rating | Notes |
|-----------|--------|-------|
| **Overall difficulty** | **Medium** | No Game Center code exists today, but dart-level event data is already rich enough for most ideas. |
| **MVP (auth + ~8 achievements + reporting)** | **2–4 dev days** | Assumes App Store Connect setup, sandbox testing, and human-only counting rules are decided up front. |
| **Polished v1 (UI, retroactive unlock, edge cases, QA)** | **1–2 weeks** | Offline retry, bot rules, localization, and manual Game Center QA add time. |
| **Risk** | **Low–medium** | GameKit is mature; main risk is product rules (bots, local players, margins) not engineering. |

**Bottom line:** This is a good post-1.0 feature. The app already stores per-dart events (`X01DartEvent`, `CricketDartTouch`) and aggregates stats in `StatsService` — achievements are mostly *when to report*, not *how to detect*.

---

## Why the codebase is well positioned

- **Immutable turn events** are the source of truth (`X01TurnEvent`, `CricketTurnEvent`) with segment, multiplier, visit total, checkout, and bust flags.
- **`StatsService.breakdowns`** already counts triples, doubles, highest visit, checkouts, and sector hits — many achievement checks can reuse the same reducers.
- **Match completion** is a clear hook (`completeMatch`, `MatchLifecycleSession.runtime.status == .completed`) in both X01 and Cricket view models.
- **No external dependencies required** — GameKit is Apple-native, consistent with [specs/TechStackSpec.md](../specs/TechStackSpec.md).

## Gaps to close first

| Gap | Impact |
|-----|--------|
| No Game Center entitlement / GameKit wiring | Blocker — add capability in Xcode + App Store Connect |
| No signed-in player concept | Achievements attach to `GKLocalPlayer`, not local roster UUIDs |
| Bot vs human attribution | Must define which throws count (human-entered turns only is recommended) |
| “Win by 100+ points” undefined | X01 margin ≠ Cricket margin; need explicit formula |
| No achievement persistence layer | Optional local cache for offline queue + retroactive backfill |
| Testing | Unit-test evaluators; Game Center itself needs sandbox manual QA |

---

## Design decisions (decide before building)

### 1. Who earns achievements?

**Recommended:** One Game Center account per device install. Any **human-entered** dart counts toward that GC player’s progress, regardless of which local roster name is selected.

- Bot-entered darts: **never** count.
- Bot-vs-bot matches: **never** count toward “games played.”
- At least one human participant required per match for match-level achievements.

### 2. Do bot wins count?

**Recommended:** Yes for *win* achievements (beating a bot is still a win), but tier achievements like “Beat Hard bot” should require winning against that difficulty specifically.

### 3. Retroactive unlock on first sign-in?

**Recommended:** Yes — scan completed match events in SwiftData once, report unlocked achievements with `showsCompletionBanner = false` for bulk catch-up. Good UX for existing users.

### 4. “Win by more than 100 points”

Define per mode at match end:

| Mode | Suggested rule |
|------|----------------|
| **X01** | Sum of all opponents’ `remainingScore` at match end (winner at 0). Example: 501 match, opponent left on 132 → margin 132. |
| **Cricket** | Winner score minus highest opponent score ≥ 100. |

Only award when the signed-in human is the winner.

### 5. Abandoned / partial matches

Do **not** count toward “games played” or wins. Only `status == .completed`.

---

## Recommended architecture

```
Domain/Achievements/
  AchievementDefinition.swift      // IDs, thresholds, hidden flags
  AchievementEvaluator.swift       // Pure functions: events → [AchievementProgress]
Support/GameCenter/
  GameCenterAuthService.swift      // GKLocalPlayer authenticate
  GameCenterAchievementService.swift // report(GKAchievement), queue offline
Features/Settings/
  GameCenterSettingsSection.swift  // sign in, view achievements (optional MVP)
```

**Hook points**

1. **After human turn accepted** — visit/dart achievements (T20, 180, bull, ton-up).
2. **On match completed** — games played, wins, margins, mode-specific wins.
3. **On first GC authentication** — retroactive scan + batch report.

Keep `AchievementEvaluator` pure and testable (same pattern as `StatsService`).

---

## Achievement catalog

Apple allows up to **100 achievements** per app. Start with **15–25**; expand later.

Legend: **Impl** = implementation effort · **Hidden** = hide until unlocked · **Inc** = incremental (report percent complete)

### Tier A — From your todo (ship first)

| ID | Name | Description | Trigger | Impl |
|----|------|-------------|---------|------|
| `db.play.first` | First Match | Complete your first game. | 1 completed match with human input | Easy |
| `db.play.50` | Regular | Complete 50 games. | 50 completed matches | Easy (Inc) |
| `db.play.100` | Dedicated | Complete 100 games. | 100 completed matches | Easy (Inc) |
| `db.dart.first_t20` | Treble Twenty | Hit your first triple 20. | Any human dart: T20 | Easy |
| `db.visit.180` | Maximum | Score 180 in a visit (three treble 20s). | X01 visit `appliedTotal == 180` or 3× T20 darts | Easy |
| `db.dart.bull` | Bullseye | Hit the inner bull. | `segmentRaw == innerBull` | Easy |
| `db.win.margin_100` | Runaway Victory | Win a match by 100+ points. | See margin rules above | Medium |

### Tier B — High-value, on-brand extras

| ID | Name | Description | Trigger | Impl |
|----|------|-------------|---------|------|
| `db.play.10` | Warm Up | Complete 10 games. | 10 matches | Easy (Inc) |
| `db.visit.100` | Ton Up | Score 100+ in a single visit. | X01 `appliedTotal >= 100` | Easy |
| `db.visit.140` | Big Score | Score 140+ in a single visit. | X01 `appliedTotal >= 140` | Easy |
| `db.checkout.any` | Finished It | Checkout to win a leg. | `didCheckout == true` | Easy |
| `db.checkout.100_plus` | Big Checkout | Checkout on 100 or more. | Checkout with `startRemaining >= 100` | Easy |
| `db.checkout.170` | Maximum Checkout | Checkout on exactly 170. | `startRemaining == 170` && checkout | Medium |
| `db.mode.cricket_win` | Cricket Champion | Win a Cricket match. | Cricket match win | Easy |
| `db.mode.x01_win` | X01 Champion | Win an X01 match. | X01 match win | Easy |
| `db.mode.both` | All-Rounder | Win at least one X01 and one Cricket match. | Both win flags | Easy |
| `db.bot.beat_easy` | Beginner Beater | Beat a Very Easy bot. | Win vs `veryEasy` bot | Easy |
| `db.bot.beat_hard` | Bot Buster | Beat a Hard bot. | Win vs `hard` bot | Easy |
| `db.streak.win_3` | Hat Trick | Win 3 matches in a row. | 3 consecutive human wins | Medium |
| `db.streak.win_5` | On a Roll | Win 5 matches in a row. | 5 consecutive wins | Medium (Inc) |
| `db.legs.whitewash` | Whitewash | Win a match without losing a leg. | Win match; opponent `legsWon == 0` | Medium |
| `db.cricket.close_all` | Closed Out | Close all Cricket numbers in one match. | Human closes 20–15 + bull in one match | Medium |
| `db.cricket.5mark_turn` | Mark Machine | Score 5+ marks in one Cricket visit. | Sum `marksAdded >= 5` in one turn | Easy |
| `db.x01.no_bust_match` | Steady Hand | Win an X01 match without busting. | Win; zero human bust turns | Medium |
| `db.dart.t20_100` | T20 Hunter | Hit 100 treble 20s (lifetime). | Count T20 darts | Easy (Inc) |
| `db.play.days_7` | Week Warrior | Play on 7 different days. | 7 distinct calendar days with a completed match | Medium (Inc) |

### Tier C — Fun / hidden / stretch (post-MVP)

| ID | Name | Description | Trigger | Hidden |
|----|------|-------------|---------|--------|
| `db.visit.177` | Unlucky Legend | Score exactly 177 in a visit. | `appliedTotal == 177` | Yes |
| `db.bust.then_180` | Redemption | Bust, then score 180 later in the same match. | Same X01 match | Yes |
| `db.win.nine_dart_leg` | Nine-Dart Leg | Win a leg in 9 darts or fewer. | Leg dart count ≤ 9 | Yes |
| `db.play.500` | Hall of Fame | Complete 500 games. | 500 matches | Inc |
| `db.checkout.double_bull` | Eyes | Checkout on double bull. | Checkout dart is inner bull double | Yes |
| `db.cricket.shutout` | Shut the Door | Win Cricket while opponent has 0 marks on at least one target. | Niche rule — define carefully | Yes |
| `db.setup.add_player` | Squad Goals | Add a custom player to your roster. | First non-seeded player created | Easy |
| `db.stats.open` | Stat Nerd | Open the Statistics tab. | One-time UI event | Easy |
| `db.history.open` | Historian | Open the History tab. | One-time UI event | Easy |

### Tier D — Skip or defer

- **Online / multiplayer achievements** — no online play in 1.0 ([specs/OnlinePlaySpec.md](../specs/OnlinePlaySpec.md)).
- **Leaderboards** — separate Game Center feature; not required for achievements MVP.
- **Time-of-day gimmicks** (“Night Owl”) — weak fit for a scorekeeper; skip unless you want personality.
- **Average-based** (“Maintain 60+ avg over 10 games”) — confusing for casual players; better as local stats, not GC.

---

## Suggested rollout phases

### Phase 1 — Foundation (day 1)

- Enable Game Center capability + entitlements
- Create achievements in App Store Connect (IDs must match code)
- `GameCenterAuthService` — authenticate on launch or Settings
- `GameCenterAchievementService` — report + simple offline queue
- Unit tests for `AchievementEvaluator`

### Phase 2 — Core hooks (day 2–3)

- Tier A achievements (todo list)
- Human-only filtering at turn + match boundaries
- Incremental reporting for 50/100 games played

### Phase 3 — Polish (day 4+)

- Retroactive unlock on first sign-in
- Settings row: Game Center status + “View Achievements” (`GKAchievementViewController`)
- Tier B achievements
- Sandbox QA checklist

### Phase 4 — Later

- Hidden achievements
- Localization of achievement strings (GC displays ASC metadata; in-app copy via L10n if you build custom UI)
- Optional celebration toast when unlocking mid-match (respect Reduce Motion)

---

## App Store Connect checklist

- [ ] Enable Game Center on the app record
- [ ] Create each achievement with **exact** identifier matching code (e.g. `db.play.first`)
- [ ] Set point values (typically 5–100; reserve 100 for rare feats like 180 or 170 checkout)
- [ ] Mark hidden achievements in ASC
- [ ] Upload achievement images (required sizes per ASC)
- [ ] Test with sandbox Game Center account on device (simulator support is limited)

---

## Testing strategy

| Layer | Approach |
|-------|----------|
| **Evaluator** | Swift Testing — feed fixture `MatchStatsInput` / turn events, assert unlock set |
| **Integration** | Mock `GameCenterAchievementService` protocol in view models |
| **Manual** | Sandbox account; verify reporting in Game Center app |
| **Regression** | Ensure bot-only sessions never increment counters |

---

## Open questions for you

1. **Scope:** Achievements only, or Game Center leaderboards too (e.g. highest visit, games won)?
2. **Sign-in UX:** Silent authenticate on launch vs explicit Settings toggle?
3. **Mid-match unlock banners:** Show in-app celebration or rely on system Game Center notification?
4. **Cricket in v1:** Include Cricket achievements in MVP or X01-only first?
5. **Incremental caps:** Use Apple’s incremental achievements for 50/100 games, or single-shot thresholds only?

---

## Related files in codebase

| Area | File |
|------|------|
| Turn / dart events | `Domain/Engines/X01Engine.swift`, `Domain/Engines/CricketEngine.swift` |
| Stat aggregation | `Domain/Services/StatsService.swift` |
| Match completion | `Features/Play/X01MatchViewModel.swift`, `Features/Play/CricketMatchViewModel.swift` |
| Bot detection | `Domain/Models/RepositoryModels.swift` (`isBot`, `botDifficulty`) |
| Post-1.0 online | `specs/OnlinePlaySpec.md`, `specs/FirebaseBackendAnalyticsSpec.md` |
