# Test Plan Specification

## 1. Purpose
Define test strategy, ownership, and quality gates for MVP release confidence.

Test-first policy for this project:
- Core logic in every production file should be covered by tests as it is introduced.
- Unit/integration coverage is mandatory in MVP delivery scope.
- UI automation is intentionally deferred and can be phased in later.

---

## 2. Test Layers

## Unit Tests
- Domain engines (`X01Engine`, `CricketEngine`, `StatsService`)
- Validation utilities
- Repository mapping/parsing logic

## Integration Tests
- End-to-end feature flows with persistence:
  - setup -> play -> complete -> history
  - app relaunch -> resume match
  - archive player -> setup/history behavior

## UI Tests
- Core happy paths for each tab
- Critical edge flows (undo, bust, checkout mode differences)
- Accessibility smoke checks

UI test execution policy:
- UI automation is out of scope for 1.0.0 implementation.
- Treat UI automation as a future task after UI behavior is locked from test feedback and MVP stabilization.
- Prioritize robust unit + integration coverage first.

---

## 3. Quality Gates
- All domain unit tests pass
- No migration invariant failures
- No crash on active-match resume path
- Core integration suites pass for match lifecycle, persistence, and player/history integrity
- New/changed files include tests for their core functions before merge

---

## 4. Regression Matrix (MVP)
- X01 single-out checkout
- X01 double-out checkout
- X01 bust near finish
- Cricket closure and overflow scoring
- Undo turn on both modes
- Player archive/delete guard behavior
- History rendering after player edits
- Settings defaults applied to setup

---

## 5. CI Recommendations
- Run unit + integration on PR
- Add UI automation jobs only in the post-MVP phase (after UI contract lock).
- Track coverage trend for domain and repository layers

---

## 6. Starter Tag Matrix (Swift Testing)
Use canonical tags from `specs/SwiftTestingTagsSpec.md`.

- `X01Engine` suite:
  - `unit`, `x01`, `critical`, `offline`, `regression`
- `CricketEngine` suite:
  - `unit`, `cricket`, `critical`, `offline`, `regression`
- `MatchLifecycleService` suite:
  - `unit`, `match`, `critical`, `regression`
- `StatsService` suite:
  - `unit`, `stats`, `regression`, `offline`
- `PlayerRepository` suite:
  - `integration`, `player`, `swiftdata`, `regression`
- `MatchRepository` suite:
  - `integration`, `match`, `swiftdata`, `critical`, `regression`
- `HistoryFeature` integration suite:
  - `integration`, `history`, `swiftdata`, `regression`
- `SettingsRepository` suite:
  - `integration`, `settings`, `swiftdata`, `regression`
- `Migration` suite:
  - `migration`, `swiftdata`, `critical`, `regression`
- `Navigation` smoke suite:
  - `integration`, `navigation`, `smoke`
- `ScoringInput` suite:
  - `unit`, `scoringInput`, `critical`
- `Accessibility` smoke suite (future, post-UI-lock):
  - `ui`, `accessibility`, `smoke`
- `Localization` smoke suite (future, post-UI-lock):
  - `integration`, `localization`, `smoke`

---

## 7. Release Readiness Checklist
- Manual exploratory pass on iPhone target device
- WCAG 2.1 AA accessibility pass on core flows
- Dark mode + Dynamic Type validation
- Landscape orientation validation on core flows
- Persistence migration smoke test from previous build
- App reset flow verified
