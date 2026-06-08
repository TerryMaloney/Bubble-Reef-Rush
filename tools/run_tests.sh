#!/usr/bin/env bash
# Run all Bubble Reef Rush headless tests against a local Godot binary.
#
# Usage:
#   GODOT=/path/to/godot ./tools/run_tests.sh
# If GODOT is unset, falls back to `godot` on PATH.
#
# Runs the project import once (to build the global class cache), then the
# smoke test, the collision-contract test, and the full playtest harness.
# Exits non-zero if any stage fails.
set -euo pipefail

GODOT="${GODOT:-godot}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

echo "==> Importing project (building class cache)…"
"$GODOT" --headless --import >/dev/null 2>&1 || true

run_stage() {
	local name="$1"; local script="$2"; local needle="$3"
	echo "==> $name"
	local out
	out="$("$GODOT" --headless --path . --script "$script" 2>&1)" || true
	echo "$out" | grep -vE '^\s*$' | tail -20
	if echo "$out" | grep -q "$needle"; then
		echo "    PASS: $name"
	else
		echo "    FAIL: $name (expected '$needle')"
		exit 1
	fi
}

run_stage "Smoke test"      "tests/smoke/run_smoke_tests.gd"              "SMOKE_OK"
run_stage "Director test"   "tests/integration/director_test.gd"         "DIRECTOR_OK"
run_stage "Collision test"  "tests/integration/collision_test.gd"        "COLLISION_OK"
run_stage "Obstacle test"   "tests/integration/obstacle_test.gd"         "OBSTACLE_OK"
run_stage "Game flow test"  "tests/integration/game_flow_test.gd"         "GAME_FLOW_OK"
run_stage "Playtest"        "tests/integration/playtest.gd"               "PLAYTEST_OK"

echo "==> All tests passed."
