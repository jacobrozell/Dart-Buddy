# Player Specification

## 1. Purpose
Define the player domain for the iPhone MVP darts app: how a player is represented in UI, persisted locally, used in game flows, and evolved safely over time.

This spec follows the current product plan:
- iPhone-only MVP
- Free app, no ads, no paywall
- Local-only data (no account, no cloud sync in 1.0.0)
- Game modes: X01 + Cricket
- Stats foundation should be chart-ready for future Swift Charts work

---

## 2. Scope

### In Scope (1.0.0)
- Create, read, update, delete local players
- Select players when starting matches
- Display player identity during live games
- Persist per-player summary stats computed from local event history
- Preserve historical match integrity when players are removed

### Out of Scope (Post-1.0.0)
- Player accounts/authentication
- Cross-device sync
- Social profiles/friends
- Online rankings
- Remote avatars/assets

---

## 3. Underlying Tech Stack

## App Layer
- `Swift 5.10+`
- `SwiftUI` (iOS 18.0+ target)
- Feature-oriented `MVVM` with domain services

## Data Layer
- `SwiftData` for local persistence
- Repository pattern between feature/domain and storage
- Derived stats pipeline backed by persisted event history (turn + dart granularity)

## Testing
- `Swift Testing` (`Testing` module) for:
  - Player CRUD
  - Referential integrity with history/matches
  - Stats recompute correctness

## Key Architectural Rule
Player state in UI is editable and user-facing; historical match/event records are immutable and must remain analyzable even if a player is later edited or retired.

---

## 4. Player Domain Model

## Canonical Player Entity (Conceptual)
- `id: UUID` (stable primary key)
- `displayName: String`
- `createdAt: Date`
- `updatedAt: Date`
- `isArchived: Bool` (soft-retired from new match selection)
- `avatarStyle: PlayerAvatarStyle` (local visual token only)
- `preferredColorToken: String` (design-token key, not raw hex)
- `notes: String?` (optional, capped length)

## Validation Rules
- Name is required, trimmed, max length 32
- Name comparison for duplicate checks is case-insensitive + whitespace-normalized
- Empty and whitespace-only names are rejected
- Archived players cannot be selected for new matches

---

## 5. UI Specification

## 5.1 Players List Screen
Purpose: Manage known players quickly.

### Layout
- Navigation title: `Players`
- Top-right add button
- Search field (client-side filter)
- Player rows with:
  - Avatar chip
  - Display name
  - Lightweight stats subtitle (`W/L`, last played)
  - Chevron for details/edit

### States
- Empty: explanatory text + primary CTA `Add Player`
- Populated: sorted alphabetically by default
- Search no-results: inline empty result state

### Interactions
- Tap row -> Player Detail
- Swipe actions:
  - `Archive` (default destructive-safe action)
  - `Delete` (secondary, requires confirmation)

## 5.2 Create/Edit Player Sheet
Fields:
- Display name (required)
- Avatar style picker (simple token set)
- Color token picker (accessible palette)
- Optional notes

Controls:
- Cancel
- Save (disabled until valid)

Validation feedback:
- Inline, immediate
- Friendly duplicate-name message with suggestion

## 5.3 Player Detail Screen
Sections:
- Identity card (name/avatar/color)
- **Training Partner** (humans only) — progress, create bot, practice shortcuts — see [`TrainingBotSpec.md`](TrainingBotSpec.md)
- Lifetime summary stats
- **Per-mode breakdown** (post-1.0, catalog scale) — the home for advanced,
  mode-specific stats. One expandable block per mode the player has played,
  rendering that mode's `statKind` card set (per-mode bests, win rate, trend).
  Heterogeneous metrics live here rather than being forced into the shared
  Statistics tables. Model and `statKind` contract: [`StatsSpec.md`](StatsSpec.md) §12.
- Recent matches (last N)
- Management actions:
  - Edit
  - Archive/Unarchive
  - Delete (guarded)

---

## 6. Functionality and Capabilities

## Core Capabilities (1.0.0)
- Create player
- Edit player profile fields
- Archive/unarchive player
- Delete player with data-safe behavior
- Use player as match participant
- Show player metrics in Players and History contexts

## Match Flow Integration
- Setup screen only lists active (`isArchived == false`) players
- Existing in-progress matches keep resolving using participant snapshots/IDs
- History always resolves display names safely even if player later changes

## Stats Capabilities (MVP)
Expose per-player baseline metrics:
- Matches played
- Matches won
- X01 average (define exact formula in StatsSpec)
- Cricket wins
- Last played date

Internally preserve enough event detail for future charts:
- Turn-level event lineage
- Dart-level event lineage (confirmed requirement)

---

## 7. Data Management

## 7.1 Storage Location
- Persisted locally via SwiftData in app sandbox
- No server writes, no cloud replication in 1.0.0

## 7.2 Storage Strategy
- `PlayerRecord` persisted as first-class model
- Match and event records reference player `id`
- Keep immutable match participant snapshots where needed for historical consistency:
  - `displayNameAtMatchStart`
  - `avatarStyleAtMatchStart` (optional but recommended)

This prevents history from becoming ambiguous after profile edits.

## 7.3 Read/Write Access Pattern
- Features call `PlayerRepository`
- Repository mediates:
  - Validation
  - Persistence
  - Referential checks against match/event tables
  - Error mapping for UI-safe messages

## 7.4 Deletion Policy
Use a two-tier deletion model:

1. **Archive (preferred user path)**
- Player removed from new-match picker
- Historical data untouched
- Fully reversible

2. **Hard Delete (restricted)**
- Allowed only if player has no match/event references
- Otherwise reject with explanatory action guidance:
  - archive instead
  - or retain for history integrity

Rationale: deleting referenced identities can corrupt stats/history semantics.

## 7.5 Data Retention and Reset
- App-level reset in Settings can wipe all local data after explicit destructive confirmation — see [`DeleteAllDataSpec.md`](DeleteAllDataSpec.md)
- Player deletions/archives should emit internal audit events for debug logs (local only)

---

## 8. Error Handling and Edge Cases
- Duplicate name attempt -> validation error, no write
- Name change during active match -> allowed; active match should continue using participant snapshot rules
- Delete referenced player -> blocked, suggest archive
- Archive last remaining active player -> allowed, but New Match flow must surface `Add/Unarchive a player` guidance
- Corrupt/missing stats cache -> recompute from events on demand

---

## 9. Accessibility and UX Quality
- Minimum 44x44 tap targets (prefer 52 in list rows where possible)
- Dynamic Type support in all player screens
- VoiceOver labels for row actions (`Archive`, `Delete`, `Edit`)
- Do not rely only on color for player identification; always pair with text/avatar
- High-contrast token palette for player colors

---

## 10. Security and Privacy
- No tracking SDKs for player data
- No third-party ad identifiers
- Player information remains local-only in 1.0.0
- Keep PII minimal (display name only, no email/phone fields)

---

## 11. Testing Requirements

## Unit Tests
- Name validation matrix (empty, max length, duplicate normalization)
- Archive/unarchive transitions
- Delete behavior with/without references
- Repository error mapping

## Integration Tests
- Create player -> start match -> finish match -> verify stats/history linkage
- Edit player profile -> historical match rendering remains stable
- Archive player -> excluded from setup -> unarchive restores visibility

## UI Tests
- Add/edit/delete/archive flows
- Empty states
- Accessibility labels for actions

---

## 12. Definition of Done (Player Component)
- Player CRUD + archive fully functional in app
- Setup and gameplay integrate with active players only
- History remains correct after player edits/archives
- Required tests passing
- No linter/build warnings introduced by player feature work
- Spec reviewed and accepted for implementation

---

## 13. Player export
- Human player detail exposes **Export** when `ProductSurface.showsPlayerExport` (see [`PlayerExportImportSpec.md`](PlayerExportImportSpec.md) for DBPE v1 format).
- Share sheet presents `.dartbuddy.json` bundle; import UI is deferred.

## 14. Accessibility verification
- Manual: [`players-list.md`](../accessibility/wcag-2.1-aa/screens/players-list.md), [`player-detail.md`](../accessibility/wcag-2.1-aa/screens/player-detail.md), [`player-edit.md`](../accessibility/wcag-2.1-aa/screens/player-edit.md)

## 15. Verification
| Field | Value |
|-------|--------|
| **Last verified** | 2026-06-04 |
| **Commit** | `0c25396` |
| **Code** | `PlayersRootView.swift`, `PlayerDetailView.swift`, `PlayersListViewModel.swift`, `PlayerDetailViewModel.swift`, `PlayerEditViewModel.swift`, `EditablePlayer.swift` |

---

## 16. Future Improvements (Post-1.0.0)
- Soft merge duplicates (combine two player identities safely)
- Expanded profile metadata (handedness, preferred game mode, league tags)
- Player-level streaks and advanced trend metrics
- Swift Charts dashboards:
  - win rate over time
  - X01 average trend
  - checkout efficiency by mode (single-out vs double-out)
  - Cricket closure pace
- CloudKit sync with conflict resolution
- DBPE import UI (export ships — [`PlayerExportImportSpec.md`](PlayerExportImportSpec.md))
- Team mode and grouped player entities

---

## 17. Open Questions for Adjacent Specs
- Should archived players appear in history filters by default or behind a toggle?
- Should hard delete ever be user-exposed, or only internal/debug?
- Which exact X01 average formula is canonical for all views?
- Should avatar/style snapshots be mandatory on all match participant records?
