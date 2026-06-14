# Bubble Reef Rush — Developer Reference

Underwater rhythm runner for kids (ages 6–12), Geometry Dash style.
Godot 4.6 (GDScript, typed). Portrait 1080×1920. Android-first.

## Quick commands

```bash
# Run full test suite (49 stages, ~6 min)
GODOT=/tmp/Godot_v4.6.3-stable_linux.x86_64 ./tools/run_tests.sh

# Validate all .brl level files (73 total)
python3 tools/validate_brl.py assets/levels/
python3 tools/check_movements.py assets/levels/

# Generate Zone click-track WAV stubs (audio fallbacks)
python3 tools/gen_audio.py

# Android export (requires Godot templates + keystore in Godot editor)
godot --headless --export-release Android bubble_reef_rush.apk
```

## Project structure

```
src/
  core/           GameManager, SaveSystem, EventBus, GameConstants,
                  AssetRegistry, VisualFactory, TransitionLayer,
                  EconomyService, AchievementSystem, LevelLoader,
                  MutatorSystem, GhostLibrary, RuleCardSystem,
                  CapsuleSerializer, PassPlaySession, DeterministicSeed
  rhythm/         BeatConductor, TimingJudge, RhythmMap, BeatVisualizer
  gameplay/       LevelRoot, ObstacleSpawner, CollectibleSpawner,
                  ScrollService, DifficultyDirector, PlayerController,
                  JuiceDirector, FXFactory, FeverController,
                  NearMissDetector, PracticeController, BackgroundController,
                  ResonanceController, GhostRecorder, GhostPlayer,
                  SpecialLevelController, CoPilotController
  gameplay/obstacles/   14 obstacle scripts (12 core + SecretExit + GravityWell)
  gameplay/collectibles/ Pearl, TreasureCoin
  gameplay/powers/      BubbleBurst, EchoShield
  gameplay/bosses/      boss_z3, boss_z4, boss_z5, boss_z6
  buildmode/      BuildSession, BrlSerializer, PlayabilityValidator,
                  DifficultyTagger, ObstacleParamSchema,
                  BuildModeRoot, TimelineView, PalettePanel,
                  PropertiesPanel, PlaybackBar, BuildUnlockRegistry
  ui/             HUDController, AchievementToast,
                  ReefRivalsScreen, PartyHubScreen, CollectionRoomScreen,
                  DailyDiveScreen, RadioShuffleScreen, CoPilotSetupScreen,
                  PassPlaySetupScreen, PassPlayNextPlayerScreen,
                  PassPlayScoreboardScreen, ChallengeExportScreen,
                  ChallengeImportScreen
  audio/          SFXManager

scenes/
  gameplay/       LevelRoot, MainMenu, ZoneSelect, LevelSelect,
                  ResultsScreen, SettingsScreen, PauseMenu, GhostPlayer
  gameplay/powers/ BubbleBurst.tscn
  buildmode/      BuildModeRoot.tscn
  obstacles/      14 obstacle scenes
  player/         Player.tscn
  ui/             ReefRivalsScreen, PartyHubScreen, CollectionRoomScreen,
                  DailyDiveScreen, RadioShuffleScreen, CoPilotSetupScreen,
                  PassPlaySetupScreen, PassPlayNextPlayerScreen,
                  PassPlayScoreboardScreen, ChallengeExportScreen,
                  ChallengeImportScreen

assets/
  levels/         48 .brl files (z1-l1 … z6-l8)
  levels/trials/  8 character trials (ct_*.brl) + 5 creator trials (crtr_*.brl)
  levels/bosses/  4 boss chase levels (boss_z3–z6.brl)
  levels/space/   8 Space Bubble stubs (sb_l1–sb_l8.brl)
  data/           achievements.json, powers.json, mutators.json,
                  rule_cards.json, blueprints.json, worlds.json
  asset_manifest.json

tests/
  smoke/          run_smoke_tests.gd
  integration/    39 headless test scripts
tools/
  run_tests.sh    45-stage headless suite runner
  validate_brl.py JSON-schema validation for .brl files
  check_movements.py  Movement budget + speed-zone readability checks
  gen_audio.py    Procedural WAV click-track generator
```

## Autoloads (project.godot order)

| Name | Script | Purpose |
|------|--------|---------|
| `GameManager` | `src/core/GameManager.gd` | Scene state machine, level lifecycle |
| `EventBus` | `src/core/EventBus.gd` | Cross-scene signals (28 expansion signals) |
| `SaveSystem` | `src/core/SaveSystem.gd` | Profile progress, v3 schema + migration |
| `BeatConductor` | `src/rhythm/BeatConductor.gd` | Fixed + variable BPM clock, beat signals |
| `Accessibility` | `src/core/Accessibility.gd` | Timing offset, wide windows, text scale, colorblind |
| `GameConstants` | `src/core/GameConstants.gd` | Canvas 1080×1920, speeds, timing windows |
| `AssetRegistry` | `src/core/AssetRegistry.gd` | Manifest-driven asset lookup with fallbacks |
| `VisualFactory` | `src/core/VisualFactory.gd` | Texture-or-placeholder obstacle visuals |
| `ScrollService` | `src/gameplay/ScrollService.gd` | Per-beat scroll speed table |
| `FXFactory` | `src/gameplay/FXFactory.gd` | Pooled CPUParticles2D one-shots |
| `TransitionLayer` | `src/core/TransitionLayer.gd` | 0.25 s fade between scenes |
| `SFXManager` | `src/audio/SFXManager.gd` | SFX playback via AssetRegistry |
| `EconomyService` | `src/core/EconomyService.gd` | Coin grants, treasure coin persistence |
| `AchievementSystem` | `src/core/AchievementSystem.gd` | Rule-engine over achievements.json |
| `AchievementToast` | `src/ui/AchievementToast.gd` | Queued toast notifications |
| `PlayerSkin` | `src/gameplay/PlayerSkin.gd` | Character + cosmetic equip state |
| `MutatorSystem` | `src/core/MutatorSystem.gd` | Active mutators; apply() at level load |
| `GhostLibrary` | `src/core/GhostLibrary.gd` | Ghost persistence (personal_best, family_champion, imported) |
| `RuleCardSystem` | `src/core/RuleCardSystem.gd` | Active rule cards; evaluate_run() + last_results |
| `BuildUnlockRegistry` | `src/buildmode/BuildUnlockRegistry.gd` | Level clears → Build Mode palette unlocks |
| `DeterministicSeed` | `src/core/DeterministicSeed.gd` | LCG seeding for Daily Dive + Seeded Reef |

## Main Menu structure

Six hub sections — each opens as an overlay child of MainMenu (queue_free() to close):
- **Journey** → ZoneSelect → LevelSelect → LevelRoot (full scene transition)
- **Create** → BuildModeRoot (full scene transition)
- **Reef Rivals** → ReefRivalsScreen (Pass & Play, Ghost Challenge, Import)
- **Party** → PartyHubScreen (5 modes: Pass & Play, Tournament, Co-Pilot, Ghost, Chain Build)
- **Radio Shuffle** → RadioShuffleScreen (Daily Dive + 5 shuffle modes)
- **Collection Room** → CollectionRoomScreen (Characters, Trophies, Blueprints, Records)

## LevelRoot scene nodes (scenes/gameplay/LevelRoot.tscn)

| Node | Script | Notes |
|------|--------|-------|
| LevelLoader | LevelLoader.gd | Reads .brl, drives beat_map |
| ObstacleSpawner | ObstacleSpawner.gd | Lookahead spawning, 14 obstacle types |
| CollectibleSpawner | CollectibleSpawner.gd | Pearl + TreasureCoin |
| DifficultyDirector | DifficultyDirector.gd | DDA: assist + push knobs |
| JuiceDirector | JuiceDirector.gd | Camera shake, hit-stop, death slow-mo |
| FeverController | FeverController.gd | Combo-gated fever mode |
| BackgroundController | BackgroundController.gd | Zone palette + beat pulse |
| PracticeController | PracticeController.gd | Checkpoint respawn |
| ResonanceController | ResonanceController.gd | Charge meter + power activation |
| GhostRecorder | GhostRecorder.gd | Beat-position input capture |
| HUD/ResonanceChargeBar | (ProgressBar) | Live charge level |
| HUD/PowerButton | (Button ⚡) | Tap to fire equipped power |

SpecialLevelController is created lazily by LevelRoot on run_started when level_type != "standard".

## Special level types

| level_type | ID format | Files | Purpose |
|-----------|-----------|-------|---------|
| `character_trial` | `ct_<name>` | `assets/levels/trials/ct_*.brl` | Unlocks character on ≥1★ |
| `creator_trial` | `crtr_<name>` | `assets/levels/trials/crtr_*.brl` | Unlocks Build Mode content |
| `boss_chase` | `boss_z<n>` | `assets/levels/bosses/boss_z*.brl` | Multi-phase boss encounter |
| `treasure_hunt` | any | any | Treats all collectibles as targets |

Boss scripts: `src/gameplay/bosses/boss_z{3-6}.gd` — each defines `get_phases() -> Array`

## Test suite (49 stages)

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
| 26 | `tests/integration/rule_card_test.gd` | `RULE_CARD_OK` |
| 27 | `tests/integration/build_unlock_test.gd` | `BUILD_UNLOCK_OK` |
| 28 | `tests/integration/special_level_test.gd` | `SPECIAL_LEVEL_OK` |
| 29 | `tests/integration/secret_exit_test.gd` | `SECRET_EXIT_OK` |
| 30 | `tests/integration/collection_room_test.gd` | `COLLECTION_ROOM_OK` |
| 31 | `tests/integration/seeded_test.gd` | `SEEDED_OK` |
| 32 | `tests/integration/daily_dive_test.gd` | `DAILY_DIVE_OK` |
| 33 | `tests/integration/copilot_test.gd` | `COPILOT_OK` |
| 34 | `tests/integration/level_tennis_test.gd` | `LEVEL_TENNIS_OK` |
| 35 | `tests/integration/reef_radio_test.gd` | `REEF_RADIO_OK` |
| 36 | `tests/integration/settings_scene_test.gd` | `SETTINGS_SCENE_OK` |
| 37 | `tests/integration/collection_room_scene_test.gd` | `COLLECTION_ROOM_SCENE_OK` |
| 38 | `tests/integration/challenge_import_scene_test.gd` | `CHALLENGE_IMPORT_SCENE_OK` |
| 39 | `tests/integration/theme_test.gd` | `THEME_OK` |
| 40 | `tests/integration/profile_manager_scene_test.gd` | `PROFILE_MANAGER_SCENE_OK` |
| 41 | `tests/integration/zone_select_scene_test.gd` | `ZONE_SELECT_SCENE_OK` |
| 42 | `tests/integration/pass_play_setup_scene_test.gd` | `PASS_PLAY_SETUP_SCENE_OK` |
| 43 | `tests/integration/hazard_warning_test.gd` | `HAZARD_WARNING_OK` |
| 44 | `tests/integration/pearl_reachability_test.gd` | `PEARL_REACHABILITY_OK` |
| 45 | `tests/integration/build_mode_overlay_test.gd` | `BUILD_MODE_OVERLAY_OK` |
| 46 | `tests/integration/hud_difficulty_test.gd` | `HUD_DIFFICULTY_OK` |
| 47 | `tests/integration/build_test_leak_test.gd` | `BUILD_TEST_LEAK_OK` |

## Level format (.brl)

Schema: `docs/design/level_schema.json` (v1.1)

Key fields:
- `metadata.id`: official = `z1-l1`…`z6-l8`; trials = `ct_<name>` / `crtr_<name>`; bosses = `boss_z<n>`; space = `sb_l<n>`; player-created = UUID v4
- `metadata.level_type`: "standard" | "character_trial" | "creator_trial" | "boss_chase" | "treasure_hunt"
- `metadata.zone`: 1–7 (7 = Space Bubble station)
- `metadata.power_mode`: "allowed" | "disabled" | "required" | specific power ID
- `metadata.bpm_variable`: true only for Zone 5; requires `bpm_changes` array
- `beat_map[]`: each entry has `beat_index`, `lane_position`, `obstacle_type`, `parameters`
- `speed_zones[]`: `{start_beat, end_beat, speed_multiplier}`

Totals: 73 .brl files (48 official Z1–Z6 + 8 character trials + 5 creator trials + 4 boss + 8 Space Bubble stubs)

## Obstacle types (14 in spawner)

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
| `pressure_wall` | Z4–Z5 | Static gate or moving PressureWave (travel_speed set) |
| `dark_void` | Z5 | Screen overlay, beat-activated, no collision |
| `crystal_shard` | Z6 | Own velocity, bounces off canvas edges |
| `mirror_fish` | Z5–Z6 | Delays player y by N frames |
| `secret_exit` | any | Invisible gate; Bubble Burst or fever timing activates |
| `gravity_well` | Z7 (Space Bubble stub) | Area2D effect zone; stub only |

## Zones + unlock chain

| Zone | Name | BPM range | Unlock condition |
|------|------|-----------|-----------------|
| Z1 | Sunlit Shallows | 100 BPM | Always available |
| Z2 | Kelp Forest Canyon | 120–130 BPM | Clear Z1-L4 |
| Z3 | Shipwreck Alley | 130–145 BPM | Clear Z2-L4 |
| Z4 | Volcanic Vent Fields | 145–165 BPM | Clear Z3-L4 |
| Z5 | Twilight Trench | 80–165 BPM variable | Clear Z4-L4 |
| Z6 | Crystal Caves | 170–180 BPM | 120 total stars (secret) |
| Z7 | Space Bubble (stub) | TBD | Radio Key (space_key) |

## Build Mode

Entry: `GameManager.open_build_mode()` → `scenes/buildmode/BuildModeRoot.tscn`

Key classes (all in `src/buildmode/`):
- `BuildSession` — RefCounted data model; `dirty`, `played_through`, Level Tennis sections
- `BrlSerializer` — Atomic file write + JSON round-trip; `played_through` gate
- `PlayabilityValidator` — Movement budget + density cap + ±80 px overlap rule
- `DifficultyTagger` — GDD §6.4 formula; override-down-only
- `ObstacleParamSchema` — Per-type param definitions for properties panel
- `BuildUnlockRegistry` — Maps level clears → palette unlocks

Palette unlocks: Z1–Z2 obstacles available from start; Z3+ unlock by clearing that zone's levels.

## Power system (ResonanceController)

- Charge: 5 pearls = 1 charge; `power_charged(pct)` signal updates HUD bar
- Fire: tap ⚡ PowerButton → `ResonanceController.fire()` → `power_activated(type, is_perfect)`
- `is_perfect`: beat fraction within ±0.12 window triggers bonus variant
- Powers defined in `assets/data/powers.json`: bubble_burst, echo_shield (active); magnet_pulse, beat_dash, phase_bubble (stub)
- `bubble_burst`: projectile at 1200 px/s, pops destructible obstacles
- `echo_shield`: absorbs one hit; `PlayerController.on_hit()` calls `consume_shield()` first
- Level metadata `power_mode`: "allowed" (default) | "disabled" | "required"

## Ghost system

- `GhostRecorder` in LevelRoot captures dive/float events at beat positions
- `GhostPlayer` replays inputs through same physics — deterministic (BeatConductor clock)
- `GhostLibrary.save_ghost(profile, level_id, type, data)` persists to `user://profiles/<id>/ghosts/`
- Types: `personal_best` (auto-saved when score improves), `family_champion` (best across profiles), `imported`
- `GhostLibrary.last_ghost_score`: set per-run so ResultsScreen can show delta

## Mutators

20 mutators defined in `assets/data/mutators.json`. `MutatorSystem.apply()` patches PlayerController + ScrollService at level load.
Default unlocked: `tiny_pebble`, `gentle_gaps`. Save key: `mutators_unlocked[]`.

## Rule Cards

14 rule cards in `assets/data/rule_cards.json`. `RuleCardSystem.set_active_rules()` before a run; `evaluate_run()` after.
Results in `RuleCardSystem.last_results` (read by ResultsScreen). Save key: `rule_cards_unlocked[]`.

## Save schema (v3)

Migration: v2 → v3 on first load. All new fields default to empty/zero. `.bak` written before migration.
Key top-level additions over v2:
- `powers_unlocked{}`, `equipped_power`, `build_unlocks{}`, `blueprints[]`
- `ghosts{}`, `radio_keys[]`, `daily_dive{}`, `mutators_unlocked[]`
- `rule_cards_unlocked[]`, `secret_exits_found{}`, `collection{}`

## Drop-in assets

See `STUB_ASSETS.md` for every stub asset spec. Drop files at listed paths; zero code changes.
Art priority: player character → obstacles → zone backgrounds → UI polish.
Music: convert WAV stubs to OGG (Godot requires OGG for streaming); place at `assets/audio/zone<N>_theme.ogg`.
