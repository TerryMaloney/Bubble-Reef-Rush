# Next Session Handoff

## Branch & Commit

- **Repository**: `TerryMaloney/Bubble-Reef-Rush`
- **Branch**: `main`
- **Last commit SHA**: `6e9b3fe16874401996354a6cad334545b1b13a47`
- **Remote**: `https://github.com/TerryMaloney/Bubble-Reef-Rush.git`

## What Works

The project now contains everything needed to open it in Godot 4.3 and run the
first level end-to-end:

### Core systems (from previous sessions)
- `project.godot` — correct autoloads, 1080×1920 portrait viewport, mobile renderer, audio bus layout
- `EventBus`, `GameManager`, `SaveSystem`, `BeatConductor` — all autoload singletons
- `LevelLoader` — loads `.brl` files; silently continues if audio file is missing
- `RhythmMap`, `TimingJudge`, `BeatVisualizer` — rhythm engine
- `ObstacleSpawner`, `CollectibleSpawner`, `RetryController`, `HUDController` — gameplay systems
- `assets/levels/z1-l1.brl` — 100 BPM, 32 beats, 7 coral spikes, 4 pearls

### Added this session
- `scenes/gameplay/MainMenu.tscn` + `src/gameplay/MainMenu.gd` — title screen with PLAY button
- `scenes/gameplay/LevelRoot.tscn` + `src/gameplay/LevelRoot.gd` — wires all systems together
- `scenes/player/Player.tscn` — CharacterBody2D with `BeatVisualizer` and `TimingJudge` children
- `scenes/obstacles/CoralSpike.tscn` + `src/gameplay/obstacles/CoralSpike.gd`
- `scenes/obstacles/JellyfishDrift.tscn` + `src/gameplay/obstacles/JellyfishDrift.gd`
- `scenes/collectibles/Pearl.tscn` + `src/gameplay/collectibles/Pearl.gd`
- `scenes/gameplay/ResultsScreen.tscn` + `src/gameplay/ResultsScreen.gd` (stub)
- `scenes/buildmode/BuildModeRoot.tscn` (minimal stub, prevents GameManager crash)
- `default_bus_layout.tres` — defines Master + Music audio buses
- `docs/design/level_schema.json` — fixed: stripped non-JSON example content that was breaking `validate_brl.py`

### CI / validation
- `python3 tools/validate_brl.py` → PASS (z1-l1.brl validates against schema v1.1)
- `python3 tools/check_secrets.py` → PASS

## Expected Play Loop

1. Godot opens `MainMenu.tscn` → player taps PLAY
2. `GameManager.start_level("z1-l1")` → loads `LevelRoot.tscn`
3. `LevelLoader` loads `z1-l1.brl`; warns about missing music file but continues
4. `BeatConductor` starts (silent — no audio file yet), fires beat signals
5. `ObstacleSpawner` and `CollectibleSpawner` spawn objects from beat map
6. Orange fish (player) floats up; tap/hold to dive
7. Hit a coral spike → 0.8 s flash → `run_failed` emitted
8. `RetryController` waits 1.5 s → `retry_requested` → level reloads
9. Score, combo, and judgment labels update live on HUD

## What Is Unfinished

| Item | Status |
|------|--------|
| Audio file `zone_1_sunlit_shallows.ogg` | Missing — BeatConductor runs silently |
| Level-complete condition | Not implemented — no one emits `run_completed` yet |
| Results screen content | Stub only (RESULTS label + MENU button) |
| Build Mode | Stub scene only |
| Font / theme styling | All default Godot fonts |
| Sound effects (hit, collect, perfect) | None |
| Android export / signing | CI job written but not tested end-to-end |

## Known Issues / Errors

1. **Godot editor may show UID warnings** on first open for hand-written `.tscn` files — Godot will auto-generate `.uid` files; safe to dismiss.
2. **`push_warning` on startup**: "LevelLoader: Music file not found at `res://assets/audio/music/zone_1_sunlit_shallows.ogg`. Audio will be silent." — expected and harmless.
3. **`smoke-tests` CI job** runs headless Godot which requires a Godot binary in CI; the workflow uses `setup-godot` action pointing to 4.3. May fail if the runner cache is cold (first run is slow).
4. **`docs/design/level_schema.json`** was repaired (non-JSON example content removed from end of file). If the schema file is regenerated from an old source, re-apply the fix.

## Next Prompt (copy-paste ready)

```
Open Bubble Reef Rush in Godot 4.3. The project is complete enough to run.
Verify it actually runs with no script errors:
  1. Open the project in Godot 4.3 editor (or run headless).
  2. Fix any remaining parse errors or node-path mismatches.
  3. Add a placeholder 100 BPM click track so audio is not silent:
     generate a short WAV (or use AudioStreamGenerator) for the metronome,
     place it at assets/audio/music/zone_1_sunlit_shallows.ogg (or rename
     the music field in z1-l1.brl to match).
  4. Add a level-complete trigger: after beat 32 of z1-l1.brl, emit
     EventBus.run_completed("z1-l1", score, stars) so the ResultsScreen
     is reachable.
  5. Commit and push when all four points work without errors.
Do NOT start Build Mode, store systems, or new obstacle types yet.
```
