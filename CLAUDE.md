# Bubble Reef Rush — Developer Reference

Underwater rhythm runner for kids (ages 6–12), Geometry Dash style.
Godot 4.6 (GDScript, typed). Portrait 1080×1920. Android-first, iOS secondary.

## Quick commands

```bash
# Run full test suite (26 stages, ~2 min)
GODOT=/tmp/Godot_v4.6.3-stable_linux.x86_64 ./tools/run_tests.sh

# Validate all 48 .brl level files (schema + movement budgets)
python3 tools/validate_brl.py assets/levels/
python3 tools/check_movements.py assets/levels/

# Generate Zone click-track WAV stubs (used as audio fallbacks)
python3 tools/gen_audio.py
```

## Project structure

```
src/
  core/           GameManager, SaveSystem, EventBus, GameConstants,
                  AssetRegistry, VisualFactory, TransitionLayer,
                  EconomyService, AchievementSystem, LevelLoader
  rhythm/         BeatConductor, TimingJudge, RhythmMap, BeatVisualizer
  gameplay/       LevelRoot, ObstacleSpawner, CollectibleSpawner,
                  ScrollService, DifficultyDirector, PlayerController,
                  JuiceDirector, FXFactory, FeverController,
                  NearMissDetector, PracticeController, BackgroundController,
                  ResonanceController
  gameplay/obstacles/   All 12 obstacle scripts
  gameplay/collectibles/ Pearl, TreasureCoin
  gameplay/powers/      BubbleBurst, EchoShield
  buildmode/      BuildSession, BrlSerializer, PlayabilityValidator,
                  DifficultyTagger, ObstacleParamSchema,
                  BuildModeRoot, TimelineView, PalettePanel,
                  PropertiesPanel, PlaybackBar
  ui/             PauseMenu, SettingsScreen, HUDController, AchievementToast
  audio/          SFXManager

scenes/
  gameplay/       LevelRoot, MainMenu, ZoneSelect, LevelSelect,
                  ResultsScreen, SettingsScreen
  gameplay/powers/ BubbleBurst.tscn
  buildmode/      BuildModeRoot.tscn
  obstacles/      All 12 obstacle scenes
  player/         Player.tscn
  ui/             HUD.tscn, PauseMenu.tscn, AchievementToast.tscn

assets/
  levels/         48 .brl files (z1-l1 … z6-l8)
  data/           achievements.json
  asset_manifest.json

tests/
  smoke/          run_smoke_tests.gd
  integration/    22 headless test scripts
tools/
  run_tests.sh    22-stage headless suite runner
  validate_brl.py JSON-schema validation for .brl files
  check_movements.py  Movement budget + speed-zone readability checks
  gen_audio.py    Procedural WAV click-track generator
```

## Autoloads (project.godot order)

| Name | Script | Purpose |
|------|--------|---------|
| `GameManager` | `src/core/GameManager.gd` | Scene state machine, level lifecycle |
| `EventBus` | `src/core/EventBus.gd` | Cross-scene signals |
| `SaveSystem` | `src/core/SaveSystem.gd` | Profile progress, v3 schema + migration |
| `BeatConductor` | `src/rhythm/BeatConductor.gd` | Fixed + variable BPM clock, beat/half-beat signals |
| `Accessibility` | `src/core/Accessibility.gd` | Reduced motion, wide timing, text scale |
| `GameConstants` | `src/core/GameConstants.gd` | Canvas 1080×1920, speeds, timing windows |
| `AssetRegistry` | `src/core/AssetRegistry.gd` | Manifest-driven asset lookup with fallbacks |
| `VisualFactory` | `src/core/VisualFactory.gd` | Texture-or-placeholder obstacle visuals |
| `ScrollService` | `src/gameplay/ScrollService.gd` | Per-beat scroll speed table, distance_until_beat() |
| `FXFactory` | `src/gameplay/FXFactory.gd` | Pooled CPUParticles2D one-shots |
| `TransitionLayer` | `src/core/TransitionLayer.gd` | 0.25 s fade between scenes |
| `SFXManager` | `src/audio/SFXManager.gd` | SFX playback routed through AssetRegistry |
| `EconomyService` | `src/core/EconomyService.gd` | Coin grants, treasure coin persistence |
| `AchievementSystem` | `src/core/AchievementSystem.gd` | Rule-engine over achievements.json |
| `AchievementToast` | `src/ui/AchievementToast.gd` | Queued toast notifications |
| `PlayerSkin` | `src/gameplay/PlayerSkin.gd` | Character + cosmetic equip state |
| `MutatorSystem` | `src/core/MutatorSystem.gd` | Active mutators for current run; apply() at level load |
| `GhostLibrary` | `src/core/GhostLibrary.gd` | Persists and retrieves ghost run data (personal_best, family_champion, imported) |

## Test suite (27 stages)

| Stage | Script | Marker |
|-------|--------|--------|
| 0 | `validate_brl.py` + `check_movements.py` | Python |
| 1 | `tests/smoke/run_smoke_tests.gd` | `SMOKE_OK` |
| 2 | `tests/integration/director_test.gd` | `DIRECTOR_OK` |
| 3 | `tests/integration/collision_test.gd` | `COLLISION_OK` |
| 4 | `tests/integration/obstacle_test.gd` | `OBSTACLE_OK` |
| 5 | `tests/integration/geometry_test.gd` | `GEOMETRY_OK` |
| 6 | `tests/integration/game_flow_test.gd` | `GAME_FLOW_OK` |
| 7 | `tests/integration/save_test.gd` | `SAVE_OK` |
| 8 | `tests/integration/settings_test.gd` | `SETTINGS_OK` |
| 9 | `tests/integration/registry_test.gd` | `REGISTRY_OK` |
| 10 | `tests/integration/speed_zone_test.gd` | `SPEED_ZONE_OK` |
| 11 | `tests/integration/juice_test.gd` | `JUICE_OK` |
| 12 | `tests/integration/checkpoint_test.gd` | `CHECKPOINT_OK` |
| 13 | `tests/integration/economy_test.gd` | `ECONOMY_OK` |
| 14 | `tests/integration/obstacle_z3_test.gd` | `OBSTACLE_Z3_OK` |
| 15 | `tests/integration/obstacle_z4_test.gd` | `OBSTACLE_Z4_OK` |
| 16 | `tests/integration/vbpm_test.gd` | `VBPM_OK` |
| 17 | `tests/integration/obstacle_z6_test.gd` | `OBSTACLE_Z6_OK` |
| 18 | `tests/integration/buildmode_test.gd` | `BUILDMODE_OK` |
| 19 | `tests/integration/playtest.gd` | `PLAYTEST_OK` |
| 20 | `tests/integration/save_v3_test.gd` | `SAVE_V3_OK` |
| 21 | `tests/integration/resonance_test.gd` | `RESONANCE_OK` |
| 22 | `tests/integration/ghost_test.gd` | `GHOST_OK` |
| 23 | `tests/integration/capsule_test.gd` | `CAPSULE_OK` |
| 24 | `tests/integration/pass_play_test.gd` | `PASS_PLAY_OK` |
| 25 | `tests/integration/mutator_test.gd` | `MUTATOR_OK` |

## Level format (.brl)

Schema: `docs/design/level_schema.json` (v1.1)

Key fields:
- `metadata.id`: official = `z1-l1` … `z6-l8`; player-created = UUID v4
- `metadata.bpm_variable`: true only for Zone 5 levels; requires `bpm_changes` array
- `beat_map[]`: each entry has `beat_index`, `lane_position`, `obstacle_type`, `parameters`
- `speed_zones[]`: `{start_beat, end_beat, speed_multiplier}` — changes scroll speed, not beat clock

Official levels: `assets/levels/z1-l1.brl` … `assets/levels/z6-l8.brl` (48 total)
Player levels: `user://profiles/<id>/levels/<uuid>.brl`

## Obstacle types (12 total)

| Type | Zones | Notes |
|------|-------|-------|
| `coral_spike` | Z1–Z2 | Static wall attachment |
| `jellyfish_drift` | Z1–Z3 | Sine-wave drift |
| `kelp_curtain` | Z2–Z3 | Positional gate (gap_y_normalized) |
| `bubble_mine` | Z2–Z4 | Proximity warning + explode |
| `current_jet` | Z2–Z5 | Beat-phased IDLE→TELEGRAPH→FIRING→COOLDOWN |
| `anchor_chain` | Z3 | Pendulum, 6 capsule segments |
| `eel_snap` | Z3–Z5 | DORMANT→TELEGRAPH→STRIKE→RETRACT |
| `lava_burst` | Z4, Z6 | DORMANT→TELEGRAPH→ERUPT |
| `pressure_wall` | Z4–Z5 | Static DDA gate (no travel_speed) or moving PressureWave (travel_speed set) |
| `dark_void` | Z5 | Screen overlay, beat-activated, no collision |
| `crystal_shard` | Z6 | Own velocity vector, bounces off canvas edges |
| `mirror_fish` | Z5–Z6 | Delays player y by N frames, approaches faster than scroll |

## Zones + unlock chain

| Zone | Name | BPM range | Unlock condition |
|------|------|-----------|-----------------|
| Z1 | Sunlit Shallows | 100 BPM | Always available |
| Z2 | Kelp Forest Canyon | 120–130 BPM | Clear Z1-L4 |
| Z3 | Shipwreck Alley | 130–145 BPM | Clear Z2-L4 |
| Z4 | Volcanic Vent Fields | 145–165 BPM | Clear Z3-L4 |
| Z5 | Twilight Trench | 80–165 BPM variable | Clear Z4-L4 |
| Z6 | Crystal Caves | 170–180 BPM | 120 total stars (secret) |

## Build Mode

Entry: `GameManager.open_build_mode()` → `scenes/buildmode/BuildModeRoot.tscn`

Key classes (all in `src/buildmode/`):
- `BuildSession` — RefCounted data model; `dirty` + `played_through` flags
- `BrlSerializer` — Atomic file write + JSON round-trip check; `played_through` gate
- `PlayabilityValidator` — Movement budget + density cap + ±80 px overlap rule
- `DifficultyTagger` — GDD §6.4 formula; override-down-only
- `ObstacleParamSchema` — Per-type param definitions for the properties panel

## Drop-in assets

See `STUB_ASSETS.md` for every stub asset spec. Drop files at listed paths; zero code changes.
