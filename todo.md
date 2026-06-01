# Dart Buddy — TODO

Goal: match the reference *Darts Scoreboard: Scorekeeper* app's functionality and feel — ad-free.

Status legend: `[x]` done · `[ ]` todo · `[~]` partial

---

## Done so far
- [x] Dark brand theme (black surfaces, green/red/amber accents), forced dark mode
- [x] Home/setup board: X01/Cricket pill, config chips, red START, player list, random order
- [x] X01 match board: player cards (active bar, big score, 3 dart boxes + visit total, sets/legs/darts/avg)
- [x] Per-dart number pad (1–25, DOUBLE/TRIPLE/0/undo) with auto-submit on 3 darts / checkout
- [x] X01 start scores 301 / 401 / 501 / 601
- [x] Statistics tab (Games / Wins / Win% with X01-Cricket + Today/7d/30d/All-time filters)
- [x] All Games list (dark cards, FINISHED badge, config line, per-player sets/legs/score)
- [x] Game Statistics detail (result card + Throws table with Double%/Triple% + turn timeline)
- [x] Players list restyle (dart icons, dark)
- [x] 5-tab shell in reference order (Home / Players / Statistics / All Games / Settings)
- [x] XCUITest target + tests for key paths (tabs, start+score, resume, undo)
- [x] Local MCP config (XcodeBuildMCP + ios-simulator) for build/run/UI automation

---

## High priority — core parity

### Cricket
- [ ] Cricket match board as a marks grid (15–20 + Bull columns per player, slash/circle marks)
- [ ] Tap-to-mark input (tap number to add a mark) instead of the X01-style pad
- [ ] Cricket-specific setup options (e.g. Cut Throat variant)
- [ ] Cricket stats: MPR (marks per round), cricket Wins in Statistics tab

### Game flow polish
- [ ] Checkout suggestion line on the board when a player is on a finish (≤170, valid out)
- [ ] Win / leg-won celebration + improved Match Summary screen (winner, averages, "New Match")
- [ ] Handle exit mid-match → mark as `abandoned` (currently stays `inProgress`)
- [ ] Per-dart bust feedback + leg/set transition animations

### Statistics & history depth
- [ ] Statistics: Legs table (Legs / Legs won / Legs win%) + 3-dart average column
- [ ] Statistics: filter by individual player
- [ ] Game Statistics detail: per-player hit-distribution bar charts (0–25, D, T) like the reference
- [ ] All Games: delete a game (swipe / trash) — needs a `deleteMatch` repository method
- [ ] All Games: "Best of / First to" + check-in/out in the config summary line

---

## Medium priority — setup & options
- [ ] Check-In modes: Straight In / Double In / Master In (engine + setup chip) — currently static "Straight In"
- [ ] Master Out checkout option (engine + setup) — currently Straight/Double only
- [ ] "First to" vs "Best of" for sets/legs (engine + setup chip) — currently static "First to"
- [ ] Persist last-used setup as defaults (wire Settings defaults ↔ setup screen both ways)
- [ ] Player reordering (drag handle) and remove-from-match on the setup roster
- [ ] Player avatars / colors (bot vs human styling)

---

## Larger features (reference has these)
- [ ] Bot opponent ("DartBot") with selectable difficulty
- [ ] AI camera auto-scoring (large — needs Vision/camera pipeline)
- [ ] External display / AirPlay scoreboard mode (TV as scoreboard)
- [ ] Voice caller ("One hundred and eighty!") + sound effects (wire up real Haptics/Audio services; currently no-ops)

---

## Quality & polish
- [ ] Localize new English strings (Statistics/All Games/board) via `Localizable.strings`
- [ ] VoiceOver labels + Dynamic Type passes on the new screens
- [ ] iPad / landscape layouts for board, setup, stats (board is portrait-tuned today)
- [ ] App icon: pick a candidate from `assets/app-icons/` and add an asset catalog
- [ ] Settings screen parity with reference + apply appearance preference (currently forced dark)

## Testing
- [ ] UI test: full checkout → winner → summary flow
- [ ] UI test: Cricket game once the grid board exists
- [ ] Unit tests: `StatisticsViewModel` aggregation + `HistoryListViewModel` standings/config decoding
- [ ] Snapshot tests for the new dark screens (light/dark, iPhone/iPad)

## Housekeeping
- [ ] Decide whether to keep the `-seed_demo` / `-seed_players` launch hooks (debug-only) long term
- [ ] Add `tmp/` (MCP screenshot output) to `.gitignore`
