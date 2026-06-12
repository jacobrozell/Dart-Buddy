# History Specification

## 1. Purpose
Define how completed matches are listed, filtered, inspected, and retained for long-term analysis.

---

## 2. MVP Scope
- **Activity tab** — History is the default segment inside `ActivityRootView` (shared chrome with Statistics). See [`StatisticsTabSpec.md`](StatisticsTabSpec.md) for the sibling segment.
- Chronological completed-match list with basic filters (match type, player, date preset)
- Match detail view with participants and key metrics
- Stable rendering even when player profiles change later

---

## 3. UI Specification

### Activity shell
- Tab label: **Activity** (`MainTabView`)
- Segment picker: History | Statistics (`ActivitySegment`)
- Shared filters (mode, period, player) apply to the active segment where applicable
- Deep links to history detail push inside the History segment navigation stack

## History List
- Card row includes:
  - Mode badge (`X01` / `Cricket`)
  - Participants
  - Winner
  - Date/time
  - Compact stat chips

## Filter UX
- Quick filter chips:
  - All / X01 / Cricket
  - Date presets (7d, 30d, all)
  - Player selector

## Detail Screen
- Match header (mode, date, duration, winner)
- Participant section
- Mode-specific summary section
- Event timeline section (turn-by-turn minimum)

---

## 4. Data Management
- History reads from completed `MatchRecord` plus linked events.
- **History list cards** use denormalized `MatchRecord.historyCardPayload` (`MatchHistoryCardPayload`, version `1`), written at match completion from the latest snapshot via `MatchHistoryCardBuilder`. List UI decodes this blob first; falls back to live computation when missing or corrupt.
- Participant display should prefer match-start snapshots for historical consistency.
- In-progress matches are excluded from History list.
- Deleting/archiving player does not remove historical participation.

---

## 5. Performance Requirements
- Initial list load should feel instant for typical local datasets.
- Use paged fetch or lazy stacks for large histories.
- Aggregate key card fields at match-complete time (`historyCardPayload`) to reduce per-row recompute.

---

## 6. Edge Cases
- Missing player record -> fallback snapshot name/avatar
- Corrupted summary cache -> compute from events and repair cache
- Very long match timeline -> chunked/lazy render

---

## 7. Testing

## Unit
- Filter predicates for mode/date/player
- Fallback display resolution logic
- `MatchHistoryCardBuilder` produces decodable payloads for X01 and Cricket

## Integration
- Completed match appears immediately in history
- `completeMatch` writes non-nil `historyCardPayload` when a snapshot exists
- Edited player name does not alter historical snapshot identity

## UI
- Filter interactions and empty states
- Detail rendering for both X01 and Cricket

---

## 8. Accessibility verification
- Manual: [`history-list.md`](../accessibility/wcag-2.1-aa/screens/history-list.md), [`history-detail.md`](../accessibility/wcag-2.1-aa/screens/history-detail.md)

## 9. Verification
| Field | Value |
|-------|--------|
| **Last verified** | 2026-06-11 |
| **Commit** | `917043e` |
| **Code** | `ActivityRootView.swift`, `HistoryRootView.swift`, `MatchHistoryDetailScreen.swift`, `MatchHistoryCardBuilder.swift`, `SwiftDataMatchRepository.swift` |

---

## 10. Future Improvements
- Full advanced filter builder
- Export match history (JSON/CSV/PDF)
- Shareable summary cards
- Chart overlays in detail (requires StatsSpec phase 2)
