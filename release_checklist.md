# DartBuddy — 1.0 Release Checklist

**Brand:** DartBuddy (customer-facing name, screenshots, App Store listing, support site)  
**Technical target:** `DartsScoreboard` (Xcode scheme, bundle ID, module)  
**Version:** `1.0.0` · **Exit criteria:** All **P0** items checked; [`roadmap/release/QA-Signoff-RC1.md`](roadmap/release/QA-Signoff-RC1.md) marked **Go** (no P0 defects).

Use this file as the single runbook. Detailed criteria live in linked specs — do not duplicate evidence here; link or file paths only.

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
| Physical device(s) | (model + iOS version) |
| Simulator(s) | |
| Firebase plist in Release | Yes / No (analytics allowlist only if Yes) |

---

## 0. Pre-flight (before device work)

### Engineering & CI

- [ ] `main` / release branch green: [`.github/workflows/ci.yml`](.github/workflows/ci.yml) (`xcodegen generate` + `xcodebuild test`)
- [ ] Local: `xcodegen generate` then **Product → Test** (`⌘U`) on `DartsScoreboard` scheme
- [ ] `GoogleService-Info.plist` present for Release archive (from example + Firebase Console); Debug stays off analytics unless `-firebase_analytics_debug`
- [ ] Version / build number bumped in Xcode / `project.yml` as needed
- [ ] **Archive** with **Release** configuration (distribution signing, not ad-hoc debug)

### Release build sanity

- [ ] No debug-only verbosity in Release (logs via `AppLogger` only; no stray `print`)
- [ ] No sensitive data in logs (player names OK for local debug policy; no tokens)
- [ ] UI tests / manual runs: `-disable_firebase_analytics` or equivalent not required on store build (only for test runs)

**P0 if CI red or Release archive fails.**

---

## 1. Fast release gate (~10 min)

**Build:** Release · **Device:** Physical iPhone preferred (sim OK for this pass only if blocked)  
**Spec:** [`specs/ReleaseGateChecklist.md`](specs/ReleaseGateChecklist.md)

**Pre-run:** Settings → **Reset All Local Data** → relaunch → land on **Play**.

- [ ] App launches; tabs **Play**, **History**, **Players**, **Settings** work (no blank/error)
- [ ] Create players `Smoke Alice`, `Smoke Bob`
- [ ] X01: start match → submit turn → **Undo Last Turn** → no crash
- [ ] Cricket: start match → submit turn → undo → board sane
- [ ] History: completed row → detail loads (header + timeline)
- [ ] Settings: toggle **Sound** → leave tab → relaunch → still persisted
- [ ] **AXXXL** spot check: New Match setup + one in-match screen — primary CTA reachable

**Decision:** [ ] **PASS** — proceed · [ ] **FAIL** — fix before any further gates

---

## 2. Full smoke test (~20 min)

**Build:** Release · **Devices:** iPhone (Light + Dark) + iPad (Dark) per [`specs/SmokeTestChecklist.md`](specs/SmokeTestChecklist.md)  
**Players:** `Smoke Alice`, `Smoke Bob`, `Smoke Carol`

**Pre-run:** Reset all local data → relaunch.

### A. App shell

- [ ] All tabs; rapid tab switch; background/foreground once — stable

### B. Players

- [ ] Add three smoke players; search `Smoke Bob`; clear search; open detail and back

### C. X01

- [ ] Setup: X01, 301 or 501, ≥2 players → start → submit → undo → submit again — no clip/overlap

### D. Cricket

- [ ] New match → Cricket → submit → undo → resubmit — marks/state correct

### E. History

- [ ] Completed match visible; filters (mode + date); detail header fields + timeline

### F. Settings

- [ ] Theme, default mode, haptics, sound — persist across navigation and relaunch

### G. Accessibility (quick)

- [ ] AXXXL on setup, X01, Cricket, Settings — usable, scrollable

**Pass criteria:** No crashes, stuck navigation, core data loss, or hidden primary controls.

**Evidence:** Capture per [`specs/SmokeTestEvidenceTemplate.md`](specs/SmokeTestEvidenceTemplate.md); store under `roadmap/release/evidence/` or link from sign-off doc.

| Artifact | Done |
|----------|------|
| `players-created.png` | [ ] |
| `x01-in-match.png` | [ ] |
| `cricket-in-match.png` | [ ] |
| `history-detail.png` | [ ] |
| `settings-persistence.png` | [ ] |
| `accessibility-setup-or-match.png` (AXXXL) | [ ] |

---

## 3. Core flow matrix (RC sign-off)

**Build:** Release · **Physical iPhone required** for haptics/resume feel  
**Log in:** [`roadmap/release/QA-Signoff-RC1.md`](roadmap/release/QA-Signoff-RC1.md) — each row `Pass` / `Fail` / `Blocked` + evidence path.

| Flow | Pass | Evidence / notes |
|------|------|------------------|
| Setup → X01 → **Match summary** | [ ] | |
| Setup → Cricket → **Match summary** | [ ] | |
| **Resume** active match (background/kill/relaunch) | [ ] | |
| Undo (X01 + Cricket) | [ ] | |
| History list + detail | [ ] | |
| **Players:** archive player; **delete guard** (cannot delete in-use / confirm destructive) | [ ] | |
| **Settings → Reset All Local Data** (confirm → relaunch clean) | [ ] | |
| **Abandon** in-progress match (wording + hidden from history per spec) | [ ] | |
| Bot match: pacing + pad disabled during bot turn | [ ] | |
| Statistics tab loads with filters | [ ] | |
| Play home: in-progress row / resume banner when applicable | [ ] | |

---

## 4. Appearance matrix (4-way)

**Screens:** Match **setup** + one **in-match** screen (X01 or Cricket)  
**Log screenshots in:** QA sign-off doc + `accessibility/wcag-2.1-aa/evidence/orientation/` if filing a11y evidence.

| Combo | Setup | In-match |
|-------|-------|----------|
| Portrait + Light | [ ] | [ ] |
| Portrait + Dark | [ ] | [ ] |
| Landscape + Light | [ ] | [ ] |
| Landscape + Dark | [ ] | [ ] |

**iPad (optional but recommended):** `GameplayLayout` max-width — setup + one match, no broken layout.

---

## 5. Data, privacy & migration (P0)

### Settings reset (on device)

- [ ] Settings → Reset → confirm → relaunch: empty players/history, Play home, no ghost active match  
- [ ] Log result in [`roadmap/reports/Phase06-Security-Privacy-Checklist.md`](roadmap/reports/Phase06-Security-Privacy-Checklist.md)

### Migration recovery screen (manual)

Architecture is ready; **device proof** of Retry / Export / Reset UX is still required ([`roadmap/reports/Phase06-Migration-Safety-Report.md`](roadmap/reports/Phase06-Migration-Safety-Report.md)).

**Trigger recovery UI (pick one):**

1. **Simulator / dev container:** Run app, create some data, quit. Delete or truncate `Application Support/DartsScoreboard.sqlite` (+ `-shm` / `-wal` if present). Relaunch → expect migration recovery screen.
2. **Upgrade path (if available):** Install previous TestFlight/RC build with data → install 1.0 RC → verify data intact OR recovery screen if failure injected.

**On recovery screen:**

- [ ] **Retry** — succeeds or shows retry failed without crash
- [ ] **Export diagnostics** — file produced; share sheet / path shown
- [ ] **Reset local data** — confirms destructive action; app reaches clean bootstrap
- [ ] VoiceOver: retry, export, reset buttons ([`accessibility/Manual_todo.md`](accessibility/Manual_todo.md) § Migration recovery)

**1.0.0 first ship note:** If schema has not changed since last beta, real-user migration may be N/A — still complete (1) or document **Blocked** with reason in Phase06 report.

### Privacy & store labels

- [ ] App Store privacy answers match app: **local-first**, no ads, no tracking IDs; analytics only if Release ships Firebase ([`specs/AppStoreConnectSpec.md`](specs/AppStoreConnectSpec.md) §6, [`roadmap/reports/Phase06-Security-Privacy-Checklist.md`](roadmap/reports/Phase06-Security-Privacy-Checklist.md))
- [ ] In-app **Reset All Local Data** described accurately in review notes if asked

---

## 6. Accessibility evidence (P0 for sign-off)

**Roll-up:** [`accessibility/wcag-2.1-aa/SUMMARY.md`](accessibility/wcag-2.1-aa/SUMMARY.md)  
**Manual list:** [`accessibility/Manual_todo.md`](accessibility/Manual_todo.md)  
**File evidence under:** `accessibility/wcag-2.1-aa/evidence/` (`voiceover/`, `dynamic-type/`, `orientation/`, `contrast/`)

### VoiceOver — end-to-end (required)

- [ ] Play home → setup → **X01** → summary
- [ ] Play home → setup → **Cricket** → summary
- [ ] Resume banner / active match when present
- [ ] Settings reset confirmation (destructive)
- [ ] Migration recovery (if triggered in §5)

### VoiceOver — spot checks (high risk screens)

- [ ] X01: pad, bust, checkout, bot turn
- [ ] Cricket: board, closure, bot turn
- [ ] History list/detail; Players list archive/delete
- [ ] Statistics: filters + partial-data banner if shown

### Dynamic Type (AXXXL)

- [ ] Match setup (roster, START, chips)
- [ ] X01 match (score + pad)
- [ ] Cricket match (board + pad on phone)
- [ ] History list, Settings

### Contrast & non-color meaning

- [ ] Critical states not color-only (bust, leg won, Cricket closed target, selected roster)
- [ ] Sample contrast check: secondary text on cards; Cricket nav title; bot banner on dark

### Reduce Motion

- [ ] Match summary: no trophy spring when Reduce Motion on; content still readable

**Update QA sign-off accessibility rows** when complete.

---

## 7. DartBuddy — App Store & branding

**Positioning spec (adapt names to DartBuddy):** [`specs/AppStoreConnectSpec.md`](specs/AppStoreConnectSpec.md)

### Brand consistency

- [ ] **App Store name:** DartBuddy (or `DartBuddy: …` if subtitle in name; ≤30 chars; check availability)
- [ ] Icon, screenshots, and in-app marketing use **DartBuddy** (not legacy “Darts Scoreboard” copy from older docs)
- [ ] Support URL / contact live (required for review)
- [ ] Bundle display name / localized app name aligned with DartBuddy where shown on Home Screen

### Listing content

- [ ] **Subtitle** (e.g. free X01 & Cricket scoring, no ads)
- [ ] **Keywords** (darts, scoreboard, x01, cricket, scorekeeper — focused set)
- [ ] **Description** — local-first, no ads, history, players, bots, accessibility
- [ ] **Category:** Sports · **Age:** 4+ · **Price:** Free · **No IAP / no ads** for 1.0
- [ ] **Promotional text** (optional, short)

### Visual assets

- [ ] **App icon** finalized in `Media.xcassets` / [`assets/app-icons/`](assets/app-icons/)
- [ ] **Marketing screenshots** (real UI, not mocks), priority order:
  1. X01 gameplay
  2. Cricket board
  3. New match setup
  4. History
  5. Statistics or player profile
- [ ] Light and/or dark variants as needed; short benefit captions only

### Submission package

- [ ] Privacy nutrition labels + App Privacy questionnaire
- [ ] Export compliance / encryption questionnaire (standard HTTPS only → typically exempt)
- [ ] Review notes: test account not required (local-only); how to reset data; analytics note if Firebase enabled
- [ ] **Release notes** from [`roadmap/release/Release-Notes-Template.md`](roadmap/release/Release-Notes-Template.md)

---

## 8. Tag, submit, launch week

### Tag & archive

- [ ] Git tag (e.g. `1.0.0`) on signed-off commit
- [ ] Upload build to App Store Connect; processing complete
- [ ] Select build on 1.0 version record; submit for review

### Optional (recommended, not blocking)

- [ ] **TestFlight** external group (3–5 players, 2–3 days) before public submit
- [ ] [`roadmap/release/Launch-Week-Monitoring-Log.md`](roadmap/release/Launch-Week-Monitoring-Log.md) — owner for Day 0–7 crashes/reviews

### Post-submit (do not block 1.0)

- Performance baselines on device ([`roadmap/reports/Phase06-Performance-Report.md`](roadmap/reports/Phase06-Performance-Report.md)) — only if RC showed jank
- Game Center, Firebase Auth, online play — see [`todo.md`](todo.md) § Post-1.0

---

## 9. Sign-off

| Gate | Owner | Date | Status |
|------|-------|------|--------|
| Release gate (§1) | | | |
| Full smoke (§2) | | | |
| Core matrix (§3) | | | |
| Appearance (§4) | | | |
| Data / migration / privacy (§5) | | | |
| Accessibility (§6) | | | |
| App Store assets (§7) | | | |

**QA Go/No-Go:** [ ] **Go** · [ ] **No-Go**

**P0 defects (must be empty for Go):**

| ID | Description | Owner | Status |
|----|-------------|-------|--------|
| | | | |

**Authoritative sign-off doc:** [`roadmap/release/QA-Signoff-RC1.md`](roadmap/release/QA-Signoff-RC1.md)

---

## 10. Explicitly out of scope for 1.0

Do not delay ship for:

- Game Center ([`achievements.md`](achievements.md))
- Snapshot tests, full motion pass, X01 total-score entry, Cricket variants (Cut Throat)
- Firebase Auth, online play, Watch/widgets, voice “180!” caller
- `DBX-DESIGN-SYSTEM` global fail on shared components (post-MVP per a11y tracker)

---

## Quick reference — doc map

| Need | Doc |
|------|-----|
| 10-min gate | [`specs/ReleaseGateChecklist.md`](specs/ReleaseGateChecklist.md) |
| 20-min smoke | [`specs/SmokeTestChecklist.md`](specs/SmokeTestChecklist.md) |
| Screenshot template | [`specs/SmokeTestEvidenceTemplate.md`](specs/SmokeTestEvidenceTemplate.md) |
| QA matrix & Go/No-Go | [`roadmap/release/QA-Signoff-RC1.md`](roadmap/release/QA-Signoff-RC1.md) |
| Manual a11y | [`accessibility/Manual_todo.md`](accessibility/Manual_todo.md) |
| A11y status | [`accessibility/wcag-2.1-aa/SUMMARY.md`](accessibility/wcag-2.1-aa/SUMMARY.md) |
| Privacy | [`roadmap/reports/Phase06-Security-Privacy-Checklist.md`](roadmap/reports/Phase06-Security-Privacy-Checklist.md) |
| Migration | [`roadmap/reports/Phase06-Migration-Safety-Report.md`](roadmap/reports/Phase06-Migration-Safety-Report.md) |
| Store copy (update brand to DartBuddy) | [`specs/AppStoreConnectSpec.md`](specs/AppStoreConnectSpec.md) |
| Active backlog | [`todo.md`](todo.md) |

---

## Suggested order (one afternoon + store day)

1. §0 Pre-flight  
2. §1 Release gate on device (Release build)  
3. §2 Smoke + evidence screenshots  
4. §3 Core matrix (resume, players guards, abandon)  
5. §4 Appearance 4-way  
6. §5 Reset + migration recovery trigger  
7. §6 VoiceOver passes + AXXXL snapshots  
8. Fill §9 + `QA-Signoff-RC1.md`  
9. §7 App Store assets (can parallelize before submit)  
10. §8 Tag & submit
