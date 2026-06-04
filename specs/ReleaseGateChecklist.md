# Release Gate Checklist (5-10 min)

Use this short checklist right before tagging/releasing.  
If any item fails, do not ship.

**Feature specs (expected behavior):** [`README.md`](README.md) § Feature Specs · **Full RC runbook:** [`docs/release/release_checklist.md`](../docs/release/release_checklist.md)

## Setup

- Build latest app from release branch/commit.
- Simulator: `iPhone 17` (Dark mode).
- Start from clean state:
  - `Settings` -> `Reset All Local Data` -> relaunch.

## Critical Path Checks

- [ ] **App Launch + Navigation**
  - App launches to `Play`.
  - Tab switching (`Play`, `Players`, `Statistics`, `History`, `Settings`) works without blank/error state.

- [ ] **Create Player**
  - Add `Smoke Alice` and `Smoke Bob` from `Players`.
  - Confirm both appear in list.

- [ ] **Start X01 Match**
  - From `Play` (setup on home) -> Mode `X01` -> select 2 players -> `Start Match`. See [`SetupFlowSpec.md`](SetupFlowSpec.md).
  - Submit one turn, then `Undo Last Turn`.
  - Verify no crash and state updates.

- [ ] **Start Cricket Match**
  - Start another match with Mode `Cricket`.
  - Submit one turn, then undo.
  - Verify board updates correctly and no crash.

- [ ] **History + Detail**
  - Open `History`.
  - Confirm at least one completed match row exists.
  - Open detail screen and verify header + timeline load.

- [ ] **Statistics Tab**
  - Open `Statistics`.
  - Confirm games table loads; mode filter responds.
  - Partial-data banner appears only when applicable.

- [ ] **Settings Persistence**
  - Toggle one setting (e.g. `Sound`).
  - Leave tab and return; value persists.
  - Relaunch app; value remains persisted.

- [ ] **Accessibility Spot Check**
  - Set content size to `accessibility-extra-extra-extra-large`.
  - Verify `New Match` and one in-match screen remain usable (no blocked primary CTA).

## Release Decision

- [ ] **PASS**: all checks complete with no blockers.
- [ ] **FAIL**: any crash, blocked flow, or data corruption (open fix ticket before release).
