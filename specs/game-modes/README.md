# Game mode specifications

Authoritative specs for each catalog game mode, split by implementation status.

**Promotion path:** [`FutureIdeas/`](../../FutureIdeas/) (assessment only) → [`planned/`](planned/) (rules spec) → [`implemented/`](implemented/) + [`GameModeCatalog.swift`](../../Features/Modes/GameModeCatalog.swift) when the engine ships. Once a mode has a planned spec, do not edit `FutureIdeas/` for rules — link to the spec instead.

| Folder | Status | When to edit here |
|--------|--------|------------------|
| [`implemented/`](implemented/) | Engine + gameplay UI shipped (`GameModeCatalog.status == .shipped`) | Behavior changes, localization, How to Play updates |
| [`planned/`](planned/) | Catalog stub only (`status == .planned`) | Rules design before `MatchType` + engine land |

## Promotion workflow

When a planned mode ships:

1. Move `planned/{Mode}GameSpec.md` → `implemented/` (or `game-modes/implemented/CricketSpec.md` naming for standard modes).
2. Update **Status** / **Shipped in app** rows in the spec; fill **Localization** **Exists** column.
3. Update [`docs/feature-inventory.md`](../../docs/feature-inventory.md) and [`specs/README.md`](../README.md).
4. Register `GameRulesCatalog` + `play.rules.{mode}.*` keys per spec § Localization.

Catalog source: [`Features/Modes/GameModeCatalog.swift`](../../Features/Modes/GameModeCatalog.swift).

## Implemented (5)

- [`X01GameSpec.md`](implemented/X01GameSpec.md)
- [`CricketSpec.md`](implemented/CricketSpec.md)
- [`BaseballGameSpec.md`](implemented/BaseballGameSpec.md) · [`BaseballModeDeferredWorkPlan.md`](implemented/BaseballModeDeferredWorkPlan.md)
- [`KillerGameSpec.md`](implemented/KillerGameSpec.md)
- [`ShanghaiGameSpec.md`](implemented/ShanghaiGameSpec.md)

## Planned (24)

See [`planned/`](planned/) — American Cricket, Mickey Mouse, Mulligan, English Cricket, Blind Killer, Knockout, Sudden Death, 51 By 5's, Golf, Football, Grand National, Hare and Hounds, Follow the Leader, Loop, Prisoner, Scam, Snooker, Tic-Tac-Toe, Around the Clock, 180 Around the Clock, Chase the Dragon, Nine Lives, Bob's 27, Halve-It.
