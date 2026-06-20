# Post-1.0 Product Backlog

Lightweight capture of feature ideas. Deep assessments live in sibling files (`achievements.md`, `play-reminders.md`) or under `specs/`. Tracked in [`docs/release/todo.md`](../docs/release/todo.md).

---

## Data & recovery

| Idea | Notes |
|------|--------|
| **Export CSV when Recovery Required** | When the app surfaces Recovery Required, offer an export (match/events snapshot) so users can inspect or share data outside the app. |

---

## Accessibility

| Idea | Notes |
|------|--------|
| **Para darts / adaptive play feedback** | Reach out to players and orgs (e.g. [USAParaDarts](https://www.facebook.com/profile.php?id=100078819201080), Denver NC) for grounded accessibility feedback — not scheduled yet. Brief: [`para-darts-accessibility-outreach.md`](para-darts-accessibility-outreach.md). |
| **Dedicated gameplay layout at accessibility text sizes** | At large Dynamic Type (accessibility sizes and up), score and keyboard are not visible together. Define an accessibility-only layout variant for in-game screens so score and input remain usable without scrolling past each other. See also [`specs/AccessibilitySpec.md`](../specs/AccessibilitySpec.md), [`accessibility/accessibility_todo.md`](../accessibility/accessibility_todo.md). |

---

## Players & bots

| Idea | Notes |
|------|--------|
| ~~**More colors and symbols (Edit Player)**~~ | _Shipped._ Avatar set expanded to 16 symbols and the color palette to 18 tokens (`PlayerAvatarStyle` / `PlayerColorToken`), surfaced on the Edit Player pickers and localized across `en`/`de`/`es`/`nl`. |
| **Random bot names with clear difficulty** | Bots get varied display names while difficulty (Very Easy, Easy, Medium, …) stays obvious. Tier colors are fixed today (`PlayerVisualViews.botDifficultyColor`); numbered default names ship (`BotNaming`). Remaining: more varied name pools per tier. |
| ~~**Custom bot with user-defined metrics**~~ | _Shipped._ `CustomBotMetrics`, `createCustomBot`, setup roster + Players list UI, `CustomBotBadge`. |

---

## Gameplay & modes

| Idea | Notes |
|------|--------|
| **Visual dartboard input** | Touchable circular board as an alternative to the number pad; in-match + Settings presentation toggle. Assessment (not a completed spec): [`visual-dartboard-input.md`](visual-dartboard-input.md). |
| **More game types** | Baseball, Killer, and Shanghai shipped (see `GameModeCatalog`). Remaining: practice modes (Bob's 27, Around the Clock), Golf, Halve-It, and 23 planned catalog entries — [`additional-game-modes.md`](additional-game-modes.md). |
| **Custom / exclusive games** | Dart Buddy–only formats (voice, hidden state, ghost bots, remix orchestrator) — brainstorm: [`custom-games-brainstorm.md`](custom-games-brainstorm.md). |
| **Tournaments** | **P1:** local brackets ([`specs/TournamentSpec.md`](../specs/TournamentSpec.md)). **P2:** Firebase + online ([`specs/OnlinePlaySpec.md`](../specs/OnlinePlaySpec.md)). |
| **Online games** | **P2** — head-to-head sync first, then online tournaments. See [`specs/OnlinePlaySpec.md`](../specs/OnlinePlaySpec.md). |

---

## Notifications

| Idea | Notes |
|------|--------|
| **Push** | Play reminders / push notifications — assessment in [`play-reminders.md`](play-reminders.md) (local MVP first; FCM optional later). |

---

## Localization

| Idea | Notes |
|------|--------|
| **Additional languages** | `de`, `es`, and `nl` shipped (system locale). Next waves per [`specs/LocalizationSpec.md`](../specs/LocalizationSpec.md) — in-app language picker, pseudo-localization in CI, RTL readiness. |

---

## Related assessments (existing)

- [`achievements.md`](achievements.md) — Game Center achievements
- [`play-reminders.md`](play-reminders.md) — Local play reminders / push path
- [`talk-mode.md`](talk-mode.md) — Voice scoring input
- [`visual-dartboard-input.md`](visual-dartboard-input.md) — Visual board scoring input
