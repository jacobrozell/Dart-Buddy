# UI Implementation Specification

## 1. Purpose
Turn the UI blueprint into build-ready contracts for engineers.

This spec defines, for each MVP screen:
- required UI states
- user intents (actions)
- ViewModel events
- data dependencies
- minimum validation scenarios

UI automation note:
- UI automation is out of scope for 1.0.0.
- Any UI automation items in this spec are future tasks to execute after UI behavior is locked from MVP test feedback.

Primary reference:
- `specs/UIBlueprintSpec.md`

---

## 2. Contract Format
Each screen contract uses the same structure:
1. **States**
2. **Intents**
3. **Events**
4. **Data Dependencies**
5. **Minimum Validation Scenarios**

---

## 3. Screen Contracts

## 3.1 Play Home
- **States:** `loading`, `readyNoActiveMatch`, `readyWithActiveMatch`, `emptyNoPlayers`, `error`.
- **Intents:** start new match, resume active match.
- **Events:** `onAppear`, `tapStartNewMatch`, `tapResumeMatch`.
- **Data dependencies:** in-progress match query, active players count, optional recent completed summaries.
- **Minimum validation scenarios:** resume card visibility logic, start route, resume route, no-player guidance state.

## 3.2 Match Setup
- **States:** `pristine`, `editingInvalid`, `editingValid`, `submitting`, `submitFailed`.
- **Intents:** configure mode and options, select players, start match.
- **Events:** `selectMode`, `togglePlayer`, `updateX01Option`, `tapStart`, `tapQuickAddPlayer`.
- **Data dependencies:** player roster, settings defaults, setup validation service.
- **Minimum validation scenarios:** validation matrix, sticky CTA, quick add transition, successful start routes by mode.

## 3.3 X01 Match
- **States:** `readyTurn`, `entryInvalid`, `submittingTurn`, `bustFeedback`, `matchCompleted`, `error`.
- **Intents:** input turn, submit turn, undo turn, exit with confirmation.
- **Events:** `enterDart`, `enterTotal`, `backspaceEntry`, `clearEntry`, `submitTurn`, `undoLastTurn`, `requestExit`.
- **Data dependencies:** `X01Engine`, match state head, recent event timeline, settings (haptics/sound).
- **Minimum validation scenarios:** submit enablement, bust handling, checkout handling, undo across leg boundary, completion route.

## 3.4 Cricket Match
- **States:** `readyTurn`, `entryInvalid`, `submittingTurn`, `closureTransition`, `matchCompleted`, `error`.
- **Intents:** target and multiplier input, submit, undo, exit with confirmation.
- **Events:** `selectTarget`, `selectMultiplier`, `submitTurn`, `undoLastTurn`, `requestExit`.
- **Data dependencies:** `CricketEngine`, board state model, per-player points, recent event timeline.
- **Minimum validation scenarios:** board render correctness, overflow scoring logic visibility, non-color closure indicators, undo restoration.

## 3.5 Match Summary
- **States:** `ready`, `loadingHistoryLink`, `error`.
- **Intents:** start new match, open history detail.
- **Events:** `tapNewMatch`, `tapViewHistoryDetail`.
- **Data dependencies:** immutable summary DTO, winner identity snapshot, match metadata.
- **Minimum validation scenarios:** winner card correctness, primary/secondary CTA routing.

## 3.6 History List
- **States:** `loading`, `readyUnfiltered`, `readyFiltered`, `emptyFiltered`, `error`.
- **Intents:** apply filters, open detail.
- **Events:** `setModeFilter`, `setDateFilter`, `setPlayerFilter`, `clearFilters`, `tapMatch`.
- **Data dependencies:** completed match summaries, filter options, pagination/lazy loading cursor.
- **Minimum validation scenarios:** filter determinism, empty state behavior, route to detail.

## 3.7 History Detail
- **States:** `loading`, `ready`, `timelineChunkLoading`, `missingReferenceFallback`, `error`.
- **Intents:** inspect summary and timeline.
- **Events:** `onAppear`, `loadTimelineChunk`.
- **Data dependencies:** completed match detail DTO, participant snapshots, event list/timeline chunks.
- **Minimum validation scenarios:** snapshot fallback rendering, long timeline lazy rendering, mode-specific sections.

## 3.8 Players List
- **States:** `loading`, `empty`, `ready`, `searchNoResults`, `error`.
- **Intents:** add, search, open detail, archive, delete.
- **Events:** `tapAddPlayer`, `searchChanged`, `tapPlayer`, `swipeArchive`, `swipeDelete`.
- **Data dependencies:** player list DTO, stats summary subtitle DTO, search query.
- **Minimum validation scenarios:** empty state CTA, search filtering, archive action, guarded delete flow.

## 3.9 Player Detail
- **States:** `loading`, `readyActive`, `readyArchived`, `deleteBlocked`, `error`.
- **Intents:** edit, archive/unarchive, delete.
- **Events:** `tapEdit`, `tapArchiveToggle`, `tapDelete`.
- **Data dependencies:** player profile DTO, lifetime stats, recent matches.
- **Minimum validation scenarios:** archive toggle behavior, guarded delete message, edit route.

## 3.10 Player Edit Sheet
- **States:** `createPristine`, `editPrefilled`, `invalid`, `valid`, `saving`, `saveFailed`.
- **Intents:** modify fields, save, cancel.
- **Events:** `nameChanged`, `avatarChanged`, `colorChanged`, `notesChanged`, `tapSave`, `tapCancel`.
- **Data dependencies:** validation service, duplicate-name checker, style token list.
- **Minimum validation scenarios:** inline validation, save enablement, duplicate handling.

## 3.11 Settings
- **States:** `loading`, `ready`, `saving`, `showResetConfirmation`, `resetInProgress`, `error`.
- **Intents:** modify preferences, reset all local data.
- **Events:** `setAppearance`, `toggleHaptics`, `toggleSound`, `updateGameplayDefault`, `tapResetAllData`, `confirmReset`.
- **Data dependencies:** `SettingsRepository`, reset service, defaults seed policy.
- **Minimum validation scenarios:** immediate appearance update, defaults propagation to setup, reset confirm/cancel/execute.

## 3.12 Migration Recovery
- **States:** `ready`, `retryInProgress`, `retryFailed`, `exportInProgress`, `resetInProgress`.
- **Intents:** retry migration, export diagnostics, reset local data.
- **Events:** `tapRetry`, `tapExportDiagnostics`, `tapResetLocalData`.
- **Data dependencies:** migration error payload, diagnostics export service.
- **Minimum validation scenarios:** each recovery action path reachable and labeled clearly.

---

## 4. Common UI Non-Functional Requirements
- WCAG 2.1 AA requirements from `specs/AccessibilitySpec.md` are mandatory.
- Portrait and landscape layouts are required for MVP.
- Light and dark appearance parity is required for all core flows.
- One primary CTA per screen.
- Critical gameplay controls stay visible and reachable during active play.

---

## 5. Definition of Done for Any New Screen
- Contract entries (states/intents/events/data/tests) added to this spec.
- Wireframe and behavior added or linked in `specs/UIBlueprintSpec.md`.
- Accessibility labels/hints and focus order verified.
- Portrait/light, portrait/dark, landscape/light, landscape/dark manually verified.
