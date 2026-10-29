#!/usr/bin/env bash
# Parse-check every GDScript file the way the game loads it.
# Usage: tools/check.sh            (uses `godot` on PATH, or $GODOT)
# Exit 0 = all scripts load, 1 = at least one PARSE FAIL.
# Note: `--import` and `--quit-after` exit 0 even on parse errors, so they are not a parse check.
set -u
GODOT="${GODOT:-godot}"
cd "$(dirname "$0")/.."
"$GODOT" --headless --path . --import >/dev/null 2>&1
FILES=$(find scripts tools -name '*.gd' | sort | sed 's#^#res://#')
# shellcheck disable=SC2086
"$GODOT" --headless --path . -s res://tools/godot_parse_check.gd -- $FILES
