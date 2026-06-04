# Play Home Specification

## 1. Purpose
Define the Play tab entry experience: resume in-progress matches, recent completed games, and the embedded new-match setup surface (`SetupHomeView`).

Match configuration rules live in [`SetupFlowSpec.md`](SetupFlowSpec.md). Lifecycle rules live in [`MatchSpec.md`](MatchSpec.md).

---

## 2. MVP Scope

### In Scope (1.0.0)
- Single scrollable Play home combining setup form + home chrome
- Resume banner when exactly one `inProgress` match exists
- Up to three recent **completed** match previews (tap → history detail)
- Mode toggle (Standard: X01 / Cricket) and party game picker on same screen
- Sticky bottom **Start Match** CTA
- Navigation to quick-add player, active match, match summary, history detail

### Out of Scope
- Separate “lobby” screen before setup
- Multiple concurrent active matches UI

---

## 3. Architecture

| Piece | Location |
|-------|----------|
| Shell | `Features/Play/Setup/PlayRootView.swift` — `NavigationStack` + routes |
| Combined UI | `Features/Play/Setup/SetupHomeView.swift` |
| Home state | `PlayHomeViewModel` |
| Setup state | `MatchSetupViewModel` |

`MainTabView` may pass `pendingResumeMatch` to auto-push an active match route after external triggers.

---

## 4. Play Home States (`PlayHomeViewModel`)

| State | UI |
|-------|-----|
| `loading` | Implicit (brief); home reload on appear |
| `readyNoActiveMatch` | Setup only; no resume banner |
| `readyWithActiveMatch` | Green-bordered resume banner |
| `error` | Localized `error.playHome.load` |

### Resume banner
- Shows mode label and **Resume Match** CTA
- `accessibilityIdentifier`: `resumeMatchButton`
- Tap navigates directly to `.x01Match`, `.cricketMatch`, or `.baseballMatch` for active `matchId`

### Recent completed
- Loaded via `MatchStatsLoader.recentCompletedMatches(limit: 3)`
- **Completed only** — abandoned and in-progress excluded
- Tap → `PlayRoute.historyDetail(matchId:)` (read-only history detail in Play stack)
- Hidden when roster empty and no recents (normal first-run)

### Empty roster gate
- If no non-archived players exist, home skips active-match lookup and stays `readyNoActiveMatch`
- Setup still offers quick-add path (`QuickAddPlayerScreen`)

---

## 5. Active Match Conflict

When user taps **Start Match** while `fetchActiveMatch()` returns a row:
- Alert: abandon current match and start new (`play.setup.activeConflict.*`)
- **Cancel** — dismiss
- **Confirm** — `confirmReplaceActiveMatch()` abandons active match then `performStart()`
- Abandon policy: [`MatchSpec.md`](MatchSpec.md) § Abandon

---

## 6. Navigation Routes (`PlayRoute`)

| Route | Destination |
|-------|-------------|
| `setup` | (home — no push) |
| `x01Match(matchId:)` | `X01MatchScreen` |
| `cricketMatch(matchId:)` | `CricketMatchScreen` |
| `baseballMatch(matchId:)` | `BaseballMatchScreen` |
| `matchSummary(matchId:)` | `MatchSummaryScreen` |
| `quickAddPlayer` | `QuickAddPlayerScreen` |
| `historyDetail(matchId:)` | `MatchHistoryDetailScreen` (embedded) |

Match completion pushes `matchSummary`; **New Match** pops stack to home.

---

## 7. Accessibility Layout

At accessibility Dynamic Type sizes, `GameplayLayout.usesAccessibilitySetupHomeLayout` may surface setup validation hints above the roster when inline chips would clip.

---

## 8. Logging

| Event | When |
|-------|------|
| `play_home_active_match` | Resume banner shown |
| `play_home_ready` | No active match |
| `play_home_load_failed` | Repository error on appear |
| `active_match_conflict` | Start blocked by in-progress match |
| `active_match_replaced` | User confirmed abandon + replace |

---

## 9. Testing

## Unit
- `PlayHomeViewModelTests` — active match, recents, empty roster

## UI
- Resume flows in navigation smoke tests
- `WCAGAccessibilityUITests` — Play home identifiers

---

## 10. Accessibility verification
- Manual: [`play-home.md`](../accessibility/wcag-2.1-aa/screens/play-home.md), [`match-setup.md`](../accessibility/wcag-2.1-aa/screens/match-setup.md)
- Identifier: `resumeMatchButton`

## 11. Analytics
§12 — `play_home_*` (log-only); `match_abandoned` when replacing active match from setup.

## 12. Verification
| Field | Value |
|-------|--------|
| **Last verified** | 2026-06-04 |
| **Commit** | `0c25396` |
| **Code** | `PlayHomeViewModel.swift`, `SetupHomeView.swift` |

---

## 13. Future Improvements
- Dedicated setup sub-screen when home cognitive load grows
- Pin/favorite recent opponents on home
