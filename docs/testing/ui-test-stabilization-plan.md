# UI test stabilization plan

Tracks remaining work after cricket/forfeit test cleanup. Check items off as they land.

**Related:** [`x01-cricket-ui-test-phased-plan.md`](x01-cricket-ui-test-phased-plan.md), [`.cursor/rules/ui-test-writing.mdc`](../../.cursor/rules/ui-test-writing.mdc)

---

## Priority 1 — `expandSetupOptions` reliability

**Blocker for:** `testX01SummaryDoneReturnsToPlayHome`, `testCompletedVisitPersistsOnInactiveScoreCard`, and most setup-preset helpers.

- [x] Add `scrollToSetupControl(_:in:timeout:)` with coordinate-tap fallback (mirror `scrollToSettingsControl`)
- [x] Harden `expandSetupOptions`: `ensurePlayTab`, scroll edit button before tap, toggle recovery when chips stay hidden
- [x] Align `assertSetupChip` with scroll-to-hittable + coordinate fallback
- [x] Harden `tapMenuChip` / `waitForSetupMenu` for chip menu presentation
- [x] Verify isolated runs:
  - `MatchChromeUITests/testX01SummaryDoneReturnsToPlayHome`
  - `X01MatchUITests/testCompletedVisitPersistsOnInactiveScoreCard`
  - `WCAGAccessibilityUITests/testMatchSetupRequiredControlsExposeLabelsAndIdentifiers`

**Also fixed (test assertion):** inactive X01 score cards expose remaining score (`41`), not visit total — updated `testCompletedVisitPersistsOnInactiveScoreCard`.

**Also fixed:** `finishQuickX01Checkout` waits for Bob/Alice turn boundaries; `scoreSingleVisit` waits for pad ready + enabled keys.

---

## Priority 2 — Forfeit WCAG contracts

**Root cause:** `MatchForfeitCoordinator.canForfeit` requires `eventCount >= 1`; a single `tapX01Segment` does not commit a visit.

- [x] Replace single-dart tap with `scoreSingleVisit` in `testX01ForfeitExitControlContract`
- [x] Replace single-dart tap with `scoreSingleVisit` in `testMatchSummaryForfeitBannerContract`
- [x] Use `assertMatchSummaryForfeitBanner` (combined header label) — child `matchSummaryForfeitBanner` is not in the a11y tree when parent uses `children: .ignore`
- [x] Query exit actions via `descendants(matching:).firstMatch` to avoid duplicate-button snapshot errors
- [x] Added `match_exit_stay` identifier on exit dialog cancel button (app)
- [x] Verify isolated runs of both WCAG forfeit contract tests

---

## Priority 3 — Regression bot + Stay (triage)

**Do not change code until isolated runs fail.**

- [ ] Run `RegressionUITests` alone on iPhone 17 Pro Max
- [ ] If green in isolation → note suite-order flake; consider split or reset in `setUp`
- [ ] If red in isolation → fix `waitForBotVisitToComplete` / Stay timing vs `-ui_test_instant_bots`

---

## Priority 4 — Settings / WCAG (separate track)

Likely unrelated to cricket/forfeit cleanup. Verify identifiers against current Settings UI.

- [ ] Run failing Settings WCAG tests in isolation with `-snapshot_tab settings`
- [ ] Diff against `SettingsUITests` — app ID drift vs scroll/audit helper gap
- [ ] Update `scrollSettingsFormForAudit` markers if new sections were added

---

## Execution order

1. ~~P1 `expandSetupOptions` helper~~ ✓
2. ~~P2 Forfeit WCAG `scoreSingleVisit`~~ ✓
3. P3 Regression isolation run (triage only)
4. P4 Settings WCAG audit (as needed)
