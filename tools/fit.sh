#!/usr/bin/env bash
# Screen-fit check: launches the game at common phone/tablet sizes and checks that the root viewport has a
# whole-number scale, no letterbox offset and covers the window (tools/runners/fit_runner.gd). Needs a display
# big enough for the largest size (e.g. xvfb-run -a -s "-screen 0 1600x3200x24" tools/fit.sh). Prints PASS/FAIL.
set -u
GODOT="${GODOT:-godot}"
cd "$(dirname "$0")/.."
if [ -e override.cfg ]; then echo "fit: override.cfg already exists, refusing to overwrite it" >&2; exit 1; fi
trap 'rm -f override.cfg' EXIT
FAILS=0
for RES in 1080x2400 1080x1920 1284x2778 1170x2532 1080x2340 720x1600 1440x3120 1536x2048 540x1120; do
  printf '[display]\n\nwindow/size/window_width_override=%s\nwindow/size/window_height_override=%s\n' "${RES%x*}" "${RES#*x}" > override.cfg
  LINE="$("$GODOT" --path . --windowed -s res://tools/run_runner.gd -- --runner=res://tools/runners/fit_runner.gd 2>&1 | grep -E '^FIT ' || echo 'FIT FAIL (no output)')"
  echo "$RES  $LINE"
  case "$LINE" in "FIT OK"*) ;; *) FAILS=$((FAILS + 1));; esac
done
if [ "$FAILS" -eq 0 ]; then echo PASS; else echo "FAIL ($FAILS)"; exit 1; fi
