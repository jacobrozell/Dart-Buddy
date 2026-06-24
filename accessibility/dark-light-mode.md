# Dark / light mode tracker

Progress log for scoreboard theming (`Brand.*`), Settings appearance policy, and light-mode QA.

**Related:** `Support/State/AppAppearancePolicy.swift`, `DesignSystem/Tokens/BrandTheme.swift`, `DesignSystem/README.md`, `accessibility/Manual_todo.md` (contrast), `docs/release/release_checklist.md` §4 (4-way matrix).

**Legend:** `[ ]` todo · `[~]` in progress · `[x]` done

---

## Architecture (reference)

| Theme setting | Scoreboard tabs (Play, Players, Stats, History) | Settings |
|---------------|--------------------------------------------------|----------|
| **Light** | `Brand` light palette via `preferredColorScheme(.light)` | Native grouped light `Form` (no brand palette) |
| **Dark** | `Brand` dark palette | Brand dark form + nav chrome |
| **System** | Follows device (`Brand` dynamic colors) | **Always brand dark** (not device light) |

`MainTabView` applies global `preferredColorScheme`; scoreboard tabs also use `brandScoreboardChrome`.

---

## Screen coverage

| Screen / area | Brand tokens | Light OK (code) | Contrast verified | Notes |
|---------------|-------------|-----------------|-------------------|-------|
| Play setup | Yes | [x] | [x] | Matrix + token audit |
| X01 match | Yes | [x] | [x] | Matrix `evidence/orientation/` |
| Cricket match | Yes | [x] | [~] | Shared token audit |
| Match summary | Yes | [x] | [~] | Trophy/score sizes fixed at AXXXL |
| History list / detail | Yes | [x] | [~] | Shared token audit |
| Statistics | Yes | [x] | [~] | Shared token audit |
| Players list / detail | Yes | [x] | [~] | Search + empty states use `Brand` |
| Settings (theme = Light) | Native | [x] | [~] | Native form; token audit |
| Settings (theme = Dark / System) | Brand dark | [x] | [~] | System + light device = dark Settings |
| Player edit sheet | Mixed | [~] | [ ] | Native `Form`; pickers use `Brand` |
| Quick add player | Native | [~] | [ ] | No brand chrome |

---

## Fix backlog (from audit 2026-06-02)

### P1 — Contrast / tokens

- [x] Audit `Brand.textSecondary` on `Brand.card` / `background` (WCAG 4.5:1) — light secondary darkened
- [x] `MatchFeedbackBanner` — `textPrimary` on adaptive tint fills
- [x] `ErrorBanner` — `textOnAccent` on `red.opacity(0.88)`
- [x] `AvatarStylePicker` — `textOnAccent` on green selection
- [x] `PlayerColorTokenPicker` — `textOnAccent` checkmark on swatches

### P2 — Consistency on brand screens

- [x] `PlayersRootView` search field → `Brand`
- [x] `ContentUnavailableView` on brand backgrounds (`brandScoreboardEmptyState`)
- [x] iPad players empty state → `Brand.card`
- [x] `SetupHomeView` sticky shadow — lighter in light mode
- [x] System `.bordered` / `.borderedProminent` on Players / Settings error — `Brand` tints

### P3 — Product / policy

- [x] **System + light device**: keep dark Settings (documented in footer)
- [x] Align `settings.theme.footer` copy with Settings behavior
- [x] `PrimaryActionButton` — `Brand.textOnAccent`

### P4 — Evidence (ship)

- [x] 4-way matrix screenshots (`docs/release/release_checklist.md` §4) → `accessibility/wcag-2.1-aa/evidence/orientation/`
- [x] Log contrast samples under `accessibility/wcag-2.1-aa/evidence/contrast/`
- [x] Update `accessibility/wcag-2.1-aa/SUMMARY.md` DBX-CONTRAST-MODES rows

---

## Marketing / screenshots

- [x] Light iPhone: `marketing-screenshots/raw/*-light.png`
- [x] Light iPad: `marketing-screenshots/ipad/raw/*-light.png` (`APPEARANCE=light ./Scripts/capture-ipad-marketing-screenshots.sh`)
- [x] Dark framed reference exists (`marketing-screenshots/framed/…-dark-framed.png`)

---

## Changelog

| Date | Change |
|------|--------|
| 2026-06-02 | Initial tracker from light-mode code audit |
| 2026-06-02 | P1–P3 code fixes: tokens, banners, Players/Settings chrome, footer copy |
| 2026-06-02 | P4: contrast log, 4-way matrix script + captures, light marketing raw set |
| 2026-06-02 | Moved to `accessibility/dark-light-mode.md` |
