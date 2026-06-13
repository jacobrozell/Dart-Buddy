# Co-op Mode Grouping — Implementation Plan

**Status:** Phase 0 **done** · Slice 1 (Raid learn rules) **done** · Phase 1 (Raid engine/UI) **done** on `dev` · Phase 2 (platform extraction) **not started**  
**Authoritative platform spec:** [`specs/CoopPvEModesSpec.md`](../../specs/CoopPvEModesSpec.md) — progress tracker §13  
**Flagship mode spec:** [`specs/game-modes/implemented/RaidGameSpec.md`](../../specs/game-modes/implemented/RaidGameSpec.md)

---

## Agent query (copy-paste)

Use this prompt to continue co-op grouping work in a fresh session:

```
Continue co-op mode work on Dart Buddy.

## Already done (Phase 0 + Phase 1 — do not redo)
- `GameModeSection.coop` + four catalog entries: `coop.raid` (**shipped**), three planned stubs
- Raid playable: `RaidEngine`, `RaidMatchScreen`, `CoopBossChromeView`, co-op summary, Activity/history, forfeit
- Learn rules + localization for Raid in en/de/es/nl
- `docs/feature-inventory.md` + `specs/CoopPvEModesSpec.md` §13 synced (2026-06-13)

## Your task (pick scope explicitly)
**Scope A — Raid polish / a11y close-out:**
1. Manual VoiceOver pass (`accessibility/Manual_todo.md`)
2. AXXXL + landscape boss chrome evidence
3. UI test smoke for `coop_boss_hp_bar`, `coop_boss_phase_banner`, `coop_hero_hearts`
4. Promote `RaidGameSpec.md` → `specs/game-modes/implemented/`

**Scope B — Phase 2 platform extraction:**
- Reusable `BossParticipant` type; `bossRaid` stats reducer; shared co-op validation helpers

**Scope C — Next co-op mode (Cerberus / Vault / Clear the Board):**
Follow `specs/CoopPvEModesSpec.md` §14 promotion checklist.

## Constraints
- Follow `specs/CoopPvEModesSpec.md` for roster (humans only on hero team), UI chrome, a11y, semantic `Brand.*` colors (light + dark)
- Do not move co-op modes back to `party.*` ids
- Update `docs/feature-inventory.md` + `CoopPvEModesSpec.md` §13/§16 when ship status changes

## References
- `docs/plans/coop-mode-grouping.md` (this plan)
- `specs/CoopPvEModesSpec.md` §13 progress tracker
- `specs/ModesTabSpec.md`, `specs/DesignSystemSpec.md`, `specs/AccessibilitySpec.md`
```

---

## 1. What Phase 0 delivered

| Area | Artifact |
|------|----------|
| Catalog | `GameModeSection.coop`; Raid shipped + 3 planned entries between Party and Practice |
| Visual identity | `Brand.amber` fallback accent for unreleased co-op cards |
| Modes tab | Section header `modes.section.coop`; cards via `ModesRootView` + `GameModeCatalogCard` |
| Play setup | Co-op rows in `playSetupPickerSections()` when party modes visible |
| Localization | Section + 4× (name, blurb) in `en` / `de` / `es` / `nl` |
| Tests | Catalog count 34; partition across 4 sections; `coop.raid` shipped |
| Specs | `CoopPvEModesSpec.md`; Raid/Cerberus/Vault/ClearTheBoard → `coop.*` |

**Not done yet:** Phase 2 platform extraction; Cerberus / Vault / Clear the Board engines; Raid WCAG UI tests + manual VO evidence; spec file promotion `planned/` → `implemented/` for shipped modes.

---

## 2. Recommended next slices

### Slice 1 — Learn rules on planned co-op cards (low risk)

Unblocks Modes tab value before Raid engine exists.

| Step | Files |
|------|-------|
| Add `play.rules.raid.*` keys from `RaidGameSpec.md` § How to Play | `Resources/*/Localizable.strings`, `Scripts/locale_data/*.json` |
| Register `GameRulesCatalog.raid` | `Features/Play/Rules/GameRulesCatalog.swift` |
| Allow Learn button on planned `coop.raid` | `GameModeCatalog.swift` (`hasRulesGuide`), `ModesRootView` sheet (may need catalog-id-based guide) |
| Tests | Unit: guide resolves; UI: `modes_learnRules_coop.raid` |

Open decision §15.4 in `CoopPvEModesSpec.md`.

### Slice 2 — Raid MVP (Phase 1)

See `CoopPvEModesSpec.md` §13 Phase 1 table and `RaidGameSpec.md` implementation checklist.

| Layer | Primary paths |
|-------|----------------|
| Domain | `Domain/Engines/RaidEngine.swift`, `MatchType`, config payload |
| Setup | `MatchSetupViewModel`, `SetupHomeView`, `setup.validation.coopHumansOnly` |
| UI | `Features/Play/Raid/`, shared co-op chrome in `DesignSystem` or `Features/Play/Shared/` |
| Summary | Extend `MatchSummaryScreen` / `SoloPracticeMatchSummarySupplement` branch |
| Rules | `GameRulesCatalog.raid` (if Slice 1 not landed) |
| A11y | `accessibility/wcag-2.1-aa/screens/raid-match.md` |

### Slice 3 — Platform extraction (Phase 2)

After Raid ships: `BossParticipant`, `CoopMatchSummary`, shared validation, `bossRaid` stats.

---

## 3. Acceptance criteria

### Co-op grouping visible (Phase 0 — verify)

- [ ] Modes tab lists **Co-op** between Party and Practice with 4 coming-soon cards
- [ ] Search finds "Raid", "Vault", "Cerberus", "Clear the Board"
- [ ] Co-op cards use amber catalog badge; readable in light and dark
- [ ] VoiceOver announces section header + card blurb + player count + coming soon
- [ ] `GameModeCatalogTests` + `GameModeSectionTests` pass

### Co-op browse complete (Slice 1)

- [x] `coop.raid` card shows **Learn the rules**; sheet opens Raid guide
- [x] `play.rules.raid.*` exist in all four locales
- [x] `CoopPvEModesSpec.md` §13 updated; open decision #4 resolved

### Raid shipped (Slice 2) — **done on `dev`**

- [x] 1–3 humans can start Raid; bots rejected on roster (`setup.validation.coopHumansOnly`)
- [x] Boss chrome + phase flow per `RaidGameSpec.md`
- [x] Co-op summary — team outcome, no single-winner trophy
- [x] History + Activity filter for Raid
- [x] WCAG raid-match evidence doc (`accessibility/wcag-2.1-aa/screens/raid-match.md`) — **partial** manual evidence
- [x] `coop.raid` catalog `status == .shipped`
- [ ] UI test smoke for raid match identifiers

---

## 4. Key files

```
Features/Modes/GameModeCatalog.swift      # section + entries (done)
Features/Modes/ModesRootView.swift        # browse UI
Features/Modes/GameModeCatalogCard.swift  # card + learn rules
Features/Play/Rules/GameRulesCatalog.swift
specs/CoopPvEModesSpec.md                 # platform + §13 tracker
specs/game-modes/implemented/RaidGameSpec.md
Tests/Unit/GameModeCatalogTests.swift
Tests/Unit/GameModeSectionTests.swift
```

---

## 5. Related docs

| Doc | Role |
|-----|------|
| [`CoopPvEModesSpec.md`](../../specs/CoopPvEModesSpec.md) | Platform contract + progress §13 |
| [`ModesTabSpec.md`](../../specs/ModesTabSpec.md) | Modes tab behaviors |
| [`full-game-catalog-ui.md`](../full-game-catalog-ui.md) | Catalog wireframes |
| [`feature-inventory.md`](../feature-inventory.md) | Ship status mirror |

When behavior ships, update **CoopPvEModesSpec §13**, **§16 Verification**, and **feature-inventory** in the same PR.
