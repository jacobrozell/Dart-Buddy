# Accessibility screenshots

Simulator captures with **largest Dynamic Type** (`accessibility-extra-extra-extra-large`) for WCAG / release evidence.

## Capture

Portrait (default):

```bash
./Scripts/capture-accessibility-screenshots.sh
APPEARANCE=light ./Scripts/capture-accessibility-screenshots.sh
```

Landscape (AXXXL + `-snapshot_orientation landscape`):

```bash
./Scripts/capture-accessibility-screenshots-landscape.sh
APPEARANCE=light ./Scripts/capture-accessibility-screenshots-landscape.sh
SIM_NAME="iPad Pro 13-inch (M5)" ./Scripts/capture-accessibility-screenshots-landscape.sh
```

Also copies into `accessibility/wcag-2.1-aa/evidence/dynamic-type/` when linked from SUMMARY.

## Naming

Portrait: `{device}-{screen}_{appearance}_{content-size}.png`

Example: `iphone-17-pro-match-setup_dark_accessibility-extra-extra-extra-large.png`

Landscape: same pattern with `-landscape` before `.png`, under `landscape/` (iPhone) or `ipad/landscape/` (iPad).

Example: `landscape/iphone-17-pro-match-setup_dark_accessibility-extra-extra-extra-large-landscape.png`

## Screens captured

1. Match setup (`-seed_demo`)
2. X01 match (`-snapshot_match_x01`)
3. Cricket match (`-snapshot_match_cricket`)
4. Activity — History (`-seed_demo -snapshot_tab activity`)
5. Activity — Statistics (`-seed_demo -snapshot_tab activity -snapshot_activity_segment statistics`)
6. Modes catalog (`-seed_demo -snapshot_tab modes`)
7. Settings (`-seed_demo -snapshot_tab settings`)
8. Onboarding welcome (`-ui_test_onboarding`)
