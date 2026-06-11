# Next Session Handoff

## Branch & Commit

- **Repository**: `TerryMaloney/Bubble-Reef-Rush`
- **Branch**: `claude/geometry-dash-game-brainstorm-m5Thu`
- **Last pushed commit**: Phase 16 (see git log)
- **Last-green tag**: `green-build-mode-v1` = commit `2407e15`
- **Remote**: `https://github.com/TerryMaloney/Bubble-Reef-Rush.git`

## Current Phase: 16 COMPLETE → Starting Phase 17

### Phase 16 deliverables (done):

- `src/gameplay/GhostRecorder.gd` — captures `{beat, event}` on swim_dive; start()/stop(score)/record_event()/get_ghost_data()
- `src/gameplay/GhostPlayer.gd` — deterministic physics replay via recorded beat-indexed inputs; Node2D, non-colliding
- `src/core/GhostLibrary.gd` — autoload; save_ghost/load_ghost/list_ghosts/get_family_champion; writes user://profiles/<id>/ghosts/
- `scenes/gameplay/GhostPlayer.tscn` — Node2D at (200,960) + translucent cyan Polygon2D Visual child (alpha 0.4)
- `scenes/gameplay/LevelRoot.tscn` — added GhostRecorder node (load_steps 16→17, ext_resource id=15)
- `src/gameplay/LevelRoot.gd` — wires GhostRecorder to player; _on_run_completed_ghost saves PB; _maybe_spawn_ghost_player reads GameManager.show_ghost
- `src/gameplay/PlayerController.gd` — set_ghost_recorder(); record_event("dive_start"/"dive_end") in _input()
- `src/core/GameManager.gd` — added show_ghost: String = "" property
- `project.godot` — GhostLibrary autoload added after MutatorSystem
- `assets/asset_manifest.json` — sprite/ghost/trail key added
- `STUB_ASSETS.md` — Ghost Sprites section added
- `tests/integration/ghost_test.gd` — 7 contracts, all PASS
- `tools/run_tests.sh` — stage 22 added (GHOST_OK)
- 24-stage suite: all green

### Ghost types available:

- `"personal_best"` — best score for the active profile
- `"family_champion"` — highest score across all profiles (scanned by get_family_champion())
- `"imported"` — from a Challenge Capsule (Phase 17)

### How to show a ghost on a level run:

```gdscript
GameManager.show_ghost = "personal_best"  # or "family_champion" or "imported"
GameManager.start_level("z1-l1")
```

LevelRoot._maybe_spawn_ghost_player() reads and acts on this flag at _ready() time.

### Next Phase: 17 — Challenge Capsules + Level Swap

Files to create:
- `src/core/CapsuleSerializer.gd` (RefCounted) — pack()/unpack()/validate(); HMAC checksum via Crypto.hmac_digest()
- `src/ui/ChallengeExportScreen.gd` + `.tscn` — clipboard code + "Share File" (Android intent)
- `src/ui/ChallengeImportScreen.gd` + `.tscn` — paste or file picker; validate → save to user://capsules/
- `assets/data/` update if capsule schema needs static data

Files to modify:
- `src/core/EventBus.gd` — capsule_exported(path), capsule_imported(level_id)
- `assets/asset_manifest.json` — capsule UI icons if needed
- `STUB_ASSETS.md` — capsule section

Tests: `tests/integration/capsule_test.gd` — round-trip deep-equal, tampered checksum → rejected, level hash mismatch → warning, old app_ver → compat flag

## Test Suite Status

| Stage | Test | Status |
|-------|------|--------|
| 0 | BRL schema + movement validation | PASS |
| 1-20 | All original + save_v3 stages | PASS |
| 21 | resonance_test.gd | PASS |
| 22 | ghost_test.gd | PASS |

24 stages, all green.

## Expansion Plan Summary

| Phase | Feature | Status |
|-------|---------|--------|
| 14 | Save v3 + MutatorSystem stub | DONE |
| 15 | Resonance: Bubble Burst + Echo Shield | DONE |
| 16 | Ghost Recording + Playback | DONE |
| 17 | Challenge Capsules (.brrc) | NEXT |
| 18 | Pass & Play + Family Tournament | pending |
| 19 | Mutators (20 effects) | pending |
| 20 | Rule Cards + Build Mode Unlock Progression | pending |
| 21 | Special Levels: Trials + Boss Chase | pending |
| 22 | Secret Exits + Collection Room | pending |
| 23 | Daily Dive + Seeded Reef + Radio Shuffle | pending |
| 24 | Co-Pilot Mode + Level Tennis | pending |
| 25 | Reef Radio Architecture + Sticker Mode + Polish | pending |
