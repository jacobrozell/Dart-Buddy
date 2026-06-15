# Marketing Screenshots — 1.1 Party Pack

App Store assets for **Baseball**, **Killer**, **Shanghai**, and **Around the Clock**.

## Quick start

```bash
# Capture raw simulator screenshots (dark mode, iPhone 17 Pro Max, portrait + landscape)
./Scripts/capture-1.1-marketing-screenshots.sh

# Light mode
APPEARANCE=light ./Scripts/capture-1.1-marketing-screenshots.sh

# Wrap in device bezels
RAW_DIR=marketing-screenshots/1.1/raw \
FRAMED_DIR=marketing-screenshots/1.1/framed \
./Scripts/frame-marketing-screenshots.sh
```

Captures use `-enable_lean_product_surface` so the binary matches the shipping **Party Pack 1.1** allowlist (six modes, four tabs, English UI).

## Screens captured

| File slug | Screen | Launch args |
|-----------|--------|-------------|
| `11-baseball-match` | Baseball mid-inning | `-snapshot_match_baseball` |
| `12-killer-match` | Killer playing phase | `-snapshot_match_killer` |
| `13-shanghai-match` | Shanghai round 8 | `-snapshot_match_shanghai` |
| `14-around-the-clock-match` | Solo Around the Clock on target 12 | `-snapshot_match_aroundTheClock` |
| `15-play-setup` | Play home / setup | `-seed_demo -snapshot_play_setup` |
| `16-activity-history` | Activity history (includes Baseball) | `-seed_demo -snapshot_tab activity` |

## QA / visual regression (all variants)

For portrait, landscape, and AXXXL captures via UI automation:

```bash
OUT_DIR=Screenshots/game-modes/party-pack-1.1/latest \
TEST_FILTER="DartBuddyUIGameplayUITests/GameModeScreenshotUITests/testCaptureBaseballScreenshots" \
./Scripts/capture_game_mode_screenshots.sh

# Repeat for testCaptureKillerScreenshots, testCaptureShanghaiScreenshots, testCaptureAroundTheClockScreenshots
```

Or capture all shipped modes (full dev catalog):

```bash
./Scripts/capture_game_mode_screenshots.sh
```

## App Store notes

- Upload from `raw/` only (no bezels).
- Do **not** use Modes tab or full-catalog shots — they are out of scope for 1.1.
- Pair with existing 1.0 shots (`marketing-screenshots/raw/`) for X01 and Cricket if updating the full listing set.
