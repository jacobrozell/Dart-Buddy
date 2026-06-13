# Co-op Mode Grouping — Implementation Plan

**Status:** Phase 0 **done** · Slice 1 (Raid learn rules) **done** · Phase 1 (Raid engine) **not started**  
**Authoritative platform spec:** [`specs/CoopPvEModesSpec.md`](../../specs/CoopPvEModesSpec.md) — progress tracker §13  
**Flagship mode spec:** [`specs/game-modes/planned/RaidGameSpec.md`](../../specs/game-modes/planned/RaidGameSpec.md)

---

## Agent query (copy-paste)

Use this prompt to continue co-op grouping work in a fresh session:

```
Add the Co-op mode grouping to Dart Buddy using the work already landed.

## Already done (Phase 0 — do not redo)
- `GameModeSection.coop` + four catalog stubs: `coop.raid`, `coop.cerberus`, `coop.theVault`, `coop.clearTheBoard` in `Features/Modes/GameModeCatalog.swift`
- `ModeStatKind.bossRaid`, `coopHeist`; amber section accent for `.coop`
- Localization: `modes.section.coop`, `modes.catalog.coop.*` in en/de/es/nl + `Scripts/locale_data/*.json`
- Modes tab + Play setup picker show Co-op via `GameModeSection.allCases`
- Unit tests: 33 modes, 4 sections (`GameModeCatalogTests`, `GameModeSectionTests`)
- Platform spec: `specs/CoopPvEModesSpec.md` (UI §7, Learn to play §8, accessibility §9, light/dark §7.5)
- Per-mode rules specs use `coop.*` catalog ids

## Your task (pick scope explicitly)
**Scope A — Co-op browse polish (no Raid engine):**
1. Extend `GameModeCatalogEntry.hasRulesGuide` (or add `hasRulesPreview`) so planned co-op cards can show **Learn the rules** when `play.rules.{mode}.*` keys exist — start with Raid copy from `RaidGameSpec.md` § How to Play
2. Add `GameRulesCatalog.raid` + localization keys in all four locales
3. Verify Modes tab Co-op section: amber badges, coming-soon cards, VoiceOver labels, light/dark on `GameModeCatalogCard`
4. Update `specs/CoopPvEModesSpec.md` §13 checklist + §16 Verification

**Scope B — Ship Raid (full Phase 1):**
Implement per `specs/game-modes/planned/RaidGameSpec.md` and `specs/CoopPvEModesSpec.md` §14 promotion checklist:
- `MatchType.raid`, `RaidEngine`, setup chips, humans-only roster validation
- `RaidMatchScreen` + boss chrome (`coop_boss_hp_bar`, `coop_boss_phase_banner`, `coop_hero_hearts`)
- Co-op match summary (no winner card), history, Activity filter
- WCAG evidence: `accessibility/wcag-2.1-aa/screens/raid-match.md`
- Promote `coop.raid` to `.shipped` in catalog; update `docs/feature-inventory.md`

## Constraints
- Follow `specs/CoopPvEModesSpec.md` for roster (humans only on hero team), UI chrome, a11y, semantic `Brand.*` colors (light + dark)
- Do not move co-op modes back to `party.*` ids
- Match existing conventions in `ModesRootView`, `GameModeCatalogCard`, `GameRulesCatalog`
- Run unit tests for catalog/sections after changes; add UI/a11y tests when Raid UI lands

## References
- `docs/plans/coop-mode-grouping.md` (this plan)
- `specs/CoopPvEModesSpec.md` §13 progress tracker
- `specs/ModesTabSpec.md`, `specs/DesignSystemSpec.md`, `specs/AccessibilitySpec.md`
```

---

## 1. What Phase 0 delivered

| Area | Artifact |
|------|----------|
| Catalog | `GameModeSection.coop`; 4 planned entries between Party and Practice |
| Visual identity | `Brand.amber` fallback accent for unreleased co-op cards |
| Modes tab | Section header `modes.section.coop`; cards via `ModesRootView` + `GameModeCatalogCard` |
| Play setup | Co-op rows in `playSetupPickerSections()` when party modes visible |
| Localization | Section + 4× (name, blurb) in `en` / `de` / `es` / `nl` |
| Tests | Catalog count 33; partition across 4 sections; coop stub ids asserted |
| Specs | `CoopPvEModesSpec.md`; Raid/Cerberus/Vault/ClearTheBoard → `coop.*` |

**Not done yet:** playable co-op match, Learn rules on coming-soon cards, setup validation, boss chrome, co-op summary.

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

### Raid shipped (Slice 2)

- [ ] 1–3 humans can start Raid; bots rejected on roster
- [ ] Boss chrome + phase flow per `RaidGameSpec.md`
- [ ] Co-op summary — team outcome, no single-winner trophy
- [ ] History + Activity filter for Raid
- [ ] WCAG raid-match evidence doc + identifier tests
- [ ] `coop.raid` catalog `status == .shipped`

---

## 4. Key files

```
Features/Modes/GameModeCatalog.swift      # section + entries (done)
Features/Modes/ModesRootView.swift        # browse UI
Features/Modes/GameModeCatalogCard.swift  # card + learn rules
Features/Play/Rules/GameRulesCatalog.swift
specs/CoopPvEModesSpec.md                 # platform + §13 tracker
specs/game-modes/planned/RaidGameSpec.md
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
