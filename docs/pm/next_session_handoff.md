# Next Session Handoff

## Branch & Commit

- **Repository**: `TerryMaloney/Bubble-Reef-Rush`
- **Branch**: `claude/geometry-dash-game-brainstorm-m5Thu`
- **Last-green tag**: `green-build-mode-v1` = commit `2407e15`
- **Remote**: `https://github.com/TerryMaloney/Bubble-Reef-Rush.git`

## Current Phase: 20 COMPLETE → Starting Phase 21

### Phase 20 deliverables (done):

- `assets/data/rule_cards.json` — 14 rule cards (no_miss, one_miss, collect_all_pearls, beat_my_score, treasure_hunt, no_powers, one_burst, shield_only, speed_run, tiny_challenge, upside_down, find_secret, family_run, high_tide)
- `src/core/RuleCardSystem.gd` (autoload):
  - `active_rules: Array[String]` — set before a run
  - `set_active_rules(cards: Array) -> void`
  - `evaluate_run(level_id, run_data) -> {passed: bool, results: Array}`
  - Emits `EventBus.rule_card_result(card_id, passed)` per card
  - Lazy-loads rule_cards.json on first evaluate_run call (res:// VFS not ready during _ready())
- `src/buildmode/BuildUnlockRegistry.gd` (autoload):
  - `check_unlocks(profile_id, level_id, stars) -> void`
  - Zone-based unlock table: z2→current_jet, z3→anchor_chain+eel_snap, z4→lava_burst+pressure_wall, z5→dark_void+mirror_fish, z6→crystal_shard
  - Called from AchievementSystem.evaluate_run() after every run
- `src/buildmode/PalettePanel.gd` modified:
  - `_available_types: Array[String]` — only unlocked obstacle types shown
  - refresh_palette() filters by `SaveSystem.has_build_unlock(profile_id, "obstacles", otype)`
  - `_on_btn_pressed()` uses `_available_types.find()` for indexing (not raw types_for_zone)
- `src/core/AchievementSystem.gd` modified:
  - `evaluate_run()` now calls `BuildUnlockRegistry.check_unlocks(profile_id, _level_id, _stars)` at end
- `project.godot` modified: RuleCardSystem and BuildUnlockRegistry added as autoloads
- `tests/integration/rule_card_test.gd` — 9 contracts, all PASS
- `tests/integration/build_unlock_test.gd` — 5 contracts, all PASS
- `tools/run_tests.sh` — stages 26+27 added (RULE_CARD_OK, BUILD_UNLOCK_OK)
- 29-stage suite: all green

### Key implementation notes:

- **Lazy loading**: RuleCardSystem._load_cards() called lazily on first evaluate_run(), not in _ready(). This is because FileAccess.open("res://...") fails silently during _ready() for late-position autoloads in headless mode. FileAccess.get_file_as_string() always fails in this context. Use FileAccess.open() pattern like AchievementSystem, plus lazy call from the first method that needs data.
- **Test profile creation**: build_unlock tests require ss.ensure_profile(profile_id) before calling add_build_unlock, since SaveSystem won't create the profile directory automatically.
- **Default build unlocks**: Save schema v3 already has default obstacles: ["coral_spike", "jellyfish_drift", "kelp_curtain", "bubble_mine"]. Only z3-z6 content needs to be earned via play.

## Next Phase: 21 — Special Levels: Character Trials, Creator Trials, Boss Chase

Files to create:
- Level metadata extension: add `level_type` ("standard"|"boss_chase"|"character_trial"|"creator_trial"|"treasure_hunt"), `character_id`, `boss_id`, `trial_unlock_id` fields
- `src/gameplay/SpecialLevelController.gd` — reads metadata.level_type at LevelRoot._ready, applies setup
- `assets/levels/trials/ct_default.brl` through `ct_grumble.brl` — 8 character trial levels (Z1 difficulty)
- `assets/levels/trials/crtr_jets.brl` through `crtr_boss.brl` — 5 creator trial levels
- `assets/levels/bosses/boss_z3.brl` through `boss_z6.brl` — 4 boss chase levels
- `src/gameplay/bosses/boss_z3.gd` through `boss_z6.gd` — boss pattern scripts

Files to modify:
- `tools/validate_brl.py` — accept new level_type values in schema check
- `STUB_ASSETS.md` — boss sprite keys, trial completion banner sprites
- `CLAUDE.md` — updated stage count + SpecialLevelController

Tests: `special_level_test.gd` — trial unlock logic, boss state machine phases, character trial → save flag

## Test Suite Status

| Stage | Test | Status |
|-------|------|--------|
| 0 | BRL schema + movement validation | PASS |
| 1-20 | All original + save_v3 stages | PASS |
| 21 | resonance_test.gd | PASS |
| 22 | ghost_test.gd | PASS |
| 23 | capsule_test.gd | PASS |
| 24 | pass_play_test.gd | PASS |
| 25 | mutator_test.gd | PASS |
| 26 | rule_card_test.gd | PASS |
| 27 | build_unlock_test.gd | PASS |

29 stages, all green.

## Expansion Plan Summary

| Phase | Feature | Status |
|-------|---------|--------|
| 14 | Save v3 + MutatorSystem stub | DONE |
| 15 | Resonance: Bubble Burst + Echo Shield | DONE |
| 16 | Ghost Recording + Playback | DONE |
| 17 | Challenge Capsules (.brrc) | DONE |
| 18 | Pass & Play + Family Tournament | DONE |
| 19 | Mutators (20 effects) | DONE |
| 20 | Rule Cards + Build Mode Unlock Progression | DONE |
| 21 | Special Levels: Trials + Boss Chase | NEXT |
| 22 | Secret Exits + Collection Room | pending |
| 23 | Daily Dive + Seeded Reef + Radio Shuffle | pending |
| 24 | Co-Pilot Mode + Level Tennis | pending |
| 25 | Reef Radio Architecture + Sticker Mode + Polish | pending |
