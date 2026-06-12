# Quick Add Player Specification

> **Superseded (1.0+):** Play setup now presents the full [`PlayerEditSheet`](PlayerSpec.md) as a sheet via **Add Players**. This spec is retained for historical context only.

## 1. Purpose (historical)
Defined the minimal player-creation flow launched from Play setup when the roster was empty or the user needed a fast add without visiting the Players tab.

Player CRUD rules: [`PlayerSpec.md`](PlayerSpec.md). Setup integration: [`SetupFlowSpec.md`](SetupFlowSpec.md).

---

## 2. Replacement behavior

| Former quick-add | Current |
|------------------|---------|
| Push `PlayRoute.quickAddPlayer` → name-only form | Sheet `PlayerEditSheet` from setup **Add Players** |
| Auto-select via `PendingMatchPlayerSelections` | Same — `MatchSetupViewModel.createHumanPlayer` |
| Default avatar/color from repository | User picks avatar/color in sheet; repository defaults apply before profile update |

Code: `Features/Players/PlayerEditSheet.swift`, `Features/Play/Setup/SetupHomeView.swift`, `Features/Players/PlayerRepository+Create.swift`.
