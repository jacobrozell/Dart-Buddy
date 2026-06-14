# Release build view decomposition plan

**Status:** Implemented (2026-06-14)  
**Created:** 2026-06-14  
**Goal:** Fix Release whole-module compile failures by splitting large SwiftUI views into smaller types — without changing behavior, accessibility identifiers, or UI-test contracts.

**Current workaround:** `SWIFT_COMPILATION_MODE: singlefile` under `Release` in [`project.yml`](../../project.yml). Remove after this plan is complete.

---

## Problem summary

Release builds fail under **default whole-module optimization** with a Swift 6.3 **SILGen crash** (not a source-level syntax error):

```
While silgen emitFunction … SetupHomeView.body
Abort: substOpaqueTypesWithUnderlyingTypes
```

Debug builds succeed. The compiler fails while synthesizing `body` for a single oversized view type that combines scroll chrome, lifecycle hooks, alerts, multiple sheet destinations, and dozens of extension-backed chip grids.

Partial extraction into `ViewModifier` types (chrome, lifecycle, sheets) improves readability but **does not fix whole-module Release** as of 2026-06-14.

---

## Confirmed vs at-risk views

| View | Release whole-module crash? | Why it matters |
|------|----------------------------|----------------|
| **`SetupHomeView`** | **Yes — confirmed** | Four chained `.sheet` modifiers + 20+ chip extensions on one struct + ~500-line roster extension + sticky footer. Only view that failed Release archive in testing. |
| **`PlayersRootView`** | **Not confirmed** | Three `.sheet` modifiers (custom bot, player edit, export share) + two `.alert`s on one `NavigationStack` body. Same anti-pattern; lower type complexity than setup. |
| **`MatchLifecycleChromeModifier`** | **Not confirmed** | Three forfeit `.sheet`s inside a generic `ViewModifier`. Already isolated from match screens; worth hardening if setup refactor isn’t enough. |
| **`ModePickerSheet`** | **Not confirmed** | Nested sheet for rules (`showsRulesForEntry`). Smaller surface; used from setup flow. |
| **`ModesRootView`** | **Not confirmed** | Single `.sheet(item:)` — lower risk. |
| **`X01MatchScreen`** | **Not confirmed** | Single vision-scoring sheet. |
| **`SettingsRootView`** | **Not confirmed** | Large file (~460 lines) but mostly alerts/settings rows, not multi-sheet chains. Monitor if file grows. |

**Takeaway:** Only **`SetupHomeView`** has a proven Release compile failure today. The others are **preventive targets** with similar SwiftUI patterns (multiple sheets/alerts on one body, or mega-extensions on one struct). Address them in Phase 5 if whole-module Release still fails after setup is decomposed, or proactively before adding more sheets.

---

## Guiding principles

1. **Split types, not just computed properties** — new `struct …: View` files, not more `extension SetupHomeView`.
2. **One presentation surface per layer** — prefer a single `.sheet(item:)` enum over four chained `.sheet(isPresented:)`.
3. **Push state down, callbacks up** — child views receive data + closures; the shell owns sheet flags and `Task` handles.
4. **Preserve the UI-test contract** — keep all existing `accessibilityIdentifier` values (`setup_*`, `startMatchButton`, etc.).
5. **Verify after each phase** — remove `singlefile`, run Release build; don’t batch everything before testing.

---

## Target architecture (Setup home)

```
PlayRootView
└── SetupHomeView                    // thin shell (~40 lines)
    └── SetupHomeSheetHost           // owns sheet enum + lifecycle alert
        └── SetupHomeChrome          // scroll + sticky start footer
            └── SetupHomeScrollContent
                ├── SetupHomeHeaderSection
                ├── SetupHomeModeSection
                ├── SetupHomeModeOptionsSection
                └── SetupHomeRosterSection
```

Each box is its **own file and struct**. `SetupHomeView.body` delegates immediately — no modifier chain on the shell type itself.

---

## Phase 0 — Baseline & guardrails (~½ day)

- [ ] Reproduce: remove `SWIFT_COMPILATION_MODE: singlefile`, `xcodegen generate`, Release build → confirm crash on `SetupHomeView.body`.
- [ ] Capture passing UI baseline: `MatchSetupUITests`, `Lean1_0SmokeUITests`, onboarding setup flows.
- [ ] Add CI **Release build smoke** (build only):

  ```bash
  xcodebuild -scheme DartBuddy -configuration Release \
    -destination 'generic/platform=iOS' build
  ```

**Exit:** Repro documented; CI catches future Release regressions.

---

## Phase 1 — Extract sheet + lifecycle host (~1 day)

**Priority:** Crash backtrace referenced sheet destinations (`GameRulesGuideView`, `CustomBotCreationSheet`, `ModePickerSheet`, `PlayerEditSheet`).

**Create** `Features/Play/Setup/SetupHomeSheetHost.swift`:

- Own sheet state (prefer one enum):

  ```swift
  private enum SetupHomeSheet: Identifiable {
      case gameRules(MatchType)
      case customBot
      case modePicker
      case addPlayer
  }
  ```

- Own `startTask`, `onAppear` / `onReceive` / `onChange` / `onDisappear`, active-match conflict alert.
- Replace four `.sheet(isPresented:)` with one `.sheet(item:)`.
- Remove `SetupHomeSheetsModifier` and `SetupHomeLifecycleModifier`.

**Verify:** Release whole-module build. If green, remaining phases may be optional for compile but still improve maintainability.

---

## Phase 2 — Extract chrome + scroll shell (~1 day)

| File | Responsibility |
|------|----------------|
| `SetupHomeChrome.swift` | ScrollView, background, nav hidden, `safeAreaInset` footer |
| `SetupHomeStartFooter.swift` | Start button + inline validation banners |
| `SetupHomeScrollContent.swift` | Wide vs compact layout switch |

Remove `SetupHomeChromeModifier`; use concrete footer view instead of generic closure where possible.

**Verify:** Release build + visual spot-check (iPhone, iPad, accessibility text size).

---

## Phase 3 — Break up content sections (~1–2 days)

### 3a — Header & mode card

- `SetupHomeHeaderSection.swift` — title, resume banner.
- `SetupHomeModeSection.swift` — selected mode card, learn-to-play, edit-options toggle, change mode.
- Optional `SetupHomeModeContext.swift` — pure helpers for `selectedCatalogEntry`, `learnToPlayMatchType`, `hasModeOptionChips` (shared by section + sheet host).

### 3b — Mode option chips

- `SetupHomeModeOptionsSection.swift` — giant `switch activeMatchTypeForSetupOptions`.
- Migrate `SetupHomeView+*OptionChips.swift` extensions → standalone chip views (`SetupCricketOptionChips`, etc.) that take `@ObservedObject setupViewModel`.

### 3c — Roster

- `SetupHomeRosterSection.swift` — content from `SetupHomeView+Roster.swift`.
- Delete empty roster extension file when done.

**Verify:** Release build + full match-setup UI tests.

---

## Phase 4 — Thin shell & remove workaround (~½ day)

- [ ] `SetupHomeView.swift` ~30–50 lines, delegates to `SetupHomeSheetHost`.
- [ ] Remove `SWIFT_COMPILATION_MODE: singlefile` from `project.yml`.
- [ ] Release **build** + **archive** succeed (whole-module).
- [ ] Debug `⌘U` green; CI Release smoke green.

---

## Phase 5 — Secondary views (optional / if needed)

Apply the same patterns if Release still fails or before adding new presentation layers.

### `PlayersRootView` (preventive)

**File:** `Features/Players/PlayersRootView.swift`

**Pattern today:** 3 sheets + 2 alerts on `NavigationStack` body.

**Refactor:**

```
PlayersRootView (shell)
└── PlayersSheetHost
    └── PlayersListChrome (header + list + bottom inset)
```

- Enum sheet: `.customBot`, `.playerEdit(PlayerSheetPresentation)`, `.export(ExportShareItem)`.
- Move alerts into host or small `PlayersAlertsModifier`.

### `MatchLifecycleChromeModifier` (preventive)

**File:** `Features/Play/Shared/MatchLifecycleChrome.swift`

**Pattern today:** 3 forfeit sheets in one modifier `body`.

**Refactor:**

- `ForfeitSheetHost` with enum: `.pickPlayer`, `.pickWinner`, `.confirm`.
- Keep `MatchExitConfirmationModifier` separate (already extracted).

### `ModePickerSheet` (low priority)

**Pattern:** Nested rules sheet inside mode picker.

**Refactor:** Single enum sheet if picker grows; fine as-is for now.

### `SettingsRootView` (monitor)

Large single file but no multi-sheet chain. Split by settings section only if compile time or file size becomes a problem.

---

## Testing checklist

**Automated**

- [ ] `DartBuddyCI` unit tests (Debug)
- [ ] `MatchSetupUITests`
- [ ] `Lean1_0SmokeUITests`
- [ ] `OnboardingUITests` (roster identifiers)
- [ ] CI Release build job

**Manual (Release on device, no launch args)**

- [ ] Resume banner → active match
- [ ] Change mode → mode picker
- [ ] Learn to play → rules sheet
- [ ] Add player / add bot sheets
- [ ] Start match conflict alert
- [ ] iPad wide layout + accessibility text size
- [ ] Players tab: add/edit player, custom bot, export share (after Phase 5)

---

## Suggested PR sequence

| PR | Scope | Gate |
|----|-------|------|
| 1 | Phase 0 + CI Release smoke | — |
| 2 | Phase 1 (sheet host) | **Must pass whole-module Release** |
| 3 | Phase 2 (chrome/scroll) | Release build |
| 4 | Phase 3 (sections + chips + roster) | Release + UI tests |
| 5 | Phase 4 (remove singlefile) | Archive |
| 6 | Phase 5 (Players / lifecycle, if needed) | Release build |

---

## File map (after setup refactor)

```
Features/Play/Setup/
├── SetupHomeView.swift
├── SetupHomeSheetHost.swift
├── SetupHomeChrome.swift
├── SetupHomeScrollContent.swift
├── SetupHomeHeaderSection.swift
├── SetupHomeModeSection.swift
├── SetupHomeModeOptionsSection.swift
├── SetupHomeRosterSection.swift
├── SetupHomeStartFooter.swift
├── SetupHomeModeContext.swift          // optional pure helpers
└── Setup*OptionChips.swift             // renamed from SetupHomeView+* extensions
```

---

## Success criteria

1. Release whole-module **build** passes without `SWIFT_COMPILATION_MODE: singlefile`.
2. Release **archive** succeeds locally and on Xcode Cloud.
3. Match-setup UI tests pass unchanged.
4. No user-visible behavior change in Play setup (and Players, if Phase 5 done).

---

## References

- Workaround: [`project.yml`](../../project.yml) `configs.Release.SWIFT_COMPILATION_MODE`
- Crash site: [`Features/Play/Setup/SetupHomeView.swift`](../../Features/Play/Setup/SetupHomeView.swift)
- UI-test identifiers: [`Tests/UI/Support/UITestMenuSupport.swift`](../../Tests/UI/Support/UITestMenuSupport.swift)
- Release checklist: [`docs/release/1.0.0-ship-checklist.md`](../release/1.0.0-ship-checklist.md) §3
