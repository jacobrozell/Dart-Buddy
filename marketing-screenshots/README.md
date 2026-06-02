# Marketing Screenshots

Professional App Store and marketing assets for **DartBuddy**.

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
| `raw/` | Upload to **App Store Connect** (no bezels) |
| `framed/` | Website, social, press kit (with bezels) |

## Screens captured (App Store priority)

1. **X01 match** — Jacob vs Sam, mid-game (`-snapshot_match_x01`)
2. **Cricket board** — marks and scoring (`-snapshot_match_cricket`)
3. **Match setup** — new game home (`-seed_demo`)
4. **History** — completed matches (`-seed_demo -snapshot_tab history`)
5. **Match summary** — post-game stats (`-snapshot_match_summary`)
6. **Players** — roster (`-seed_demo -snapshot_tab players`)

## Options

```bash
# Light mode set
APPEARANCE=light ./Scripts/capture-marketing-screenshots.sh

# 6.9" display (App Store “iPhone 6.9\"” slot)
SIM_NAME="iPhone 17 Pro Max" ./Scripts/capture-marketing-screenshots.sh

# iPad (optional)
SIM_NAME="iPad Pro 13-inch (M4)" ./Scripts/capture-marketing-screenshots.sh
```

## Launch arguments reference

| Screen | Arguments |
|--------|-----------|
| Reset + quiet | `-ui_test_reset -ui_test_disable_feedback -disable_firebase_analytics` |
| X01 in progress | `-snapshot_match_x01` |
| Cricket in progress | `-snapshot_match_cricket` |
| Demo data | `-seed_demo` |
| Match summary | `-snapshot_match_summary` |
| Tab | `-snapshot_tab history` / `players` / `statistics` |

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
