# Onboarding roster staging tests — root-cause note for future agents

If `OnboardingUITests` (in `DartBuddyUIChromeUITests`) or
`MatchSetupUITests/testAddPlayerFromSetupAutoSelectsInRoster`
(in `DartBuddyUISmokeUITests`) are failing with messages like:

```
XCTAssertTrue failed - Expected staged player 'Casey' on Play setup (created=true)
XCTAssertTrue failed - Created player should auto-select in turn order
```

**Read this before touching the staging pipeline.** Multiple agents have burned
hours "fixing" staging logic when staging was never the problem.

## The trap

The failure message says the player was created but is "not staged", so the
obvious assumption is that the onboarding → Play setup handoff
(`PendingMatchPlayerSelections` / `OnboardingSetupStaging` /
`PlaySetupStagingRefresh`) is dropping the player. **It is not.** Adding retry
loops, fetch-reconcile, extra `onAppear()` calls, or longer
`applyPendingSelections` attempt counts does not fix it and only adds dead code.

## The actual root cause (accessibility tree, not staging)

The tests assert on the accessibility id `setup_selected_<name>`. That id lives
on each turn-order row in `Features/Play/Setup/SetupHomeRosterSection.swift`
(`selectedRosterRow`, which uses `.accessibilityElement(children: .ignore)`).
The rows live inside `accessibilityTurnOrderList`, whose container owns
`.accessibilityIdentifier("setup_turnOrderList")`.

When **exactly one** player is staged, SwiftUI merges that lone child row up into
its identified parent container. The merged element keeps the container's id
(`setup_turnOrderList`) and absorbs the row's label
(`"Throwing position 1, <name>"`), so the row's own `setup_selected_<name>` id
**disappears from the tree**. With two or more staged players the merge does not
happen, which is why multi-player roster tests always passed and only the
single-row paths failed:

- `testAddPlayerFromSetupAutoSelectsInRoster` — always one player.
- `testFinishOnboardingStagesPlayerAndBotOnPlay` / `…EasyPath…` — assert on the
  single human row before/independently of the bot row.

### How this was confirmed

Pull the UI hierarchy from the failing result bundle:

```bash
xcodebuild test … -resultBundlePath /tmp/x.xcresult
xcrun xcresulttool export attachments --path /tmp/x.xcresult --output-path /tmp/x
# open the "App UI hierarchy" .txt attachment
```

The tree showed the player fully staged and visible — `setup_turnOrderList` with
label `'Throwing position 1, Casey'`, a `Casey` static text, and a working
`setup_remove_Casey` button — but **no** `setup_selected_Casey` element. Staging
worked; only the per-row id was missing.

## The fix

One line in `SetupHomeRosterSection.swift`, on the `accessibilityTurnOrderList`
container:

```swift
.accessibilityElement(children: .contain)   // before .accessibilityIdentifier("setup_turnOrderList")
```

`children: .contain` marks the container as a grouping element whose children are
independent accessibility elements, so a lone row never merges in and always
keeps its `setup_selected_<name>` id. No staging changes required.

## User impact

None for real users — this was an accessibility-metadata / test-visibility bug.
Staging delivered the player correctly. The fix also makes each turn-order row a
properly distinct element for VoiceOver, which is a small correctness win.

## Guardrails for the next change here

- Do **not** add a second `.accessibilityIdentifier` on the same element as
  `.accessibilityElement(children: .ignore)` children without `children: .contain`
  on the container — that re-introduces the merge.
- If you think staging is broken, first export the failing run's UI hierarchy and
  check whether `setup_turnOrderList` already shows the player. If it does, the
  bug is accessibility composition, not staging.
- Keep the diff minimal. The committed `MatchSetupViewModel.onAppear` staging plus
  `PlayRootView`'s `PlaySetupStagingRefresh.refreshHandler` registration are
  sufficient to carry the onboarding roster into Play setup.
