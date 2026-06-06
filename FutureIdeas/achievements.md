# Game Center Achievements — Assessment & Catalog

Assessment for [todo.md](../docs/release/todo.md) item: *Add Game Center support with achievements*.

---

## Executive summary

| Dimension | Rating | Notes |
|-----------|--------|-------|
| **Overall difficulty** | **Medium** | No Game Center code exists today, but dart-level event data is already rich enough for most ideas. |
| **MVP (auth + ~18 achievements + reporting)** | **2–4 dev days** | Assumes App Store Connect setup, sandbox testing, and human-only counting rules are decided up front. |
| **Polished v1 (UI, retroactive unlock, Tier B, QA)** | **1–2 weeks** | Offline retry, bot rules, party-mode evaluators, localization, and manual Game Center QA add time. |
| **Full catalog (~62 + per-mode expansions)** | **3–5 weeks** | Incremental counters, hidden achievements, all shipped modes, celebration UX. |
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

Apple allows up to **100 achievements** per app. Full catalog below is **~62** (7 + ~40 + ~15); ship **18** for MVP, grow in phases.

Legend: **Impl** = implementation effort · **Hidden** = hide until unlocked · **Inc** = incremental (report percent complete)

### Categories

Grouped by skill dimension. Items marked *(catalog)* already appear in a tier table below. **Mode** column notes when an achievement is limited to a `MatchType` or deferred until that engine ships.

#### Scoring — visits & averages

| Achievement | Trigger | Mode | ID / status |
|-------------|---------|------|-------------|
| First T20 | Hit first triple 20 | Any | *(catalog)* `db.dart.first_t20` |
| Ton up (100+) | Single visit `appliedTotal >= 100` | X01 | *(catalog)* `db.visit.100` |
| Big score (140+) | Single visit `appliedTotal >= 140` | X01 | *(catalog)* `db.visit.140` |
| First 180 | Score 180 in a visit | X01 | *(catalog)* `db.visit.180` |
| Two 180s in one match | ≥ 2 visits with `appliedTotal == 180` in same match | X01 | **New** `db.visit.180_x2_match` |
| Hat trick of 180s | 3× 180 in one match | X01 | **New** (Hidden) `db.visit.180_x3_match` |
| 60+ average in a match | Human 3-dart avg ≥ 60 (points ÷ darts × 3) | X01 | **New** `db.avg.match_60` |
| 70+ average in a match | Human 3-dart avg ≥ 70 | X01 | **New** `db.avg.match_70` |
| 80+ average in a match | Human 3-dart avg ≥ 80 | X01 | **New** `db.avg.match_80` |
| 90+ average in a match | Human 3-dart avg ≥ 90 | X01 | **New** (Hidden) `db.avg.match_90` |
| 60+ average in a leg | Leg-level 3-dart avg ≥ 60 | X01 | **New** `db.avg.leg_60` |
| 20 total 180s | Lifetime 180 visits ≥ 20 | X01 | **New** (Inc) `db.visit.180_20` |
| 100 total 180s | Lifetime 180 visits ≥ 100 | X01 | **New** (Inc) `db.visit.180_100` |
| T20 centurion | 100 lifetime T20 hits | Any | *(catalog)* `db.dart.t20_100` |
| T20 master | 500 lifetime T20 hits | Any | **New** (Inc) `db.dart.t20_500` |
| Bullseye | Hit inner bull | Any | *(catalog)* `db.dart.bull` |
| 50 lifetime bulls | 50 inner-bull hits | Any | **New** (Inc) `db.dart.bull_50` |
| 1,000 darts thrown | Lifetime human darts ≥ 1,000 | Any | **New** (Inc) `db.dart.1000` |
| 10,000 darts thrown | Lifetime human darts ≥ 10,000 | Any | **New** (Inc) `db.dart.10000` |

#### Finishing — checkouts & doubles

| Achievement | Trigger | Mode | ID / status |
|-------------|---------|------|-------------|
| First checkout | Win a leg via checkout (`didCheckout`) | X01 | *(catalog)* `db.checkout.any` |
| Checkout 40–99 | `startRemaining` in 40…99 && checkout | X01 | **New** `db.checkout.40_99` |
| Checkout 100+ | `startRemaining >= 100` && checkout | X01 | *(catalog)* `db.checkout.100_plus` |
| Checkout 150+ | `startRemaining >= 150` && checkout | X01 | **New** `db.checkout.150_plus` |
| Checkout 161 | Exactly 161 remaining && checkout | X01 | **New** `db.checkout.161` |
| Maximum checkout (170) | `startRemaining == 170` && checkout | X01 | *(catalog)* `db.checkout.170` |
| Double bull finish | Checkout dart is inner bull (double) | X01 | *(catalog)* `db.checkout.double_bull` |
| First-dart checkout | `checkoutDartCount == 1` | X01 | **New** `db.checkout.one_dart` |
| Two-dart checkout | `checkoutDartCount == 2` on 100+ | X01 | **New** `db.checkout.two_dart_100` |
| 50% checkout rate (match) | Success rate ≥ 50%, ≥ 3 attempts | X01 | **New** `db.checkout.rate_50` |
| 100% checkout rate (match) | All attempts succeed, ≥ 3 attempts | X01 | **New** `db.checkout.rate_100` |
| 10 lifetime checkouts | `checkouts >= 10` | X01 | **New** (Inc) `db.checkout.count_10` |
| 50 lifetime checkouts | `checkouts >= 50` | X01 | **New** (Inc) `db.checkout.count_50` |
| Highest checkout 120+ | Lifetime `highestCheckout >= 120` | X01 | **New** `db.checkout.high_120` |

> **Checkout rate rule:** Attempt = visit where `startRemaining <= 170` and human was on a finish (exclude bust-only visits). Success = `didCheckout` on that visit.

#### Consistency — streaks & habits

| Achievement | Trigger | Mode | ID / status |
|-------------|---------|------|-------------|
| First win | Win first completed match | Any | **New** `db.win.first` |
| Win 3 in a row | 3 consecutive match wins | Any | *(catalog)* `db.streak.win_3` |
| Win 5 in a row | 5 consecutive match wins | Any | *(catalog)* `db.streak.win_5` |
| Win 10 in a row | 10 consecutive match wins | Any | **New** (Hidden) `db.streak.win_10` |
| Play 3 days in a row | Match on 3 consecutive calendar days | Any | **New** `db.streak.days_3` |
| Play every day for a week | 7 consecutive calendar days | Any | **New** `db.streak.days_7_consecutive` |
| Play every day for a month | 30 consecutive calendar days | Any | **New** (Inc) `db.streak.days_30_consecutive` |
| 7 different days (any week) | 7 distinct days with a match | Any | *(catalog)* `db.play.days_7` |
| Weekend warrior | Matches on both Sat and Sun same weekend | Any | **New** `db.play.weekend` |
| Comeback kid | Win match after trailing by 2+ legs | Any | **New** `db.win.comeback_2legs` |
| Whitewash | Win match; all opponents `legsWon == 0` | Any | *(catalog)* `db.legs.whitewash` |
| Win without busting | Win X01 match; zero human bust turns | X01 | *(catalog)* `db.x01.no_bust_match` |

> **Streak reset:** Any completed match loss or non-human-only session breaks win streak. Calendar streak breaks if no completed match by local-midnight boundary.

#### Milestones — volume & career

| Achievement | Trigger | Mode | ID / status |
|-------------|---------|------|-------------|
| First match | 1 completed match | Any | *(catalog)* `db.play.first` |
| 10 / 50 / 100 / 500 games | Completed match thresholds | Any | *(catalog)* `db.play.10` … `db.play.500` |
| 250 games | 250 completed matches | Any | **New** (Inc) `db.play.250` |
| 1,000 games | 1,000 completed matches | Any | **New** (Inc, Hidden) `db.play.1000` |
| 10 match wins | Lifetime wins ≥ 10 | Any | **New** (Inc) `db.win.10` |
| 50 match wins | Lifetime wins ≥ 50 | Any | **New** (Inc) `db.win.50` |
| 100 match wins | Lifetime wins ≥ 100 | Any | **New** (Inc) `db.win.100` |
| Win 10 legs | Lifetime legs won ≥ 10 | Any | **New** (Inc) `db.legs.win_10` |
| Win 100 legs | Lifetime legs won ≥ 100 | Any | **New** (Inc) `db.legs.win_100` |
| Win 500 legs | Lifetime legs won ≥ 500 | Any | **New** (Inc) `db.legs.win_500` |
| Runaway victory | Win by 100+ points | X01 / Cricket | *(catalog)* `db.win.margin_100` |

#### Modes — standard & party

| Achievement | Trigger | Mode | ID / status |
|-------------|---------|------|-------------|
| X01 champion | Win an X01 match | X01 | *(catalog)* `db.mode.x01_win` |
| Cricket champion | Win a Cricket match | Cricket | *(catalog)* `db.mode.cricket_win` |
| All-rounder | Win ≥ 1 X01 and ≥ 1 Cricket | Multi | *(catalog)* `db.mode.both` |
| Party starter | Win Baseball, Killer, or Shanghai | Party | **New** `db.mode.party_win` |
| Mode explorer | Complete ≥ 1 match in each shipped mode | Multi | **New** `db.mode.all_shipped` |
| 301 specialist | Win a 301 match | X01 | **New** `db.mode.301_win` |
| 501 specialist | Win a 501 match | X01 | **New** `db.mode.501_win` |
| Cutthroat cricket | Win Cricket with points-on | Cricket | **New** `db.cricket.cutthroat_win` |
| Baseball champion | Win a Baseball match | Baseball | **New** `db.baseball.win` |
| Grand slam inning | Score max runs in one Baseball inning | Baseball | **New** `db.baseball.max_inning` |
| Killer champion | Win a Killer match | Killer | **New** `db.killer.win` |
| Last one standing | Win Killer as last player with lives | Killer | **New** `db.killer.survivor` |
| Shanghai! | Hit single + double + triple of round target in one visit | Shanghai | **New** `db.shanghai.instant` |
| Shanghai champion | Win a Shanghai match | Shanghai | **New** `db.shanghai.win` |

#### Cricket — marks & closes

| Achievement | Trigger | Mode | ID / status |
|-------------|---------|------|-------------|
| Mark machine | 5+ marks in one visit | Cricket | *(catalog)* `db.cricket.5mark_turn` |
| 7-mark visit | 7 marks in one visit (e.g. 2× T20 + T19) | Cricket | **New** `db.cricket.7mark_turn` |
| Closed out | Close 20–15 + bull in one match | Cricket | *(catalog)* `db.cricket.close_all` |
| 100 lifetime marks | `cricketMarks >= 100` | Cricket | **New** (Inc) `db.cricket.marks_100` |
| 3 MPR in a match | Marks per round ≥ 3.0 | Cricket | **New** `db.cricket.mpr_3` |
| Shut the door | Win while opponent has 0 marks on a closed target | Cricket | *(catalog)* `db.cricket.shutout` |

#### Bots & opponents

| Achievement | Trigger | Mode | ID / status |
|-------------|---------|------|-------------|
| Beginner beater | Beat Very Easy bot | Any | *(catalog)* `db.bot.beat_easy` |
| Beat Easy bot | Win vs Easy bot | Any | **New** `db.bot.beat_easy_tier` |
| Beat Medium bot | Win vs Medium bot | Any | **New** `db.bot.beat_medium` |
| Bot buster | Beat Hard bot | Any | *(catalog)* `db.bot.beat_hard` |
| Pro slayer | Beat Pro bot | Any | **New** `db.bot.beat_pro` |
| Full ladder | Win vs every `BotDifficulty` at least once | Any | **New** `db.bot.beat_all` |
| Local legends | Win match with ≥ 3 human roster players | Any | **New** `db.play.3p_local` |

#### App & exploration (low-friction onboarding)

| Achievement | Trigger | Mode | ID / status |
|-------------|---------|------|-------------|
| Squad goals | Add first custom roster player | Meta | *(catalog)* `db.setup.add_player` |
| Stat nerd | Open Statistics tab once | Meta | *(catalog)* `db.stats.open` |
| Historian | Open History tab once | Meta | *(catalog)* `db.history.open` |
| Modes curious | Open Modes tab once | Meta | **New** `db.modes.open` |
| Rematch | Start a rematch from match summary | Meta | **New** `db.play.rematch` |

#### Hidden & novelty (Tier C)

| Achievement | Trigger | Mode | ID / status |
|-------------|---------|------|-------------|
| Unlucky legend | Visit score exactly 177 | X01 | *(catalog)* `db.visit.177` |
| Redemption | Bust, then 180 later in same match | X01 | *(catalog)* `db.bust.then_180` |
| Nine-dart leg | Win leg in ≤ 9 darts | X01 | *(catalog)* `db.win.nine_dart_leg` |
| Bust-free leg | Complete leg with zero busts, 15+ darts | X01 | **New** (Hidden) `db.x01.no_bust_leg` |
| Miss every dart | Visit with 3 misses (`wasMiss`) | Any | **New** (Hidden) `db.dart.triple_miss` |
| Perfect visit | 3× T20 without bust (not necessarily 180 if rules differ) | X01 | **New** (Hidden) `db.visit.perfect_t20` |

---

### Catalog at a glance

| Tier | Count | Ship when | Focus |
|------|-------|-----------|-------|
| **A** | 7 | MVP / Phase 2 | Todo list + first-match hooks |
| **B** | ~40 | Phase 3 | Scoring, finishing, consistency, milestones, modes (shipped) |
| **C** | ~15 | Phase 4+ | Hidden, novelty, 1,000-game stretch |
| **Deferred** | — | Per mode ship | Achievements tagged to planned catalog modes only |

**Recommended MVP slice (18):** Tier A (7) + `db.win.first`, `db.visit.100`, `db.checkout.any`, `db.mode.x01_win`, `db.mode.cricket_win`, `db.streak.win_3`, `db.play.10`, `db.bot.beat_easy`, `db.setup.add_player`, `db.legs.win_10`, `db.checkout.count_10`.

### Point value guide (App Store Connect)

| Rarity | Points | Examples |
|--------|--------|----------|
| Onboarding | 5–10 | First match, open tab, first T20 |
| Common | 15–25 | Ton up, 10 games, first win, beat Easy bot |
| Uncommon | 30–50 | 180, 100+ checkout, win streak 5, mode wins |
| Rare | 60–80 | 170 checkout, 80+ avg, whitewash, beat Pro |
| Legendary | 100 | Nine-dart leg, 180×3 in match, 1,000 games, 30-day streak |

---

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
| `db.avg.match_60` | Sharp Shooter | Average 60+ in a match. | Human 3-dart avg ≥ 60 in one completed match | Medium |
| `db.avg.match_80` | Elite Average | Average 80+ in a match. | Human 3-dart avg ≥ 80 in one completed match | Medium |
| `db.visit.180_20` | Maximum Machine | Score 20 lifetime 180s. | 20× 180 visits | Easy (Inc) |
| `db.visit.180_100` | Century of Maximums | Score 100 lifetime 180s. | 100× 180 visits | Easy (Inc) |
| `db.checkout.150_plus` | Heavy Finish | Checkout on 150 or more. | `startRemaining >= 150` && checkout | Easy |
| `db.checkout.rate_50` | Closer | 50%+ checkout rate in a match. | ≥ 3 attempts; success rate ≥ 50% | Medium |
| `db.checkout.rate_100` | Perfect Finisher | 100% checkout rate in a match. | ≥ 3 attempts; all successful | Medium |
| `db.streak.days_3` | Three-Day Streak | Play 3 days in a row. | 3 consecutive calendar days | Medium |
| `db.streak.days_7_consecutive` | Daily Player | Play every day for a week. | 7 consecutive calendar days | Medium |
| `db.streak.days_30_consecutive` | Iron Routine | Play every day for a month. | 30 consecutive calendar days | Hard (Inc) |
| `db.legs.win_100` | Leg Legend | Win 100 legs. | Lifetime `legsWon >= 100` | Easy (Inc) |
| `db.win.first` | Winner | Win your first match. | First human win | Easy |
| `db.avg.match_70` | On Target | Average 70+ in a match. | 3-dart avg ≥ 70 | Medium |
| `db.avg.leg_60` | Hot Leg | Average 60+ in a single leg. | Leg-level avg | Medium |
| `db.visit.180_x2_match` | Double Maximum | Two 180s in one match. | 2× 180 visits same match | Medium |
| `db.dart.bull_50` | Bull Hunter | Hit 50 inner bulls. | Lifetime inner bull count | Easy (Inc) |
| `db.dart.1000` | Arm Strong | Throw 1,000 darts. | Lifetime dart count | Easy (Inc) |
| `db.checkout.40_99` | Middle Finish | Checkout between 40 and 99. | `40 <= startRemaining <= 99` | Easy |
| `db.checkout.161` | Big Fish | Checkout exactly 161. | `startRemaining == 161` | Medium |
| `db.checkout.one_dart` | Ice in the Veins | Checkout on your first dart. | `checkoutDartCount == 1` | Medium |
| `db.checkout.two_dart_100` | Two-Dart Ton | Checkout 100+ in two darts. | 2-dart checkout, `startRemaining >= 100` | Medium |
| `db.checkout.count_10` | Finisher | Complete 10 checkouts. | Lifetime checkouts ≥ 10 | Easy (Inc) |
| `db.checkout.count_50` | Clutch | Complete 50 checkouts. | Lifetime checkouts ≥ 50 | Easy (Inc) |
| `db.checkout.high_120` | High Wire | Checkout of 120 or more (lifetime best). | `highestCheckout >= 120` | Easy |
| `db.win.10` | Ten and Counting | Win 10 matches. | Lifetime wins ≥ 10 | Easy (Inc) |
| `db.win.50` | Regular Winner | Win 50 matches. | Lifetime wins ≥ 50 | Easy (Inc) |
| `db.win.100` | Century of Wins | Win 100 matches. | Lifetime wins ≥ 100 | Easy (Inc) |
| `db.legs.win_10` | Leg Up | Win 10 legs. | Lifetime legs ≥ 10 | Easy (Inc) |
| `db.legs.win_500` | Leg Machine | Win 500 legs. | Lifetime legs ≥ 500 | Easy (Inc) |
| `db.play.250` | Veteran | Complete 250 games. | 250 matches | Easy (Inc) |
| `db.play.weekend` | Weekend Warrior | Play Saturday and Sunday same weekend. | 2 days, same ISO week | Medium |
| `db.win.comeback_2legs` | Comeback Kid | Win after trailing by 2+ legs. | Max deficit ≥ 2 legs, then win | Medium |
| `db.mode.party_win` | Party Starter | Win a Baseball, Killer, or Shanghai game. | Any party `MatchType` win | Easy |
| `db.mode.all_shipped` | Mode Explorer | Play every shipped game type. | 1+ completed match per shipped mode | Medium |
| `db.mode.301_win` | 301 Specialist | Win a 301 match. | X01 config `startScore == 301` win | Easy |
| `db.mode.501_win` | 501 Specialist | Win a 501 match. | X01 config `startScore == 501` win | Easy |
| `db.cricket.cutthroat_win` | Cutthroat | Win Cricket with points on. | Points-on config win | Easy |
| `db.cricket.7mark_turn` | Bullseye Barrage | Score 7 marks in one Cricket visit. | `marksAdded == 7` one turn | Easy |
| `db.cricket.marks_100` | Mark Collector | Score 100 lifetime Cricket marks. | `cricketMarks >= 100` | Easy (Inc) |
| `db.cricket.mpr_3` | Three MPR | Average 3+ marks per round in a match. | Match MPR ≥ 3.0 | Medium |
| `db.baseball.win` | Home Run Hero | Win a Baseball match. | Baseball win | Easy |
| `db.baseball.max_inning` | Grand Slam | Max runs in one Baseball inning. | Inning points == rules max | Medium |
| `db.killer.win` | Killer Instinct | Win a Killer match. | Killer win | Easy |
| `db.killer.survivor` | Last One Standing | Win Killer as the sole survivor. | Last player with lives | Medium |
| `db.shanghai.win` | Shanghai Champion | Win a Shanghai match. | Shanghai win | Easy |
| `db.shanghai.instant` | Shanghai! | Hit S+D+T of round target in one visit. | Shanghai instant-win rule | Medium |
| `db.bot.beat_easy_tier` | Easy Pickings | Beat an Easy bot. | Win vs `easy` | Easy |
| `db.bot.beat_medium` | Middleweight | Beat a Medium bot. | Win vs `medium` | Easy |
| `db.bot.beat_pro` | Pro Slayer | Beat a Pro bot. | Win vs `pro` | Medium |
| `db.bot.beat_all` | Full Ladder | Beat every bot difficulty. | Win vs each `BotDifficulty` | Medium |
| `db.play.3p_local` | Local Legends | Win with 3+ humans at the table. | ≥ 3 human participants, human wins | Easy |
| `db.modes.open` | Modes Curious | Open the Modes tab. | One-time UI event | Easy |
| `db.play.rematch` | Rematch | Start a rematch from summary. | Rematch flow used once | Easy |
| `db.dart.t20_500` | T20 Master | Hit 500 treble 20s. | Lifetime T20 count | Easy (Inc) |

### Tier C — Fun / hidden / stretch (post-MVP)

| ID | Name | Description | Trigger | Hidden |
|----|------|-------------|---------|--------|
| `db.visit.177` | Unlucky Legend | Score exactly 177 in a visit. | `appliedTotal == 177` | Yes |
| `db.bust.then_180` | Redemption | Bust, then score 180 later in the same match. | Same X01 match | Yes |
| `db.win.nine_dart_leg` | Nine-Dart Leg | Win a leg in 9 darts or fewer. | Leg dart count ≤ 9 | Yes |
| `db.play.500` | Hall of Fame | Complete 500 games. | 500 matches | Inc |
| `db.play.1000` | Obsessed | Complete 1,000 games. | 1,000 matches | Yes, Inc |
| `db.checkout.double_bull` | Eyes | Checkout on double bull. | Checkout dart is inner bull double | Yes |
| `db.cricket.shutout` | Shut the Door | Win Cricket while opponent has 0 marks on at least one target. | Niche rule — define carefully | Yes |
| `db.setup.add_player` | Squad Goals | Add a custom player to your roster. | First non-seeded player created | No |
| `db.stats.open` | Stat Nerd | Open the Statistics tab. | One-time UI event | No |
| `db.history.open` | Historian | Open the History tab. | One-time UI event | No |
| `db.visit.180_x3_match` | Hat Trick of Max | Three 180s in one match. | 3× 180 same match | Yes |
| `db.avg.match_90` | Tour Average | Average 90+ in a match. | 3-dart avg ≥ 90 | Yes |
| `db.streak.win_10` | Untouchable | Win 10 matches in a row. | 10 consecutive wins | Yes |
| `db.x01.no_bust_leg` | Clean Leg | Finish a leg with no busts. | Leg with 15+ darts, zero busts | Yes |
| `db.dart.triple_miss` | Air Mail | Miss all three darts in a visit. | 3× `wasMiss` | Yes |
| `db.visit.perfect_t20` | Perfect Bed | Three treble 20s in a visit. | 3× T20, no bust | Yes |
| `db.dart.10000` | Lifetime Thrower | Throw 10,000 darts. | Lifetime dart count | Inc |

### Tier D — Skip or defer

- **Online / multiplayer achievements** — no online play in 1.0 ([specs/OnlinePlaySpec.md](../specs/OnlinePlaySpec.md)).
- **Leaderboards** — separate Game Center feature; not required for achievements MVP.
- **Time-of-day gimmicks** (“Night Owl”) — weak fit for a scorekeeper; skip unless you want personality.
- **Rolling multi-match averages** (“Maintain 60+ avg over 10 games”) — confusing for casual players; better as local stats, not GC. Single-match average thresholds are covered in Tier B (`db.avg.match_60` … `db.avg.match_80`).
- **Planned catalog modes** (Around the Clock, Halve-It, Football, etc.) — add achievements when each engine ships; reserve `db.<mode>.*` ID namespace now.
- **Cross-device progress** — Game Center syncs unlocks, not custom counters; incremental achievements must report through `GKAchievement` percent or a local persisted counter keyed to `GKLocalPlayer.gamePlayerID`.

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
- MVP slice extras: `db.win.first`, `db.checkout.any`, mode wins, `db.play.10`
- Human-only filtering at turn + match boundaries
- Incremental reporting for games played / lifetime counters

### Phase 3 — Polish (day 4–7)

- Retroactive unlock on first sign-in
- Settings row: Game Center status + “View Achievements” (`GKAchievementViewController`)
- Tier B — scoring, finishing, consistency, milestones (X01 + Cricket first)
- Party mode evaluators as Baseball / Killer / Shanghai events stabilize
- Sandbox QA checklist

### Phase 4 — Later

- Tier C hidden achievements
- Bot ladder + streak stretch goals
- Localization of achievement strings (GC displays ASC metadata; in-app copy via L10n if you build custom UI)
- Optional celebration toast when unlocking mid-match (respect Reduce Motion)
- New achievements per planned mode as each ships from `GameModeCatalog`

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

## Future mode achievements (reserve IDs)

When planned catalog modes ship, add 2–4 achievements each using the `db.<family>.*` prefix:

| Mode (planned) | Suggested achievements |
|----------------|------------------------|
| Around the Clock | First complete circuit · sub-60-second run · perfect segment streak |
| Halve-It / Bob's 27 | Reach par · survive all 27 beds · beat par by 50+ |
| Football | Score a goal · win without extra time · hat trick goals |
| Blind Killer | Win without revealing your number early |
| Grand National | Clear all fences · win on final fence |
| Practice (e.g. Doubles) | Hit every double on the board in one session |

Keep these out of App Store Connect until the mode is routable.

---

## Evaluator input cheat sheet

| Check | Primary source |
|-------|----------------|
| Visit score / 180 / bust | `X01TurnEvent.appliedTotal`, `isBust`, `darts` |
| Checkout value / darts used | `startRemaining`, `didCheckout`, `checkoutDartCount` |
| Match average | Sum human `appliedTotal` ÷ sum `effectiveDartsThrown` × 3 |
| Leg average | Same reducer scoped to `legIndex` |
| Checkout rate | Per-leg visits where `startRemaining <= 170` vs `didCheckout` |
| Cricket marks | `CricketTurnEvent.targetsTouched`, `marksAdded` per turn |
| Win / margin | `winnerKey`, final `remainingScore` / Cricket scores at `completed` |
| Bot tier | `BotDifficulty` on opponent participant |
| Calendar streak | `MatchStatsInput.playedAt` dates (local timezone) |
| Mode / config | `MatchType` + match config payload (301 vs 501, points-on) |

---

## Open questions for you

1. **Scope:** Achievements only, or Game Center leaderboards too (e.g. highest visit, games won)?
2. **Sign-in UX:** Silent authenticate on launch vs explicit Settings toggle?
3. **Mid-match unlock banners:** Show in-app celebration or rely on system Game Center notification?
4. **Cricket in v1:** Include Cricket achievements in MVP or X01-only first?
5. **Incremental caps:** Use Apple’s incremental achievements for 50/100 games, or single-shot thresholds only?
6. **Party modes in v1:** Ship Baseball/Killer/Shanghai achievements with Phase 3, or defer until those modes have more play data?
7. **Meta achievements:** Include low-friction tab/rematch unlocks, or keep GC strictly gameplay?
8. **Checkout rate floor:** Is min 3 attempts right, or require min 5 for rate achievements?

---

## Related files in codebase

| Area | File |
|------|------|
| Turn / dart events | `Domain/Engines/X01Engine.swift`, `Domain/Engines/CricketEngine.swift` |
| Stat aggregation | `Domain/Services/StatsService.swift` |
| Match completion | `Features/Play/X01/X01MatchViewModel.swift`, `Features/Play/Cricket/CricketMatchViewModel.swift` |
| Bot detection | `Domain/Models/RepositoryModels.swift` (`isBot`, `botDifficulty`) |
| Post-1.0 online | `specs/OnlinePlaySpec.md`, `specs/FirebaseBackendAnalyticsSpec.md` |
