# Smoke Test Checklist

Use this checklist before release candidates and after major refactors to verify core app behavior has not regressed.

**Authoritative flows:** [`README.md`](README.md) § Feature Specs — especially [`PlayHomeSpec.md`](PlayHomeSpec.md), [`SetupFlowSpec.md`](SetupFlowSpec.md), [`MatchSpec.md`](MatchSpec.md), [`game-modes/implemented/X01GameSpec.md`](game-modes/implemented/X01GameSpec.md), [`game-modes/implemented/CricketSpec.md`](game-modes/implemented/CricketSpec.md), [`HistorySpec.md`](HistorySpec.md), [`StatisticsTabSpec.md`](StatisticsTabSpec.md), [`SettingsSpec.md`](SettingsSpec.md).

## Scope

- Covers critical end-to-end user flows.
- Focuses on functionality and obvious UX regressions, not deep edge-case testing.
- Intended runtime: 15-25 minutes.

## Test Environment

- Build: latest Debug or RC build from current branch.
- Device pass:
  - iPhone simulator (`iPhone 17`) in Light and Dark mode.
  - iPad simulator (`iPad (A16)`) in Dark mode.
- Optional accessibility pass:
  - Content size: `accessibility-extra-extra-extra-large`.

## Test Data

Use these players for consistency:

- `Smoke Alice`
- `Smoke Bob`
- `Smoke Carol`

## Pre-Run Reset

1. Open `Settings`.
2. Tap `Reset All Local Data`.
3. Confirm reset.
4. Relaunch app.

Expected:

- App opens to `Play`.
- No active match.
- No players in roster/history.

## A. App Shell + Navigation

1. Verify tab navigation: `Play`, `Players`, `Statistics`, `History`, `Settings`.
2. Switch tabs quickly 2-3 times.
3. Background and foreground the app once.

Expected:

- No crash or blank screen.
- Selected tab content loads each time.
- App resumes in stable state.

## B. Players Flow

1. Go to `Players`.
2. Add `Smoke Alice`, `Smoke Bob`, `Smoke Carol`.
3. Use search to find `Smoke Bob`.
4. Clear search.
5. Open one player detail screen and return.

Expected:

- Players are created and visible immediately.
- Search filters correctly.
- Detail navigation works without popping to wrong tab/root.

## C. Start + Play X01 Match

1. Go to `Play` (setup is on the home screen).
2. In setup:
   - Mode: `X01`
   - Start score: `301` or `501`
   - Select at least 2 players
3. Tap `Start Match`.
4. In X01 match:
   - Submit one valid turn.
   - Use `Undo Last Turn`.
   - Submit a turn again.

Expected:

- Match starts successfully.
- Turn submission updates state.
- Undo reverts latest turn cleanly.
- No UI overlap or clipped controls.

## D. Start + Play Cricket Match

1. Start a new match from `Play`.
2. In setup:
   - Mode: `Cricket`
   - Select at least 2 players
3. Tap `Start Match`.
4. In Cricket match:
   - Enter one turn with dart buttons.
   - Submit turn.
   - Undo and resubmit.

Expected:

- Cricket match starts and accepts input.
- Marks/turn progression updates.
- Undo works and does not corrupt state.

## E. History + Stats/Detail Validation

1. Go to `History`.
2. Verify a completed match appears (if no completed match yet, finish one short match and return).
3. Apply filters:
   - Mode: `All`, `X01`, `Cricket`
   - Date: `7d`, `30d`, `All`
4. Open a history detail row.

Expected:

- List renders and filters respond correctly.
- Detail screen loads header fields:
  - mode
  - winner
  - date/duration
  - participants
  - mode-specific summary text
- Timeline section loads without error state.

## F. Statistics Tab

1. Go to `Statistics`.
2. Verify games table and filter controls (mode, date range).
3. Change mode filter; confirm table updates.
4. If partial stats exist, verify banner copy (see [`StatisticsTabSpec.md`](StatisticsTabSpec.md), [`StatsSpec.md`](StatsSpec.md)).

## F2. Training Partner + Cut Throat (optional RC)

1. Player with 5+ completed X01 games → create Training Partner on Player Detail.
2. Add partner from Play setup Add Bot menu; start short X01 match.
3. Cricket setup → Cut Throat + Points On + bot → start; confirm bot throws ([`BotOpponentSpec.md`](BotOpponentSpec.md)).

## G. Settings Persistence

1. In `Settings`, change:
   - Theme (`System` -> `Dark` or `Light`)
   - Default mode
   - Haptics and Sound toggles
2. Navigate away and back to `Settings`.
3. Relaunch app and re-check settings.

Expected:

- Updated values persist across navigation and relaunch.
- App theme updates as expected.

## H. Accessibility Sanity (Quick)

1. Set content size to `accessibility-extra-extra-extra-large`.
2. Re-check:
   - New Match setup screen
   - X01 match screen
   - Cricket match screen
   - Statistics screen
   - Settings screen

Expected:

- Primary actions remain reachable.
- No blocking text overlap/clipping.
- Content can be scrolled when needed.

## Pass / Fail Criteria

Pass if all sections complete without:

- crashes
- stuck navigation
- data loss in core flows
- critical visual blockers (hidden primary controls)

Fail if any critical step fails; log failing step, device, mode, and screenshot.
