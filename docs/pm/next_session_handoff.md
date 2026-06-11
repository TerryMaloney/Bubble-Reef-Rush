# Next Session Handoff

## Branch & Commit

- **Repository**: `TerryMaloney/Bubble-Reef-Rush`
- **Branch**: `claude/geometry-dash-game-brainstorm-m5Thu`
- **Last pushed commit**: Phase 15 (see git log)
- **Last-green tag**: `green-build-mode-v1` = commit `2407e15`
- **Remote**: `https://github.com/TerryMaloney/Bubble-Reef-Rush.git`

## Current Phase: 15 COMPLETE → Starting Phase 16

### Phase 15 deliverables (done):

- `src/gameplay/ResonanceController.gd` — charge meter (5 pearls = 1 charge), fire(), consume_shield(), _is_perfect_timed()
- `src/gameplay/powers/BubbleBurst.gd` — rightward projectile at 1200/1600 px/s, pops bubble_destructible group
- `src/gameplay/powers/EchoShield.gd` — visual ring on Player node, pulse animation, break flash
- `scenes/gameplay/powers/BubbleBurst.tscn` — minimal Node2D + Polygon2D visual
- `assets/data/powers.json` — 5 powers defined (bubble_burst, echo_shield + 3 stubs)
- `scenes/gameplay/LevelRoot.tscn` — ResonanceController node, ResonanceChargeBar label, PowerButton (bottom-right 184x96 px)
- `scenes/player/Player.tscn` — EchoShield child node with octagonal Ring polygon
- `src/gameplay/LevelRoot.gd` — wires RC; reads level power_mode/max_charges from metadata on run_started
- `src/ui/HUDController.gd` — resonance_bar label, power_button export, update_power_button_mode(), _on_power_charged() with pip progress
- `src/gameplay/PlayerController.gd` — on_hit() checks ResonanceController.consume_shield() before death
- `src/gameplay/obstacles/JellyfishDrift.gd` — added to bubble_destructible group
- `src/gameplay/obstacles/BubbleMine.gd` — added to bubble_destructible group
- `assets/asset_manifest.json` — 8 new keys: sfx/power_charge, sfx/power_fire, sfx/shield_break + 5 sprite/power/* keys
- `tools/gen_audio.py` — 3 new power SFX WAV stubs (generated on disk)
- `STUB_ASSETS.md` — Power SFX section + Power Sprites section
- `tests/integration/resonance_test.gd` — 8 contracts, all PASS
- `tools/run_tests.sh` — stage 21 added (RESONANCE_OK)
- 23-stage suite: all green

### Level metadata fields (existing .brl levels default gracefully):

- metadata.power_mode: String — "allowed" (default) | "disabled" | "required"
- metadata.max_charges: int — default 1

### Next Phase: 16 — Ghost Recording + Playback

Files to create:
- src/gameplay/GhostRecorder.gd — captures {beat: float, event: String} on swim_dive action
- src/gameplay/GhostPlayer.gd — replays inputs as translucent Node2D (non-colliding, alpha=0.4)
- src/core/GhostLibrary.gd — autoload; save_ghost(), load_ghost(), list_ghosts() → user://profiles/<id>/ghosts/

Files to modify:
- src/gameplay/PlayerController.gd — attach GhostRecorder; emit inputs when alive
- src/gameplay/LevelRoot.gd — wire GhostPlayer if GameManager.show_ghost != ""
- project.godot — GhostLibrary autoload after MutatorSystem
- src/core/GameManager.gd — add show_ghost: String property (ghost type to show on next run)
- assets/asset_manifest.json — ghost sprite key
- STUB_ASSETS.md — ghost sprite section

Test to add: tests/integration/ghost_test.gd (5 contracts: record/replay, determinism, non-collide, ghost_saved signal, family_champion selection)

## Test Suite Status

| Stage | Test | Status |
|-------|------|--------|
| 0 | BRL schema + movement validation | PASS |
| 1-20 | All original + save_v3 stages | PASS |
| 21 | resonance_test.gd | PASS |

23 stages, all green.

## Expansion Plan Summary

| Phase | Feature | Status |
|-------|---------|--------|
| 14 | Save v3 + MutatorSystem stub | DONE |
| 15 | Resonance: Bubble Burst + Echo Shield | DONE |
| 16 | Ghost Recording + Playback | NEXT |
| 17 | Challenge Capsules (.brrc) | pending |
| 18 | Pass & Play + Family Tournament | pending |
| 19 | Mutators (20 effects) | pending |
| 20 | Rule Cards + Build Mode Unlock Progression | pending |
| 21 | Special Levels: Trials + Boss Chase | pending |
| 22 | Secret Exits + Collection Room | pending |
| 23 | Daily Dive + Seeded Reef + Radio Shuffle | pending |
| 24 | Co-Pilot Mode + Level Tennis | pending |
| 25 | Reef Radio Architecture + Sticker Mode + Polish | pending |
