# Accessibility screenshots

Simulator captures with **largest Dynamic Type** (`accessibility-extra-extra-extra-large`) for WCAG / release evidence.

## Capture

```bash
./Scripts/capture-accessibility-screenshots.sh
APPEARANCE=light ./Scripts/capture-accessibility-screenshots.sh
```

Also copies into `accessibility/wcag-2.1-aa/evidence/dynamic-type/` when linked from SUMMARY.

## Naming

`{device}-{screen}_{appearance}_{content-size}.png`

Example: `iphone-17-pro-match-setup_dark_accessibility-extra-extra-extra-large.png`

Screens captured: match setup, X01 match, cricket match, history, statistics, settings, onboarding welcome.
