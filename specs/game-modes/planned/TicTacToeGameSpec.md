# Tic-Tac-Toe Game Specification

## 1. Purpose
Define Tic-Tac-Toe (Noughts and Crosses) darts — claim a 3×3 grid of board targets — for future implementation.

**Status:** Planned (`party.ticTacToe`).

References: [darts501.com — Noughts and Crosses](https://darts501.com/Games.html).

---

## 2. Catalog metadata
| Field | Value |
|-------|-------|
| **Section** | Party |
| **UI template** | H — Board state |
| **Stat kind** | Board claim |
| **Ruleset (v1)** | `tic_tac_toe_preset_grid` |

---

## Player count

| Question | Answer |
|----------|--------|
| **Solo?** | No — X/O requires an opponent |
| **Minimum** | 2 participants (≥1 human) |
| **Recommended** | 2 exactly |
| **App maximum** | 2 (`maximumPlayers: 2` in catalog) |

### Brainstorm
- Classic noughts-and-crosses is **two sides**; team pairs could share a side but v1 is 1v1.
- Handicap via grid difficulty is per-side, not extra players.
- Setup enforces exactly 2 roster slots.

---

## 3. MVP Scope
- 3×3 grid: center = **bull**; eight outer cells = preset targets (e.g. T20, small 14, D2, …)
- Default grid shipped in config; optional **custom grid** v2
- Players alternate 3-dart visits; hitting a cell claims it (X/O)
- First **three in a row** wins
- Skill handicap: easier cells for novice (singles) vs harder (doubles) — setup preset
- Per-dart entry; undo; local persistence

### Out of Scope (v1)
- Online grid editor

---

## 4. Rules Engine (`TicTacToeEngine`)

### Config (`MatchConfigTicTacToe`, payload v1)
| Field | Default |
|-------|---------|
| `gridCells: [TargetArea]` | preset 9 cells |
| `handicapPreset` | `.balanced` |

### State
- `claims: [CellIndex: PlayerSide]`
- `currentSide`, `winner?`

### Turn flow
1. Player throws 3 darts; any hit on unclaimed cell claims it.
2. Check rows/cols/diags after each claim.

### Undo
Replay restores grid claims.

---

## 5. UI Specification
- Template H: 3×3 grid with target labels + X/O markers (not color-only)
- Show which cells remain open

---

## How to Play

| | |
|---|---|
| **Key prefix** | `play.rules.ticTacToe.` |
| **Shipped in app** | Planned |

### Overview
| **Title key** | `play.rules.ticTacToe.overview.title` |
| **Body key** | `play.rules.ticTacToe.overview.body` |

Noughts and crosses on a 3×3 grid of dartboard targets. Hit a cell to claim it. First to three in a row wins.

### The grid
| **Title key** | `play.rules.ticTacToe.grid.title` |
| **Body key** | `play.rules.ticTacToe.grid.body` |

Nine cells: the center is bull; the other eight are specific segments (for example treble 9, small 14, double 2). The exact grid is shown at setup. Handicap presets can make one side's cells easier.

### Turns
| **Title key** | `play.rules.ticTacToe.turns.title` |
| **Body key** | `play.rules.ticTacToe.turns.body` |

Players alternate visits of three darts. The first hit on an open cell claims it for X or O. Already claimed cells do nothing.

### Winning
| **Title key** | `play.rules.ticTacToe.winning.title` |
| **Body key** | `play.rules.ticTacToe.winning.body` |

Three claimed cells in a row — across, down, or diagonal — wins the game. If all nine cells fill with no line, it's a draw (optional rematch in setup).

---

## Localization

| **Exists** | `modes.catalog.party.ticTacToe.name`, `.blurb` |

### New keys

**Setup:** `play.party.ticTacToe.title`, `.subtitle`; `play.ticTacToe.setup.handicapPreset`; `play.ticTacToe.grid.cell.*` (per-cell target labels for default grid)

**Gameplay:** `play.ticTacToe.navTitle`, `grid.claimedByFormat`, `side.x` / `side.o`, `cellHit`, `winLine`, `draw`, `currentSideFormat`, `gridAccessibilityFormat`

**How to play:** `play.rules.ticTacToe.overview|grid|turns|winning`

**History:** `history.timeline.ticTacToeClaimFormat`, `history.detail.ticTacToeSummaryFormat`

**Validation:** `setup.validation.ticTacToeExactTwoPlayers`

---

## 6. Data Capture
- `TicTacToeVisitEvent`: `claimsThisVisit`, `gridSnapshot`

---

## 7. Testing
- Unit: win detection, occupied cell ignores re-hit
- Handicap presets change cell definitions only

---

## 8. Verification
| Field | Value |
|-------|-------|
| **Status** | Planned |
