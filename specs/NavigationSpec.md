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
- `PlayersRoute`: list, detail(playerId), edit(playerId?)
- `StatisticsRoute`: root (filters and games table; no push stack in MVP)
- `HistoryRoute`: list, detail(matchId)
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

## Statistics
`StatisticsRoot` (mode/date filters, games table, partial-data banner when applicable)

---

## 4. Rules
- Navigation IDs must use stable UUID-backed entities.
- Route params are minimal and strongly typed.
- Never pass entire mutable models through route payload.
- All destructive exits from active match require confirmation.

---

## 5. Testing
- Limited UI tests in CI: tab smoke, marketing snapshot harness, core happy paths (see `Tests/UI/DartsScoreboardUITests.swift`).
- Full UI automation matrix (edge flows, accessibility suite) deferred post-1.0 UI lock.
- Route resolution tests for deep-link readiness
