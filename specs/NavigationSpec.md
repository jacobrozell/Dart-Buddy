# Navigation Specification

## 1. Purpose
Define typed navigation behavior across tabs and feature flows.

---

## 2. Navigation Model
- Tab-based root navigation
- Per-tab navigation stacks
- Typed route enums per feature

Example route groups:
- `PlayRoute`: setup, x01Match, cricketMatch, matchSummary
- `HistoryRoute`: list, detail(matchId)
- `PlayersRoute`: list, detail(playerId), edit(playerId?)
- `SettingsRoute`: root

---

## 3. Core Flows

## New Match
`PlayHome -> Setup -> (X01|Cricket) Match -> Summary -> New Match`

## Resume Match
`PlayHome -> Active Match`

## Player Management
`PlayersList -> PlayerDetail -> EditSheet`

## History
`HistoryList -> MatchDetail`

---

## 4. Rules
- Navigation IDs must use stable UUID-backed entities.
- Route params are minimal and strongly typed.
- Never pass entire mutable models through route payload.
- All destructive exits from active match require confirmation.

---

## 5. Testing
- UI automation out of scope for 1.0.0; add route UI tests post-UI-lock
- Route resolution tests for deep-link readiness
