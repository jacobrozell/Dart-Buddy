# Match Forfeit Specification

## 1. Purpose

Define **Save & Forfeit** — a deliberate, user-initiated way to end an in-progress match early while **preserving scored play** in Activity history and player statistics.

Today the exit flow offers only:

| Action | Terminal status | History | Player stats | Resumable |
|--------|-----------------|---------|--------------|-----------|
| **Save & Exit** | `inProgress` | No | No | Yes |
| **Abandon Match** | `abandoned` | No | No | No |

Forfeit fills the gap: *"We didn't finish, but I want credit for the darts we threw."*

**Related specs:** [`MatchSpec.md`](MatchSpec.md), [`HistorySpec.md`](HistorySpec.md), [`StatsSpec.md`](StatsSpec.md), [`MatchSummarySpec.md`](MatchSummarySpec.md), [`NavigationSpec.md`](NavigationSpec.md), [`ScoringInputSpec.md`](ScoringInputSpec.md), [`AccessibilitySpec.md`](AccessibilitySpec.md).

**Status:** **Required for 1.0.0 ship.** No feature flag. Lean 1.0 surfaces forfeit on **X01 + Cricket** only (party modes gated by `ProductSurface`); implementation must still land on **all five shipped engines** so full-surface and post-1.0 builds work without a second pass.
**Estimated release:** `1.3`

---

## 2. Product goals

### Primary use cases
1. **Bar / league cutoff** — time runs out mid-leg; players agree to stop and record partial stats.
2. **Injury or equipment failure** — match cannot continue; remaining standings should be saved.
3. **Multi-player drop-out** — one player leaves a 3–8 player game; group ends match and saves stats for everyone else.
4. **Bot match quit** — human concedes; bot recorded as winner with throws-to-date preserved.
5. **Party mode early end** — Baseball / Killer / Shanghai stopped mid-session with runs/lives/points preserved.

### Non-goals (1.0.0)
- Forfeit **without** at least one committed scoring event.
- **Undo last throw** after forfeit (terminal state).
- Online / remote forfeit negotiation.
- Partial forfeit where some players leave and others keep playing (v1 ends the **whole** match).
- Solo-practice-only flows (Call & Hit, etc.) — separate spec when those modes ship.

---

## 3. Terminology

| Term | Meaning |
|------|---------|
| **Natural completion** | Engine declares match complete (`status = completed`). |
| **Forfeit** | User ends match early; scored events kept; winner assigned by forfeit rules (`status = forfeited`). |
| **Abandon** | User discards match; no history/stats (existing behavior). |
| **Save & Exit** | User leaves UI; match stays `inProgress` for resume. |
| **Forfeiting player** | Participant who conceded (`forfeitedByPlayerId`). |
| **Forfeit winner** | `winnerPlayerId` after forfeit — not a checkout/closure win. |
| **Standings leader** | Best-scoring **remaining** participant after removing forfeiter, per mode rules §7. |

---

## 4. 1.0.0 scope

### In scope — all shipped competitive modes

Every mode with a live `*MatchScreen` and `*MatchViewModel` **must** support forfeit when `ProductSurface.isMatchTypeReachable(type)` is true:

| `MatchType` | Screen | ViewModel | Lean 1.0 reachable | Player counts |
|-------------|--------|-----------|-------------------|---------------|
| `x01` | `X01MatchScreen.swift` | `X01MatchViewModel.swift` | Yes | 1–8 (solo forfeit: forfeiter = sole human; winner = self N/A — see §7.4) |
| `cricket` | `CricketMatchScreen.swift` | `CricketMatchViewModel.swift` | Yes | 2–8 |
| `baseball` | `BaseballMatchScreen.swift` | `BaseballMatchViewModel.swift` | When `showsPartyModes` | 2–8 |
| `killer` | `KillerMatchScreen.swift` | `KillerMatchViewModel.swift` | When `showsPartyModes` | 2–8 |
| `shanghai` | `ShanghaiMatchScreen.swift` | `ShanghaiMatchViewModel.swift` | When `showsPartyModes` | 2–8 |

**Player counts:** 2-player **and** 3+ player flows are both 1.0.0 requirements.

### Deliverables checklist (agent must complete all)

- [ ] Domain: `MatchStatus.forfeited`, `MatchLifecycleService.forfeit`, `MatchForfeitWinnerResolver`, `MatchForfeitStandingsRegistry`
- [ ] Runtime: `forfeitedByPlayerId` on `MatchRuntimeState`
- [ ] Persistence: `SchemaV3` + `forfeitedByPlayerId` on `MatchRecord`; `MatchRepository.forfeitMatch`
- [ ] Payload: `MatchHistoryCardPayload` v2 with `isForfeited`
- [ ] Shared chrome: `MatchLifecycleChrome`, `MatchForfeitCoordinator`, `MatchPlaySessionHost` (§6.7)
- [ ] UI: forfeit picker sheets inside chrome; forfeit summary variant
- [ ] Catalog gate: `everyShippedMatchTypeHasForfeitStandingsRegistered` test
- [ ] History: list badge, detail subtitle, accessibility strings
- [ ] Stats: include `forfeited` in all aggregate/history queries
- [ ] Analytics: `match_forfeited` / `match_forfeit_failed`
- [ ] Localization: `en`, `de`, `es`, `nl` keys §22
- [ ] Tests: unit + integration + UI + WCAG + identifier contract §24
- [ ] Accessibility evidence: update screen docs §25
- [ ] Cross-spec amendments §26

### Out of scope (1.0.0)
- History filter chip **Finished / Forfeited** (post-1.0 polish)
- Campaign forfeit rules (campaign not in 1.0)
- Forfeit reason picker
- `enableMatchForfeit` feature flag

---

## 5. Domain model

### 5.1 New status value

Add to `MatchStatus` (`Domain/Models/RepositoryModels.swift`) and `MatchLifecycleStatus` (`Domain/Match/MatchLifecycleModels.swift`):

```swift
case forfeited
```

Terminal states: `completed` | `forfeited` | `abandoned`.

### 5.2 New fields

**`MatchRuntimeState`** (`Domain/Services/MatchLifecycleService.swift`):

```swift
public var forfeitedByPlayerId: UUID?
```

**`MatchSummary`** (`Domain/Models/RepositoryModels.swift`):

```swift
public let forfeitedByPlayerId: UUID?
```

Default `nil` for non-forfeit rows. Add to `init` with default `nil` so existing call sites compile.

**`MatchRecord`** — new schema version `SchemaV3` (`Persistence/Schemas/SchemaV3.swift`):

```swift
public var forfeitedByPlayerId: UUID?
```

Do **not** add redundant `completionKind` — `status == forfeited` is authoritative.

### 5.3 History card payload v2

Extend `MatchHistoryCardPayload` (`Domain/Match/MatchHistoryCardPayload.swift`):

```swift
public static let currentPayloadVersion = 2

public let isForfeited: Bool           // default false when decoding v1
public let forfeitedByPlayerId: UUID?  // default nil when decoding v1
```

Custom `init(from decoder:)` — if `payloadVersion < 2`, set `isForfeited = false`, `forfeitedByPlayerId = nil`.

`MatchHistoryCardBuilder.build` accepts optional `forfeitedByPlayerId` and sets `isForfeited` when non-nil.

### 5.4 Events immutability

All turn/dart events before forfeit remain immutable. Forfeit appends **no** scoring events.

---

## 6. Lifecycle

### 6.1 State diagram

```text
notStarted → inProgress → completed   (natural)
                      ↘ forfeited    (Save & Forfeit)
                      ↘ abandoned    (Abandon Match)
                      ↗ (Save & Exit — stays inProgress)
```

### 6.2 `MatchLifecycleService.forfeit`

Add to `Domain/Services/MatchLifecycleService.swift`:

```swift
public static func forfeit(
    session: MatchLifecycleSession,
    forfeitingPlayerId: UUID,
    winnerPlayerId: UUID,
    timestamp: Date = Date()
) throws -> MatchLifecycleSession
```

**Preconditions** (throw `AppError` `validationFailed`, key `error.match.forfeit.invalid`):
- `session.runtime.status == .inProgress`
- `session.runtime.eventCount >= 1`
- `forfeitingPlayerId` matches a participant `playerId` (or participant `id` when `playerId` nil for edge bots)
- `winnerPlayerId` matches a **different** participant
- `winnerPlayerId` must not equal `forfeitingPlayerId`

**Effects:**
- `runtime.status = .forfeited`
- `runtime.endedAt = timestamp`
- `runtime.forfeitedByPlayerId = forfeitingPlayerId`
- `runtime.winnerPlayerId = winnerPlayerId`
- `runtime.currentTurnPlayerId = nil`
- New snapshot at current `eventCount`
- Return updated session

**Idempotency:** If already `forfeited` or `completed`, return unchanged (mirror `abandon`).

### 6.3 `MatchForfeitWinnerResolver`

New file: `Domain/Services/MatchForfeitWinnerResolver.swift`

Pure struct with:

```swift
enum MatchForfeitWinnerResolution: Equatable {
    case automatic(winnerPlayerId: UUID)
    case chooseAmongTied([ForfeitCandidate])  // UI shows picker
}

struct ForfeitCandidate: Identifiable, Equatable {
    let playerId: UUID
    let displayName: String
    let standingSummary: String  // e.g. "121 remaining" / "45 pts"
}

enum MatchForfeitWinnerResolver {
    static func resolve(
        session: MatchLifecycleSession,
        forfeitingPlayerId: UUID
    ) throws -> MatchForfeitWinnerResolution
}
```

**Algorithm:**
1. Collect remaining participants (exclude `forfeitingPlayerId`).
2. If exactly one remains → `.automatic(that playerId)`.
3. Else score each remaining participant per §7.2 → sort best-first.
4. If unique leader → `.automatic(leader)`.
5. If tie at top → `.chooseAmongTied(tied subset only)`.

Use participant `playerId` when present; fall back to participant row `id` for bots without linked players (same as elsewhere in app).

### 6.4 `MatchForfeitSupport`

New file: `Features/Play/Shared/MatchForfeitSupport.swift`

```swift
@MainActor
enum MatchForfeitSupport {
    static func persistForfeit(
        session: MatchLifecycleSession,
        forfeitingPlayerId: UUID,
        winnerPlayerId: UUID,
        matchId: UUID,
        store: ActiveMatchStore,
        matchRepository: any MatchRepository,
        logger: any AppLogger,
        matchType: MatchType
    ) async throws -> MatchLifecycleSession
}
```

**Sequence** (single transactional intent — if `updateMatch` fails, do not remove from store):
1. `let forfeited = try MatchLifecycleService.forfeit(session:, forfeitingPlayerId:, winnerPlayerId:)`
2. `try await matchRepository.saveSnapshot(...)` if needed
3. `try await matchRepository.forfeitMatch(matchId:, endedAt:, winnerPlayerId:, forfeitedByPlayerId:)`
4. `store.remove(matchId:)`
5. Log `match_forfeited` via `logger.matchInfo`
6. Return forfeited session

### 6.5 Repository `forfeitMatch`

Add to `MatchRepository` protocol (`Data/Repositories/RepositoryProtocols.swift`):

```swift
func forfeitMatch(
    matchId: UUID,
    endedAt: Date,
    winnerPlayerId: UUID,
    forfeitedByPlayerId: UUID
) async throws -> MatchSummary
```

Implement in `SwiftDataMatchRepository.swift` — mirror `completeMatch`:
- Set `statusRaw = forfeited`
- Set `endedAt`, `winnerPlayerId`, `forfeitedByPlayerId`
- Clear `currentTurnPlayerId`
- Build `historyCardPayload` via `buildHistoryCardPayload` (pass forfeit metadata)
- `context.save()`

Update `updateMatch` branch: write `historyCardPayload` when `status == .forfeited` (same as `.completed`).

Update **all** history fetch predicates — replace single `completedRaw` filter with:

```swift
let completedRaw = MatchStatus.completed.rawValue
let forfeitedRaw = MatchStatus.forfeited.rawValue
// predicate: statusRaw == completedRaw || statusRaw == forfeitedRaw
```

Files to update:
- `SwiftDataMatchRepository.fetchHistory`
- `SwiftDataMatchRepository.fetchHistoryWithParticipants`
- Any other `statusRaw == completed` queries (grep the repo)

Stub implementations: `Data/Repositories/StubRepositories.swift`, test doubles as needed.

### 6.6 Eligibility gate

| `eventCount` | Save & Forfeit visible | Abandon Match |
|--------------|------------------------|---------------|
| `0` | **No** (hidden) | Yes |
| `>= 1` | Yes | Yes |

Computed once in shared chrome — **not** reimplemented per mode:

```swift
var canForfeit: Bool { session?.runtime.eventCount ?? 0 >= 1 }
```

### 6.7 Scalable architecture — new modes inherit forfeit automatically

**Principle:** Forfeit is **match-lifecycle** behavior (like abandon, resume, history), not mode-specific gameplay. Any mode that runs through `MatchLifecycleSession` + `*MatchScreen` with `match_exit` gets Save & Forfeit **for free** by wiring shared chrome. New engines only register **how to rank standings** — not the exit UI, flow state machine, persistence, history, or stats.

```text
┌─────────────────────────────────────────────────────────────────┐
│  *MatchScreen (mode board + pad only)                           │
│    .matchLifecycleChrome(host:onShowSummary:onDismiss:)  ◄── ONE │
└────────────────────────────┬────────────────────────────────────┘
                             │
┌────────────────────────────▼────────────────────────────────────┐
│  MatchLifecycleChrome (NEW)                                     │
│    MatchGameplayHeader (match_exit)                             │
│    MatchExitConfirmationModifier                                │
│    ForfeitPlayerPicker / ForfeitWinnerPicker / FinalConfirm     │
│    MatchForfeitCoordinator (flow state machine)                 │
│    MatchAbandonCoordinator (existing abandon path, extracted)   │
└────────────────────────────┬────────────────────────────────────┘
                             │
┌────────────────────────────▼────────────────────────────────────┐
│  MatchPlaySessionHost (protocol — thin ViewModel surface)       │
│    session, matchId, isBotTurnBlocking, recoverBotPlayback…     │
└────────────────────────────┬────────────────────────────────────┘
                             │
┌────────────────────────────▼────────────────────────────────────┐
│  Domain (mode-agnostic)                                         │
│    MatchLifecycleService.forfeit                                │
│    MatchForfeitWinnerResolver + MatchForfeitStandingsRegistry   │
│    MatchForfeitSupport.persistForfeit                           │
│    MatchRepository.forfeitMatch                                 │
└─────────────────────────────────────────────────────────────────┘
```

#### 6.7.1 `MatchPlaySessionHost` protocol

**New file:** `Features/Play/Shared/MatchPlaySessionHost.swift`

Minimum surface each `*MatchViewModel` exposes (via protocol conformance — **no forfeit methods in ViewModels**):

```swift
@MainActor
protocol MatchPlaySessionHost: AnyObject, ObservableObject {
    var matchId: UUID { get }
    var session: MatchLifecycleSession? { get }
    var isBotTurnBlocking: Bool { get }  // bot playing or submitting turn

    func loadSessionIfNeeded() async
    func recoverBotPlaybackIfNeeded()
    func onDisappear()
    func abandonMatch() async
}
```

Default implementations live in `MatchPlaySessionHost+Lifecycle.swift` for shared `abandonMatch` body (today duplicated 5×).

Each existing ViewModel conforms in **≤10 lines** — mostly `var isBotTurnBlocking` mapping from mode state enum.

#### 6.7.2 `MatchForfeitCoordinator` (owns entire UI flow)

**New file:** `Features/Play/Shared/MatchForfeitCoordinator.swift`

`@MainActor @Observable final class MatchForfeitCoordinator` holds:
- `flowState: MatchForfeitFlowState` (idle → pickPlayer → pickWinner → confirm → persisting)
- References: `host: any MatchPlaySessionHost`, repositories, store, logger
- All methods currently specced as per-ViewModel: `beginForfeitFlow`, `selectForfeitingPlayer`, `confirmForfeit`, etc.

`MatchLifecycleChrome` owns `@StateObject private var forfeitCoordinator` and injects the host ViewModel on appear.

**New mode ship checklist (forfeit slice):**
1. ViewModel conforms to `MatchPlaySessionHost`.
2. Screen applies `.matchLifecycleChrome(host:viewModel, ...)`.
3. Add **one** `MatchType` case to `MatchForfeitStandingsRegistry` (§6.7.3).
4. Done — no copy-paste exit alerts, no `forfeitMatch()` on ViewModel.

#### 6.7.3 `MatchForfeitStandingsRegistry` (only per-mode customization)

**New file:** `Domain/Services/MatchForfeitStandingsRegistry.swift`

```swift
struct MatchForfeitStanding: Equatable {
    let playerId: UUID
    let primaryScore: Int      // higher-is-better or lower-is-better per mode
    let tieBreakKey: Int       // packed tie-break (document per mode in §7.2)
    let summaryKey: String     // localization key + args for picker row
    let prefersLowerScore: Bool
}

enum MatchForfeitStandingsRegistry {
    static func standing(
        for playerId: UUID,
        in session: MatchLifecycleSession
    ) throws -> MatchForfeitStanding
}
```

Implementation is a **single exhaustive `switch session.runtime.type`**:

```swift
switch session.runtime.type {
case .x01: …
case .cricket: …
case .baseball: …
case .killer: …
case .shanghai: …
// compiler error when MatchType grows — forces new mode registration
}
```

`MatchForfeitWinnerResolver` calls this registry only — never mode-specific branches elsewhere.

**Future `MatchType` (e.g. `callAndHit`):** add one `case` with standing extraction from that engine's state blob on `MatchRuntimeState`. If a mode uses a new state property, add it to `MatchRuntimeState` in the same PR — standings registry reads it.

#### 6.7.4 `MatchLifecycleChrome` view modifier

**New file:** `Features/Play/Shared/MatchLifecycleChrome.swift`

```swift
extension View {
    func matchLifecycleChrome<Host: MatchPlaySessionHost>(
        host: Host,
        showExitConfirmation: Binding<Bool>,
        onShowSummary: @escaping () -> Void,
        onDismiss: @escaping () -> Void,
        dependencies: MatchLifecycleChromeDependencies
    ) -> some View
}
```

Bundles:
- `MatchExitConfirmationModifier` (Stay / Save & Exit / Save & Forfeit / Abandon)
- Sheet presenters for forfeit pickers bound to `MatchForfeitCoordinator`
- `onSaveAndExit` → `host.onDisappear()` + `onDismiss()`
- `onAbandon` → `host.abandonMatch()` + `onDismiss()`
- `onForfeitComplete` → `onShowSummary()` (summary reads `forfeited` from repository)

Apply **once** at the bottom of each `*MatchScreen` body (replace inline `.alert` blocks).

#### 6.7.5 Catalog contract — `GameModeCatalogEntry`

Add to `GameModeCatalogEntry` (`Features/Modes/GameModeCatalog.swift`):

```swift
/// Competitive matches using shared lifecycle get forfeit via MatchLifecycleChrome.
var usesStandardMatchForfeit: Bool { matchType != nil && status == .shipped }
```

Default: **true** for every shipped mode with a `MatchType`. Solo-only practice modes (`maximumPlayers == 1` + `uiTemplate == .soloChallenge` / `.voiceDrill`) may override to `false` until [`SoloPracticeModesSpec.md`](SoloPracticeModesSpec.md) defines an early-stop path — they still use match lifecycle but may use different summary chrome.

**Compiler gate** — add to `Tests/Unit/GameModeCatalogTests.swift`:

```swift
@Test
func everyShippedMatchTypeHasForfeitStandingsRegistered() throws {
    for entry in GameModeCatalog.shipped where entry.usesStandardMatchForfeit {
        guard let type = entry.matchType else { continue }
        let session = try MatchForfeitStandingsRegistry.fixtureSession(for: type)
        _ = try MatchForfeitStandingsRegistry.standing(
            for: session.runtime.participants[0].playerId!,
            in: session
        )
    }
}
```

`fixtureSession(for:)` lives in test support — minimal in-progress session per type. **When a developer adds `MatchType.foo` without a registry case, this test fails at compile time (switch) or runtime (fixture).**

#### 6.7.6 What new-mode authors must NOT do

| Anti-pattern | Do instead |
|--------------|------------|
| Copy exit `.alert` into new `FooMatchScreen` | `.matchLifecycleChrome(...)` |
| Implement `forfeitMatch()` on `FooMatchViewModel` | `MatchPlaySessionHost` only |
| Branch history/stats on mode for forfeit | Already mode-agnostic in repository |
| Custom forfeit analytics per mode | Single `match_forfeited` with `match_type` param |

#### 6.7.7 Promotion workflow hook

When promoting `planned/` → `implemented/` per [`game-modes/README.md`](game-modes/README.md), add to promotion checklist:

1. `MatchType` enum case
2. `MatchRuntimeState.{foo}State` if needed
3. **`MatchForfeitStandingsRegistry` case** (§7.2 standing + tie-break)
4. `MatchPlaySessionHost` conformance on `FooMatchViewModel`
5. `.matchLifecycleChrome` on `FooMatchScreen`
6. `GameModeCatalogTests.everyShippedMatchTypeHasForfeitStandingsRegistered` passes

#### 6.7.8 1.0 migration from today's duplicated abandon alerts

The five existing screens each have an inline exit alert — refactor to `MatchLifecycleChrome` in the **same PR** as forfeit. After refactor:
- `abandonMatch()` stays on host protocol (shared default implementation calling `MatchLifecycleService.abandon`)
- Zero mode-specific forfeit/abandon UI code remains in X01/Cricket/Baseball/Killer/Shanghai screens

---

## 7. Winner and standings rules

### 7.1 Two players

| Forfeiting player | Winner |
|-------------------|--------|
| Player A | Player B |
| Human | Bot (`playerId` or participant id) |

Bots cannot tap exit — only humans initiate forfeit.

### 7.2 Three or more players (1.0.0 — required)

After removing forfeiter, rank **remaining** participants:

| `MatchType` | Leader criterion (best wins) | Tie-break order |
|-------------|------------------------------|-----------------|
| `x01` | Lowest `remainingScore` | Fewer legs lost → fewer sets lost → lower turn order index |
| `cricket` | Highest `score` (points) | More marks closed (sum) → lower turn order |
| `baseball` | Highest `cumulativeRuns` | Higher current inning score → lower turn order |
| `killer` | Most `lives` remaining | More kills dealt → lower turn order |
| `shanghai` | Highest `cumulativePoints` | Higher current round points → lower turn order |

**Tie at top:** UI shows **Choose winner** sheet listing tied players only (§8.5). User must pick before persist.

**Not a tie:** automatic winner, show in confirmation copy.

### 7.3 Legs / sets

Forfeit does not award extra legs or sets. History card `isWinner` = forfeit winner only. Forfeiter standing row is **not** winner.

### 7.4 X01 solo (1 player)

Lean 1.0 allows 1-player X01 practice. Forfeit rules:
- Forfeiter = the sole participant.
- **No winner** — `winnerPlayerId = nil` is allowed **only** when `participants.count == 1`.
- Stats: `matchesPlayed +1`, `matchesWon` unchanged, dart averages still update.
- Summary: performance hero (no winner card), same as solo natural completion framing.
- Confirmation copy uses `play.match.forfeit.confirm.solo.message` (no winner name).

Adjust `MatchLifecycleService.forfeit` precondition: allow `winnerPlayerId == forfeitingPlayerId` only when participant count is 1; otherwise require distinct IDs.

---

## 8. UI specification

### 8.1 Entry point — `MatchLifecycleChrome` only

`match_exit` remains on `MatchGameplayHeader` (`PlayViewHelpers.swift`). **Do not** wire exit/forfeit/abandon per screen.

Each `*MatchScreen` ends with:

```swift
.matchLifecycleChrome(
    host: viewModel,
    showExitConfirmation: $showExitConfirmation,
    onShowSummary: onShowSummary,
    onDismiss: { dismiss() },
    dependencies: .init(
        store: …,
        matchRepository: …,
        logger: …
    )
)
```

`MatchLifecycleChrome` internally composes:
- `MatchExitConfirmationModifier` — `.confirmationDialog` (not `.alert`) for four actions
- `MatchForfeitCoordinator` sheets
- Bot-turn gating (`host.isBotTurnBlocking`)

**New `FooMatchScreen`:** one modifier line — forfeit included automatically when host conforms.

### 8.2 Exit sheet actions

| Action | Role | Identifier | Enabled when |
|--------|------|------------|--------------|
| Stay | cancel | — (system) | always |
| Save & Exit | default | — | always |
| Save & Forfeit | destructive | `match_exit_save_and_forfeit` | `canForfeit && !isBotTurnBlocking` |
| Abandon Match | destructive | `match_exit_abandon` | `!isBotTurnBlocking` |

When `canForfeit == false`, omit Save & Forfeit button entirely (do not show disabled gray button).

### 8.3 Multi-step forfeit flow

```text
Tap match_exit
  → confirmationDialog (Stay / Save & Exit / Save & Forfeit / Abandon)
  → [if Save & Forfeit]
      → if participants.count >= 3:
           sheet: ForfeitPlayerPicker (who is forfeiting?)
      → else:
           forfeitingPlayerId = sole human participant
      → MatchForfeitWinnerResolver.resolve(...)
      → if .chooseAmongTied:
           sheet: ForfeitWinnerPicker
      → alert/sheet: final confirm (forfeiter, winner, save stats)
      → persistForfeit
      → push PlayRoute.matchSummary(matchId) with forfeit configuration
```

**New views** (can be private structs in same file or dedicated):
- `ForfeitPlayerPickerSheet` — `accessibilityIdentifier("forfeit_player_picker")`
- `ForfeitWinnerPickerSheet` — `accessibilityIdentifier("forfeit_winner_picker")`
- `ForfeitFinalConfirmSheet` — `accessibilityIdentifier("forfeit_final_confirm")`

Picker rows: `forfeit_pick_{playerName}` sanitized (match setup convention `select_{name}`).

### 8.4 ViewModel surface — `MatchPlaySessionHost` only (no forfeit methods)

**Do not** add `forfeitMatch()`, `beginForfeitFlow()`, or `forfeitFlow` to mode ViewModels. All flow logic lives in `MatchForfeitCoordinator` (§6.7.2).

Each `*MatchViewModel` conforms to `MatchPlaySessionHost`:

```swift
extension X01MatchViewModel: MatchPlaySessionHost {
    var isBotTurnBlocking: Bool { isBotPlaying || state == .submittingTurn }
    // matchId, session, loadSessionIfNeeded, recoverBotPlaybackIfNeeded,
    // onDisappear, abandonMatch — already exist; abandon uses shared default if extracted
}
```

**Human participant discovery** — static helper on coordinator, not per ViewModel:

```swift
enum MatchForfeitParticipantSupport {
    static func humanParticipantIds(in session: MatchLifecycleSession) -> [UUID]
}
```

Return non-bot participants. Multiple humans → picker. Exactly one → auto-select.

### 8.5 Post-forfeit navigation

Reuse `PlayRoute.matchSummary(matchId:)` — pass forfeit flag via `MatchSummaryViewModel` reading `session.runtime.status == .forfeited` from store after persist (store removed — rehydrate from repository on summary `loadIfNeeded`).

`MatchSummaryViewModel` additions:

```swift
var isForfeited: Bool { session?.runtime.status == .forfeited }
var canUndoLastThrow: Bool { ... && !isForfeited }
var canRematch: Bool { ... && !isForfeited }  // or allow rematch — product choice: **hide rematch on forfeit** in 1.0
```

### 8.6 Forfeit summary chrome

`MatchSummaryScreen` — when `viewModel.isForfeited`:

| Element | Natural | Forfeit |
|---------|---------|---------|
| Trophy animation | Yes | **No** — use `flag.checkered.2.crossed` or `clock.badge.exclamationmark` |
| Header | Winner celebration | `play.summary.forfeit.title` — "Match ended early" |
| Subtitle | Game recorded | `play.summary.forfeit.subtitle` — "{Forfeiter} conceded · {Winner} wins" |
| `matchSummaryGameRecorded` badge | Green check | Amber/warning style + "Stats saved" |
| `matchSummaryRematch` | Visible | **Hidden** |
| `matchSummaryUndoLastThrow` | If eligible | **Hidden** |
| `matchSummaryDone` | Done | Done (unchanged id) |
| View in History | Visible | Visible |

Add identifiers:
- `matchSummaryForfeitBanner`
- `matchSummaryForfeitSubtitle`

### 8.7 Bot turn blocking

While `isBotPlaying == true` or `state == .submittingTurn`:
- Disable Save & Forfeit and Abandon in exit dialog.
- Accessibility hint on disabled actions: `play.match.exit.disabledWhileBot`.

User taps Stay → `recoverBotPlaybackIfNeeded()` (existing).

### 8.8 `onDisappear` guard

Keep existing guard: when exit confirmation visible, do not call `onDisappear` persistence cancel paths incorrectly. When forfeit completes, dismiss match screen **after** persist; set flag to skip abandon-on-disappear.

---

## 9. Statistics impact

### 9.1 Inclusion

`forfeited` ∈ history and stats source sets everywhere `completed` is used today.

**Files to grep and update:**
- `Domain/Services/StatsService.swift` — `recomputePlayerAggregates`, trend builders
- `Domain/Services/MatchStatsLoader.swift` — games table, player detail
- `Features/History/HistoryListViewModel.swift`
- `Features/History/HistoryDetailViewModel.swift` — allow forfeited detail load
- `Data/Repositories/SwiftDataMatchRepository.swift`

### 9.2 Per-metric rules

| Metric | Forfeited behavior |
|--------|-------------------|
| `matchesPlayed` | +1 all participants |
| `matchesWon` | +1 `winnerPlayerId` only (nil winner solo X01: no win) |
| `cricketWins` | +1 winner when type cricket |
| `x01Average3Dart` | All X01 turn events included |
| Mode-specific aggregates | Same reducers as natural completion on frozen events |
| `lastPlayedAt` | `endedAt` |

### 9.3 Exclusions

- Checkout % denominators (no checkout)
- Achievement unlocks on forfeit summary (**none in 1.0 forfeit ship**; Phase 2b catalog in [`AchievementForfeitSpec.md`](AchievementForfeitSpec.md))

---

## 10. History impact

### 10.1 List row (`HistoryListViewModel` / `MatchHistoryCard`)

```swift
let isForfeited = record.summary.status == .forfeited
let isFinished = record.summary.status == .completed || isForfeited
```

Badge:
- `completed` → green **FINISHED** (`history.status.finished`)
- `forfeited` → amber **FORFEIT** (`history.status.forfeit`)

Add `isForfeited` to `HistoryListRow`.

Accessibility: append forfeit clause to `accessibilitySummary` when forfeited — `history.row.forfeitAccessibilitySuffix`.

### 10.2 Detail (`HistoryDetailViewModel`)

When `status == .forfeited`:
- `winnerText` uses `history.detail.winnerForfeitFormat` — "{Winner} won (forfeit)"
- Subtitle line: `history.detail.forfeitSubtitleFormat` — "{Forfeiter} conceded"
- `resultAccessibilitySummary` includes forfeit context

### 10.3 Delete

Existing delete match on detail works for forfeited rows (same as completed).

---

## 11. Schema migration (SchemaV3)

Per [`SwiftData.md`](SwiftData.md):

1. Create `Persistence/Schemas/SchemaV3.swift` — copy `SchemaV2` models, add `forfeitedByPlayerId` to `MatchRecord`.
2. Register `SchemaV3` in migration plan (`Persistence/SchemaMigrationPlan.swift` or equivalent).
3. `V2 → V3` stage: lightweight additive (new optional column defaults nil).
4. Update `statusRaw` documentation to include `forfeited`.
5. Add `Tests/Unit/SchemaV2ToV3MigrationTests.swift` — verify existing matches migrate, new field nil.

Enum raw value `forfeited` needs **no** migration — stored as string in `statusRaw`.

---

## 12. Analytics

Add to `Support/Logging/FirebaseAnalyticsEventMapping.swift` allowlist:

| Event | Parameters |
|-------|------------|
| `match_forfeited` | `match_type`, `event_count`, `participant_count`, `forfeited_by_player_id`, `winner_player_id`, `duration_seconds`, `resolution` (`automatic` \| `user_picked`) |
| `match_forfeit_failed` | `match_type`, `error_code` |

Do **not** emit `match_completed` on forfeit.

Update `Tests/Unit/FirebaseAnalyticsEventMappingTests.swift`.

---

## 13. Edge cases

| Case | Behavior |
|------|----------|
| App killed mid-forfeit | Stays `inProgress` if persist incomplete |
| Double confirm tap | Idempotent `forfeit` returns unchanged if already forfeited |
| 3 players, 2 humans 1 bot, human forfeits | Resolver ranks remaining human + bot |
| All-but-one bot — one human | Auto-winner the remaining participant |
| Player archived after forfeit | Snapshot names in history |
| Setup conflict abandon | Still **abandon** only (no forfeit from setup) |
| Export bundle | Include `forfeited` status + `forfeitedByPlayerId` in `PlayerExportBundle` |
| `ProductSurface` lean | Party mode forfeit code exists; UI tests run with `-enable_full_product_surface` for Baseball/Killer/Shanghai |

---

## 14. Implementation order (one-pass agent sequence)

Execute in this order to keep CI green:

### Phase A — Domain & persistence
1. `MatchStatus.forfeited`, `MatchLifecycleStatus.forfeited`
2. `forfeitedByPlayerId` on runtime + summary models
3. `MatchLifecycleService.forfeit` + tests
4. `MatchForfeitWinnerResolver` + tests (2p, 3p, ties, all 5 modes)
5. `SchemaV3` + migration + migration test
6. `MatchRepository.forfeitMatch` + repository contract tests
7. `MatchHistoryCardPayload` v2 + builder tests
8. Update history fetch predicates

### Phase B — Stats & history UI
9. `StatsService` / `MatchStatsLoader` include forfeited
10. `HistoryListViewModel` + `MatchHistoryCard` badge
11. `HistoryDetailViewModel` forfeit copy

### Phase C — Scalable match UI (§6.7)
12. `MatchPlaySessionHost` + shared `abandonMatch` default
13. `MatchForfeitStandingsRegistry` (all 5 `MatchType` cases)
14. `MatchForfeitCoordinator` + `MatchForfeitSupport`
15. `MatchLifecycleChrome` + `MatchExitConfirmationModifier` + picker sheets
16. Replace inline exit alerts on all 5 screens with `.matchLifecycleChrome` only
17. `MatchPlaySessionHost` conformance on each ViewModel (no forfeit methods)
18. `MatchSummaryScreen` / `MatchSummaryViewModel` forfeit variant

### Phase D — Localization & analytics
19. All strings §22 in 4 locales
20. `L10n.swift` typed accessors if project uses them for new keys
21. Firebase mapping + tests

### Phase E — Tests & a11y
22. Unit/integration tests §24 (include `MatchForfeitCoordinatorTests`, catalog registry gate)
23. UI tests + helpers §24
24. WCAG identifier tests §25
25. Update accessibility screen markdown §25
26. Cross-spec amendments §26
27. `docs/feature-inventory.md` — mark forfeit shipped

---

## 15. File touch list (complete)

| File | Change |
|------|--------|
| `Domain/Models/RepositoryModels.swift` | `MatchStatus.forfeited`, `MatchSummary.forfeitedByPlayerId` |
| `Domain/Match/MatchLifecycleModels.swift` | `MatchLifecycleStatus.forfeited` |
| `Domain/Services/MatchLifecycleService.swift` | `forfeitedByPlayerId` on runtime, `forfeit()` |
| `Domain/Services/MatchForfeitWinnerResolver.swift` | **NEW** |
| `Domain/Services/MatchForfeitStandingsRegistry.swift` | **NEW** — exhaustive per `MatchType` |
| `Domain/Match/MatchHistoryCardPayload.swift` | v2 fields + decode |
| `Support/Localization/MatchHistoryCardBuilder.swift` | forfeit params |
| `Features/Play/Shared/MatchPlaySessionHost.swift` | **NEW** protocol |
| `Features/Play/Shared/MatchPlaySessionHost+Lifecycle.swift` | **NEW** shared abandon default |
| `Features/Play/Shared/MatchForfeitCoordinator.swift` | **NEW** — all flow state |
| `Features/Play/Shared/MatchForfeitSupport.swift` | **NEW** — persist only |
| `Features/Play/Shared/MatchLifecycleChrome.swift` | **NEW** — single integration point |
| `Features/Play/Shared/MatchExitConfirmationModifier.swift` | **NEW** — used by chrome |
| `Features/Play/Shared/MatchTurnSupport.swift` | map `forfeitedByPlayerId` in `matchSummary` |
| `Features/Play/Shared/MatchSummaryViewModel.swift` | `isForfeited`, gate undo/rematch |
| `Features/Play/Shared/MatchSummaryScreen.swift` | forfeit banner UI |
| `Features/Modes/GameModeCatalog.swift` | `usesStandardMatchForfeit` |
| `Features/Play/*/*MatchViewModel.swift` (×5) | `MatchPlaySessionHost` conformance only |
| `Features/Play/*/*MatchScreen.swift` (×5) | `.matchLifecycleChrome`; remove inline alerts |
| `Data/Repositories/RepositoryProtocols.swift` | `forfeitMatch` |
| `Data/Repositories/SwiftDataMatchRepository.swift` | implement + history predicates + payload |
| `Data/Repositories/StubRepositories.swift` | stub `forfeitMatch` |
| `Data/Repositories/SwiftDataRepositorySupport.swift` | map `forfeitedByPlayerId` |
| `Persistence/Schemas/SchemaV3.swift` | **NEW** |
| `Persistence/SchemaMigrationPlan.swift` | V2→V3 |
| `Features/History/HistoryModels.swift` | `isForfeited` on row |
| `Features/History/HistoryListViewModel.swift` | finished/forfeit flags |
| `Features/History/HistoryRootView.swift` | forfeit badge |
| `Features/History/HistoryDetailViewModel.swift` | forfeit header copy |
| `Domain/Services/StatsService.swift` | include forfeited sessions |
| `Domain/Services/MatchStatsLoader.swift` | include forfeited |
| `Domain/Export/PlayerExportBundle.swift` | export fields |
| `Support/Logging/FirebaseCrashlyticsEventMapping.swift` | if mirror analytics |
| `Support/Logging/FirebaseAnalyticsEventMapping.swift` | new events |
| `Support/Localization/L10n.swift` | new keys |
| `Resources/en.lproj/Localizable.strings` | §22 |
| `Resources/de.lproj/Localizable.strings` | §22 |
| `Resources/es.lproj/Localizable.strings` | §22 |
| `Resources/nl.lproj/Localizable.strings` | §22 |
| All test files | §24 |

---

## 16. Localization keys (all four locales)

Add to `en`, `de`, `es`, `nl`:

### Exit dialog (update existing + add)

| Key | English |
|-----|---------|
| `play.match.exit.confirm.title` | Leave active match? |
| `play.match.exit.confirm.message` | Resume later, save stats and end the match, or abandon without saving. |
| `play.match.exit.saveAndExit` | Save & Exit |
| `play.match.exit.saveAndForfeit` | Save & Forfeit |
| `play.match.exit.abandon` | Abandon Match |
| `play.match.exit.disabledWhileBot` | Wait until the bot finishes throwing. |
| `play.match.exit.saveAndForfeit.accessibility` | Save and forfeit. End match and keep stats. |

### Forfeit picker

| Key | English |
|-----|---------|
| `play.match.forfeit.pickPlayer.title` | Who is forfeiting? |
| `play.match.forfeit.pickPlayer.message` | Select the player leaving the match. |
| `play.match.forfeit.pickWinner.title` | Who won? |
| `play.match.forfeit.pickWinner.message` | Two or more players are tied. Choose the winner. |
| `play.match.forfeit.standingFormat.x01` | %d remaining |
| `play.match.forfeit.standingFormat.cricket` | %d points |
| `play.match.forfeit.standingFormat.baseball` | %d runs |
| `play.match.forfeit.standingFormat.killer` | %d lives |
| `play.match.forfeit.standingFormat.shanghai` | %d points |

### Final confirm

| Key | English |
|-----|---------|
| `play.match.forfeit.confirm.title` | End match and save stats? |
| `play.match.forfeit.confirm.message` | %1$@ will forfeit. %2$@ wins. Throws so far are saved to history. |
| `play.match.forfeit.confirm.solo.message` | End practice and save stats? Throws so far are saved to history. |
| `play.match.forfeit.confirm.action` | End Match |
| `play.match.forfeit.confirm.cancel` | Cancel |
| `play.match.forfeit.confirm.accessibility` | End match. %1$@ forfeits. %2$@ wins. Stats saved. |

### Summary

| Key | English |
|-----|---------|
| `play.summary.forfeit.title` | Match ended early |
| `play.summary.forfeit.subtitle` | %1$@ conceded · %2$@ wins |
| `play.summary.forfeit.solo.subtitle` | Practice ended early |
| `play.summary.forfeit.statsSaved` | Stats saved |

### History

| Key | English |
|-----|---------|
| `history.status.forfeit` | FORFEIT |
| `history.detail.winnerForfeitFormat` | %@ won (forfeit) |
| `history.detail.forfeitSubtitleFormat` | %@ conceded |
| `history.row.forfeitAccessibilitySuffix` | Match ended by forfeit. |

### Errors

| Key | English |
|-----|---------|
| `error.match.forfeit.invalid` | This match can't be forfeited right now. |
| `error.match.forfeit.failed` | Couldn't save the forfeited match. Try again. |

Translate `de`, `es`, `nl` to match tone of existing `play.match.exit.*` strings in each file.

---

## 17. Accessibility (WCAG 2.1 AA — 1.0 requirement)

### 17.1 Criteria addressed

| Criterion | Requirement |
|-----------|-------------|
| **2.4.4** Link/button purpose | Each exit action has distinct visible label **and** `accessibilityLabel` (not just "destructive") |
| **2.5.2** Pointer cancellation | Forfeit uses two-step confirm; destructive action on up-event inside confirm sheet |
| **3.3.2** Labels/instructions | Picker sheets have `title` + `message`; final confirm speaks forfeiter + winner |
| **4.1.2** Name, role, value | All new controls have identifiers §17.2 |
| **1.3.1** Info and relationships | Forfeit badge not color-only — includes "FORFEIT" text + accessibility suffix |

### 17.2 Identifier contract (add to `AccessibilityIdentifierContractTests`)

```text
match_exit_save_and_forfeit
match_exit_abandon
forfeit_player_picker
forfeit_winner_picker
forfeit_final_confirm
forfeit_confirm_action
forfeit_confirm_cancel
matchSummaryForfeitBanner
matchSummaryForfeitSubtitle
```

Picker rows: `forfeit_pick_{sanitizedName}` — document in `.cursor/rules/gameplay-ui-test-identifiers.mdc`.

### 17.3 VoiceOver scripts (manual + UI test announcements)

**X01 2-player forfeit:**
1. Focus `match_exit` — hear "Leave match".
2. Activate → dialog actions include "Save & Forfeit".
3. Activate Save & Forfeit → confirm hear "{Alice} will forfeit. {Bob} wins…".
4. Confirm → summary hear "Match ended early. {Bob} conceded…" / winner stats.
5. Done → Play home.

**Cricket 3-player forfeit:**
1. Score one visit each.
2. Exit → Save & Forfeit.
3. Picker "Who is forfeiting?" → select Carol.
4. If tie → winner picker.
5. History row → hear forfeit suffix on row.

**Bot turn block:**
1. Start bot match, during bot throw tap exit.
2. Save & Forfeit not available OR hear `disabledWhileBot` hint.

**Reduce Motion:**
- Forfeit summary skips trophy spring animation; banner appears immediately (respect `accessibilityReduceMotion`).

### 17.4 Dynamic Type

- Exit `confirmationDialog` — system handles.
- Picker sheets use `List` with `.font(.body)` — test AXL on iPhone 17 simulator.
- Forfeit badge on history card — allow wrap at AXXL.

### 17.5 Screen doc updates

Update these files with forfeit path + verification log entry:

| Screen doc | Add |
|------------|-----|
| `accessibility/wcag-2.1-aa/screens/x01-match.md` | O-2.4.4 Save & Forfeit action; R-4.1.2 new ids |
| `accessibility/wcag-2.1-aa/screens/cricket-match.md` | Same |
| `accessibility/wcag-2.1-aa/screens/baseball-match.md` | Same |
| `accessibility/wcag-2.1-aa/screens/killer-match.md` | Same |
| `accessibility/wcag-2.1-aa/screens/shanghai-match.md` | Same |
| `accessibility/wcag-2.1-aa/screens/match-summary.md` | Forfeit banner, undo hidden |
| `accessibility/wcag-2.1-aa/screens/history-list.md` | FORFEIT badge |
| `accessibility/wcag-2.1-aa/screens/history-detail.md` | Conceded subtitle |

### 17.6 WCAG UI tests (`WCAGAccessibilityUITests.swift`)

Add to existing match chrome audit:

```swift
assertInteractiveElement(app.buttons["match_exit_save_and_forfeit"], identifier: "match_exit_save_and_forfeit")
```

Run after starting match with one scored turn (helper needed). When `eventCount == 0`, assert button **does not exist** in exit dialog.

---

## 18. Testing — unit (`Swift Testing`)

Tag all new tests: `.unit`, `.match`, `.regression`, `.offline`. Critical paths add `.critical`.

### 18.1 `Tests/Unit/MatchLifecycleServiceTests.swift`

| Test name | Assert |
|-----------|--------|
| `lifecycleForfeitMarksInProgressMatchForfeited` | status, endedAt, winner, forfeitedBy, events preserved |
| `lifecycleForfeitRequiresAtLeastOneEvent` | throws when eventCount 0 |
| `lifecycleForfeitLeavesCompletedMatchUntouched` | idempotent |
| `lifecycleForfeitLeavesAbandonedMatchUntouched` | idempotent |
| `lifecycleForfeitSoloX01AllowsNilWinner` | 1 participant, winner can equal forfeiter or nil per §7.4 |

### 18.2 `Tests/Unit/MatchForfeitWinnerResolverTests.swift` (NEW)

| Test name | Assert |
|-----------|--------|
| `resolverTwoPlayerReturnsOpponent` | X01 + Cricket |
| `resolverThreePlayerX01PicksLowestRemaining` | automatic |
| `resolverThreePlayerCricketPicksHighestScore` | automatic |
| `resolverThreePlayerBaseballPicksMostRuns` | automatic |
| `resolverThreePlayerKillerPicksMostLives` | automatic |
| `resolverThreePlayerShanghaiPicksMostPoints` | automatic |
| `resolverTiedX01ReturnsChooseAmongTied` | 2+ tied at lowest remaining |
| `resolverExcludesForfeitingPlayer` | forfeiter never wins |
| `resolverTieBreakByLegsLost` | X01 tie-break order |

Use synthetic `MatchLifecycleSession` fixtures — do not require UI.

### 18.3 `Tests/Unit/MatchHistoryCardBuilderTests.swift`

| Test name | Assert |
|-----------|--------|
| `historyCardPayloadV2EncodesForfeitFlags` | isForfeited true, forfeitedBy set |
| `historyCardPayloadV1DecodesWithoutForfeit` | backward compat |

### 18.4 `Tests/Unit/RepositoryContractTests.swift`

| Test name | Assert |
|-----------|--------|
| `matchRepositoryHistoryIncludesForfeitedMatches` | fetch returns forfeited |
| `matchRepositoryHistoryExcludesAbandonedMatches` | abandoned still excluded |
| `matchRepositoryForfeitWritesHistoryCardPayload` | non-nil payload |

### 18.5 `Tests/Unit/StatsServiceTests.swift`

| Test name | Assert |
|-----------|--------|
| `statsRecomputeCountsForfeitedMatchAsPlayed` | matchesPlayed |
| `statsRecomputeAwardsWinToForfeitWinnerOnly` | matchesWon |
| `statsRecomputeIncludesX01DartsFromForfeitedMatch` | average |

### 18.6 `Tests/Unit/MatchStatsLoaderTests.swift`

| Test name | Assert |
|-----------|--------|
| `matchStatsLoaderIncludesForfeitedInGamesTable` | |
| `matchStatsLoaderMarksForfeitedRows` | `isForfeited` flag on DTO |

### 18.7 `Tests/Unit/MatchForfeitCoordinatorTests.swift` (NEW — replaces per-ViewModel forfeit tests)

| Test name | Assert |
|-----------|--------|
| `coordinatorPersistForfeitClearsActiveStore` | uses mock host + repo |
| `coordinatorLogsMatchForfeited` | analytics |
| `coordinatorGatesWhenNoEvents` | Save & Forfeit path not offered |
| `coordinatorThreePlayerPickForfeiter` | flow state transitions |

### 18.7b `Tests/Unit/GameModeCatalogTests.swift`

| Test name | Assert |
|-----------|--------|
| `everyShippedMatchTypeHasForfeitStandingsRegistered` | §6.7.5 compiler gate |

### 18.7c ViewModel tests (smoke only)

Each `*MatchViewModelTests` — **one** test: `{mode}MatchViewModelConformsToMatchPlaySessionHost` (compile-time protocol check, no forfeit logic duplicated).

### 18.8 `Tests/Unit/MatchSummaryViewModelTests.swift`

| Test name | Assert |
|-----------|--------|
| `summaryViewModelCannotUndoForfeitedMatch` | canUndo false |
| `summaryViewModelCannotRematchForfeitedMatch` | canRematch false |
| `summaryViewModelDetectsForfeitedSession` | isForfeited |

### 18.9 `Tests/Unit/FeatureFlowViewModelTests.swift` / `HistoryDetailViewModel`

| Test name | Assert |
|-----------|--------|
| `historyDetailFormatsForfeitWinner` | copy keys |
| `historyListRowMarksForfeitedBadge` | isForfeited |

### 18.10 `Tests/Unit/SchemaV2ToV3MigrationTests.swift` (NEW)

Migrate in-memory store with completed match → `forfeitedByPlayerId` nil.

### 18.11 `Tests/Unit/FirebaseAnalyticsEventMappingTests.swift`

Map `match_forfeited` and `match_forfeit_failed`.

### 18.12 `Tests/Unit/AccessibilityIdentifierContractTests.swift`

Add §17.2 identifiers to contract arrays.

### 18.13 Integration — `Tests/Unit/LongTermSimulationTests.swift`

Extend journey:

```text
setup → partial X01 → forfeit → history list contains row → player stats updated
```

---

## 19. Testing — UI (`XCTest`)

Follow [`.cursor/rules/ui-test-writing.mdc`](../.cursor/rules/ui-test-writing.mdc). Subclass `DartBuddyUITestCase`. Use localized button titles in helpers (English CI).

### 19.1 Helper additions — `Tests/UI/Support/UITestGameplayHelpers.swift`

```swift
func tapExitSaveAndForfeit(in app: XCUIApplication, timeout: TimeInterval)
func confirmForfeitFinal(in app: XCUIApplication, timeout: TimeInterval)
func pickForfeitPlayer(named name: String, in app: XCUIApplication, timeout: TimeInterval)
func pickForfeitWinner(named name: String, in app: XCUIApplication, timeout: TimeInterval)
func forfeitMatchFromExit(in app: XCUIApplication, timeout: TimeInterval)  // 2-player fast path
```

`tapExitAlertButton` currently uses alerts — update to support `confirmationDialog` buttons (same `app.buttons` query in XCTest).

### 19.2 `Tests/UI/MatchChromeUITests.swift` — extend

| Test | Steps |
|------|-------|
| `testX01ExitForfeitHiddenBeforeFirstTurn` | Start match, exit immediately, assert Save & Forfeit absent |
| `testX01ExitForfeitSavesToHistory` | Score 20, forfeit, summary banner, Done, Activity history contains row |
| `testX01ExitForfeitNoResumeBanner` | After forfeit, resume button absent |
| `testCricketExitForfeitThreePlayer` | 3 players, score, forfeit as Carol, verify summary |
| `testCricketExitForfeitSaveAndExitStillResumes` | Regression: Save & Exit still works |

### 19.3 `Tests/UI/MatchForfeitUITests.swift` (NEW)

| Test | Steps |
|------|-------|
| `testX01ForfeitSummaryViewStatsOpensDetail` | Forfeit → View Game Statistics → detail forfeit subtitle |
| `testX01ForfeitUndoNotOffered` | Assert `matchSummaryUndoLastThrow` absent |
| `testCricketForfeitTieShowsWinnerPicker` | Craft tie state via fast setup or seed if available |

Party modes (nightly with `-enable_full_product_surface`):

| Test | Steps |
|------|-------|
| `testBaseballForfeitFromExit` | Party surface, score inning, forfeit |
| `testKillerForfeitFromExit` | Party surface, forfeit after one turn |
| `testShanghaiForfeitFromExit` | Party surface, forfeit after one round |

### 19.4 `Tests/UI/WCAGAccessibilityUITests.swift`

| Test | Assert |
|------|--------|
| `testX01ForfeitExitControlContract` | identifiers §17.2 after one turn |
| `testMatchSummaryForfeitBannerContract` | after forfeit flow |

### 19.5 `Tests/UI/Lean1_0SmokeUITests.swift`

Add smoke: **forfeit one X01 turn** in lean surface (validates 1.0 ship path).

### 19.6 `Tests/UI/PlayerDetailUITests.swift`

After forfeit against bot, open player detail — `matchesPlayed` subtitle reflects new game (if visible in UI).

### 19.7 CI matrix

| Suite | Simulator | Launch args |
|-------|-----------|-------------|
| PR `DartBuddyCI` | iPhone 17 | `-seed_players` |
| Nightly UI | iPhone 17 Pro Max | party forfeit tests add `-enable_full_product_surface` |

---

## 20. Cross-spec amendments (agent must apply)

| Spec | Change |
|------|--------|
| [`MatchSpec.md`](MatchSpec.md) | §4 status enum; §5 Forfeit lifecycle (remove "planned"); §7 forfeited in integrity; §11 analytics |
| [`HistorySpec.md`](HistorySpec.md) | §4 query completed\|forfeited; forfeit badge |
| [`StatsSpec.md`](StatsSpec.md) | §3–4 forfeited inclusion table |
| [`MatchSummarySpec.md`](MatchSummarySpec.md) | §4 forfeit variant; undo ineligible |
| [`SwiftData.md`](SwiftData.md) | SchemaV3, `forfeitedByPlayerId`, status raw |
| [`FirebaseBackendAnalyticsSpec.md`](FirebaseBackendAnalyticsSpec.md) | `match_forfeited` |
| [`NavigationSpec.md`](NavigationSpec.md) | §4 note 4-action exit dialog |
| [`docs/feature-inventory.md`](../docs/feature-inventory.md) | Forfeit → shipped |
| [`docs/testing/x01-cricket-ui-test-phased-plan.md`](../docs/testing/x01-cricket-ui-test-phased-plan.md) | Add Phase forfeit row |
| [`game-modes/README.md`](game-modes/README.md) | Promotion step 6 — forfeit registry |
| [`ArchitectureSpec.md`](ArchitectureSpec.md) | § Play layer — reference `MatchLifecycleChrome` as mandatory match shell |
| [`.cursor/rules/gameplay-ui-test-identifiers.mdc`](../.cursor/rules/gameplay-ui-test-identifiers.mdc) | Forfeit identifiers |

---

## 21. Analytics

See §12. Wire in `MatchForfeitSupport` success/failure paths.

---

## 22. Migration

- SchemaV3 additive migration only.
- No backfill of abandoned → forfeited.
- Existing `completed` / `abandoned` rows unchanged.

---

## 23. Future improvements (post-1.0)

- History filter: Finished / Forfeited / All
- Campaign forfeit = stage loss
- Forfeit reason picker
- Statistics tab "exclude forfeits" toggle
- Opponent must accept forfeit (pass-the-phone)

---

## 24. Verification (fill on ship)

| Field | Value |
|-------|--------|
| **Last verified** | — |
| **Commit** | — |
| **Code** | `MatchForfeitSupport.swift`, `MatchForfeitWinnerResolver.swift`, `MatchExitConfirmationModifier.swift`, `SwiftDataMatchRepository.forfeitMatch` |
| **Tests** | `MatchForfeitWinnerResolverTests`, `MatchForfeitUITests`, extended `MatchChromeUITests` |
| **A11y evidence** | `accessibility/wcag-2.1-aa/screens/x01-match.md` forfeit log entry |

---

## 25. Agent acceptance criteria (definition of done)

1. User can **Save & Forfeit** on all five shipped modes (when reachable) with 2–8 players.
2. 3+ player flow shows **who is forfeiting** picker when multiple humans exist.
3. Tied standings show **who won** picker.
4. Forfeited match appears in **Activity → History** with FORFEIT badge.
5. **Player stats** and **history detail** reflect throws played; winner gets win credit.
6. **Abandon** and **Save & Exit** behavior unchanged.
7. **Undo last throw** not offered on forfeit summary.
8. All §18 unit tests pass; §19 UI tests pass on CI matrix.
9. WCAG identifiers present per §17.2 audits.
10. `de`, `es`, `nl` strings ship alongside `en`.
11. No regressions in `RepositoryContractTests` abandoned exclusion.
12. **Scalability:** no `forfeitMatch()` (or equivalent) on any `*MatchViewModel`; all five screens use `.matchLifecycleChrome` only.
13. **Scalability:** `MatchForfeitStandingsRegistry` switch is exhaustive over `MatchType`; `everyShippedMatchTypeHasForfeitStandingsRegistered` passes.
14. **New-mode contract documented** in `game-modes/README.md` promotion step 6.
