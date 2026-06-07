# Dart Buddy — App Store Listing Copy

> Ready-to-paste copy for App Store Connect. Character limits noted per field. Pick one primary
> option per field; alternates are provided for A/B testing post-launch.
> Keep everything truthful to shipped 1.0 behavior — engineering signs off before submission.

App Store Connect identifiers (from `specs/AppStoreConnectSpec.md`):
- **App name (display):** Dart Buddy
- **Bundle ID:** `com.jacobrozell.DartBuddy`
- **App Store ID:** `6775713346` · **URL:** https://apps.apple.com/app/id6775713346
- **Category:** Sports · **Price:** Free · **Age rating:** 4+

---

## 1. App Name — *max 30 characters*

**Primary:**
```
Dart Buddy: X01 & Cricket
```
*(25 chars — adds two strong keywords to the most heavily-weighted ASO field.)*

**Alternates:**
- `Dart Buddy — Darts Scorer` (25)
- `Dart Buddy` (10 — cleanest, weakest for search)

---

## 2. Subtitle — *max 30 characters*

**Primary:**
```
Free X01 & Cricket scoreboard
```
*(29 chars.)*

**Alternates:**
- `No-ads darts scorekeeper` (24)
- `Darts scorekeeper, no ads` (25)
- `Score X01 & Cricket, no ads` (27)

---

## 3. Keyword field — *max 100 characters, comma-separated, no spaces*

Don't repeat words already in the name/subtitle (Apple indexes those separately). No plurals
needed (Apple handles them). No spaces after commas to save characters.

**Primary:**
```
scorekeeper,scorer,counter,tracker,501,301,checkout,bull,oche,board,score,leg,mpr,average,pub
```
*(94 chars.)*

**Notes:**
- "darts", "x01", "cricket", "scoreboard", "free" are covered by name + subtitle.
- Revisit after real Search analytics; drop low-performers, test "league", "practice", "bdo",
  "180", "throw".

---

## 4. Promotional Text — *max 170 characters, editable anytime without review*

**Primary:**
```
Fast, clean darts scoring for X01 and Cricket. No ads, no account, no nonsense. Track your average, play smart bot opponents, and keep your full match history.
```
*(157 chars.)*

**Launch/seasonal variant:**
```
New: clean X01 & Cricket scoring with no ads and no sign-up. Score a leg in seconds, then watch your 3-dart average climb. Free on iPhone & iPad.
```

---

## 5. Description — *max 4000 characters*

```
Dart Buddy is the fast, clean way to score darts on your iPhone and iPad — for X01 and Cricket. No ads. No account. No nonsense. Just open it and play.

Most darts apps bury the scoreboard under ads, sign-up walls, and clutter. Dart Buddy does the opposite: a big, high-contrast board, quick input, and trustworthy math so you can keep your eyes on the oche.

— FREE, WITH NO ADS —
No banners. No interstitials mid-leg. No in-app purchases. No login. Your match data stays on your device.

— X01 (301 & 501) —
• Single-out and double-out finishes
• Legs and optional sets
• Built-in checkout suggestions for the fastest legal way to close
• One-tap undo for misclicks

— CRICKET —
• Normal and Cut Throat scoring
• Points on or off
• Clean mark-based input for 20–15 and the bull

— PLAY ANYONE, ANYTIME —
• Five bot opponents, from Very Easy to Pro
• Training Partners that calibrate to your own stats and push you just past your level
• Perfect for solo practice when there's no one to throw against

— SEE YOUR GAME IMPROVE —
• 3-dart average, highest scores, and trends for X01
• Marks Per Round (MPR) and sector hits for Cricket
• Filter by player and time period
• Full match history with turn-by-turn detail

— BUILT THE RIGHT WAY —
• Designed for iPhone and iPad
• Light and dark mode
• Accessibility-first: Dynamic Type and VoiceOver support
• Available in English, German, Spanish, and Dutch
• Resume an in-progress match right where you left off

Whether you're throwing in the garage, down the pub, or in your local league, Dart Buddy keeps score so you can focus on the darts.

Download free and play your next leg.
```
*(~1,500 chars — well under the limit, leaving room to expand with roadmap features later.)*

---

## 6. "What's New" — release notes

**1.0 (launch):**
```
Welcome to Dart Buddy! The first release of a fast, clean, ad-free darts scoreboard for X01 and Cricket.

• Score X01 (301/501) with single- and double-out plus checkout suggestions
• Play Cricket with Normal and Cut Throat scoring
• Challenge five bot tiers or Training Partners tuned to your skill
• Track averages, MPR, trends, and full match history
• iPhone & iPad, light/dark mode, no ads, no account

Found a bug or have an idea? We'd love to hear from you.
```

**1.0.1 template (patch):**
```
Thanks for playing Dart Buddy! This update polishes the launch:
• Fixes and stability improvements based on your feedback
• [Specific fix here]

Keep the feedback coming — and please leave a rating if you're enjoying it.
```

---

## 7. Screenshot captions

Use real in-app UI (assets in `marketing-screenshots/`). Keep overlays short and benefit-driven.
Order matters — the first 1–2 are what most users see before scrolling.

| # | Screen (asset) | Caption (overlay) | Sub-caption (optional) |
|---|----------------|-------------------|------------------------|
| 1 | X01 match (`...01-x01-match`) | **No ads. Just darts.** | Fast, clean X01 scoring |
| 2 | Cricket match (`...02-cricket-match`) | **X01 & Cricket** | Normal & Cut Throat |
| 3 | Match setup (`...03-match-setup`) | **Set up a game in seconds** | No account needed |
| 4 | Statistics (`...07-statistics`) | **Watch your average climb** | Averages, MPR & trends |
| 5 | History (`...04-history`) | **Every match, saved** | Full turn-by-turn history |
| 6 | Match summary (`...05-match-summary`) | **Know who really won** | Stats the moment you finish |
| 7 | Players (`...06-players`) | **Add your whole crew** | Players & profiles |

> Provide both 6.5"/6.9" iPhone and 12.9"/13" iPad sets. Dark-mode hero shots lead; include light
> variants where they read better. Sizes per `AppStoreConnectSpec.md` §8.

---

## 8. Support & privacy URLs (required)

- **Support URL:** publish from `docs/support.html` (e.g., the GitHub Pages site)
- **Privacy Policy URL:** publish from `docs/privacy.html`
- **Marketing URL (optional):** the `docs/` landing page

Confirm both are live and reachable before submission. Ensure the **App Privacy** labels reflect
local-first behavior and the actual enabled diagnostics (Firebase Analytics/Crashlytics on
release builds) — re-audit before each release.

---

## 9. Pre-submission checklist

- [ ] App name reserved and available
- [ ] Subtitle + keyword field finalized (no overlap with name)
- [ ] Description proofread; no unshipped feature promised
- [ ] Promo text set (editable later without review)
- [ ] Screenshots uploaded for all required device sizes (iPhone + iPad)
- [ ] App icon final in `Resources/Media.xcassets`
- [ ] Support + Privacy URLs live and entered
- [ ] App Privacy labels match real data behavior
- [ ] Age rating set to 4+
- [ ] Price = Free; no IAP configured
- [ ] "What's New" notes entered
- [ ] Build uploaded, TestFlight-validated on a physical device
- [ ] Release checklist in `docs/release/release_checklist.md` completed
</content>
