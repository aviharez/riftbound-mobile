#!/usr/bin/env bash
# Launch the game windowed, capture a frame, keep it as QA evidence.
# Usage: tools/screenshot.sh <name> [resolution] [scene]
#   tools/screenshot.sh m1-aim-line                 -> docs/qa/evidence/m1-aim-line-1080x2400.png
#   tools/screenshot.sh m1-aim-line 1080x1920       -> 16:9 phone (scale x3)
#   tools/screenshot.sh boss 1080x2400 res://scenes/battle/battle_screen.tscn
# Uses Godot's --write-movie (never --headless: it skips rendering). Captures frame N (default 30, set FRAMES=).
# Movie Maker ignores --resolution and records at the project window size, so the size is set through a
# temporary override.cfg (a standard Godot feature) that is removed afterwards.
set -eu
GODOT="${GODOT:-godot}"
NAME="${1:?usage: tools/screenshot.sh <name> [resolution] [scene]}"
RES="${2:-1080x2400}"
SCENE="${3:-}"
FRAMES="${FRAMES:-30}"
cd "$(dirname "$0")/.."
OUT_DIR="docs/qa/evidence"
TMP="$(mktemp -d)"
mkdir -p "$OUT_DIR"
W="${RES%x*}"; H="${RES#*x}"
if [ -e override.cfg ]; then echo "screenshot: override.cfg already exists, refusing to overwrite it" >&2; exit 1; fi
trap 'rm -f override.cfg; rm -rf "$TMP"' EXIT
printf '[display]\n\nwindow/size/window_width_override=%s\nwindow/size/window_height_override=%s\n' "$W" "$H" > override.cfg
# shellcheck disable=SC2086
"$GODOT" --path . --windowed --write-movie "$TMP/frame.png" --quit-after "$FRAMES" $SCENE >/dev/null 2>&1 || true
LAST="$(ls "$TMP"/frame*.png 2>/dev/null | sort | tail -n 1)"
if [ -z "$LAST" ]; then echo "screenshot: no frame captured" >&2; exit 1; fi
cp "$LAST" "$OUT_DIR/$NAME-$RES.png"
echo "$OUT_DIR/$NAME-$RES.png"
