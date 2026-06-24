**Estimated release:** `1.0`

# Match Summary Specification

## 1. Purpose
Define the post-match summary screen: celebration, per-player stats, undo-last-throw, and navigation to a new match or history detail.

Shared lifecycle completion rules live in [`MatchSpec.md`](MatchSpec.md). Mode-specific metrics follow [`game-modes/implemented/X01GameSpec.md`](game-modes/implemented/X01GameSpec.md) and [`game-modes/implemented/CricketSpec.md`](game-modes/implemented/CricketSpec.md).

**Solo practice modes** (Call & Hit, Bob's 27, Halve-It): use the shared solo shell — no winner card. See [`SoloPracticeModesSpec.md`](SoloPracticeModesSpec.md) and [`SoloPracticeMatchSummarySupplement.md`](SoloPracticeMatchSummarySupplement.md).

---

## 2. MVP Scope

### In Scope (1.0.0)
- Shown after X01 or Cricket leg/match completion (pushed on `PlayRoute.matchSummary`)
- Winner highlight and participant stat rows
- Match metadata (mode, duration, leg/set context)
- **New Match** — pops Play navigation to setup home
- **View in History** — pushes history detail for same `matchId`
- **Undo last throw** — reopens completed match as in-progress with restored dart pad state (single throw only)

### Out of Scope (1.0.0)
- Editing completed match scores
- Share sheet / screenshot export from summary

### Post-1.0 (when flagged)
- **Achievement unlocks** — section on summary when new local achievements unlock; revoked if user undoes last throw (see [`AchievementsSpec.md`](AchievementsSpec.md) §7)
- **Campaign layer** — stars and Journey CTAs on campaign-tagged matches (see [`CampaignSpec.md`](CampaignSpec.md) §10)

---

## 3. Architecture

| Piece | Location |
|-------|----------|
| View | `Features/Play/Shared/MatchSummaryScreen.swift` |
| VM | `MatchSummaryViewModel` |
| Session | `ActiveMatchStore` + `MatchLifecycleSession` |

On appear, VM loads session from store or rehydrates via `MatchStatsLoader.rehydrateSession`.

---

## 4. UI Specification

### Layout
- Brand scoreboard chrome
- Winner card (trophy / emphasis typography)
- Participant rows: name, winner badge, labeled stat chips (mode-specific)
- Primary: **New Match**
- Secondary: history detail, undo (when allowed)

### Undo last throw
- Available when `session.runtime.status == .completed` and events non-empty
- `MatchTurnSupport.undoLastDart` reverts last accepted dart, returns restored `[DartInput]` for keypad
- On success: `ActiveMatchStore.setResumeHint(matchId:restoredDarts:)` and pop summary → active match screen
- Errors surface `undoErrorKey`

Undo does not appear for abandoned matches (never reach summary).

---

## 5. Data Rules

- Summary reads participant **snapshots** at match start for names/colors
- Stats chips computed from final session / event reducers
- Completing match already persisted aggregates (`StatsSpec.md`); undo triggers recomputation path via lifecycle

---

## 6. Navigation

| Action | Result |
|--------|--------|
| New Match | `path.removeAll()` on Play stack |
| View in History | `PlayRoute.historyDetail(matchId:)` |
| Undo | Pop to `.x01Match` / `.cricketMatch` with resume hint |

---

## 7. Accessibility

- Winner and scores must have spoken labels (not color-only)
- Primary CTA stable identifier for UI tests
- Dynamic Type: prefer scaled metrics; known AXXXL gaps tracked in `docs/release/todo.md`

---

## 8. Testing

## Unit
- `MatchSummaryViewModelTests` — rows, undo eligibility, rehydrate

## UI
- End-of-match flows in smoke / WCAG suites

---

## 9. Accessibility verification
- Manual: [`match-summary.md`](../accessibility/wcag-2.1-aa/screens/match-summary.md)

## 10. Analytics
§12 — inherits `match_completed`; undo flows use `dart_undone` / `turn_undone`.

## 11. Verification
| Field | Value |
|-------|--------|
| **Estimated release** | `1.0` |
| **Last verified** | 2026-06-04 |
| **Commit** | `0c25396` |
| **Code** | `MatchSummaryScreen.swift`, `MatchSummaryViewModel.swift` |

---

## 12. Future Improvements
- Share match result card
- Animated celebration pass (post-1.0 motion)

---

## 13. Solo practice summary (planned)

When `GameModeCatalogEntry.isSolo == true`:

| Element | Competitive | Solo practice |
|---------|-------------|---------------|
| Hero | Winner + trophy | Performance metric (accuracy, score, time) |
| Participants | Rows + winner badge | Single strip, no winner |
| Primary CTA | New Match | **Practice again** (prefill setup) |
| Undo | Last dart (pad modes) | Mode-specific (last target / round) |

Wireframes, protocol sketch, and per-stat-kind hero variants: [`SoloPracticeMatchSummarySupplement.md`](SoloPracticeMatchSummarySupplement.md).

Platform contract (catalog, setup, history, stats): [`SoloPracticeModesSpec.md`](SoloPracticeModesSpec.md).