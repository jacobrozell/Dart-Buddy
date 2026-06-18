# Dart Buddy — 1.0 Release Checklist

> **Start here:** [`1.0.0-ship-checklist.md`](1.0.0-ship-checklist.md) — single master list (engineering, App Review hardening, nutrition labels, QA, Connect, submit). This file is the **expanded runbook** with full §-by-§ detail.

**Customer brand:** Dart Buddy (App Store listing, marketing, Reddit)  
**Technical target:** `DartBuddy` (Xcode scheme, bundle ID `com.jacobrozell.DartBuddy`, module)  
**Version:** `1.0.0` (lean core scorekeeper)  
**Scope:** [`lean-1.0-implementation-plan.md`](lean-1.0-implementation-plan.md) — **X01 + Cricket** (Normal + Cut Throat), **4 tabs** (Play · Players · Activity · Settings), **preset + custom bots**, **English UI**, Analytics + Crashlytics on. **Not in 1.0:** Modes tab, party modes, Training Partner bots, player export, bundled de/es/nl.

**Exit criteria:** All **P0** sections checked on a **physical iPhone** (Release build); [`../../roadmap/release/QA-Signoff-RC1.md`](../../roadmap/release/QA-Signoff-RC1.md) marked **Go**; App Store record complete and submitted.

This is the **single runbook** for device QA, App Store setup, and launch marketing. Detailed criteria live in linked specs — log evidence paths here and in the sign-off doc, not duplicate prose.

**Suggested order:** §0 → §1–§2 (same session) → §3–§6 (afternoon) → §7–§8 (parallel before submit) → §9 submit → §10–§11 after approval.

---

## Record (fill in before testing)

| Field | Value |
|-------|-------|
| RC version | `1.0.0` |
| Build number | |
| Git commit | |
| Branch | |
| Tester | |
| Date range | |
| Physical iPhone (model + iOS) | **Required for §1–§6** |
| iPad (optional) | |
| Simulator used | |
| Firebase plist in Release archive | Yes / No |
| App Store Connect app ID | |
| TestFlight build # (if used) | |

---

## 0. Pre-flight (before device work)

### Engineering & CI

- [ ] `main` / release branch green — [`.github/workflows/ci.yml`](../../.github/workflows/ci.yml) (`xcodegen generate` + `xcodebuild test`)
- [ ] Local: `xcodegen generate` then **Product → Test** (`⌘U`) on `DartBuddy` scheme
- [ ] `GoogleService-Info.plist` present for Release archive (copy from [`Resources/GoogleService-Info.plist.example`](../../Resources/GoogleService-Info.plist.example) + Firebase Console)
- [ ] Debug/CI/UI tests: analytics + Crashlytics **off** (launch args `-disable_firebase_analytics` / `-ui_test_reset` — not on store build)
- [ ] **Crashlytics:** Firebase Console → Crashlytics enabled for bundle ID; Release archive log shows dSYM upload script succeeded (no `GOOGLE_APP_ID` / sandbox errors)
- [ ] **TestFlight telemetry smoke** (internal build, real plist): launch → verify `app_open` in Firebase Analytics Realtime or DebugView; play one X01 leg → `match_started`, `turn_submitted`, `match_completed`; confirm no events from Debug/CI builds
- [ ] Version + build number set in [`project.yml`](../../project.yml) / Xcode (`MARKETING_VERSION`, `CURRENT_PROJECT_VERSION`)
- [ ] **Archive** with **Release** configuration + distribution signing

### Release build sanity

- [ ] No debug-only verbosity in Release (`AppLogger` only; no stray `print`)
- [ ] No sensitive data in logs (no tokens; player display names OK per policy)
- [ ] App icon present in `Resources/Media.xcassets` / finalized asset in [`assets/app-icons/`](../../assets/app-icons/)

**P0 if CI red or Release archive fails.**

---

## 1. Fast release gate (~10 min)

**Build:** Release · **Device:** Physical iPhone (simulator OK only if blocked)  
**Pre-run:** Settings → **Reset All Local Data** → confirm → relaunch → land on **Play**.

- [ ] App launches; **four tabs** work: **Play**, **Players**, **Activity**, **Settings** — **no Modes tab**
- [ ] Play setup has **no Change mode** button (mode chosen via Edit options chips + Settings default)
- [ ] Create players **Smoke Alice**, **Smoke Bob** on **Players**
- [ ] **X01:** Play → select Alice + Bob → Start → submit turn → **Undo Last Turn** → no crash
- [ ] **Cricket (Normal):** new match → submit turn → undo → board sane
- [ ] **Cricket (Cut Throat):** setup → Cut Throat chip → start match → pad loads
- [ ] **Activity → History:** at least one completed row → detail loads (header + timeline)
- [ ] **Activity → Statistics:** segment loads; mode filter shows All / X01 / Cricket only
- [ ] **Settings:** toggle **Sound** → leave tab → relaunch → still persisted
- [ ] **Hidden surface check:** no Modes tab, no party modes, no Export on player detail, no Training Partner section (custom bots **are** in 1.0)
- [ ] **English UI:** device language de/es/nl still shows English strings (en-only bundle)
- [ ] **AXXXL spot check:** Settings → Display → Larger Text → AXXXL → New Match setup + one in-match screen — primary CTA reachable

**Decision:** [ ] **PASS** — continue · [ ] **FAIL** — fix before §2+

Spec reference: [`../../specs/ReleaseGateChecklist.md`](../../specs/ReleaseGateChecklist.md)

---

## 2. Full smoke test (~20–25 min)

**Build:** Release preferred · **Devices:** iPhone (Light + Dark) + iPad Dark if available  
**Players:** `Smoke Alice`, `Smoke Bob`, `Smoke Carol`  
**Pre-run:** Reset all local data → relaunch.

### A. App shell

- [ ] All **four** tabs; rapid tab switch 2–3×; background/foreground once — stable, no blank screens
- [ ] Confirm **Modes** tab absent; Play setup has no **Change mode** affordance

### B. Players

- [ ] Add three smoke players
- [ ] Search `Smoke Bob`; clear search
- [ ] Open player detail → back — correct tab/root

### C. X01 match

- [ ] Setup: X01, 301 or 501, ≥2 players → Start Match
- [ ] Submit turn → Undo → submit again — state correct, no clipped controls

### D. Cricket match

- [ ] Setup: Cricket (Normal), ≥2 players → Start Match
- [ ] Enter turn via pad → submit → undo → resubmit — marks/progression correct
- [ ] Setup: Cricket **Cut Throat** → start → at least one turn submits cleanly

### E. Activity → History

- [ ] Completed match visible (finish one if needed)
- [ ] Filters: mode **All / X01 / Cricket** only; date 7d/30d/All
- [ ] Detail: mode, winner, date/duration, participants, timeline — no error state

### F. Activity → Statistics

- [ ] Games table + mode/date filters respond (mode chips: All, X01, Cricket only)
- [ ] Partial-data banner only when applicable ([`../../specs/StatsSpec.md`](../../specs/StatsSpec.md))

### G. Settings

- [ ] Change theme, default mode, haptics, sound
- [ ] Persist after tab switch and relaunch; theme applies

### H. Accessibility quick pass (AXXXL)

- [ ] Setup, X01 match, Cricket match, Activity (both segments), Settings — scrollable, no blocked primary CTA

**Decision:** [ ] **PASS** · [ ] **FAIL**

Spec reference: [`../../specs/SmokeTestChecklist.md`](../../specs/SmokeTestChecklist.md) · Evidence template: [`../../specs/SmokeTestEvidenceTemplate.md`](../../specs/SmokeTestEvidenceTemplate.md)

---

## 3. Core flow matrix (physical iPhone — RC sign-off)

**Build:** Release · **Log each row** in [`../../roadmap/release/QA-Signoff-RC1.md`](../../roadmap/release/QA-Signoff-RC1.md) as Pass/Fail/Blocked + evidence path.

| Flow | Done | Evidence / notes |
|------|------|------------------|
| Setup → X01 → **play to Match summary** (winner + stats) | [ ] | |
| Setup → Cricket (Normal) → **play to Match summary** | [ ] | |
| Setup → Cricket (**Cut Throat**) → start + submit at least one turn | [ ] | |
| **Resume** active match (background app → kill → relaunch) | [ ] | |
| **Undo** on X01 and Cricket (mid-match, state restores) | [ ] | |
| **Activity → History** list + detail integrity | [ ] | |
| **Activity → Statistics** — filters + table after completed games | [ ] | |
| **Players:** archive player; **delete guard** on referenced player | [ ] | |
| **Settings → Reset All Local Data** — confirm → clean bootstrap | [ ] | |
| **Abandon** in-progress match — wording correct; hidden from Activity ([`../../specs/MatchSpec.md`](../../specs/MatchSpec.md)) | [ ] | |
| **Preset bot match:** stagger pacing; pad disabled during bot turn; bot dart haptics if enabled | [ ] | |
| **Custom bot:** create from Play setup (or Players +) → X01 match completes | [ ] | |
| **Custom bot:** same bot in Cricket (Normal or Cut Throat) match | [ ] | |
| **Play home:** resume banner when applicable | [ ] | |
| **X01 checkout:** finish leg with double-out (if default) — summary correct | [ ] | |
| **Cricket closure:** close a number — banner/haptic/VO sensible | [ ] | |
| **Setup:** drag reorder roster; random order at start | [ ] | |
| **Quick-add player** from setup → returns with refreshed roster | [ ] | |
| **Lean hidden surface:** no Modes tab, party modes, export, Training Partner (custom bots allowed) | [ ] | |

---

## 4. Appearance matrix (4-way)

**Screens:** Match **setup** + one **in-match** screen (X01 or Cricket)  
**Save screenshots to:** QA sign-off doc + `../../accessibility/wcag-2.1-aa/evidence/orientation/` (captured 2026-06-02; see `README.md` there; re-run `./Scripts/capture-appearance-matrix.sh`)

| Combo | Setup | In-match |
|-------|-------|----------|
| Portrait + Light | [x] | [x] |
| Portrait + Dark | [x] | [x] |
| Landscape + Light | [x] | [x] |
| Landscape + Dark | [x] | [x] |

**iPad (recommended):** setup + one match — `GameplayLayout` max-width, no broken layout.

### 4.1 iOS 26 Liquid Glass (simulator — P1)

**Ship target remains iOS 18+.** On iOS 26+, system tab bar and nav toolbars use Liquid Glass when app code does not override them (`SystemNavigationPolicy`).

**Save screenshots to:** `../../accessibility/wcag-2.1-aa/evidence/ios26-liquid-glass/` (run `./Scripts/capture-ios26-liquid-glass.sh` on **iPhone 17 Pro, iOS 26.x**)

| Check | Done | Evidence |
|-------|------|----------|
| Tab bar glass visible on Play, Modes, Players, Activity, Settings | [x] partial (4 tabs, lean surface) | `ios26-liquid-glass/tab-*.png` (2026-06-11) |
| No accidental opaque `.toolbarBackground` on iOS 26 (grep policy helpers only) | [x] | `SystemNavigationPolicy.swift` |
| Settings usable with **Reduce Transparency** on | [ ] | `WCAGAccessibilityUITests` / manual |
| Scoreboard/match UI stays opaque (brand layer) | [ ] | spot-check Play + one match |

---

## 5. Data, privacy & migration (P0)

### Settings reset (on device)

- [ ] Reset → confirm → relaunch: empty players/history, Play home clean, no ghost active match
- [ ] Log in [`../../roadmap/reports/Phase06-Security-Privacy-Checklist.md`](../../roadmap/reports/Phase06-Security-Privacy-Checklist.md)

### Bootstrap store recovery (manual smoke)

Automatic recovery via `BootstrapStoreRecovery` — **device proof** still required — [`../../roadmap/reports/Phase06-Migration-Safety-Report.md`](../../roadmap/reports/Phase06-Migration-Safety-Report.md).

**Trigger (pick one):**

1. **Forced failure:** Create data → quit app → delete/truncate `Application Support/DartBuddy.sqlite` (+ `-shm`/`-wal`) → relaunch → app opens with empty store (no crash, no blocking screen).
2. **Upgrade path:** Install prior TestFlight/RC with data → install 1.0 RC → verify data intact.

**On relaunch after forced failure:**

- [ ] App reaches main tabs without crash
- [ ] Play home is usable (fresh store)
- [ ] Optional: confirm backup file logged (`bootstrap_store_backed_up` in device logs)

**First-ship note:** If schema unchanged since last beta, real-user migration may be N/A — still run (1) or mark **Blocked** with reason in Phase06 report.

### Privacy & App Store labels

- [ ] Privacy answers match app: **local-first**, no ads, no tracking IDs
- [ ] If Release ships Firebase: Analytics + Crashlytics disclosed accurately ([`../../specs/FirebaseBackendAnalyticsSpec.md`](../../specs/FirebaseBackendAnalyticsSpec.md))
- [ ] No ATT prompt (no cross-app tracking)
- [ ] Review notes mention **Reset All Local Data** if asked

---

## 6. Accessibility evidence (P0 for sign-off)

**Roll-up:** [`../../accessibility/wcag-2.1-aa/SUMMARY.md`](../../accessibility/wcag-2.1-aa/SUMMARY.md)  
**Full manual list:** [`../../accessibility/Manual_todo.md`](../../accessibility/Manual_todo.md)  
**Timed Nutrition Label script (~30 min):** [`../../accessibility/1.0-nutrition-label-checklist.md`](../../accessibility/1.0-nutrition-label-checklist.md)  
**Evidence folder:** `../../accessibility/wcag-2.1-aa/evidence/` (`voiceover/`, `dynamic-type/`, `orientation/`, `contrast/`, `ios26-liquid-glass/`)

### VoiceOver — end-to-end (required)

- [ ] Play → setup → **X01** → match summary
- [ ] Play → setup → **Cricket (Normal)** → match summary
- [ ] Play → setup → **Cricket (Cut Throat)** → at least one submitted turn
- [ ] Resume banner / active match when present
- [ ] Settings reset confirmation (destructive)

### VoiceOver — high-risk spot checks

- [ ] **X01:** pad, bust, checkout, bot turn disabled state
- [ ] **Cricket:** board, closure announcement, bot turn
- [ ] **Activity → History** list/detail; **Players** archive/delete actions
- [ ] **Activity → Statistics:** filters (All/X01/Cricket), partial banner, trend/table labels
- [ ] **Player detail** + **edit** sheet save/cancel (no export / training partner in lean 1.0)

### Dynamic Type (AXXXL)

- [ ] Match setup (roster, START, chips)
- [ ] X01 match (score + pad)
- [ ] Cricket match (board + pad on phone)
- [ ] History list (Activity segment), Statistics (Activity segment), Settings

### Contrast & non-color meaning

- [ ] Cricket closed targets understandable without relying on color alone
- [ ] Critical status banners (bust, leg won, bot throwing) readable in Light and Dark

Log results in QA sign-off **Accessibility** section.

---

## 7. Performance (P1 — only block ship if RC shows jank)

Record on **physical device**, Release build → [`../../roadmap/reports/Phase06-Performance-Report.md`](../../roadmap/reports/Phase06-Performance-Report.md).

- [ ] Cold launch → usable Play home (target: feels instant, no multi-second blank)
- [ ] `submitTurn` perceived latency during X01/Cricket (target: immediate UI update)
- [ ] Resume active match after relaunch
- [ ] History first paint with ≥10 completed matches (Activity → History segment)

---

## 8. App Store Connect & assets

Reference: [`../../specs/AppStoreConnectSpec.md`](../../specs/AppStoreConnectSpec.md)

### Apple Developer & app record

- [ ] Apple Developer Program membership active
- [ ] App record created in App Store Connect
- [ ] Bundle ID `com.jacobrozell.DartBuddy` matches Xcode
- [ ] SKU / primary language (English) set

### Listing copy (draft → final)

| Field | Draft / final value | Done |
|-------|---------------------|------|
| **Name** (≤30 chars) | `Dart Buddy` — check availability | [ ] |
| **Subtitle** | `X01 & Cricket Scorekeeper` (no pricing/monetization words — Guideline 2.3.7) | [ ] |
| **Promotional text** (optional) | Short hook; updatable without review | [ ] |
| **Description** | Value prop → features → no ads/local-first → accessibility | [ ] |
| **Keywords** | darts, scoreboard, x01, cricket, scorekeeper, … | [ ] |
| **Support URL** | `https://jacobrozell.github.io/Dart-Buddy/support.html` | [ ] |
| **Privacy Policy URL** (App Store) | `https://jacobrozell.github.io/Dart-Buddy/privacy.html` | [ ] |
| **Accessibility URL** (App Store) | `https://jacobrozell.github.io/Dart-Buddy/accessibility.html` | [ ] |
| **Marketing URL** (optional) | | [ ] |
| **Copyright** | e.g. `2026 Jacob Rozell` | [ ] |

### Category, pricing, rating

- [ ] Primary category: **Sports**
- [ ] Price: **Free** · No IAP · **No ads**
- [ ] Age rating questionnaire complete (expect **4+**)
- [ ] Export compliance: **No** custom encryption beyond Apple exempt ([`ITSAppUsesNonExemptEncryption`](../../project.yml) = NO)

### Privacy nutrition labels

- [ ] Data collected reflects Release behavior (Analytics/Crashlytics if enabled)
- [ ] No “tracking” across apps
- [ ] Contact info / identifiers: none linked to user for ads
- [ ] Reconcile with [`../../roadmap/reports/Phase06-Security-Privacy-Checklist.md`](../../roadmap/reports/Phase06-Security-Privacy-Checklist.md)

### Legal pages & policies (required for submit)

Apple does **not** require a custom EULA for most free apps — the **Standard Apple EULA** applies unless you upload your own in App Store Connect. You **do** need hosted pages for privacy (and support) once Firebase Analytics/Crashlytics ship in Release.

| Item | Required? | Notes |
|------|-----------|--------|
| **Privacy Policy URL** | **Yes** | App Store Connect field; must describe local storage, player names, Firebase Analytics + Crashlytics, reset/delete, no ads/tracking |
| **Support URL** | **Yes** | Contact method or FAQ; can be same site as privacy |
| **Custom EULA** | No (1.0) | Default: [Apple Standard EULA](https://www.apple.com/legal/internet-services/itunes/dev/stdeula/) — only add custom terms if you need special liability/limitation language |
| **Terms of Service** | No (1.0) | Optional unless you add accounts, IAP, or online play |
| **In-app privacy link** | Recommended | [`../../specs/SecurityPrivacySpec.md`](../../specs/SecurityPrivacySpec.md) — Settings → Help & Feedback → Privacy Policy |
| **Accessibility URL** | Optional (recommended) | App Store Connect → App Accessibility; same page linked in Settings → Help & Feedback → Accessibility |

**Privacy policy should cover (plain language, not legal boilerplate dump):**

- [ ] What stays on device (matches, players, settings — SwiftData, no account)
- [ ] What leaves device in **Release** only: Firebase **Analytics** (allowlisted events) and **Crashlytics** (crashes + allowlisted errors)
- [ ] What you **don’t** do: ads, cross-app tracking, selling data, IDFA/ATT
- [ ] User controls: **Reset All Local Data** wipes local store; how to request help
- [ ] Contact email (or support form URL)
- [ ] “Last updated” date; bump when adding Firebase services or online features

**Hosting options (pick one):**

- [x] **GitHub Pages** — `docs/privacy.html` + `docs/support.html` (see [`docs/README.md`](../README.md))
- [ ] Enable Pages: repo **Settings → Pages → Branch `master` → `/docs`**
- [ ] **Privacy Policy URL:** `https://jacobrozell.github.io/Dart-Buddy/privacy.html`
- [ ] **Support URL:** `https://jacobrozell.github.io/Dart-Buddy/support.html`
- [ ] Verify both URLs load in a private browser before submit

**App Store Connect → App Privacy questionnaire (align with policy):**

- [ ] **Diagnostics** — Crash data (Crashlytics): likely Yes, not used for tracking
- [ ] **Usage data** — Analytics events: likely Yes, not linked to identity if anonymous
- [ ] **User content** — Player display names: stored **on device only**; declare only if questionnaire asks about data stored on device vs collected by developer (local-only names often = not “collected” by you, but be consistent with policy wording)
- [ ] **Tracking** — No (no ATT, no ad networks)
- [ ] Export answers or screenshot for records

**EULA in App Store Connect:**

- [ ] Leave **Standard Apple EULA** selected (recommended for 1.0)
- [ ] OR upload custom EULA only if you’ve had it reviewed

> Not legal advice — have a lawyer review policy/EULA if you want extra certainty; for a free local-first scorer with Firebase diagnostics, the gaps above are the usual App Store blockers.

### Visual assets

- [ ] **App icon** 1024×1024 (no alpha, no rounded corners — Apple applies mask)
- [ ] **iPhone screenshots** in `marketing-screenshots/raw/` (**no device frames**; default **1284×2778** for 6.5" slot — see `marketing-screenshots/README.md`)
  - [ ] X01 in-match
  - [ ] Cricket board (Normal or Cut Throat)
  - [ ] Play setup (no Modes tab / no party modes visible)
  - [ ] Activity → History
  - [ ] Activity → Statistics
  - [ ] Players roster (optional 6th)
- [ ] **English only** for 1.0 listing (no localized metadata until locales re-ship)
- [ ] **iPad** screenshots (`marketing-screenshots/ipad/raw/` — **2064×2752**, `./Scripts/capture-ipad-marketing-screenshots.sh`)
- [ ] Preview video (optional — skip for 1.0 if not ready)

**Generate marketing shots:** [`marketing-screenshots/README.md`](../../marketing-screenshots/README.md)

```bash
./Scripts/capture-marketing-screenshots.sh   # exports 1284×2778 for App Store 6.5"
# App Store upload: marketing-screenshots/raw/ only (not framed/)
# Reddit/social: marketing-screenshots/framed/ after frame-marketing-screenshots.sh
```

### TestFlight (automated via Xcode Cloud)

See [`xcode-cloud.md`](xcode-cloud.md) for one-time ASC/Xcode setup.

- [ ] GitHub CI green on `main`; bump `MARKETING_VERSION` in `project.yml` if shipping a new version
- [ ] Trigger release: `/dart-buddy release` in Slack, or GitHub Actions → **Trigger TestFlight**
- [ ] `#dart-buddy-releases` shows Xcode Cloud Notify when archive completes
- [ ] Internal TestFlight build installs on physical device
- [ ] External testers (optional) — collect feedback before public submit

**Escape hatch:** manual archive via Xcode Organizer if automation is unavailable.

---

## 9. Submit, tag & release notes

- [ ] Fill [`../../roadmap/release/Release-Notes-Template.md`](../../roadmap/release/Release-Notes-Template.md) → paste into App Store “What’s New”
- [ ] Git tag RC/build (e.g. `1.0.0` / build N)
- [ ] Select TestFlight build in App Store Connect (or upload via Organizer / Transporter if not using Xcode Cloud)
- [ ] Select build in App Store Connect → **Submit for Review**
- [ ] Complete **App Review Information** (contact, demo account N/A, notes if needed)
- [ ] Fill §12 sign-off + [`QA-Signoff-RC1.md`](../../roadmap/release/QA-Signoff-RC1.md) → **Go** only when P0 empty

Post-submit ops: [`../../roadmap/release/Launch-Day-Runbook.md`](../../roadmap/release/Launch-Day-Runbook.md) · Hotfix gates: [`../../roadmap/release/Rollback-and-Hotfix-Criteria.md`](../../roadmap/release/Rollback-and-Hotfix-Criteria.md)

---

## 10. Launch week (first 48–72 hours after approval)

- [ ] Confirm App Store listing live — copy **public URL**
- [ ] Firebase Crashlytics: watch for new crash clusters
- [ ] App Store Connect: monitor reviews daily; reply to substantive feedback
- [ ] Log incidents in [`../../roadmap/release/Launch-Week-Monitoring-Log.md`](../../roadmap/release/Launch-Week-Monitoring-Log.md) (create entries as needed)
- [ ] Note keyword/impression baseline for later ASO tweaks

---

## 11. Reddit & community launch

**Timing:** After App Store approval and the listing link works — not before.

### Prep (can do before approval)

- [ ] Pick **primary subreddit:** r/darts (also consider r/Darts if active)
- [ ] Secondary (space 24–48h): r/SideProject, r/iOS, r/apple — avoid same-day spam
- [ ] Prepare **3–5 screenshots** or short screen recording (Cricket board + X01 score UI sell well)
  - Use `marketing-screenshots/framed/` for polish; Reddit accepts gallery posts
- [ ] Draft post (save offline; paste App Store link at publish time)

### Suggested post structure

**Title options (pick one):**

- `I built a free, no-ads darts scoreboard for X01 & Cricket — would love feedback from actual throwers`
- `[iOS] Dart Buddy — local-first X01/Cricket scorer with history & stats (no ads)`

**Body outline:**

1. **Hook** — why you built it (pub night, existing apps had ads, wanted clean UI)
2. **What it does** — X01 + Cricket, undo, bots, history, statistics, players, dark mode, VoiceOver basics
3. **What it doesn’t** — no ads, no account required, data stays on device; online/watch deferred
4. **Platform** — iPhone + iPad, iOS 18+ (App Store minimum OS; verify on oldest supported device or simulator)
5. **Ask** — feedback on scoring flow, Cricket UI, feature priorities
6. **Link** — App Store URL (required once live)
7. **Optional** — TestFlight story or “solo dev” transparency if comfortable

### Post checklist

- [ ] Read subreddit rules (self-promo days, flair, screenshot-only rules)
- [ ] Use **link post** or **text post + gallery** — avoid bare URL with no context
- [ ] Flair: “App” / “Project” / mod-approved promo if required
- [ ] Respond to comments same day (especially bug reports and rule questions)
- [ ] Cross-post only after primary thread has traction; customize title per sub
- [ ] Do **not** claim features not in 1.0 (watch, online, camera scoring)

### Optional follow-ups (post-1.0)

- [ ] Local pub/league Facebook groups (with permission)
- [ ] Product Hunt (separate prep — not required for 1.0)
- [ ] Short demo clip for Reddit/Twitter if engagement is good

---

## 12. Sign-off

| Gate | Owner | Date | Status |
|------|-------|------|--------|
| Pre-flight (§0) | | | |
| Release gate (§1) | | | |
| Full smoke (§2) | | | |
| Core matrix (§3) | | | |
| Appearance (§4) | | | |
| Data / migration / privacy (§5) | | | |
| Accessibility (§6) | | | |
| App Store assets (§8) | | | |
| Submitted (§9) | | | |

**QA Go/No-Go:** [ ] **Go** · [ ] **No-Go**

**P0 defects (must be empty for Go):**

| ID | Description | Owner | Status |
|----|-------------|-------|--------|
| | | | |

**Authoritative sign-off doc:** [`../../roadmap/release/QA-Signoff-RC1.md`](../../roadmap/release/QA-Signoff-RC1.md)

---

## 13. Explicitly out of scope for 1.0

Do not delay ship for:

- Game Center ([`FutureIdeas/achievements.md`](../../FutureIdeas/achievements.md))
- Play reminders ([`FutureIdeas/play-reminders.md`](../../FutureIdeas/play-reminders.md))
- Snapshot tests, full motion pass, X01 total-score entry, Cricket variants beyond shipped Normal/Cut Throat (e.g. no-score, Points Off bots)
- Firebase Auth, online play, Watch/widgets, voice “180!” caller
- Full UI automation matrix beyond current CI smoke

---

## Quick reference — doc map

| Need | Doc |
|------|-----|
| **Master ship checklist** | [`1.0.0-ship-checklist.md`](1.0.0-ship-checklist.md) |
| **This runbook (expanded)** | `release_checklist.md` |
| 10-min gate (abbrev) | [`../../specs/ReleaseGateChecklist.md`](../../specs/ReleaseGateChecklist.md) |
| 20-min smoke (abbrev) | [`../../specs/SmokeTestChecklist.md`](../../specs/SmokeTestChecklist.md) |
| Screenshot template | [`../../specs/SmokeTestEvidenceTemplate.md`](../../specs/SmokeTestEvidenceTemplate.md) |
| QA matrix & Go/No-Go | [`../../roadmap/release/QA-Signoff-RC1.md`](../../roadmap/release/QA-Signoff-RC1.md) |
| Manual a11y detail | [`../../accessibility/Manual_todo.md`](../../accessibility/Manual_todo.md) |
| A11y status roll-up | [`../../accessibility/wcag-2.1-aa/SUMMARY.md`](../../accessibility/wcag-2.1-aa/SUMMARY.md) |
| Privacy | [`../../roadmap/reports/Phase06-Security-Privacy-Checklist.md`](../../roadmap/reports/Phase06-Security-Privacy-Checklist.md) |
| Migration | [`../../roadmap/reports/Phase06-Migration-Safety-Report.md`](../../roadmap/reports/Phase06-Migration-Safety-Report.md) |
| Store metadata spec | [`../../specs/AppStoreConnectSpec.md`](../../specs/AppStoreConnectSpec.md) |
| Marketing screenshots | [`marketing-screenshots/README.md`](../../marketing-screenshots/README.md) |
| Privacy & support pages | [`docs/README.md`](../README.md) |
| Active backlog | [`todo.md`](todo.md) |
