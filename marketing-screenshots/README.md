# Marketing Screenshots

Professional App Store and marketing assets for **Dart Buddy**.

## Quick start

```bash
# 1. Capture raw simulator screenshots (dark mode, iPhone 17 Pro, portrait + landscape)
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

Upload **`raw/`** only (no device frames).

**Portrait** (6.5" iPhone slot):

- **1284 × 2778** (default after capture — `Scripts/app-store-screenshot-size.sh`)
- **1242 × 2688** — `APP_STORE_WIDTH=1242 APP_STORE_HEIGHT=2688 ./Scripts/capture-marketing-screenshots.sh`

**Landscape** (same slot, dimensions swapped):

- **2778 × 1284** (default after capture)
- **2688 × 1242** — set portrait sizes above; landscape export swaps automatically

iPhone 17 Pro simulators capture **1206 × 2622** portrait; the capture script resizes to the size above unless `APP_STORE_RESIZE=0`. Landscape files use a **`-landscape`** suffix (e.g. `iphone-17-pro-01-x01-match-dark-landscape.png`).

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
5. **Match summary** — post-game stats (`-snapshot_match_summary`)
6. **Players** — roster (`-seed_demo -snapshot_tab players`)
7. **Activity (Statistics)** — leaderboards (`-seed_demo -snapshot_tab activity -snapshot_activity_segment statistics`)
8. **Onboarding welcome** — first-launch tour (`-ui_test_onboarding`)
9. **Settings** — preferences shell (`-seed_demo -snapshot_tab settings`)

Lean 1.0 omits the **Modes** catalog shot (`04b-modes`); the Modes tab is hidden in the shipping build.

## iPad (12.9" / 13" Displays)

App Store accepts portrait **2064 × 2752** or **2048 × 2732**, and landscape **2752 × 2064** or **2732 × 2048**.

```bash
./Scripts/capture-ipad-marketing-screenshots.sh
# → marketing-screenshots/ipad/raw/*.png (portrait + landscape)

# Light mode
APPEARANCE=light ./Scripts/capture-ipad-marketing-screenshots.sh

# Portrait only (skip landscape pass)
ORIENTATIONS=portrait ./Scripts/capture-ipad-marketing-screenshots.sh
```

Uses **iPad Pro 13-inch** simulator (native **2064×2752** portrait). Upload from `ipad/raw/` only — no device frames.

## Options

```bash
# Light mode set (→ raw/*-light.png and *-light-landscape.png)
APPEARANCE=light ./Scripts/capture-marketing-screenshots.sh

# Portrait only (legacy behavior — no -landscape files)
ORIENTATIONS=portrait ./Scripts/capture-marketing-screenshots.sh

# Landscape only
ORIENTATIONS=landscape ./Scripts/capture-marketing-screenshots.sh

# 6.9" display (1320×2868 native; disable auto-resize)
SIM_NAME="iPhone 17 Pro Max" APP_STORE_RESIZE=0 ./Scripts/capture-marketing-screenshots.sh

# Alternate 6.5" size (1242×2688 portrait; landscape auto-swaps to 2688×1242)
APP_STORE_WIDTH=1242 APP_STORE_HEIGHT=2688 ./Scripts/capture-marketing-screenshots.sh

# iPad 12.9" / 13" (2064×2752 portrait, 2752×2064 landscape)
./Scripts/capture-ipad-marketing-screenshots.sh
```

## Launch arguments reference

| Screen | Arguments |
|--------|-----------|
| Reset + quiet | `-ui_test_reset -ui_test_disable_feedback -disable_firebase_analytics` |
| Screenshot orientation | `-snapshot_orientation portrait` or `landscape` (set by capture script) |
| X01 in progress | `-snapshot_match_x01` |
| X01 in progress (8 players) | `-snapshot_match_x01_8player` |
| Cricket in progress | `-snapshot_match_cricket` |
| Demo data | `-seed_demo` |
| Match summary | `-snapshot_match_summary` |
| Tab | `-snapshot_tab play` / `modes` / `players` / `activity` / `settings` |
| Activity segment | `-snapshot_activity_segment statistics` (with `-snapshot_tab activity`) |
| Onboarding | `-ui_test_onboarding` (with `-ui_test_reset` for clean state) |

## Framing tips

- **App Store:** use files from `raw/` only — Apple rejects device frames in upload slots.
- **Marketing:** use `framed/` for a polished look; prefer dark mode to match the scoreboard chrome. Landscape raw shots are skipped by the framing script (frameit provides portrait bezels only).
- **Transparency:** framed PNGs use a transparent background outside the device (place on any color in Figma/Keynote/web).
- **Colors:** iPhone 17 Pro — Deep Blue (default), Cosmic Orange, Silver
- **Captions:** add short benefit text in Figma/Keynote above framed exports if desired (keep under ~6 words per slide)

## Manual capture (Xcode)

1. Edit scheme → Run → Arguments: add `-ui_test_reset -snapshot_match_x01` (etc.)
2. Run on **iPhone 17 Pro** simulator
3. Simulator → **File → Save Screen** (⌘S)
