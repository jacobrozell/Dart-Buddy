# Marketing Screenshots

Professional App Store and marketing assets for **Dart Buddy**.

## Quick start

```bash
# 1. Capture raw simulator screenshots (dark mode, iPhone 17 Pro)
./Scripts/capture-marketing-screenshots.sh

# 2. Wrap in device bezels (ImageMagick; frames auto-download on first run)
brew install imagemagick   # once
./Scripts/frame-marketing-screenshots.sh

# Optional: Deep Blue, Cosmic Orange, or Silver (iPhone 17 Pro)
FRAME_COLOR="Cosmic Orange" ./Scripts/frame-marketing-screenshots.sh
```

## Output folders

| Folder | Use |
|--------|-----|
| `raw/` | iPhone → **App Store Connect** (no bezels) |
| `ipad/raw/` | iPad 12.9" / 13" → **App Store Connect** |
| `framed/` | Website, social, press kit (with bezels) |

## App Store Connect dimensions

Upload **`raw/`** only (no device frames). For the **6.5" Display** slot, Apple accepts portrait:

- **1284 × 2778** (default after capture — `Scripts/app-store-screenshot-size.sh`)
- **1242 × 2688** — `APP_STORE_WIDTH=1242 APP_STORE_HEIGHT=2688 ./Scripts/capture-marketing-screenshots.sh`

iPhone 17 Pro simulators capture **1206 × 2622**; the capture script resizes to the size above unless `APP_STORE_RESIZE=0`.

For the **6.9" Display** slot, capture on **iPhone 17 Pro Max** (native **1320 × 2868**) and set `APP_STORE_RESIZE=0`, or use `APP_STORE_WIDTH=1320 APP_STORE_HEIGHT=2868` if you need an exact export from a smaller device.

Fix existing PNGs without re-capturing:

```bash
./Scripts/app-store-screenshot-size.sh resize marketing-screenshots/raw/*.png
```

## Screens captured (App Store priority)

1. **X01 match** — Jacob vs Sam, mid-game (`-snapshot_match_x01`)
2. **Cricket board** — marks and scoring (`-snapshot_match_cricket`)
3. **Match setup** — new game home (`-seed_demo`)
4. **Activity (History)** — completed matches (`-seed_demo -snapshot_tab activity`)
4b. **Modes** — game catalog (`-seed_demo -snapshot_tab modes`)
5. **Match summary** — post-game stats (`-snapshot_match_summary`)
6. **Players** — roster (`-seed_demo -snapshot_tab players`)
7. **Activity (Statistics)** — leaderboards (`-seed_demo -snapshot_tab activity -snapshot_activity_segment statistics`)
8. **Onboarding welcome** — first-launch tour (`-ui_test_onboarding`)
9. **Settings** — preferences shell (`-seed_demo -snapshot_tab settings`)

## iPad (12.9" / 13" Displays)

App Store accepts portrait **2064 × 2752** or **2048 × 2732** (and matching landscape sizes).

```bash
./Scripts/capture-ipad-marketing-screenshots.sh
# → marketing-screenshots/ipad/raw/*.png

# Light mode (captured 2026-06-02)
APPEARANCE=light ./Scripts/capture-ipad-marketing-screenshots.sh
```

Uses **iPad Pro 13-inch** simulator (native **2064×2752**). Upload from `ipad/raw/` only — no device frames.

## Options

```bash
# Light mode set (captured 2026-06-02 → raw/*-light.png)
APPEARANCE=light ./Scripts/capture-marketing-screenshots.sh

# 6.9" display (1320×2868 native; disable auto-resize)
SIM_NAME="iPhone 17 Pro Max" APP_STORE_RESIZE=0 ./Scripts/capture-marketing-screenshots.sh

# Alternate 6.5" size (1242×2688)
APP_STORE_WIDTH=1242 APP_STORE_HEIGHT=2688 ./Scripts/capture-marketing-screenshots.sh

# iPad 12.9" / 13" (2064×2752 — native on iPad Pro 13-inch simulator)
./Scripts/capture-ipad-marketing-screenshots.sh
```

## Launch arguments reference

| Screen | Arguments |
|--------|-----------|
| Reset + quiet | `-ui_test_reset -ui_test_disable_feedback -disable_firebase_analytics` |
| X01 in progress | `-snapshot_match_x01` |
| Cricket in progress | `-snapshot_match_cricket` |
| Demo data | `-seed_demo` |
| Match summary | `-snapshot_match_summary` |
| Tab | `-snapshot_tab play` / `modes` / `players` / `activity` / `settings` |
| Activity segment | `-snapshot_activity_segment statistics` (with `-snapshot_tab activity`) |
| Onboarding | `-ui_test_onboarding` (with `-ui_test_reset` for clean state) |

## Framing tips

- **App Store:** use files from `raw/` only — Apple rejects device frames in upload slots.
- **Marketing:** use `framed/` for a polished look; prefer dark mode to match the scoreboard chrome.
- **Transparency:** framed PNGs use a transparent background outside the device (place on any color in Figma/Keynote/web).
- **Colors:** iPhone 17 Pro — Deep Blue (default), Cosmic Orange, Silver
- **Captions:** add short benefit text in Figma/Keynote above framed exports if desired (keep under ~6 words per slide)

## Manual capture (Xcode)

1. Edit scheme → Run → Arguments: add `-ui_test_reset -snapshot_match_x01` (etc.)
2. Run on **iPhone 17 Pro** simulator
3. Simulator → **File → Save Screen** (⌘S)
