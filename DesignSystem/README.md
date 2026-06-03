# DesignSystem

Shared visual primitives for **DartBuddy**. Feature code should not hardcode spacing or brand colors outside these tokens.

## Token layers

| Symbol | File | Use when |
|--------|------|----------|
| **`Brand`** | `Tokens/BrandTheme.swift` | Scoreboard UI: backgrounds, cards, accents, text on brand surfaces |
| **`DS`** | `Tokens/DesignTokens.swift` | Spacing (`DS.Spacing`), corner radius (`DS.Radius`), and **semantic** colors for native UI (`DS.ColorRole`) |
| **`AppAppearancePolicy`** | `Support/State/AppAppearancePolicy.swift` | Maps user theme to `preferredColorScheme` and Settings chrome |
| **Chrome modifiers** | `Tokens/BrandChrome.swift` | `.brandScoreboardChrome`, `.brandSettingsScreenChrome`, `.brandSettingsFormChrome`, empty-state styling |
| **`GameplayLayout`** | `Components/GameplayLayout.swift` | iPad max width for list/setup screens |
| **`DynamicTypeSize` / `ScoringPadLabels`** | `Tokens/DynamicTypeLayout.swift` | AXXXL pad labels |

### Rules

1. On **brand scoreboard screens**, use `Brand.textPrimary` / `Brand.textSecondary` — not `DS.ColorRole.textPrimary` (system semantic).
2. Use **`DS.Spacing` / `DS.Radius`** everywhere for layout rhythm (brand and native screens).
3. **Settings (Light theme)** uses native `Form` → `DS.ColorRole` for secondary text is correct.
4. **Settings (Dark / System)** uses brand palette → `Brand.textSecondary`.
5. Do not add new `Color.red` / `.green` in features; use `Brand.red`, `Brand.green`, etc.

## Components

| Component | Role |
|-----------|------|
| `PrimaryActionButton` | Full-width CTA (START, primary actions) |
| `StartMatchCTAButton` | Empty-state “Start a Match” CTA (Statistics, History) |
| `BrandRootScreenTitle` / `BrandMatchScreenTitle` | Tab root vs in-match titles |
| `BrandSegmented` | Square-corner segmented control (mode, stats period) |
| `ScoringPadKey` / `ScoringPadStyle` | Shared square scoring-pad keys (X01 + Cricket) |
| `ErrorBanner` | Inline validation / error strip |
| `MatchFeedbackBanner` | Leg/bust/checkout feedback |
| `StatChip` | Compact stat label |
| `GameplayLayout` | Width helpers |

### Scoreboard shape policy

- **Scoring pad keys:** square (`Rectangle` via `ScoringPadStyle.keyShape`).
- **Cards, chips, banners, CTAs:** `DS.Radius.sm` (`RoundedRectangle`), not capsules.
- **Visit dart slots:** `DS.Radius.xs` (6pt).

## Related docs

- Appearance matrix & contrast: [`accessibility/dark-light-mode.md`](../accessibility/dark-light-mode.md)
- Engineering audit: [`docs/ios-code-audit.md`](../docs/ios-code-audit.md)
- Architecture boundaries: [`specs/ArchitectureSpec.md`](../specs/ArchitectureSpec.md)
