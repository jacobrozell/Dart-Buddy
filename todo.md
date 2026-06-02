# Dart Buddy — TODO

Goal: match the reference *Darts Scoreboard: Scorekeeper* app's functionality and feel — ad-free.

Status legend: `[ ]` todo · `[~]` partial

---
logging,Firebase?

## 1.0 — Still needed

Ship blockers before App Store. Product scope is complete; remaining work is **evidence + store ops**.

### QA sign-off (device)

Close `roadmap/release/QA-Signoff-RC1.md` — no P0 rows left `Pending`.

- [ ] **RC smoke pass** — `specs/ReleaseGateChecklist.md` + `SmokeTestChecklist.md` on device (Release build).
- [ ] **Core flow matrix** — Setup → X01 → summary; setup → Cricket → summary; **resume active match**; undo (both modes); history list/detail; **players archive/delete guard**; settings reset flow.
- [ ] **Appearance matrix** — Portrait/landscape × light/dark on setup + one match screen (screenshots in sign-off doc).
- [ ] **Accessibility evidence** — VoiceOver core flows, Dynamic Type (AXXXL), non-color meaning; log in `accessibility/wcag-2.1-aa/evidence/` + `accessibility/accessibility_todo.md` Phase 0–1.
- [ ] **Smoke test evidence** — `specs/SmokeTestEvidenceTemplate.md` screenshots linked from sign-off.

### Data & recovery (device)

- [x] **On-device reset wipe verification** — Full transactional wipe; relaunch clean (`Phase06-Security-Privacy-Checklist.md`).
- [ ] **Migration recovery smoke** — Retry / export / reset paths on target runtime (upgrade or forced failure); log in `Phase06-Migration-Safety-Report.md`. Distinct from settings reset.

### App Store & release ops

- [ ] **App icon finalization** — `Media.xcassets` / `assets/app-icons/`
- [ ] **App Store listing** — Name, subtitle, keywords, category, age rating, **support URL** (`specs/AppStoreConnectSpec.md`).
- [ ] **Privacy disclosure** — Store labels match app behavior (local-only, no ads, no tracking); validate against `Phase06-Security-Privacy-Checklist.md`.
- [ ] **Marketing screenshots** — X01, Cricket, setup, history, stats (§8 of `AppStoreConnectSpec`; separate from smoke evidence).
- [ ] **Release build sanity** — Release config drops debug verbosity; no sensitive data in logs.
- [ ] **Release notes** — Finalize from `roadmap/release/Release-Notes-Template.md`; tag RC build.

### Product (1.0 scope)

- [x] **Settings: default X01/Cricket options** — Settings form exposes X01 defaults; setup reads/writes same fields.
- [x] **Abandoned matches** — Policy: hidden from History/Statistics; no UI list; cleared on reset (`specs/MatchSpec.md` § Abandon).
- [x] **Setup: reorder + remove roster** — Turn order list with drag reorder + swipe remove; random order still shuffles at start.
- [x] **Document in-progress + abandoned match rules** — `specs/MatchSpec.md` (Abandon + Active match constraint).

### Polish (1.0)

- [x] **Cricket closure highlight** — Target closed banner, column pulse, haptic + VO.
- [x] **Bot turn pacing** — Settings: bot stagger + bot dart haptics; `BotTurnPacing` delays.
- [x] **Bust / leg / set feedback** — `MatchFeedbackBanner` for bust + leg won on X01.
- [x] **DesignSystem primitives** — `PrimaryActionButton`, `StatChip`, `ErrorBanner`, `MatchFeedbackBanner`.
- [x] **iPad content width** — `GameplayLayout` on setup, X01, Cricket, summary.

---

## 1.0 — Skip (post-1.0 or explicitly deferred)

Do not block 1.0 on these.

### Deferred product

- [ ] **X01 total-score entry toggle** — Keep per-dart entry.
- [ ] **Cricket setup variants** — Cut Throat etc. (`CricketSpec` MVP is standard only).
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

- [ ] **Game Center achievements** — `achievements.md` (2–4 day MVP; good 1.1 candidate).
- [ ] **Firebase Auth** — `specs/FirebaseBackendAnalyticsSpec.md`
- [ ] **Online play / Firebase SDKs** — `specs/OnlinePlaySpec.md`
- [ ] **AI camera auto-scoring** — `AutoScoringVisionSpec`
- [ ] **External display / AirPlay**
- [ ] **Voice caller (“180!”)**
- [ ] **Apple Watch / widgets / cloud sync**

### Housekeeping (non-blocking)

- [ ] **TestFlight beta** — Optional pre-submission buffer; not a spec blocker.
- [ ] **Debug launch args policy** — `-seed_demo`, `-snapshot_*`, `-ui_test_reset`
- [ ] **XcodeGen team note** — gitignored `.xcodeproj`; no `xcuserstate` in git.

---

## Completed (reference)

<details>
<summary>User feedback, core gaps, testing, release items already done</summary>

### User feedback

- [x] **Turn total caller (optional)**
- [x] **Leg vs match finish SFX**
- [x] **Bot zero visits** (`477a2c5`)
- [x] **X01 live darts + avg**

### History & statistics

- [x] **Statistics: in-progress / partial stats**
- [x] **History: player filter UI**
- [x] **History: push filters to SwiftData**
- [x] **History: pagination**
- [x] **All Games: in-progress row**
- [x] **Home: recent completed mini-list**
- [x] **Game detail per-player hit bars**

### Match setup & play

- [x] **Bot-vs-bot guard**
- [x] **Match Summary cold path**

### UI / UX

- [x] **Localize remaining English**
- [x] **Cricket nav title contrast**
- [x] **X01 layout dead space**
- [x] **Setup flow**
- [x] **Unify match exit chrome**
- [x] **Match Summary stat parity**
- [x] **Empty-state CTAs**
- [x] **Cricket one-screen fit (phone)**
- [x] **X01 player card legibility**
- [x] **Theme cohesion**
- [x] **Reduce Motion on summary celebration**

### Copy / quick fixes

- [x] **“Delete & Start” → abandon wording**
- [x] **Bust banner** — `L10n.bustFeedback`
- [x] **`PlayHomeViewModel.emptyNoPlayers`** removed
- [x] **Tab labels vs spec**

### Testing

- [x] **`StatisticsViewModel`**, **`HistoryListViewModel`**, **`MatchSummaryViewModel`**, **`MigrationRecoveryViewModel`**
- [x] **UI:** checkout → summary, Cricket grid, settings persistence
- [x] **Repository contract tests**

### Release

- [x] **Commit bot tuning + Very Easy** (`477a2c5`)

</details>

---

## Sprint order

| Sprint | Focus | Status |
|--------|--------|--------|
| **A–C** | Feedback, history, layout | Done |
| **D** | QA sign-off + a11y evidence + data/recovery smoke | **Current** |
| **E** | App Store listing + RC tag + submit | Next |

**Exit criteria for 1.0:** `QA-Signoff-RC1.md` Go (no P0), privacy checklist closed, listing assets ready.
