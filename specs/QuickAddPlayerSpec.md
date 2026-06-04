# Quick Add Player Specification

## 1. Purpose
Define the minimal player-creation flow launched from Play setup when the roster is empty or the user needs a fast add without visiting the Players tab.

Player CRUD rules: [`PlayerSpec.md`](PlayerSpec.md). Setup integration: [`SetupFlowSpec.md`](SetupFlowSpec.md).

---

## 2. MVP Scope

### In Scope (1.0.0)
- Single-field create (display name only)
- Push navigation from `PlayRoute.quickAddPlayer`
- On success: auto-select new player in setup roster via `PendingMatchPlayerSelections`
- Same validation as full create (trim, duplicate name, max length via repository)

### Out of Scope
- Avatar/color on quick add (defaults applied by repository)
- Editing existing players

---

## 3. UI Specification

| Element | Behavior |
|---------|----------|
| Form | One section: name `TextField` (`players.edit.name`) |
| Cancel | Toolbar — dismiss without side effects |
| Save | Toolbar — disabled while empty or saving |
| Error | Inline section with `AppError.userMessageKey` or `error.player.create` |

Navigation title: `L10n.quickAddTitle`.

---

## 4. Data Flow

1. User saves → `PlayerRepository.createPlayer(name:)`
2. `onCreated(PlayerSummary)` callback:
   - `pendingMatchPlayerSelections.enqueueForNextMatchSetup(id)`
   - `setupViewModel.onAppear()` refresh (via `changeCount` observer on `SetupHomeView`)
3. `dismiss()` back to setup home

Training Partner practice uses `enqueuePractice` from Player Detail instead (not this screen).

---

## 5. Empty Roster UX

When `PlayHomeViewModel` finds zero players, setup still renders; quick-add is the primary path to reach two participants. Minimum-player validation copy is suppressed until roster is non-empty (`displayValidationErrors`).

---

## 6. Accessibility

Manual WCAG checklist: [`accessibility/wcag-2.1-aa/screens/match-setup.md`](../accessibility/wcag-2.1-aa/screens/match-setup.md) (quick-add is pushed from setup).

---

## 7. Analytics

No dedicated events. Player create errors may surface via repository logging. See [`FirebaseBackendAnalyticsSpec.md`](FirebaseBackendAnalyticsSpec.md) §12.

---

## 8. Testing

- Create player from setup navigation smoke
- Duplicate name → inline error key
- `PendingMatchPlayerSelections` dequeue on setup `onAppear`

---

## 9. Verification

| Field | Value |
|-------|--------|
| **Last verified** | 2026-06-04 |
| **Commit** | `0c25396` |
| **Code** | `Features/Play/Setup/QuickAddPlayerScreen.swift`, `App/Bootstrap/PendingMatchPlayerSelections.swift` |
