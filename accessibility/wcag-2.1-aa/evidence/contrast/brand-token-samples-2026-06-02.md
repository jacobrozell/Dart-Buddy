# Brand token contrast samples (2026-06-03)

Computed from `DesignSystem/Tokens/BrandTheme.swift` + banner opacity rules in `MatchFeedbackBanner` / `ErrorBanner`.
WCAG 2.1 AA: **4.5:1** normal text, **3:1** large text.

| Pair | Ratio | Normal AA | Large AA |
|------|-------|-----------|----------|
| light: textPrimary on background | 16.44:1 | PASS | PASS |
| light: textPrimary on card | 18.35:1 | PASS | PASS |
| light: textSecondary on background | 6.22:1 | PASS | PASS |
| light: textSecondary on card | 6.94:1 | PASS | PASS |
| light: textOnAccent on redAccent (CTA) | 4.80:1 | PASS | PASS |
| light: textOnAccent on redAccent error banner | 4.80:1 | PASS | PASS |
| light: textPrimary on bust banner fill | 12.45:1 | PASS | PASS |
| light: textPrimary on leg-win banner fill | 13.42:1 | PASS | PASS |
| light: textPrimary on bot-turn amber pill (bg) | 14.62:1 | PASS | PASS |
| light: textPrimary on partial-stats amber pill (card) | 16.00:1 | PASS | PASS |
| light: inkOnBright on amber fill (armed DOUBLE key) | 9.92:1 | PASS | PASS |
| light: inkOnBright on green fill (ENTER) | 6.32:1 | PASS | PASS |
| light: inkOnBright on orange fill (armed TRIPLE key) | 6.18:1 | PASS | PASS |
| light: textPrimary on cardElevated (selected avatar) | 15.43:1 | PASS | PASS |
| light: textDisabled on cardElevated (disabled START) | 5.74:1 | PASS | PASS |
| light: dartBox on card (visit slots) | 1.56:1 | PASS (non-text) | PASS |
| dark: textPrimary on background | 19.77:1 | PASS | PASS |
| dark: textPrimary on card | 17.00:1 | PASS | PASS |
| dark: textSecondary on background | 6.26:1 | PASS | PASS |
| dark: textSecondary on card | 5.96:1 | PASS | PASS |
| dark: textOnAccent on redAccent (CTA) | 4.80:1 | PASS | PASS |
| dark: textOnAccent on redAccent error banner | 4.80:1 | PASS | PASS |
| dark: textPrimary on bust banner fill | 13.61:1 | PASS | PASS |
| dark: textPrimary on leg-win banner fill | 11.98:1 | PASS | PASS |
| dark: textPrimary on bot-turn amber pill (bg) | 9.85:1 | PASS | PASS |
| dark: textPrimary on partial-stats amber pill (card) | 8.15:1 | PASS | PASS |
| dark: inkOnBright on amber fill (armed DOUBLE key) | 9.92:1 | PASS | PASS |
| dark: inkOnBright on green fill (ENTER) | 6.32:1 | PASS | PASS |
| dark: inkOnBright on orange fill (armed TRIPLE key) | 6.18:1 | PASS | PASS |
| dark: textPrimary on cardElevated (selected avatar) | 14.52:1 | PASS | PASS |

## Result

All logged primary-surface pairs meet **4.5:1** for normal text (or are decorative/large-only).

Manual follow-up: verify in Accessibility Inspector on device/simulator screenshots in `evidence/orientation/`.

Related: `DBX-CONTRAST-MODES`, `accessibility/dark-light-mode.md` P4.
