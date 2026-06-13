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
- **1.0:** CI runs limited UI smoke (`Tests/UI/`); items marked “future UI automation” below are post-1.0 expansion.
- Manual RC evidence remains required for accessibility and appearance matrices.

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

## 3. Screen Contract Index

**Do not duplicate feature behavior here.** Each row points to the authoritative feature spec (states, validation, analytics, a11y). This file keeps only cross-screen implementation conventions (§4–§5).

Wireframes and visual behavior: [`UIBlueprintSpec.md`](UIBlueprintSpec.md).

| Screen / flow | Feature spec | UI implementation notes |
|---------------|--------------|-------------------------|
| Play home + setup (combined) | [`PlayHomeSpec.md`](PlayHomeSpec.md), [`SetupFlowSpec.md`](SetupFlowSpec.md) | `SetupHomeView` + `PlayHomeViewModel` / `MatchSetupViewModel` |
| Modes tab | [`ModesTabSpec.md`](ModesTabSpec.md) | `ModesRootView`, `GameModeCatalog` |
| Quick add player | [`QuickAddPlayerSpec.md`](QuickAddPlayerSpec.md) | Pushed from `PlayRoute.quickAddPlayer` |
| X01 match | [`game-modes/implemented/X01GameSpec.md`](game-modes/implemented/X01GameSpec.md), [`ScoringInputSpec.md`](ScoringInputSpec.md) | `X01MatchScreen`, `DartNumberPad` |
| Cricket match | [`game-modes/implemented/CricketSpec.md`](game-modes/implemented/CricketSpec.md), [`ScoringInputSpec.md`](ScoringInputSpec.md) | `CricketMatchScreen`, `CricketBoardView` |
| Baseball match | [`game-modes/implemented/BaseballGameSpec.md`](game-modes/implemented/BaseballGameSpec.md), [`ScoringInputSpec.md`](ScoringInputSpec.md) | `BaseballMatchScreen`, `DartNumberPad` |
| Killer match | [`game-modes/implemented/KillerGameSpec.md`](game-modes/implemented/KillerGameSpec.md) | `KillerMatchScreen`, `KillerNumberGridView` |
| Shanghai match | [`game-modes/implemented/ShanghaiGameSpec.md`](game-modes/implemented/ShanghaiGameSpec.md), [`ScoringInputSpec.md`](ScoringInputSpec.md) | `ShanghaiMatchScreen`, `DartNumberPad` |
| Match summary | [`MatchSummarySpec.md`](MatchSummarySpec.md) | `MatchSummaryScreen` |
| Activity tab (History + Statistics) | [`HistorySpec.md`](HistorySpec.md), [`StatisticsTabSpec.md`](StatisticsTabSpec.md) | `ActivityRootView` → `HistoryRootView` / `StatisticsRootView` |
| History list / detail | [`HistorySpec.md`](HistorySpec.md) | Embedded in Activity; `MatchHistoryDetailScreen` |
| Statistics segment | [`StatisticsTabSpec.md`](StatisticsTabSpec.md) | Embedded in Activity; charts in `StatsChartViews` |
| Players list / detail / edit | [`PlayerSpec.md`](PlayerSpec.md), [`PlayerExportImportSpec.md`](PlayerExportImportSpec.md) | `PlayersRootView`, `PlayerDetailView`, export via `PlayerExportService` |
| Settings | [`SettingsSpec.md`](SettingsSpec.md) | `SettingsRootView` |
| Migration recovery | [`MigrationRecoverySpec.md`](MigrationRecoverySpec.md) | `MigrationRecoveryView` (no tabs) |
| Preset / training / custom bots | [`BotOpponentSpec.md`](BotOpponentSpec.md), [`TrainingBotSpec.md`](TrainingBotSpec.md), [`CustomBotSpec.md`](CustomBotSpec.md) | Setup Add Bot + Player Detail + `CustomBotCreationSheet` |

When adding a screen: update the feature spec first, then add one row to this table. Add state/event detail here only if it is shared across multiple features (e.g. global loading chrome).

---

## 4. Common UI Non-Functional Requirements
- WCAG 2.1 AA requirements from `specs/AccessibilitySpec.md` are mandatory.
- Portrait and landscape layouts are required for MVP.
- Light and dark appearance parity is required for all core flows.
- One primary CTA per screen.
- Critical gameplay controls stay visible and reachable during active play.

---

## 5. Definition of Done for Any New Screen
- Feature spec created or updated (see [`SpecGovernance.md`](SpecGovernance.md) §6).
- Row added to §3 index above.
- Wireframe and behavior added or linked in `specs/UIBlueprintSpec.md`.
- Per-screen WCAG checklist under `accessibility/wcag-2.1-aa/screens/` linked from feature spec.
- Accessibility labels/hints and focus order verified; `WCAGAccessibilityUITests` updated if new identifiers.
- Portrait/light, portrait/dark, landscape/light, landscape/dark manually verified.
