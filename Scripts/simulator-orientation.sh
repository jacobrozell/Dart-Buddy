#!/usr/bin/env bash
# Screenshot orientation helpers for simulator captures.
# Orientation is applied in-app via `-snapshot_orientation portrait|landscape`.
# simctl may still write landscape UI into a portrait-sized buffer; normalize before resize.

_require_imagemagick() {
  if ! command -v magick >/dev/null 2>&1; then
    echo "ImageMagick is required. Install with: brew install imagemagick" >&2
    return 1
  fi
}

_screenshot_dimensions() {
  magick identify -format "%w %h" "$1"
}

normalize_screenshot_for_orientation() {
  local path="$1"
  local orientation="$2"
  local w h

  _require_imagemagick || return 1
  read -r w h <<< "$(_screenshot_dimensions "$path")"

  if [[ "$orientation" == "landscape" && "$w" -lt "$h" ]]; then
    echo "→ Normalizing $(basename "$path"): rotating landscape capture (${w}×${h})…" >&2
    magick "$path" -rotate -90 "$path"
  elif [[ "$orientation" == "portrait" && "$w" -gt "$h" ]]; then
    echo "→ Normalizing $(basename "$path"): rotating portrait capture (${w}×${h})…" >&2
    magick "$path" -rotate -90 "$path"
  fi
}

verify_screenshot_orientation() {
  local path="$1"
  local expected="$2"
  local w h

  _require_imagemagick || return 1
  read -r w h <<< "$(_screenshot_dimensions "$path")"

  if [[ "$expected" == "landscape" && "$w" -le "$h" ]]; then
    echo "Screenshot $(basename "$path") is ${w}×${h} but expected landscape." >&2
    return 1
  fi
  if [[ "$expected" == "portrait" && "$h" -le "$w" ]]; then
    echo "Screenshot $(basename "$path") is ${w}×${h} but expected portrait." >&2
    return 1
  fi
  return 0
}
