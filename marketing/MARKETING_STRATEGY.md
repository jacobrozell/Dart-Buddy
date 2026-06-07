# Dart Buddy — Marketing Strategy

> Version 1.0 · For the 1.0 App Store launch and the first ~90 days post-launch.
> All claims below map to shipped behavior; revisit after real analytics arrive.

---

## 1. Executive summary

Dart Buddy is a **free, no-ads, local-first darts scorekeeper** for X01 and Cricket on iPhone
and iPad. The darts scoring category is crowded but mostly poor: the popular apps are
ad-cluttered, bloated, account-gated, or ugly. Dart Buddy wins on the things players actually
feel every game — **speed of input, trustworthy math, a clean board, and zero ads or sign-ups**.

The strategy is deliberately lean and sustainable for a solo developer:

1. **Own the "no ads / no account" positioning** in a category full of the opposite.
2. **Win App Store search (ASO) first** — it's the highest-intent, lowest-cost channel for a
   utility like this.
3. **Seed credibility in darts communities** (Reddit, forums, leagues) with a genuinely useful
   free tool rather than ads.
4. **Convert quality into ratings**, because ratings compound ASO and trust over time.

The goal for the first 90 days is not virality — it's a **clean, well-reviewed launch that ranks
for the core keywords and builds a base of loyal, returning players** to fund a 1.x roadmap.

---

## 2. Product positioning

**One-liner:**
> The fast, clean darts scoreboard for X01 and Cricket — no ads, no account, just play.

**Positioning statement:**
> For darts players who score at home, in the pub, or in a league, **Dart Buddy** is an iPhone &
> iPad scorekeeper that makes scoring X01 and Cricket fast, accurate, and clean — unlike the
> ad-heavy, account-gated apps that dominate the category, because it's free, has no ads, needs
> no sign-up, and keeps all your data on your device.

**Brand attributes:** clean · fast · trustworthy · friendly · competitive but non-gimmicky.

**What we are NOT (1.0):** not an online multiplayer platform, not a camera/auto-scoring product,
not a social network, not a subscription. These keep the message focused and the bar achievable.

---

## 3. Target audience

| Segment | Who they are | What they want | Hook |
|---------|--------------|----------------|------|
| **Casual home players** | Families/friends, weekend darts, a board in the garage | Stop doing mental math; settle who won | "Put the calculator away. Just throw." |
| **Pub & social players** | Play out, no app loyalty, hate ads | Quick scoring on a phone that isn't covered in ads | "No ads. No login. Just score." |
| **League & serious amateurs** | Regular play, care about averages/MPR | Track 3-dart avg, MPR, checkouts, history | "See your average climb." |
| **Solo practicers** | Practicing alone, want a challenge | A credible opponent to play against | "Bots that play at your level — then push you." |

**Primary launch focus:** casual home players + pub players (largest, easiest to convert with the
"no ads / no account" message). **Secondary:** league players (highest retention, drive word of
mouth and feature requests).

**Geographic priority:** darts-strong markets — UK & Ireland, Netherlands, Germany, Belgium,
Scandinavia, then broader EU, Australia, and the US. Localization already covers en/de/es/nl,
which aligns with this.

---

## 4. Competitive landscape & differentiation

Typical category pain points (the messaging openings):

- **Ads everywhere** — interstitials mid-game, banners over the board.
- **Account/login walls** before you can score a casual game.
- **Bloat & clutter** — too many modes/menus burying the scoreboard.
- **Paywalls** on basic functionality.

**Dart Buddy's wedge — lead with these, in order:**

1. **No ads. Ever.** (1.0)
2. **No account, no login** — open and play.
3. **Local-first & private** — your data stays on your device.
4. **Fast, large, high-contrast scoring UI** built for glances during a game.
5. **Calibrated bot opponents** (5 tiers + Training Partners tuned to your stats) — a credible
   solo-play story most free scorekeepers lack.
6. **Real stats** — 3-dart average, highest score, MPR, sector hits, trends, full match history.
7. **Accessible & native** — SwiftUI, Dynamic Type, VoiceOver, dark mode, iPad support.

> Avoid naming competitors in store copy. Use the *pain* ("no ads", "no sign-up") as contrast.

---

## 5. Messaging framework

**Primary message:** *Fast, clean darts scoring — no ads, no account.*

**Proof points (use as needed per channel):**
- X01 (301/501) with single-out and double-out + checkout suggestions
- Cricket with Normal and Cut Throat, points on/off
- Bot opponents from Very Easy → Pro, plus Training Partners calibrated to you
- Averages, MPR, highest scores, trends, and full match history
- Undo, resume in-progress matches, dark mode, iPhone + iPad
- Free, no ads, no in-app purchases, no account, data stays on device

**Tone:** plain-spoken, confident, a little playful. Talk like a darts player, not a SaaS deck.
Short sentences. Benefit before feature.

**Tagline options (A/B over time):**
- "No ads. No login. Just darts."
- "Your darts scoreboard. Clean and fast."
- "Put the calculator away. Just throw."
- "X01 & Cricket scoring, done right."

---

## 6. Channels & tactics

### 6.1 App Store Optimization (ASO) — *primary channel*
Highest-intent traffic for a utility app. See `APP_STORE_LISTING.md` for finalized copy.

- **Title + subtitle** carry the strongest keywords ("darts", "scoreboard", "scorekeeper",
  "X01", "cricket").
- **Keyword field** fills the long tail (counter, tracker, 501, 301, checkout, MPR…).
- **Screenshots** are the real conversion lever — first 2 must land the value in a glance
  (big X01 score + "No ads"; Cricket board + "X01 & Cricket"). Captions are benefit-driven.
- **Ratings prompts** at genuine moments of delight (e.g., after winning a match), throttled and
  respectful — ratings volume + recency drive ranking.
- **Iterate**: revisit subtitle, keyword field, and screenshot order monthly from real search and
  conversion data.

### 6.2 Community seeding — *primary credibility channel*
Darts players congregate online. Show up as a helpful player, not a marketer.

- **Reddit:** r/Darts (and relevant regional subs). Share a genuinely useful free tool; respond
  to "best free darts scoring app / no ads?" threads honestly. Follow each sub's self-promo rules.
- **Forums & communities:** darts forums, league Facebook groups, Discord servers.
- **Local leagues & pub teams:** offer it to a few teams; league players are high-retention
  evangelists and a goldmine for feedback.

### 6.3 Owned web presence
A lightweight site already exists under `docs/` (landing, privacy, support).

- Keep a one-screen **landing page**: hero shot, three benefits ("No ads", "X01 & Cricket",
  "Stats & history"), App Store badge.
- Ensure **privacy** and **support** pages are live and linked (App Store requires both).
- Add an FAQ over time from real support questions.

### 6.4 Content & social (low-cost, optional)
- Short vertical video: a 10-second leg scored start-to-finish, "no ads" punchline.
- Before/after: cluttered ad-app vs. Dart Buddy's clean board.
- "Did you check out correctly?" checkout tips that show the suggester.
- Post to TikTok/Instagram Reels/YouTube Shorts where darts content performs.

### 6.5 Paid (deferred)
Hold paid acquisition until ASO and organic conversion are validated. If used later, **Apple
Search Ads** on brand + core keywords is the most efficient first test for a free utility.

---

## 7. Launch approach

A phased, quality-first launch (full timeline in `CONTENT_AND_LAUNCH_CALENDAR.md`):

1. **TestFlight beta** — recruit darts players from communities; fix top issues; collect early
   testimonials and screenshots of real use.
2. **Soft launch** — listing live, polished, ratings prompt wired; quietly invite beta cohort to
   rate. Validate that the listing converts before amplifying.
3. **Announcement** — community posts, web/social, ask happy users for honest reviews.
4. **Sustain** — weekly community presence, respond to every review, ship a fast 1.0.1 patch for
   anything launch surfaces.

---

## 8. Retention & lifecycle

Acquisition is wasted without retention. Levers already in the product:

- **Onboarding tour** sets expectations in <60s.
- **Resume in-progress matches** removes friction for interrupted games.
- **Stats & trends** give a reason to come back ("watch your average climb").
- **Bot opponents** enable solo sessions when no human is around.

Roadmap levers (from `FutureIdeas/`) that strengthen retention — sequence by impact/effort:
- **Local play-reminder notifications** (low effort, brings players back).
- **Game Center achievements** (cheap delight + light virality).
- **Apple Watch companion** and **cloud sync** (bigger bets; differentiators for 1.x).

---

## 9. Pricing & monetization

- **1.0:** Free, no ads, no IAP. This *is* the wedge — protect it.
- **Build trust and a user base first.** Don't add friction early.
- **Future, only if value-additive and non-intrusive** (post-1.0, optional):
  - A one-time "Pro" unlock or small tip jar for advanced stats / extra game modes
    (Killer, Shanghai, Around the Clock, etc. — already scoped in `FutureIdeas/`).
  - Cloud sync / multi-device as a premium convenience.
  - **Never** banner/interstitial ads — it contradicts the entire brand.

---

## 10. KPIs & targets

Track against a simple funnel. Use Firebase Analytics events already in place
(`app_open`, `match_started`, `match_completed`, etc.) plus App Store Connect.

| Stage | Metric | Why it matters | Early target* |
|-------|--------|----------------|---------------|
| Discovery | Impressions, keyword rank for core terms | ASO health | Rank top-10 for "X01"/"cricket darts" niche terms |
| Conversion | Product page conversion rate | Listing/screenshot quality | ≥ category-typical, improve monthly |
| Activation | % installs that complete ≥1 match | Onboarding works | ≥ 60% |
| Retention | D1 / D7 / D30 | Real value & habit | Establish baseline, then improve |
| Quality | Crash-free rate (Crashlytics) | Stability | ≥ 99.5% |
| Advocacy | Rating count, avg stars, review sentiment | Compounds ASO + trust | 4.5★+, growing review volume |

\*Targets are directional for a solo-dev launch; replace with real baselines after 30 days.

---

## 11. Risks & mitigations

| Risk | Mitigation |
|------|------------|
| Desired app name unavailable | Backup names ready (see `AppStoreConnectSpec.md` §3) |
| Low discoverability at launch | Iterate subtitle/keywords/screenshots monthly from data |
| Crowded category, hard to stand out | Lead hard on "no ads / no account / local-first" |
| Few early ratings | Well-timed in-app prompt + ask beta cohort directly |
| Negative review on a bug | Respond fast, ship 1.0.1 patch, show responsiveness publicly |
| Solo-dev bandwidth | Lean channels (ASO + community) over expensive paid/content machines |
| Over-promising roadmap | Tease direction (watch, smart scoring) without committing dates |

---

## 12. Ownership

- **Positioning & messaging:** product/PM (you).
- **Listing copy:** this folder is the source; engineering verifies truthfulness vs. behavior.
- **Visual assets:** design owns icon/screenshot quality (`marketing-screenshots/`).
- **Release checklist:** release owner validates final App Store Connect submission
  (see `docs/release/release_checklist.md`).

---

*Next step: finalize the store text in [`APP_STORE_LISTING.md`](APP_STORE_LISTING.md) and execute
[`CONTENT_AND_LAUNCH_CALENDAR.md`](CONTENT_AND_LAUNCH_CALENDAR.md).*
</content>
