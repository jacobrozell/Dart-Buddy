#!/usr/bin/env bash
# App Store Connect screenshot dimensions (portrait).
# iPhone 6.5": 1284×2778 or 1242×2688
# iPad 12.9"/13": 2064×2752 or 2048×2732
#
# Usage (sourced or run directly):
#   ./Scripts/app-store-screenshot-size.sh resize path/to.png
#   ./Scripts/app-store-screenshot-size.sh resize marketing-screenshots/raw/*.png

set -euo pipefail

# 6.5" Display slot (required when 6.9" set is not provided): 1284×2778 or 1242×2688
APP_STORE_WIDTH="${APP_STORE_WIDTH:-1284}"
APP_STORE_HEIGHT="${APP_STORE_HEIGHT:-2778}"

app_store_resize_png() {
  local path="$1"
  local w h
  w="$(magick identify -format "%w" "$path")"
  h="$(magick identify -format "%h" "$path")"
  if [[ "$w" == "$APP_STORE_WIDTH" && "$h" == "$APP_STORE_HEIGHT" ]]; then
    return 0
  fi
  magick "$path" -filter Lanczos -resize "${APP_STORE_WIDTH}x${APP_STORE_HEIGHT}!" "$path"
}

app_store_resize_paths() {
  if ! command -v magick >/dev/null 2>&1; then
    echo "ImageMagick is required. Install with: brew install imagemagick" >&2
    exit 1
  fi
  for path in "$@"; do
    echo "→ ${APP_STORE_WIDTH}×${APP_STORE_HEIGHT}: $(basename "$path") (was $(magick identify -format '%wx%h' "$path"))"
    app_store_resize_png "$path"
  done
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  [[ $# -ge 2 && "$1" == resize ]] || {
    echo "Usage: $0 resize <file.png>..." >&2
    exit 1
  }
  shift
  app_store_resize_paths "$@"
fi
