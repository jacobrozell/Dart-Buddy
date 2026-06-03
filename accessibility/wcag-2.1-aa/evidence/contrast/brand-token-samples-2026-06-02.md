# Brand token contrast samples (2026-06-03)

Computed from `DesignSystem/Tokens/BrandTheme.swift` + banner opacity rules in `MatchFeedbackBanner` / `ErrorBanner`.
WCAG 2.1 AA: **4.5:1** normal text, **3:1** large text.

| Pair | Ratio | Normal AA | Large AA |
|------|-------|-----------|----------|
| light: textPrimary on background | 16.44:1 | PASS | PASS |
| light: textPrimary on card | 18.35:1 | PASS | PASS |
| light: textSecondary on background | 6.22:1 | PASS | PASS |
| light: textSecondary on card | 6.94:1 | PASS | PASS |
| light: textOnAccent on red (CTA) | 3.94:1 | FAIL | PASS |
| light: textOnAccent on error banner fill | 3.47:1 | FAIL | PASS |
| light: textPrimary on bust banner fill | 12.45:1 | PASS | PASS |
| light: textPrimary on leg-win banner fill | 13.42:1 | PASS | PASS |
| light: textPrimary on cardElevated (selected avatar) | 15.43:1 | PASS | PASS |
| dark: textPrimary on background | 19.77:1 | PASS | PASS |
| dark: textPrimary on card | 17.00:1 | PASS | PASS |
| dark: textSecondary on background | 6.26:1 | PASS | PASS |
| dark: textSecondary on card | 5.96:1 | PASS | PASS |
| dark: textOnAccent on red (CTA) | 3.94:1 | FAIL | PASS |
| dark: textOnAccent on error banner fill | 4.84:1 | PASS | PASS |
| dark: textPrimary on bust banner fill | 13.61:1 | PASS | PASS |
| dark: textPrimary on leg-win banner fill | 11.98:1 | PASS | PASS |
| dark: textPrimary on cardElevated (selected avatar) | 14.52:1 | PASS | PASS |

## Result

**Review required** for pairs marked FAIL (normal text):
- light: textOnAccent on red (CTA)
- light: textOnAccent on error banner fill
- dark: textOnAccent on red (CTA)

Related: `DBX-CONTRAST-MODES`, `accessibility/dark-light-mode.md` P4.
