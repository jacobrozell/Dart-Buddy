#!/usr/bin/env bash
# Shared Simulator orientation helpers (Cmd+Left/Right in Simulator.app).
# Tracks current orientation and rotates at most once per transition.

SIMULATOR_ORIENTATION="${SIMULATOR_ORIENTATION:-portrait}"

_rotate_simulator() {
  local keycode="$1"
  osascript <<APPLESCRIPT >/dev/null 2>&1 || true
tell application "Simulator" to activate
delay 0.15
tell application "System Events"
  tell process "Simulator"
    key code ${keycode} using {command down}
  end tell
end tell
APPLESCRIPT
  sleep 0.8
}

rotate_simulator_left() {
  _rotate_simulator 123
}

rotate_simulator_right() {
  _rotate_simulator 124
}

reset_simulator_orientation() {
  osascript <<'APPLESCRIPT' >/dev/null 2>&1 || true
tell application "Simulator" to activate
delay 0.15
tell application "System Events"
  tell process "Simulator"
    try
      click menu item "Portrait" of menu "Orientation" of menu item "Device" of menu bar 1
    end try
  end tell
end tell
APPLESCRIPT
  sleep 0.8
  SIMULATOR_ORIENTATION="portrait"
}

set_simulator_orientation() {
  local target="$1"
  if [[ "$SIMULATOR_ORIENTATION" == "$target" ]]; then
    return 0
  fi

  if [[ "$target" == "landscape" ]]; then
    rotate_simulator_left
    SIMULATOR_ORIENTATION="landscape"
  else
    rotate_simulator_right
    SIMULATOR_ORIENTATION="portrait"
  fi
}

ensure_portrait() {
  set_simulator_orientation portrait
}

ensure_landscape() {
  set_simulator_orientation landscape
}
