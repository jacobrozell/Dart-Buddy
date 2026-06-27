**Estimated release:** `2.0+`

# Team Play Platform Specification

## 1. Purpose

Define the **shared platform** for splitting humans into **teams** during match setup and carrying team identity through gameplay, history, and stats — without duplicating team rules in every mode spec.

Mode-specific win conditions (points, legs, cells claimed) stay in each `*GameSpec.md`. This spec owns **roster assignment**, **persistence**, **turn-order policies**, and **UI contracts**.

**Status:** Planned platform — no shipped mode uses full platform yet; [`ClearTheBoardGameSpec.md`](game-modes/planned/ClearTheBoardGameSpec.md) §5.6c prototypes team rules inline.

**Related specs:**
- [`SetupFlowSpec.md`](SetupFlowSpec.md) — roster surface
- [`MatchSpec.md`](MatchSpec.md) — `MatchRecord`, participants, resume
- [`StatsSpec.md`](StatsSpec.md) — per-player dart credit vs team outcome
- [`CoopPvEModesSpec.md`](CoopPvEModesSpec.md) — **not** team vs team (hero co-op ≠ two teams)
- [`game-modes/planned/RollTwentyGameSpec.md`](game-modes/planned/RollTwentyGameSpec.md) — optional team scoring

---

## 2. Terminology

| Term | Meaning |
|------|---------|
| **Team play** | Match where participants are grouped into named sides; scores or objectives accrue to teams |
| **Team vs team** | Two human teams competing (Clear the Board, Roll Twenty teams, Tag Out) |
| **Co-op hero team** | All humans share one outcome (Raid, Vault) — **out of scope** here; see Co-op spec |
| **`TeamSide`** | `teamA` \| `teamB` — v1 only two teams |
| **Interleaved turn order** | A1 → B1 → A2 → B2 → … |
| **Team assignment snapshot** | Immutable map frozen at match start |

---

## 3. Scope

### In scope (platform v1)

| Item | Detail |
|------|--------|
| **Team count** | **2** teams only |
| **Assignment UI** | Setup: split roster into Team A / Team B columns |
| **Validation** | Mode declares `teamPlayRequirements` (even split, min per team, humans-only) |
| **Persistence** | `teamSideRaw` on each `MatchParticipant` at match start |
| **Turn policies** | `interleaved` (default for vs team), `rosterOrder` (FFA with team score rollup) |
| **Display** | Team names from palette tokens; scoreboard team totals |
| **History / summary** | Winner team + roster per side |
| **Stats** | Darts credit to thrower; win credits to all humans on winning team |
| **Forfeit** | Team-level standings when mode registers forfeit registry |

### Out of scope (v1)

| Item | Notes |
|------|-------|
| 3+ teams | Pub leagues rare on one phone; defer |
| **Odd teams** (3v2) | Rejected for competitive vs team — even split only |
| Bots on human teams | Clear the Board v1: humans only; Roll Twenty: bots as FFA opponents only |
| Online / multi-device teammates | [`OnlinePlaySpec.md`](OnlinePlaySpec.md) P2 |
| Shared team score X01/Cricket legs | **Tag Out** / doubles league — v2 mode family (§7) |
| Custom team names | v1: "Team A" / "Team B" localized + color chips from first member |

---

## 4. Catalog contract

Add to `GameModeCatalogEntry` (when platform ships):

| Field | Type | Meaning |
|-------|------|---------|
| `supportsTeamPlay` | `Bool` | Setup shows Teams toggle / team roster UI |
| `teamPlayRequirements` | `TeamPlayRequirements?` | Nil when `supportsTeamPlay == false` |

```swift
struct TeamPlayRequirements: Equatable, Sendable {
    var minimumPlayersPerTeam: Int      // default 1 co-op rollup; 1 for 1v1
    var requiresEvenTeams: Bool         // true for vs team
    var allowsBots: Bool                // false default
    var defaultTurnPolicy: TeamTurnPolicy
    var humansOnly: Bool                // true for pub crew modes
}

enum TeamTurnPolicy: String, Codable, Sendable {
    case interleaved    // A1,B1,A2,B2
    case rosterOrder    // existing order; scores aggregate to team
}
```

### Mode registry (v1 targets)

| Mode | `supportsTeamPlay` | Requirements | Mode spec |
|------|-------------------|--------------|-----------|
| Clear the Board | Yes (Team vs Team variant only) | even, ≥1/team, interleaved, humans | [`ClearTheBoardGameSpec.md`](game-modes/planned/ClearTheBoardGameSpec.md) |
| Roll Twenty | Yes (optional chip) | even optional; rosterOrder rollup | [`RollTwentyGameSpec.md`](game-modes/planned/RollTwentyGameSpec.md) |
| Tag Out | Yes (required 2v2) | even 2v2, interleaved, humans | Future `TagOutGameSpec.md` (brainstorm §21) |
| X01 / Cricket / most party | **No** | — | — |

Engines **must not** invent ad-hoc team maps in config when platform is available — read participant `teamSideRaw`.

---

## 5. Data model

### 5.1 Participant snapshot (authoritative)

Extend `MatchParticipant` ([`MatchSpec.md`](MatchSpec.md) / [`SwiftData.md`](SwiftData.md)):

| Field | Type | Notes |
|-------|------|-------|
| `teamSideRaw` | `String?` | `"teamA"` \| `"teamB"`; `nil` = FFA / non-team match |

Immutable after match start — same policy as `displayNameAtMatchStart`.

### 5.2 Mode config (optional duplicate)

Modes may mirror assignment in config for replay portability (e.g. `MatchConfigClearTheBoard.teamAssignment`). On conflict, **participant snapshot wins** for display; config used for engine bootstrap only at creation.

### 5.3 Team display tokens

| Side | Default label key | Color |
|------|-------------------|-------|
| `teamA` | `teams.sideA` | First assigned player's `PlayerColorToken` |
| `teamB` | `teams.sideB` | First assigned player's color |

Scoreboard uses side color as accent bar; player chips retain individual avatars.

---

## 6. Setup UI (`SetupFlowSpec` extension)

### 6.1 When visible

- `GameModeCatalogEntry.supportsTeamPlay == true` **and** mode variant enables teams (e.g. Clear the Board → Team vs Team), **or** Roll Twenty teams chip on.

Insert **below** selected roster, **above** Start Match:

```text
+--------------------------------------------------+
| Teams                                            |
| [ Off | Team vs Team ]                           |
|--------------------------------------------------|
| Team A          | Team B                          |
| [ Alice    ]    | [ Carol    ]                    |
| [ Bob      ]    | [ Dave     ]                    |
|--------------------------------------------------|
| Unassigned: (empty when valid)                   |
| [ Balance teams ]                                |
+--------------------------------------------------+
```

### 6.2 Interactions

| Action | Behavior |
|--------|----------|
| Tap player on roster | Assign to focused team column (or toggle A ↔ B) |
| Drag player | Move between A / B / unassigned |
| **Balance teams** | Split `selectedPlayerIds` alternating into A/B (preserve relative order) |
| Teams off | Clear assignment; hide columns |

### 6.3 Validation keys

| Rule | Key |
|------|-----|
| Teams on + unassigned players | `setup.validation.teamUnassigned` |
| Requires even + odd count | `setup.validation.teamUneven` |
| Below min per team | `setup.validation.teamMinimum` |
| Bot on team when disallowed | `setup.validation.teamBotsUnsupported` |
| Teams on but mode variant disallows | `setup.validation.teamModeUnsupported` |

Start Match disabled until team validation passes.

### 6.4 Start match

When teams enabled:
1. Build `MatchParticipant` rows with `teamSideRaw` from assignment.
2. Compute `turnOrder` per mode's `TeamTurnPolicy`:
   - **`interleaved`:** sort each team by roster order, zip A[i] with B[i], flatten A1,B1,A2,B2,…
   - **`rosterOrder`:** keep user roster order unchanged.
3. Persist assignment on match record.

---

## 7. Turn order policies

### 7.1 Interleaved (default vs team)

Used by: Clear the Board Team vs Team, Tag Out.

```text
Team A roster order: A1, A2, A3
Team B roster order: B1, B2, B3
Turn order: A1 → B1 → A2 → B2 → A3 → B3 → A1 → …
```

If team sizes differ (validation should prevent): engine throws `validationFailed`.

### 7.2 Roster order (team score rollup)

Used by: Roll Twenty teams mode.

- Turn order unchanged from standard roster drag order.
- Points earned accrue to thrower's `TeamSide`.

---

## 8. Gameplay UI conventions

| Element | Rule |
|---------|------|
| Scoreboard header | Show **both** team totals when `teamSideRaw` present on ≥2 participants |
| Active player chip | Player avatar + small team color bar |
| Catch-up / behind rules | Mode spec defines "behind" per **team** (Clear the Board §5.4) |
| Win celebration | Team victory card lists all members on winning side |
| Co-op summary style | **Do not** use for team vs team — use standard winner card with team banner |

---

## 9. History, stats, forfeit

### 9.1 History list row

- Subtitle includes team result when applicable: `Team A won · 67–58`
- Detail screen: team rosters as grouped sections

### 9.2 Stats

- **Dart-level stats** (doubles %, heatmap): credit **throwing** player only ([`ThrowHistoryHeatmapSpec.md`](ThrowHistoryHeatmapSpec.md)).
- **Match win:** increment `matchesWon` for **each human** on winning team (same as doubles league convention).
- **Bot participants:** never on teams v1; bot wins in FFA Roll Twenty unchanged.

### 9.3 Forfeit

- **Whole team forfeits:** if any human on a side uses Save & Forfeit in a team match, the **opposing team wins** (no sub-finish, no 1v2 continuation).
- Register team standings in `MatchForfeitStandingsRegistry` per mode.

---

## 10. Future — team X01 / Cricket (v2)

Brainstorm [`FutureIdeas/custom-games-brainstorm.md`](../FutureIdeas/custom-games-brainstorm.md) §21 **Tag Out**:

- 2v2 shared remaining score (501)
- **One dart per visit** rotation
- Requires `TeamTurnPolicy.interleaved` + shared checkout state entity

**Not part of platform v1.** Platform v1 unblocks Clear the Board + Roll Twenty; Tag Out adds `TagOutGameSpec.md` consuming this platform.

Do **not** add a generic "Teams toggle" to standard X01/Cricket setup until Tag Out (or similar) ships — avoids half-implemented shared score UX.

---

## 11. Architecture

| Piece | Location |
|-------|----------|
| Requirements + policy | `Domain/Match/TeamPlayModels.swift` |
| Setup validation | `MatchSetupViewModel+TeamPlay.swift` |
| Assignment UI | `Features/Play/Setup/TeamRosterSplitView.swift` |
| Turn order builder | `TeamTurnOrderBuilder.swift` |
| Catalog flags | `GameModeCatalog.swift` |

---

## 12. Accessibility

- Team columns: `accessibilityIdentifier` `setup_teamColumnA`, `setup_teamColumnB`
- Balance button: `setup_teamBalanceButton`
- Player team membership announced on assign: `teams.accessibility.assignedFormat`
- Team scoreboard: combine team name + score; not color-only (team color bar + text label)

Add WCAG row to `accessibility/wcag-2.1-aa/screens/setup.md` at implementation.

---

## 13. Testing

### Unit
- `TeamTurnOrderBuilderTests` — interleaved 1v1, 2v2, 4v4
- Validation matrix — uneven, unassigned, bots disallowed
- Participant snapshot round-trip on resume

### UI
- Setup smoke: enable teams, balance, start match
- Clear the Board integration test (when mode ships)

---

## 14. Cross-references

| Spec | Update when platform ships |
|------|----------------------------|
| [`SetupFlowSpec.md`](SetupFlowSpec.md) | §3 Roster + §4 validation table |
| [`MatchSpec.md`](MatchSpec.md) | Participant fields |
| [`SwiftData.md`](SwiftData.md) | Migration for `teamSideRaw` |
| [`DataSchemaSpec.md`](DataSchemaSpec.md) | Invariant: team side frozen at start |
| [`ClearTheBoardGameSpec.md`](game-modes/planned/ClearTheBoardGameSpec.md) | Replace inline assignment notes with links here |
| [`RollTwentyGameSpec.md`](game-modes/planned/RollTwentyGameSpec.md) | Teams chip dependency |

---

## 15. Verification

| Field | Value |
|-------|--------|
| **Estimated release** | `2.0+` |
| **Last verified** | — |
| **Commit** | — |
| **Code** | — (planned) |

---

## 16. Decisions (locked 2026-06-26)

| # | Question | Decision |
|---|----------|----------|
| 1 | Win stat credit | **All humans** on the winning team receive +1 `matchesWon` (not throwers only). |
| 2 | Team forfeit | **Whole team loss** — one forfeit on a side ends the match; opponent team wins. |
| 3 | Ship order | **Phased — not locked to a single release.** Build toward full platform + Clear the Board Team vs Team + Roll Twenty teams + Tag Out. Recommended sequence: (a) platform + schema behind feature flag, (b) first consumer mode ships teams UI, (c) remaining modes. Exact release pairing TBD at implementation planning. |
