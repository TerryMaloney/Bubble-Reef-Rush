# Next Session Handoff

## Branch & Commit

- **Repository**: `TerryMaloney/Bubble-Reef-Rush`
- **Branch**: `claude/geometry-dash-game-brainstorm-m5Thu`
- **Last pushed commit**: Phase 14 (see git log)
- **Last-green tag**: `green-build-mode-v1` = commit `2407e15`
- **Remote**: `https://github.com/TerryMaloney/Bubble-Reef-Rush.git`

## Current Phase: 14 COMPLETE → Starting Phase 15

### Phase 14 deliverables (done):
- Save schema v3 migration (`_migrate_v2_to_v3`)
- 15 new accessor methods: powers, build_unlocks, blueprints, workshop_rank, secret_exits, mutators, rule_cards, radio_keys, world_stations
- `MutatorSystem.gd` autoload (stub, effects in Phase 19)
- All 28 new EventBus signals declared (Phases 15–23)
- `save_v3_test.gd` — 13 contracts, all PASS
- 22-stage test suite green

### Next Phase: 15 — Resonance: Bubble Burst

Files to create:
- `src/gameplay/ResonanceController.gd` (scene-local, like FeverController)
- `src/gameplay/powers/BubbleBurst.gd` + `scenes/gameplay/powers/BubbleBurst.tscn`
- `src/gameplay/powers/EchoShield.gd`
- `assets/data/powers.json`

Files to modify:
- `src/gameplay/LevelRoot.gd` — wire ResonanceController
- `src/gameplay/PlayerController.gd` — EchoShield interception
- `src/ui/HUDController.gd` — ResonanceChargeBar + PowerButton
- `project.godot` — `activate_power` input action
- `assets/asset_manifest.json` — power SFX + sprite keys
- `STUB_ASSETS.md` — power asset specs

Test to add: `tests/integration/resonance_test.gd`

## Test Suite Status

| Stage | Test | Status |
|-------|------|--------|
| 0 | BRL schema + movement validation | ✅ PASS |
| 1–19 | All original stages | ✅ PASS |
| 20 | save_v3_test.gd | ✅ PASS |

**22 stages, all green.**

## Manual Test Instructions (Phase 14)

Phase 14 is infrastructure only (no gameplay changes). No manual playtest needed.
Run `GODOT=/tmp/Godot_v4.6.3-stable_linux.x86_64 ./tools/run_tests.sh` to verify.

## Expansion Plan Summary

Phases 14–25 expand the game per the Ultimate Expansion Mandate.
Plan file: `/root/.claude/plans/polished-launching-marble.md`

| Phase | Feature | Status |
|-------|---------|--------|
| 14 | Save v3 + MutatorSystem stub | ✅ DONE |
| 15 | Resonance: Bubble Burst + Echo Shield | ⏳ NEXT |
| 16 | Ghost Recording + Playback | ⏳ |
| 17 | Challenge Capsules (.brrc) | ⏳ |
| 18 | Pass & Play + Family Tournament | ⏳ |
| 19 | Mutators (20 effects) | ⏳ |
| 20 | Rule Cards + Build Mode Unlock Progression | ⏳ |
| 21 | Special Levels: Trials + Boss Chase | ⏳ |
| 22 | Secret Exits + Collection Room | ⏳ |
| 23 | Daily Dive + Seeded Reef + Radio Shuffle | ⏳ |
| 24 | Co-Pilot Mode + Level Tennis | ⏳ |
| 25 | Reef Radio Architecture + Sticker Mode + Polish | ⏳ |
