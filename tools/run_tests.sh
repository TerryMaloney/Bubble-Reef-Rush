#!/usr/bin/env bash
# Run all Bubble Reef Rush headless tests against a local Godot binary.
#
# Usage:
#   GODOT=/path/to/godot ./tools/run_tests.sh
# If GODOT is unset, falls back to `godot` on PATH.
#
# Stage 0: Python validators (schema + movement budgets) over all .brl files.
# Stages 1-8: Godot headless unit/integration tests.
# Exits non-zero if any stage fails.
set -euo pipefail

GODOT="${GODOT:-/tmp/Godot_v4.6.3-stable_linux.x86_64}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

# ── Stage 0: Python validators ───────────────────────────────────────────────
echo "==> Stage 0: BRL schema validation"
python3 tools/validate_brl.py assets/levels/
echo "    PASS: BRL schema validation"

echo "==> Stage 0: Movement budget check"
python3 tools/check_movements.py assets/levels/
echo "    PASS: Movement budget check"

# ── Godot headless stages ────────────────────────────────────────────────────
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
run_stage "Geometry test"   "tests/integration/geometry_test.gd"         "GEOMETRY_OK"
run_stage "Game flow test"  "tests/integration/game_flow_test.gd"        "GAME_FLOW_OK"
run_stage "Save test"       "tests/integration/save_test.gd"             "SAVE_OK"
run_stage "Settings test"   "tests/integration/settings_test.gd"        "SETTINGS_OK"
run_stage "Registry test"   "tests/integration/registry_test.gd"        "REGISTRY_OK"
run_stage "Speed zone test" "tests/integration/speed_zone_test.gd"       "SPEED_ZONE_OK"
run_stage "Juice test"       "tests/integration/juice_test.gd"            "JUICE_OK"
run_stage "Checkpoint test" "tests/integration/checkpoint_test.gd"      "CHECKPOINT_OK"
run_stage "Playtest"        "tests/integration/playtest.gd"              "PLAYTEST_OK"

echo "==> All tests passed."
