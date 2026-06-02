# WCAG 2.1 AA compliance tracker

Living tracker for Dart Buddy MVP accessibility work. Target standard: **WCAG 2.1 Level AA** (see `specs/AccessibilitySpec.md`).

**Long-term work plan:** [`../accessibility_todo.md`](../accessibility_todo.md)  
**Manual verification checklist:** [`../Manual_todo.md`](../Manual_todo.md)

## How to use

1. **Roll up status** — Start at [`SUMMARY.md`](SUMMARY.md) for screen-level and criterion-level counts.
2. **Criterion definitions** — [`criteria.md`](criteria.md) maps WCAG success criteria to iOS checks and Dart Buddy engineering rules.
3. **Per-screen work** — Edit files under [`screens/`](screens/) when you implement or verify a screen.
4. **Evidence** — Store screenshots, VoiceOver notes, and Inspector exports under [`evidence/`](evidence/) (or link into `snapshots/` with filenames noted in the screen file).

## Status legend

| Status | Meaning |
|--------|---------|
| `Untested` | No manual verification; code may be incomplete. |
| `Partial` | Some requirements met; known gaps remain. |
| `Pass` | Verified for this screen/criterion (note date + device in Evidence). |
| `Fail` | Verified failure; fix tracked in Open work. |
| `N/A` | Criterion does not apply to this screen. |
| `Blocked` | Cannot test until dependency ships (e.g. localization). |

## Screen inventory

Maps to `specs/UIBlueprintSpec.md` §3 plus Statistics tab.

| Screen ID | Swift entry (primary) | Tracker |
|-----------|----------------------|---------|
| `play-home` | `PlayRootView` | [screens/play-home.md](screens/play-home.md) |
| `match-setup` | `SetupHomeView` | [screens/match-setup.md](screens/match-setup.md) |
| `x01-match` | `X01MatchScreen` | [screens/x01-match.md](screens/x01-match.md) |
| `cricket-match` | `CricketMatchScreen` | [screens/cricket-match.md](screens/cricket-match.md) |
| `match-summary` | `MatchSummaryScreen` | [screens/match-summary.md](screens/match-summary.md) |
| `history-list` | `HistoryRootView` | [screens/history-list.md](screens/history-list.md) |
| `history-detail` | `MatchHistoryDetailScreen` | [screens/history-detail.md](screens/history-detail.md) |
| `statistics` | `StatisticsRootView` | [screens/statistics.md](screens/statistics.md) |
| `players-list` | `PlayersRootView` | [screens/players-list.md](screens/players-list.md) |
| `player-detail` | `PlayersRootView` (detail route) | [screens/player-detail.md](screens/player-detail.md) |
| `player-edit` | `PlayersRootView` (sheet) | [screens/player-edit.md](screens/player-edit.md) |
| `settings` | `SettingsRootView` | [screens/settings.md](screens/settings.md) |
| `migration-recovery` | `MigrationRecoveryView` | [screens/migration-recovery.md](screens/migration-recovery.md) |

Shared UI used on multiple screens: [screens/_shared-components.md](screens/_shared-components.md).

## Related specs and gates

- `specs/AccessibilitySpec.md` — authoritative requirements
- `specs/UIReviewChecklist.md` §6–7 — PR accessibility + orientation gate
- `specs/SmokeTestChecklist.md` — AXXXL and VoiceOver smoke steps
- `roadmap/release/QA-Signoff-RC1.md` — release evidence matrix
- `accessibility/accessibility_todo.md` — a11y engineering phases
- `todo.md` § 1.0 QA sign-off — release accessibility evidence tasks

## Release rule

Do not mark **Overall: Pass** in `SUMMARY.md` until every **core flow** screen is `Pass` on all **Required** criteria and evidence is attached for VoiceOver, Dynamic Type (AXXXL), and 4-way appearance (portrait/landscape × light/dark) per `specs/AccessibilitySpec.md` §6–7.
