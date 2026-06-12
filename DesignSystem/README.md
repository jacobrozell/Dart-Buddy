# DesignSystem

Shared visual primitives for **DartBuddy**. Feature code should not hardcode spacing or brand colors outside these tokens.

## Token layers

| Symbol | File | Use when |
|--------|------|----------|
| **`Brand`** | `Tokens/BrandTheme.swift` | Scoreboard UI: backgrounds, cards, accents, text on brand surfaces |
| **`DS`** | `Tokens/DesignTokens.swift` | Spacing (`DS.Spacing`), corner radius (`DS.Radius`), and **semantic** colors for native UI (`DS.ColorRole`) |
| **`AppAppearancePolicy`** | `Support/State/AppAppearancePolicy.swift` | Maps user theme to `preferredColorScheme` and Settings chrome |
| **Chrome modifiers** | `Tokens/BrandChrome.swift` | `.brandScoreboardChrome`, `.brandSettingsScreenChrome`, `.brandSettingsFormChrome`, empty-state styling |
| **`SystemNavigationPolicy`** | `Tokens/SystemNavigationPolicy.swift` | iOS 26+ system Liquid Glass for nav/tab chrome; legacy opaque toolbar helpers for iOS 18–25 |
| **`Motion` / `MotionPolicy`** | `Tokens/MotionPolicy.swift` | Durations, curves, reduce-motion gate — see [`specs/AnimationSpec.md`](../specs/AnimationSpec.md) |
| **`GameplayLayout`** | `Components/GameplayLayout.swift` | Phone vs iPad match/setup/tab layout predicates — see [`docs/gameplay-layout-modes.md`](../docs/gameplay-layout-modes.md) |
| **`GameModeAccent`** | `Tokens/GameModeAccent.swift` | Per-mode **identity** accent + SF Symbol (catalog, history rows, stats filters) |
| **`DynamicTypeSize` / `ScoringPadLabels`** | `Tokens/DynamicTypeLayout.swift` | AXXXL pad labels |

### Rules

1. On **brand scoreboard screens**, use `Brand.textPrimary` / `Brand.textSecondary` — not `DS.ColorRole.textPrimary` (system semantic).
2. Use **`DS.Spacing` / `DS.Radius`** everywhere for layout rhythm (brand and native screens).
3. **Settings (Light theme)** uses native `Form` → `DS.ColorRole` for secondary text is correct.
4. **Settings (Dark / System)** uses brand palette → `Brand.textSecondary`.
5. Do not add new `Color.red` / `.green` in features; use `Brand.red`, `Brand.green`, etc.
6. For **per-mode** color/glyph (history rows, the mode catalog, stats filters), use `GameModeAccent` — it is **identity**, never status. Do not reuse it as `positive`/`negative`/`warning`.

### Navigation vs content layer (iOS 26 Liquid Glass)

- **System navigation layer** (tab bar, `NavigationStack` toolbars, sheets, alerts): on iOS 26+, let SwiftUI render Liquid Glass. Do not set opaque `.toolbarBackground` or hide the system bar material.
- **Brand content layer** (scoreboard tabs, match UI, cards, scoring pads, segmented controls): stay **opaque** on `Brand.background` / `Brand.card`. Use `SystemNavigationPolicy` helpers instead of per-screen `#available` checks.
- **Accessibility:** with Reduce Transparency, iOS replaces glass with opaque system fallbacks — keep content contrast on brand surfaces; do not add custom `.glassEffect` workarounds.

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
| `MotionEntrance` | `motionBannerEntrance()`, `motionTabContentReveal(when:)`, `motionStaggeredReveal`, `motionMarkIncrementPulse`, `motionNumericScore` |
| `StatChip` | Compact stat label |
| `GameModeBadge` | Leading mode glyph (tinted square) for rows/cards |
| `GameplayLayout` | Width helpers |

### Scoreboard shape policy

- **Scoring pad keys:** square (`Rectangle` via `ScoringPadStyle.keyShape`).
- **Cards, chips, banners, CTAs:** `DS.Radius.sm` (`RoundedRectangle`), not capsules.
- **Visit dart slots:** `DS.Radius.xs` (6pt).

## Related docs

- Appearance matrix & contrast: [`accessibility/dark-light-mode.md`](../accessibility/dark-light-mode.md)
- Engineering audit: [`docs/ios-code-audit.md`](../docs/ios-code-audit.md)
- Architecture boundaries: [`specs/ArchitectureSpec.md`](../specs/ArchitectureSpec.md)
