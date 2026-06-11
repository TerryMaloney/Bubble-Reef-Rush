# Next Session Handoff

## Branch & Commit

- **Repository**: `TerryMaloney/Bubble-Reef-Rush`
- **Branch**: `claude/geometry-dash-game-brainstorm-m5Thu`
- **Last pushed commit**: Phase 22 (see git log)
- **Last-green tag**: `green-build-mode-v1` = commit `2407e15`
- **Remote**: `https://github.com/TerryMaloney/Bubble-Reef-Rush.git`

## Current Phase: 22 COMPLETE → Starting Phase 23

### Phase 22 deliverables (done):
- `SecretExit.gd` obstacle: invisible gate with `activate(profile_id, level_id)` → SaveSystem
- `SecretExit.tscn` + `CollectionRoomScreen.tscn` stub scenes
- `CollectionRoomScreen.gd`: `get_collection_data(profile_id)` returns characters (8), boss trophies (4), blueprints, family_records (cross-profile best scores)
- `SaveSystem.get_boss_trophy()` + `add_boss_trophy()` methods
- `ObstacleSpawner`: `secret_exit` added to OBSTACLE_SCENE_MAP
- Schema: `secret_exit` added to obstacle_type enum
- 3 levels retrofitted with secret exits: z1-l1 (z1_hidden_grotto), z2-l1 (z2_sunken_chest), z3-l1 (z3_volcanic_vent)
- `secret_exit_test.gd` (5 tests) + `collection_room_test.gd` (4 tests) — all PASS
- **31-stage test suite green; 65/65 BRL files pass validation**

### Next Phase: 23 — Daily Dive + Seeded Reef + Radio Shuffle

Files to create:
- `src/core/DeterministicSeed.gd` (autoload): LCG seeded from date string or salt; `pick_levels(count, zone_range) → Array[String]`
- `scenes/ui/DailyDiveScreen.tscn` + `src/ui/DailyDiveScreen.gd`
- `scenes/ui/RadioShuffleScreen.tscn` + `src/ui/RadioShuffleScreen.gd`

Files to modify:
- `src/core/EventBus.gd` — add `daily_dive_completed(date, score)` signal
- `src/core/SaveSystem.gd` — daily_dive.history{} read/write
- `project.godot` — register DeterministicSeed autoload
- `tools/run_tests.sh` — add stages 32-33 (SEEDED_OK, DAILY_DIVE_OK)

Tests:
- `seeded_test.gd`: same seed → identical level list on 5 calls, different seed → different, date change → different daily dive
- `daily_dive_test.gd`: daily_dive_completed signal, history saved, determinism matches

## Test Results (31 stages)

All 31 stages green as of Phase 22 push.

## Manual Test Steps

1. `GODOT=/tmp/Godot_v4.6.3-stable_linux.x86_64 ./tools/run_tests.sh` → "All tests passed."
2. `python3 tools/validate_brl.py` → "65/65 files passed."
3. `python3 tools/check_movements.py` → all PASS (if run)

## Build Stamp

`v0.14.0 / 2026-06-11`
