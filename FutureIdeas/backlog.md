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
| **Dedicated gameplay layout at accessibility text sizes** | At large Dynamic Type (accessibility sizes and up), score and keyboard are not visible together. Define an accessibility-only layout variant for in-game screens so score and input remain usable without scrolling past each other. See also [`specs/AccessibilitySpec.md`](../specs/AccessibilitySpec.md), [`accessibility/accessibility_todo.md`](../accessibility/accessibility_todo.md). |

---

## Players & bots

| Idea | Notes |
|------|--------|
| ~~**More colors and symbols (Edit Player)**~~ | _Shipped._ Avatar set expanded to 16 symbols and the color palette to 18 tokens (`PlayerAvatarStyle` / `PlayerColorToken`), surfaced on the Edit Player pickers and localized across `en`/`de`/`es`/`nl`. |
| **Random bot names with clear difficulty** | Bots get varied display names while difficulty (Very Easy, Easy, Medium, …) stays obvious. **Define fixed colors per difficulty tier** so bot names always render in the tier color regardless of random name. |
| **Custom bot with user-defined metrics** | User-configurable bot opponent (skill/metrics) beyond preset tiers. |

---

## Gameplay & modes

| Idea | Notes |
|------|--------|
| **More game types** | Additional formats beyond current X01 / Cricket scope (variants, party modes, etc.). R&D specs: [`additional-game-modes.md`](additional-game-modes.md) (Killer, Baseball, 20+ modes from Target + [Darts Corner catalog](https://www.dartscorner.co.uk/blogs/how-to/what-darts-games-can-you-play)). |
| **Online games** | See [`specs/OnlinePlaySpec.md`](../specs/OnlinePlaySpec.md). |

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
