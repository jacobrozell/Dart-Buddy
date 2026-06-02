# Player Edit Sheet

| Field | Value |
|-------|-------|
| Screen ID | `player-edit` |
| Primary source | `Features/Players/PlayersRootView.swift`, `PlayerVisualViews.swift` |
| Core flow | No (tab) |
| Last verified | — |
| Screen status | `Partial` |

## Criterion checklist

| ID | Status | Implementation notes | Evidence |
|----|--------|----------------------|----------|
| P-1.1.1 | Pass | Avatar/color pickers labeled | `PlayerVisualViews.swift` |
| P-1.3.1 | Partial | Picker grids | |
| P-1.3.2 | Untested | | |
| P-1.3.4 | Untested | Sheet on iPad | |
| P-1.4.1 | Pass | Selected traits on pickers | |
| P-1.4.3 | Untested | | |
| P-1.4.4 | Untested | | |
| P-1.4.10 | Untested | | |
| P-1.4.11 | Untested | Color swatches | |
| O-2.4.3 | Untested | | |
| O-2.4.4 | Untested | Save/Cancel | |
| O-2.5.3 | Untested | | |
| DBX-TARGET-44 | Partial | Avatar grid cells — verify 44pt | |
| U-3.1.1 | Partial | Localized picker labels | |
| U-3.3.1 | Partial | Validation errors | |
| U-3.3.2 | Partial | Name field | |
| R-4.1.2 | Pass | `.isSelected` traits on pickers | |
| DBX-CONTRAST-MODES | Untested | | |

## Open work

- [ ] Name `TextField` accessibility label
- [ ] Verify color-only swatch has selected trait + label (not color alone)

## Verification log

| Date | Tester | Result | Notes |
|------|--------|--------|-------|
