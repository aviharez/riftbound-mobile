#!/usr/bin/env bash
# Play through every screen and keep a screenshot of each in docs/qa/evidence/<prefix>-<flow>-<screen>-<WxH>.png:
#   loop:   title, academy, building panel, repair, restored academy, battle, result, back at the academy
#   students: roster, profile, a student joins, Frost Nova, Verdant Bloom
#   battle: play, level up, fusion, pause, ultimate, many balls, result
# Uses a throwaway save, never the player's.
# Usage: tools/capture_flow.sh [prefix] [resolution]     e.g. tools/capture_flow.sh m6 1080x2400
set -eu
GODOT="${GODOT:-godot}"
PREFIX="${1:-flow}"
RES="${2:-1080x2400}"
cd "$(dirname "$0")/.."
mkdir -p docs/qa/evidence
W="${RES%x*}"; H="${RES#*x}"
if [ -e override.cfg ]; then echo "capture_flow: override.cfg already exists, refusing to overwrite it" >&2; exit 1; fi
trap 'rm -f override.cfg' EXIT
printf '[display]\n\nwindow/size/window_width_override=%s\nwindow/size/window_height_override=%s\n' "$W" "$H" > override.cfg
"$GODOT" --headless --path . --import >/dev/null 2>&1
"$GODOT" --path . --windowed -s res://tools/run_runner.gd -- --runner=res://tools/runners/academy_runner.gd --scene=res://scenes/title/title_screen.tscn "--prefix=$PREFIX" 2>&1 | grep -E "SHOT|LOOP|SCRIPT ERROR|ERROR:|at:" || true
"$GODOT" --path . --windowed -s res://tools/run_runner.gd -- --runner=res://tools/runners/students_runner.gd --scene=res://scenes/title/title_screen.tscn "--prefix=$PREFIX" 2>&1 | grep -E "SHOT|STUDENTS|SCRIPT ERROR|ERROR:|at:" || true
"$GODOT" --path . --windowed -s res://tools/run_runner.gd -- --runner=res://tools/runners/flow_runner.gd "--prefix=$PREFIX" 2>&1 | grep -E "SHOT|SCRIPT ERROR|ERROR:|at:" || true
