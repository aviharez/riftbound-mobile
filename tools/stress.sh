#!/usr/bin/env bash
# Headless ball-physics invariant test (no ball inside walls/enemies, no near-horizontal loops, no NaN).
# Usage: tools/stress.sh        Exit 0 = PASS, 1 = FAIL.
set -u
GODOT="${GODOT:-godot}"
cd "$(dirname "$0")/.."
"$GODOT" --headless --path . --import >/dev/null 2>&1
"$GODOT" --headless --path . --fixed-fps 60 -s res://tools/run_runner.gd -- --runner=res://tools/runners/stress_runner.gd 2>&1 | grep -E "STRESS|SCRIPT ERROR|ERROR:|at:"
exit "${PIPESTATUS[0]}"
