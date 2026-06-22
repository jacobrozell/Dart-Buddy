# Dart Buddy — TODO

Goal: match the reference *Darts Scoreboard: Scorekeeper* app's functionality and feel — ad-free.

Status legend: `[ ]` todo · `[~]` partial

> **1.0.0 shipped:** App Store **1.0.0 (7)** — released 2026-06-22 (submitted 2026-06-20). Tag `1.0.0` on `7df4358`. Items below are post-ship backlog / 1.1 prep unless a hotfix is required.

---

## 1.0 — Post-ship backlog (not blockers)

**1.0.0 is live.** **Scope shipped:** lean 1.0 — X01 + Cricket only, 4 tabs, English, preset + custom bots. See [`lean-1.0-implementation-plan.md`](lean-1.0-implementation-plan.md) for what landed; [`ongoing-release-plan.md`](ongoing-release-plan.md) for **1.1+**.

Deferred evidence + polish from the RC pass:

**Master checklist:** [`1.0.0-ship-checklist.md`](1.0.0-ship-checklist.md) — everything before submit (start here).  
**Expanded runbook:** [`release_checklist.md`](release_checklist.md) — device QA, App Store Connect, launch week, Reddit.

### QA sign-off (device)

Close `../../roadmap/release/QA-Signoff-RC1.md` — no P0 rows left `Pending`. Work through `release_checklist.md` §1–§6.

- [ ] **RC smoke pass** — `release_checklist.md` §1–§2 (or `../../specs/ReleaseGateChecklist.md` + `SmokeTestChecklist.md`) on device (Release build).
- [ ] **Core flow matrix** — Setup → X01 → summary; setup → Cricket → summary; **resume active match**; undo (both modes); history list/detail; **players archive/delete guard**; settings reset flow.
- [ ] **Appearance matrix** — Portrait/landscape × light/dark on setup + one match screen (screenshots in sign-off doc).
- [ ] **Accessibility evidence** — VoiceOver core flows, Dynamic Type (AXXXL), non-color meaning; log in `../../accessibility/wcag-2.1-aa/evidence/` + `../../accessibility/accessibility_todo.md` Phase 0–1.
- [ ] **Smoke test evidence** — `../../specs/SmokeTestEvidenceTemplate.md` screenshots linked from sign-off.

### Data & recovery (device)

- [x] **SwiftData 1.0 schema freeze** — `SchemaV2` baseline documented (`specs/SwiftData.md` §15); V1→V2 migration test in CI.
- [ ] **Bootstrap store recovery smoke** — Corrupt/truncate store on device → app launches cleanly (fresh store); log in `Phase06-Migration-Safety-Report.md`. Distinct from settings reset.

### App Store & release ops

Work through [`release_checklist.md`](release_checklist.md) §8–§11.

- [ ] **App icon finalization** — `Resources/Media.xcassets` / `assets/app-icons/`
- [ ] **App Store listing** — Name, subtitle, keywords, category, age rating, **support URL**, **privacy policy URL** (`../../specs/AppStoreConnectSpec.md`).
- [ ] **Privacy disclosure** — Hosted privacy policy + App Store privacy labels match app behavior (local-first, Firebase Analytics/Crashlytics in Release, no ads/tracking); validate against `Phase06-Security-Privacy-Checklist.md`.
- [ ] **Marketing screenshots** — X01, Cricket, setup, history, stats (§8 of `AppStoreConnectSpec`; separate from smoke evidence). Include `de`/`es`/`nl` device-language captures if localized listings ship in 1.0 (`LocalizationSpec` § App Store Connect).
- [ ] **Release build sanity** — Release config drops debug verbosity; no sensitive data in logs.
- [ ] **Release notes** — Finalize from `../../roadmap/release/Release-Notes-Template.md`; tag RC build.

### Product (1.0 scope)


### UI/UX audit (2026-06-02 — MCP simulator + WCAG suite)

Full audit via XcodeBuildMCP + iOS Simulator MCP. **40/40** `WCAGAccessibilityUITests` passed; manual VO / contrast / AXXXL evidence still required (`todo.md` § QA sign-off). Engineering review: [`ios-code-audit.md`](../ios-code-audit.md).

#### P1 — High-impact UX
- [ ] **Statistics: bot with 0 games but non-zero averages** — Partial-stats banner helps; table still confusing when in-progress match includes bots.
- [ ] **Setup cognitive load** — Consider collapsing advanced X01 chips (Check-In, Set/Leg) behind “Advanced”.

#### P2 — Polish & consistency

- [ ] **Tab bar content bleed** — Settings scroll appeared under Play tab label on simulator; verify safe-area / tab-bar padding on device.

- [ ] **X01 keypad density on small phones** — 7-column grid; validate on SE-class devices.
- [ ] **Dynamic Type at AXXXL** — Hardcoded trophy/score sizes (`MatchSummaryScreen`, `X01MatchScreen`); manual evidence still needed.


#### Audit — working well (no action)

- X01/Cricket gameplay hierarchy, checkout suggestion, turn indicators, match summary celebration, filter patterns on History/Statistics, automated WCAG regression suite.

### Polish (1.0)


---

## 1.0 — Skip (post-1.0 or explicitly deferred)

Do not block 1.0 on these.

### Deferred product

- [ ] **X01 total-score entry toggle** — Keep per-dart entry.
- [ ] **Cricket setup variants (post-1.0)** — No-score / other formats beyond shipped Normal + Cut Throat (`CricketSpec` §8).
- [ ] **Bust / leg / set animations** — Covered by match feedback banners; full motion pass still post-1.0.
- [ ] **iPad / landscape layouts** — Max-width polish only; no two-column match layout.
- [ ] **Snapshot tests** — After UI lock.

### User feedback (broader than shipped caller)

- *Animations ?* — Partially addressed via match feedback banners; broader motion pass post-1.0.
- *Speak mode while playing* — Full caller (“180!”) is post-1.0; turn-total caller is done.

### Performance & data (only if RC finds issues)

- [ ] **Profile SwiftData per-call `ModelContext`**
- [ ] **Performance baselines** — Launch, submitTurn, resumeMatch, history first paint on device (`Phase06-Performance-Report.md`).
- [ ] **Stats aggregate rebuild utility**

### Post-1.0 roadmap

- [ ] **Product backlog** — [`FutureIdeas/backlog.md`](../../FutureIdeas/backlog.md) (prioritized post-1.0 index: CSV recovery, Talk Mode, campaign, dartboard UI, platform items).
- [ ] **Game Center achievements** — [`FutureIdeas/achievements.md`](FutureIdeas/achievements.md) (2–4 day MVP; good 1.1 candidate).
- [ ] **Play reminders / push** — [`FutureIdeas/play-reminders.md`](FutureIdeas/play-reminders.md) (local notifications + Settings; 1–2 day MVP).
- [ ] **Talk Mode (voice scoring input)** — [`FutureIdeas/talk-mode.md`](../../FutureIdeas/talk-mode.md) (speak darts at oche → `DartInput`; distinct from turn-total caller).
- [ ] **Campaign mode** — [`FutureIdeas/campaign-mode.md`](../../FutureIdeas/campaign-mode.md) (ladder; depends on new game engines).
- [ ] **Firebase Auth** — `../../specs/FirebaseBackendAnalyticsSpec.md` Phase 2
- [ ] **Online play / Firestore sync** — `../../specs/OnlinePlaySpec.md`
- [ ] **AI camera auto-scoring** — `AutoScoringVisionSpec`
- [ ] **External display / AirPlay**
- [ ] **Voice caller (“180!”)** — output/hype TTS; not Talk Mode input ([`FutureIdeas/talk-mode.md`](../../FutureIdeas/talk-mode.md))
- [ ] **Apple Watch / widgets / cloud sync**

### Housekeeping (non-blocking)

- [ ] **TestFlight beta** — Optional pre-submission buffer; not a spec blocker.
- [ ] **Debug launch args policy** — `-seed_demo`, `-snapshot_*`, `-ui_test_reset`
- [ ] **XcodeGen team note** — gitignored `.xcodeproj`; no `xcuserstate` in git.

---

## Owner decisions (1.0)

Work below is **blocked on your call** — not just time on device. Everything else in §1.0 is execution (run checklists, capture evidence, upload assets).

### Ship gate

| Decision | Options / notes |
|----------|-----------------|
| **Go / no-go for RC submit** | After `QA-Signoff-RC1.md` is filled — accept remaining P1/P2 polish vs hold for fixes. |
| **TestFlight before App Store** | Optional buffer (`todo.md` § Skip). Skip = submit straight to review. |
| **RC build number** | Which Release build gets tagged `1.0.0-rc1` / final `1.0.0`. |
| **Launch-week hotfix bar** | What counts as P0 post-ship (`../../roadmap/release/Rollback-and-Hotfix-Criteria.md`). |

### App Store & branding

| Decision | Options / notes |
|----------|-----------------|
| **App icon** | Pick one from `assets/app-icons/` (5 concepts) → export into `Resources/Media.xcassets/AppIcon.appiconset/`. |
| **Display name** | Default `Dart Buddy`; backups in `AppStoreConnectSpec.md` §3 if name taken. |
| **Subtitle** | e.g. `Free X01 & Cricket Scoring` vs `No Ads Darts Scorekeeper` (≤30 chars). |
| **Keywords & promo copy** | Starter set in spec §5 — finalize description + promotional text. |
| **Screenshot set** | Framed iPhone set exists (`marketing-screenshots/framed/`); decide **order**, **light vs dark only**, and whether **iPad** uploads are in scope for 1.0. |
| **Support & privacy URLs** | Code points to GitHub Pages (`Support/Navigation/AppLinks.swift`); confirm pages are live and copy is final before Connect upload. |
| **Buy Developer a Coffee** | Link is on in Settings — keep, change URL, or remove for 1.0. |

### Privacy & compliance

| Decision | Options / notes |
|----------|-----------------|
| **App Store privacy labels** | Confirm Analytics + Crashlytics (Release only, no ads/tracking) match `Phase06-Security-Privacy-Checklist.md`. |
| **Hosted privacy policy** | Must match labels and in-app behavior before submit. |

### Product UX (optional for 1.0 — ship as-is or fix first)

| Decision | Options / notes |
|----------|-----------------|
| **Statistics: bot, 0 games, non-zero avg** | Exclude bots from table until 1 completed game · show `—` for avg · keep banner-only · other. |
| **Setup: advanced X01 chips** | Collapse Check-In / Set-Leg behind “Advanced” · leave flat · default expanded vs collapsed. |
| **Tab bar content bleed** | Verify on **physical device** first; if real, choose safe-area padding vs scroll inset fix. |
| **X01 keypad on SE-class phones** | Accept 7-column density · reduce columns · larger hit targets (layout change). |
| **Dynamic Type AXXXL** | Ship with current trophy/score sizes + manual a11y evidence · or require typography pass before submit. |

### Post-1.0 (no 1.0 blocker — pick when planning 1.1)

| Decision | Notes |
|----------|--------|
| **First 1.1 feature** | Game Center achievements vs play reminders vs other (`FutureIdeas/`). |
| **X01 total-score entry** | Currently deferred; per-dart only for 1.0. |
| **Cricket variants** | Normal + Cut Throat shipped for 1.0; other formats (e.g. no-score) post-1.0. |

### Conditional (only if QA / RC finds issues)

- Performance work (`Phase06-Performance-Report.md`) — if baselines fail.
- SwiftData `ModelContext` profiling — if jank observed.
- Stats aggregate rebuild utility — if data inconsistency found.

---

## Sprint order

| Sprint | Focus | Status |
|--------|--------|--------|
| **A–C** | Feedback, history, layout | Done |
| **D** | QA sign-off + a11y evidence + data/recovery smoke | **Current** |
| **E** | App Store listing + RC tag + submit | Next |

**Exit criteria for 1.0:** `QA-Signoff-RC1.md` Go (no P0), privacy checklist closed, listing assets ready.
