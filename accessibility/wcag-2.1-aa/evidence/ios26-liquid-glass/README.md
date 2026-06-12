# iOS 26 Liquid Glass — visual evidence

Baseline screenshots for **system navigation chrome** (tab bar, standard nav toolbars) on iOS 26+.

**Policy:** `DesignSystem/Tokens/SystemNavigationPolicy.swift` — do not override nav/tab materials on iOS 26; scoreboard content stays opaque on `Brand.background`.

**Capture:** `./Scripts/capture-ios26-liquid-glass.sh` (iPhone 17 Pro, iOS 26.x simulator by default).

| File | Screen |
|------|--------|
| `tab-play_*.png` | Play home (tab bar glass over brand content) |
| `tab-modes_*.png` | Modes catalog |
| `tab-players_*.png` | Players roster |
| `tab-activity_*.png` | Activity (History segment) |
| `tab-settings_*.png` | Settings root |

Re-run after navigation chrome changes. Pair with Reduce Transparency / Increase Contrast checks in `WCAGAccessibilityUITests` and release checklist §4.1.
