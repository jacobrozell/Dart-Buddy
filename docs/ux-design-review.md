# UI/UX Design Review

A whole-product design pass on **Dart Buddy** as it crosses from a focused
X01/Cricket scorekeeper into a multi-mode darts app (X01, Cricket, plus the
Baseball / Killer / Shanghai party modes, with Online Play, Apple Watch,
auto-scoring, achievements, campaign, and "talk" modes on the roadmap).

This is a **review and proposal** document, not a spec. Authoritative UX
contracts still live in [`specs/`](../specs/README.md); anything adopted here
should land in the relevant spec first. It is meant to be read alongside
[`DesignSystem/README.md`](../DesignSystem/README.md),
[`specs/DesignSystemSpec.md`](../specs/DesignSystemSpec.md), and
[`FutureIdeas/backlog.md`](../FutureIdeas/backlog.md).

> **Scope note:** Grounded in the current source (Brand/DS tokens, the
> `SetupHomeView` cluster, `MainTabView`, X01/Cricket match screens). The
> images under `marketing-screenshots/` are **stale** — they show the old
> "Dart Scoreboard" title and saturated green/red option chips that the code
> has since replaced with neutral `Brand.key` chips. See finding **D9**.

---

## TL;DR — what to change and why

The app's bones are good: a coherent token system, strong accessibility/Dynamic
Type handling, square-key scoring pads, and consistent gameplay screens. The
pressure points are all **scaling** pressure points — the places that worked at
2 modes and 5 tabs and start to strain at 5+ modes and a growing feature set.

The five highest-leverage moves, in order:

1. **Collapse the two parallel color systems** (`Brand` vs `DS.ColorRole`) into
   one semantic token layer, and stop overloading green/red. (§D1)
2. **Rebuild match setup around a scalable game-mode model** instead of nested
   `Standard | Party` + per-mode chip clusters. (§A2, §B1)
3. **Reconsider the 5-tab bar** — merge History into Statistics, and make the
   Play tab a light **Home** instead of a config form. (§A1)
4. **Give every game mode a formal accent identity** so modes stay legible as
   they multiply across setup, history, and stats. (§D2)
5. **Refresh the stale marketing screenshots** and wire screenshot generation
   to the real current UI. (§D9)

Everything below is organized as **A. Information architecture**, **B. Setup &
flows**, **C. Gameplay & screens**, **D. Design system & visual language**,
**E. Future-facing direction**, then a **prioritized roadmap**.

---

## A. Information architecture & navigation

### A1. The 5-tab bar is at capacity, and one slot is mis-cast

Today: `Play · Players · Statistics · History · Settings` (`App/MainTabView.swift`).

Two problems:

- **Statistics and History are the same mental model** — "look back at what
  happened." They already share filter chrome (player filter, period filter,
  mode filter). Users bounce between them to answer one question. Merging them
  into a single **Activity** (or **Stats**) tab with a segmented
  `Overview | History` header frees a tab slot and removes the duplicated
  filter bars.
- **"Play" is a house icon over a setup *form***. The home metaphor promises a
  landing/dashboard; the screen delivers a scroll of mode pickers and option
  chips. Either the icon should match the screen (`target` / a dartboard glyph)
  or — better — the screen should become a real Home (see A3).

**Proposal:** `Home · Players · Stats · Settings` (4 tabs) for 1.x, with the
freed slot reserved for the first social/online surface (**Friends** or
**Online**) when `OnlinePlaySpec` lands. Four tabs also leaves the
`.badge` affordance (active-match indicator) less crowded.

### A2. The `Standard | Party` split won't survive more modes

`SetupHomeView` branches on `setupCategory` (`.standard` → X01/Cricket mode
segmented control; `.party` → `PartyGamePickerView`). The split is arbitrary
from a player's point of view — Cricket and Shanghai are both "stand around a
board and score," and the line blurs further with each new mode. It also forces
a two-step taxonomy (category, *then* mode) onto every launch.

**Proposal:** one flat, scrollable **game-mode catalog** (cards or a grid),
each mode carrying its own icon, accent, one-line description, and player-count
range. "Standard / Party / Practice" become *filters or section headers*, not a
mode-blocking segmented control. This is also where Campaign and Online modes
slot in cleanly later.

### A3. Make Play a Home, not a form

A scaled darts app's most common intent is "play again," not "configure a match
from scratch." The resume banner already hints at this. A light Home would lead
with:

- **Resume / Active match** (already exists — promote it).
- **Quick rematch** of the last roster+mode (one tap to the board).
- **Recent games** strip (already in `PlayHomeSpec`).
- A **"New match"** entry that opens the mode catalog (A2).
- Hooks for future surfaces: daily challenge, streak, achievement nudges.

Setup becomes a *destination you push to*, not the tab root. This removes the
"land on a wall of chips" first impression and gives the roadmap features a
natural home.

### A4. One canonical "active match" surface

The resume banner currently renders in **both** Play setup
(`SetupHomeView.resumeBanner`) and History (`HistoryRootView`), and the active
match drives a History tab badge. That's three places expressing one state.
Consolidate to a single persistent affordance (a Home hero card + the tab
badge), so "you have a match in progress" reads identically everywhere.

---

## B. Setup & flows

### B1. Setup density and the chip-cluster sprawl

`SetupHomeView` is one long scroll: category control → mode control → learn-to-play
→ per-mode option chips → random-order toggle → add bot/player → turn-order list
→ available-player list → sticky Start. The per-mode options already span six
files (`SetupHomeView+OptionChips`, `+CricketOptionChips`, `+KillerOptionChips`,
`+BaseballOptionChips`, `+ShanghaiOptionChips`, `+ShanghaiOptionChips`). Every
new mode adds another extension and more vertical scroll.

**Proposals:**

- **Separate "what to play" from "who plays."** A mode-config step (options for
  the chosen mode) and a roster step read far better than one merged scroll,
  and each scales independently. On iPad this becomes a natural two-pane layout
  (config left, roster right) instead of today's width-capped single column.
- **Make options progressive.** Most launches use defaults. Show a compact
  summary line ("501 · Double Out · First to 3 legs") with an **Edit** that
  expands the chip grid, rather than always rendering every chip. Defaults live
  in Settings already — lean on them.
- **Normalize the option control.** The chips are `Menu`-backed dropdowns
  styled as tappable boxes with a tiny `chevron.down` in the corner. The tap
  target reads like a button but behaves like a picker. Either use a clearly
  picker-shaped control or a labeled stepper for numeric values (sets/legs),
  so the affordance matches the behavior.

### B2. Turn-order vs. roster is a subtle two-list model

Setup shows a draggable **turn-order** list *and* an **available players** list,
plus a separate `randomOrder` toggle that invalidates manual ordering. Three
controls govern "who's in and in what order." Consider a single roster list
where selected players sort to the top and drag-to-reorder is inline, with
"Randomize order" as a one-shot action (shuffle button) rather than a mode
toggle that hides the ordering you just set.

### B3. "Add Bot" menu is deep

Bots come from a nested `Menu` with Training / Custom / preset-difficulty
sections. As bot types grow (custom metrics, training partners per player),
a dedicated **opponent picker sheet** with search, avatars, and difficulty
badges will scale better than a long context menu — and it can preview skill.

---

## C. Gameplay & screens

Gameplay is the strongest part of the app — keep its restraint. Refinements:

### C1. Strengthen the active-player signal

The active player is shown via a 6pt accent bar + accent-colored name
(`PlayerScoreCard`). On a busy board with 3–4 players this is easy to lose.
Add a second, redundant cue — a subtle card elevation or full accent border on
the active card — so the "whose turn" read survives glance-and-look-away and
color-vision differences.

### C2. Checkout suggestion deserves more presence

The checkout route is a small caption-weight banner. For X01 it's one of the
most-looked-at pieces of information near the end of a leg. Consider giving it a
persistent slot near the active player's remaining score (not only the inline
banner), so eyes don't have to hunt between the pad and the card.

### C3. Modifier "armed" state on the pad

DOUBLE/TRIPLE arm-then-tap is correct, and the selected state uses a bright
fill. Because the modifier auto-resets to single after each dart, a first-time
user can miss that the bright state is transient. A brief pulse/label ("next
dart ×2") on arm would teach the model without a tutorial. Validate against the
existing scoring-pad UI tests before changing key visuals.

### C4. Players & Stats clarity

- **Players list** uses cryptic micro-stats (`2G · 2W`). Spell out or
  icon-label them (a small games/wins glyph), or move to a single most-useful
  stat (e.g. 3-dart average) that reads at a glance.
- **Statistics** is currently table-forward (Games table, Average & Highest
  table). You already have `StatsChartViews` — lead the tab with one **hero
  trend** (e.g. 3-dart average over time) before the tables, so the screen
  feels like insight rather than a spreadsheet. Sparklines in the per-player
  rows would carry a lot of meaning cheaply.

### C5. History rows

History cards pack date, mode, config, two rosters, and sets/legs. The
hierarchy is flat — date and result compete. Lead each row with the **outcome**
(winner + score), demote the timestamp to secondary, and use the mode accent
(see D2) as a leading color rail so modes are scannable in a long list.

---

## D. Design system & visual language

### D1. Collapse the two color systems; stop overloading green/red

There are two parallel palettes — `Brand.*` (scoreboard) and `DS.ColorRole.*`
(native/Settings) — governed by a page of prose rules in
`DesignSystem/README.md` ("on brand screens use `Brand.textPrimary`, not
`DS.ColorRole.textPrimary`…"). Rules-by-convention are exactly what breaks as
contributors and screens multiply.

Compounding it, the accents are **semantically overloaded**:

- **Green** = brand accent **and** success **and** primary CTA **and**
  add-player **and** active-player tint **and** the global `.tint`.
- **Red** = destructive **and** undo **and** error.

When one color means five things, it stops communicating.

**Proposal:** one semantic token layer that both native and brand surfaces draw
from, with **roles split from brand**:

```
color/
  surface           (was Brand.background)
  surface-card      (was Brand.card)
  surface-elevated  (was Brand.cardElevated)
  content-primary / content-secondary / content-on-accent / ink-on-bright
  accent-brand      (the green — identity only)
  action-primary    (CTA fill; can == accent-brand, but named for its role)
  positive / negative / warning / info   (status, never decoration)
```

Concretely: undo should not be `red` (it's not destructive), the "add players"
button being brand-green while Start is also brand-green flattens the hierarchy,
and status colors (`positive`/`negative`) should never be reused as chip
decoration. This is a mechanical token rename plus a small audit, and it
deletes most of the README's "use X not Y on screen Z" prose.

### D2. Give each game mode a formal accent identity

You already have `Brand.proBot` (purple), `amber`, `orange`, `green`, `red` as
ad-hoc accents. As modes multiply, formalize a **per-mode accent** token
(`mode/x01`, `mode/cricket`, `mode/baseball`, `mode/killer`, `mode/shanghai`,
…). Used as a leading rail/icon tint in the mode catalog (A2), history rows
(C5), and stats filters, it lets players parse "which game" pre-attentively
everywhere. This is the single best investment for a multi-mode future.

### D3. Lean (lightly) into a dartboard motif for identity

The visual language is competent but generic — neutral grays + one green. The
only real brand moment is the app icon. A darts app has a gift: the **board's
own palette** (the segment red/green, the cream/black wedges, the bull).
Used sparingly — an empty-state illustration, the Home hero, the splash, a
subtle wedge texture behind the title — it would give the app a recognizable
identity without touching the deliberately calm gameplay screens.

### D4. Tokenize elevation & shadow

Cards are flat fills today; the only shadow is the setup sticky-footer
(`setupStickyShadowColor`, hand-rolled per color scheme). If elevation becomes a
UI cue (e.g. active-player card in C1), add an `elevation` token set so shadows
are consistent and not re-derived per view.

### D5. Component inventory & a living catalog

The component set (`PrimaryActionButton`, `BrandSegmented`, `ScoringPadKey`,
`StatChip`, banners…) is healthy. Two gaps worth filling as the team grows:

- There's no in-repo **visual catalog**. A SwiftUI `#Preview` gallery (or a
  hidden dev screen) showing every component in light/dark × Dynamic Type would
  catch regressions the stale screenshots can't.
- **Empty states** are one-off `Text` blocks (e.g. `availablePlayerList`'s
  "players empty" hint). Promote to a single `EmptyState` component (icon +
  title + message + optional CTA) and reuse across Players/Stats/History.

### D6. Numeric typography

Scores use rounded-heavy system font; the pad visit preview uses
`monospacedDigit`. Make **all** live-scoring numerics monospaced-digit so totals
don't jitter as they change. Small, high-polish.

### D7. Consistent shape language is good — document the exceptions

The README's shape policy (square pad keys; `Radius.sm` cards; `Radius.xs` dart
slots) is a real strength. Keep it, and add the two newer surfaces (mode catalog
cards, opponent picker) to that policy so they don't drift.

### D8. iPad is width-capped, not laid out

`GameplayLayout.contentMaxWidth` centers a phone-width column on iPad. That's
safe but leaves the platform unused. The setup two-pane (B1) and a
master-detail History/Stats are the natural iPad wins once the IA settles.

### D9. The marketing screenshots are stale — and that's a process gap

`marketing-screenshots/` shows the old "Dart Scoreboard" wordmark and the
retired green/red option chips. Beyond regenerating them, wire screenshot
capture to the real current UI (the snapshot launch args already exist:
`-snapshot_tab`) so store assets can't silently drift from the shipping design
again.

---

## E. Future-facing direction

How the design should bend toward the roadmap (`FutureIdeas/`, `specs/` post-1.0):

- **Online play / Friends** (`OnlinePlaySpec`): needs the freed tab slot (A1)
  and identity/presence affordances (avatars already exist; add online status,
  invites). The mode catalog (A2) should treat "Online X01" as a mode entry,
  not a separate app mode.
- **Apple Watch companion** (`AppleWatchCompanionSpec`): the scoring pad and
  score card must degrade to a glanceable, large-target subset. Designing the
  **minimum scoring unit** now (one player's remaining + a number entry) keeps
  phone and watch coherent.
- **Auto-scoring / vision** (`AutoScoringVisionSpec`): introduces a camera/live
  state the current pad-centric layout has no room for. Reserve a gameplay
  "input mode" concept (manual pad ↔ auto) in the design language early so it
  isn't bolted on.
- **Achievements / Game Center** (`FutureIdeas/achievements.md`): wants a
  surface — the Home dashboard (A3) and Player detail are the homes. Define an
  achievement **badge/medal** component under the new mode-accent system (D2).
- **Campaign mode** (`FutureIdeas/campaign-mode.md`): a progression UI (map /
  ladder) is a brand-new pattern — the dartboard motif (D3) is where its
  identity should come from.
- **Talk mode** (`FutureIdeas/talk-mode.md`) & richer audio: surface a clear,
  consistent **audio/feedback status** affordance in-game rather than burying it
  in Settings.
- **More languages + RTL** (`LocalizationSpec`): the token + component
  consolidation (D1, D5) is what makes RTL and an in-app language picker cheap.

The through-line: **a formal mode model (A2 + D2) and a consolidated token
system (D1)** are the two foundations every roadmap item leans on. Do those
first and the rest get cheaper.

---

## Implemented in this PR (foundation)

A first, deliberately low-risk slice — additive tokens/polish that don't
restructure tested flows — landed alongside this review:

- **D2 (foundation)** — `GameModeAccent` token (`DesignSystem/Tokens/GameModeAccent.swift`):
  a per-mode identity accent + SF Symbol, plus a `GameModeBadge` view, drawn from
  the existing `Brand` palette and registered in `DesignSystem/README.md` with an
  "identity, never status" rule. First adoption: a mode badge on each History row
  (`MatchHistoryCard`). Remaining adoptions (mode catalog, stats filters) follow
  once those surfaces are built.
- **D6** — Monospaced digits on live-scoring numerics in the X01 `PlayerScoreCard`
  (remaining score, visit total, darts, average) and History result scores, so
  totals don't jitter as they change. Same one-line treatment can extend to the
  Cricket/Baseball/Killer/Shanghai scoreboards as a follow-up.

The larger structural items below intentionally remain proposals: they need
build/UI-test verification and, per `SpecGovernance`, a spec update first.

## Prioritized roadmap

### Quick wins (low risk, high polish — mostly token/visual)
- ~~**D6** Monospaced digits on live-scoring numerics.~~ *(started — X01 + History)*
- **D9** Regenerate marketing screenshots from current UI.
- **C1** Stronger active-player cue (border/elevation).
- **C4** Spell out / icon-label Players micro-stats.
- **A4** Single canonical active-match affordance.

### Structural (sequence deliberately; touch specs first)
- **D1** Consolidate `Brand` + `DS.ColorRole` into one semantic token layer;
  split status colors from brand/action.
- ~~**D2** Per-mode accent tokens.~~ *(token + first adoption landed; wire into
  the mode catalog and stats filters as those surfaces ship)*
- **D5** A `#Preview` component gallery (empty states already covered by
  `ContentUnavailableView` + `brandScoreboardEmptyState()`).

### Flow & IA (bigger UX shifts — prototype before committing)
- **A2 / B1** Game-mode catalog + split setup (what to play / who plays).
- **A1 / A3** 4-tab bar; Play becomes Home; merge History into Stats.
- **B2 / B3** Unified roster + reorder; opponent picker sheet.

### Platform & future (gated on roadmap specs)
- **D8** iPad two-pane setup and master-detail Stats/History.
- **E** Watch minimum-scoring-unit, online/friends tab, auto-scoring input mode,
  achievements surface, campaign identity.

---

*Process note:* none of this should ship straight to UI. Per
[`specs/SpecGovernance.md`](../specs/SpecGovernance.md), adopted items update
the relevant spec (and `UIBlueprintSpec` / `DesignSystemSpec`) first, then code,
then the screenshot refresh closes the loop so the documented design and the
shipping design stay in sync.
</content>
</invoke>
