# Architecture Specification

## 1. Purpose
Define the production architecture for a simple, scalable iPhone darts app with clean boundaries between UI, game logic, and persistence.

---

## 2. Architectural Style
- Feature-first modular monolith
- `SwiftUI` presentation
- `MVVM` per feature
- Pure domain engines/services for rules and stat math
- Repository pattern for data access
- Unidirectional state updates inside each feature

---

## 3. Module Boundaries

## `App`
- App entry point
- Root navigation/tab shell
- Dependency container bootstrap

## `Features`
- `PlayFeature` (setup + active match shell)
- `X01Feature`
- `CricketFeature`
- `HistoryFeature`
- `PlayersFeature`
- `SettingsFeature`

## `Domain`
- `X01Engine`
- `CricketEngine`
- `MatchLifecycleService`
- `StatsService`
- Domain models and rule enums

## `Data`
- SwiftData models and schemas
- Repositories and mappers
- Persistence validators

## `DesignSystem`
- Color/typography tokens
- Reusable UI controls (`ScoringInputPad`, buttons, chips)

## `Support`
- Haptics/sound services
- Logging and diagnostics
- Future companion transport adapters (watch connectivity boundary)

Logging implementation details are defined in `specs/LoggingSpec.md`.

---

## 4. Dependency Rules
- `Features` may depend on `Domain`, `Data` interfaces, `DesignSystem`, `Support`.
- `Domain` depends on no UI or persistence framework types.
- `Data` can depend on `Domain` contracts and SwiftData.
- `DesignSystem` has no feature/domain knowledge.
- No circular dependencies.
- Domain and command DTOs must remain platform-neutral so iPhone and watch clients can share behavior.

---

## 5. State Management Rules
- ViewModels own screen state and intent handling.
- Domain services perform deterministic computation.
- Repositories perform IO only.
- Views remain declarative and side-effect light.

---

## 6. Error Handling Model
- Domain errors return typed failures (invalid input, bust/illegal checkout, etc.)
- Data errors map to user-safe messages in ViewModel
- Fatal persistence/migration issues route to recovery UI flow

---

## 7. Definition of Done
- All core features conform to module boundaries
- No business rules in SwiftUI views
- No direct SwiftData calls from views
- Unit tests exist for all domain engines

---

## 8. Future Apple Watch Readiness
- Introduce a `MatchCommandService` boundary between UI actions and domain engines.
- Keep scoring actions command-based (`submitTurn`, `undo`) rather than view-driven mutations.
- Ensure all accepted score actions become deterministic events so watch-originated input works identically.
- See `specs/AppleWatchCompanionSpec.md`.

---

## 9. Codebase map (repo layout)

Authoritative folder names (XcodeGen `project.yml` sources):

| Layer | Path | Contents |
|-------|------|----------|
| App shell | `App/` | `DartsScoreboardApp`, `MainTabView`, bootstrap, migration recovery |
| Features | `Features/{Play,History,Players,Statistics,Settings,Components}/` | SwiftUI + ViewModels per tab/flow |
| Domain | `Domain/` | Engines, services, scoring models |
| Data | `Data/Repositories/` | Protocols + SwiftData implementations |
| Persistence | `Persistence/` | Schema, migrations, container factory |
| DesignSystem | `DesignSystem/` | `Brand`, `DS`, shared components — see `DesignSystem/README.md` |
| Support | `Support/` | L10n, logging, preferences, feature flags |
| Tests | `Tests/Unit/`, `Tests/Accessibility/`, `Tests/UI/` | Unit + a11y regression; UI smoke + WCAG audits |

**Engineering audit (grades, P1–P3 findings):** [`docs/ios-code-audit.md`](../docs/ios-code-audit.md)  
**Appearance / contrast tracker:** [`accessibility/dark-light-mode.md`](../accessibility/dark-light-mode.md)
