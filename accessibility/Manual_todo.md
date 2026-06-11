# Manual accessibility verification

Human-only checks that simulator AX-tree tools cannot complete. Tick items when done and link evidence under `accessibility/wcag-2.1-aa/evidence/`.

**Automated spot-checks:** see `evidence/voiceover/*-ax-spotcheck-*.md` (X01 + Cricket logged 2026-06-02; X01 less-is-more 2026-06-10; Cricket less-is-more 2026-06-11)

**Less-is-more plan:** `accessibility/voiceover-less-is-more-plan.md`

---

## VoiceOver — X01 match (`x01-match`)

- [ ] Focus order: score cards → checkout (when shown) → pad → header actions
- [ ] Leave match → Undo last turn → score 3 darts (hear visit on score card)
- [ ] Arm TRIPLE, score 20 — pad says “Triple 20”; score card visit says “Triple 20” not “T20”
- [ ] Bust: hear announcement only (`play.x01.bustFeedback`); banner is visual-only
- [ ] Checkout banner: hear update when route changes
- [ ] Leg won / match complete announcements
- [ ] Bot match: “Bot throwing…” banner; pad disabled + hint while bot plays

## VoiceOver — Match summary (`match-summary`)

- [ ] With **Reduce Motion** on: no trophy spring; header/stats still readable
- [ ] Header: winner name + match type in one swipe
- [ ] Each player row: stats read as one element (winner called out)
- [ ] Primary CTAs: New match, View game statistics

## VoiceOver — Cricket match (`cricket-match`)

- [ ] Focus order: board (active column) → pad → Cancel / state banner
- [ ] Active column: name, score, “Your turn” in one label (no per-visit darts/marks — see `evidence/voiceover/cricket-less-is-more-ax-spotcheck-2026-06-11.md`)
- [ ] **Mid-game spot-check:** after several visits, confirm column labels stay concise and marks remain discoverable via pad focus (not duplicated on every column swipe)
- [ ] Pad: “Triple 20”, “Miss”, “Double Bull” when modifiers armed
- [ ] Close a target (3 marks): hear closure / board updated announcement
- [ ] Bot match: pad disabled + bot banner (same pattern as X01)

## VoiceOver — Match setup / Play home (`match-setup`, `play-home`)

- [ ] Mode pill: X01 vs Cricket selected state
- [ ] Option chips: hear title + value (e.g. “Points, 501”)
- [ ] START disabled hint when fewer than two players
- [ ] Roster row: selected state + toggle hint
- [ ] Resume match banner (when active match exists)

## VoiceOver — History list (`history-list`)

- [ ] Mode/date segmented filters — selected state
- [ ] Player filter menu label
- [ ] Game row combined summary
- [ ] Load more / resume in-progress banner

## VoiceOver — Players list (`players-list`)

- [ ] Search field label
- [ ] Row: name + bot difficulty or win record
- [ ] Swipe archive / delete actions

## VoiceOver — Settings (`settings`)

- [x] Reset all data → confirmation → Cancel (AX spot-check + UI test — `evidence/voiceover/settings-reset-ax-spotcheck-2026-06-06.md`)
- [ ] Reset flow audio pass + destructive confirm execution (`evidence/voiceover/core-flow-settings-reset.md`)

## VoiceOver — Migration recovery (`migration-recovery`)

- [ ] Retry / Export / Reset buttons (`migration_retry`, `migration_export`, `migration_reset`)

## VoiceOver — Statistics (`statistics`)

- [ ] Player filter menu (`statsPlayerFilterMenu`)
- [ ] Partial-match banner when data incomplete
- [ ] Trend chart: each point reads value + date
- [ ] Stat table rows: combined label + value
- [ ] X01 / Cricket segmented filter — selected state

## VoiceOver — History detail (`history-detail`)

- [ ] Result card: mode, players, outcome in one swipe
- [ ] Show timeline toggle — on/off value
- [ ] Delete game: label + hint → confirmation alert
- [ ] Stat tables + sector chart sections

## VoiceOver — Player detail (`player-detail`)

- [ ] Identity card: name + bot difficulty
- [ ] Stat tiles: label + value per tile
- [ ] Recent match rows: mode, opponent, outcome, date
- [ ] Edit / archive toolbar actions

## VoiceOver — Player edit (`player-edit`)

- [ ] Name field label; notes field
- [ ] Avatar picker: selected trait + label
- [ ] Color swatches: 44pt targets, selected state
- [ ] Save (`players_edit_save`) / Cancel

## VoiceOver — Core flows (end-to-end)

- [ ] `play-home` → `match-setup` → **X01** → `match-summary`
- [ ] `play-home` → `match-setup` → **Cricket** → `match-summary`

## Dynamic Type (AXXXL)

- [ ] `match-setup` — roster, START, chips
- [ ] `x01-match` — remaining score + pad usable
- [ ] `cricket-match` — board + pad on phone
- [ ] `history-list`, `history-detail`, `statistics`, `players-list`, `player-detail`, `settings`
- [x] `settings` — automated Dynamic Type audit at AXXXL (`testSettingsPassesDynamicTypeAuditAtAXXXL`); capture `iphone-17-pro-settings_*_accessibility-extra-extra-extra-large.png`

## Contrast & appearance

- [ ] `Brand.textSecondary` on `Brand.card` / gameplay backgrounds (Inspector)
- [ ] Cricket navigation title readable (light on dark bar)
- [ ] Amber bot banner on dark background
- [ ] Light Settings vs dark Play surfaces (`DBX-CONTRAST-MODES`)

## Orientation (4-way matrix)

- [ ] Portrait + landscape × light + dark — setup, X01, Cricket (`evidence/orientation/`)

## Release evidence

- [ ] Copy or link AXXXL snapshots into `evidence/dynamic-type/`
- [ ] Update `roadmap/release/QA-Signoff-RC1.md` accessibility rows
