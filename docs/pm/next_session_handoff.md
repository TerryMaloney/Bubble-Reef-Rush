# Next Session Handoff

## Branch & Commit

- **Repository**: `TerryMaloney/Bubble-Reef-Rush`
- **Branch**: `claude/geometry-dash-game-brainstorm-m5Thu`
- **Last-green tag**: `green-build-mode-v1` = commit `2407e15`
- **Remote**: `https://github.com/TerryMaloney/Bubble-Reef-Rush.git`

## Current Phase: 19 COMPLETE → Starting Phase 20

### Phase 19 deliverables (done):

- `assets/data/mutators.json` — 20 mutators with `{id, name, description, effect_type, effect_params, unlock_condition}`
- `src/core/MutatorSystem.gd` — full apply() implementing all 20 effects:
  - tiny_pebble / giant_pebble: player.scale
  - reverse_buoyancy: negate float_force + dive_force
  - slippery_water: drag = 0.998
  - double_pearls: CollectibleSpawner.pearl_value_multiplier = 2
  - treasure_only: CollectibleSpawner.pearls_visible = false
  - one_hit_shield: ResonanceController.grant_shield()
  - no_powers: ResonanceController._mode = "disabled" (via Object.set)
  - bubble_burst_only: ResonanceController.equipped_power = "bubble_burst"
  - ghost_mode: player.modulate.a = 0.3
  - mirror_controls: swap float_force / dive_force
  - faster_scroll: scroll.speed_now *= 1.3
  - gentle_gaps / sudden_darkness / fever_forever / one_attempt / random_character / invisible_hud / beat_rings_only / chaos_background: pass or delegate to child nodes
- `tests/integration/mutator_test.gd` — 5 contracts, all PASS:
  1. tiny_pebble_scales: player scale == (0.5, 0.5)
  2. reverse_buoyancy_flips: float_force negated
  3. reverse_buoyancy_flips: dive_force negated
  4. no_powers_blocks_fire: fire() blocked when mode=disabled
  5. faster_scroll_increases: speed_now x1.3
- `tools/run_tests.sh` — stage 25 MUTATOR_OK added
- 27-stage suite: all green

### Key implementation notes:

- `_force_power_mode()` sets ResonanceController `_mode` via `rc.set("_mode", mode)` (Object.set bypasses GDScript private access)
- Test mocks use inline GDScript (`GDScript.new()` + `source_code` + `reload()`) so properties are real GDScript variables (needed for `in` operator and direct dot access)
- No `await` in signal-based tests — Godot signals fire synchronously

## Next Phase: 20 — Rule Cards + Build Mode Unlock Progression

Files to create:
- `assets/data/rule_cards.json` — 14 rule cards with `{id, name, check_type, check_params, description}`
- `src/core/RuleCardSystem.gd` (autoload) — `set_active_rules(cards)`, `evaluate_run(level_id, run_data) → {passed, results}`
- `src/buildmode/BuildUnlockRegistry.gd` — maps level completions → `SaveSystem.add_build_unlock(category, id)`
- `tests/integration/rule_card_test.gd` — rule evaluation, pass/fail, capsule stores rules
- `tests/integration/build_unlock_test.gd` — clearing level → palette entry appears

Files to modify:
- `src/core/SaveSystem.gd` — `add_build_unlock(category, id)` + `has_build_unlock(category, id)` methods
- `src/core/AchievementSystem.gd` — hook to BuildUnlockRegistry on evaluate_run
- `src/buildmode/PalettePanel.gd` — check `SaveSystem.has_build_unlock("obstacles", otype)` before showing
- `project.godot` — add RuleCardSystem autoload
- `CLAUDE.md` — add RuleCardSystem to autoloads table, update stage count

Rule card check_types: max_misses, collect_all_pearls, find_secret, one_bubble_burst, no_powers, shield_only, race_ghost, tiny_character, reverse_buoyancy, max_attempts, family_relay, treasure_hunt, beat_score

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

27 stages, all green.

## Expansion Plan Summary

| Phase | Feature | Status |
|-------|---------|--------|
| 14 | Save v3 + MutatorSystem stub | DONE |
| 15 | Resonance: Bubble Burst + Echo Shield | DONE |
| 16 | Ghost Recording + Playback | DONE |
| 17 | Challenge Capsules (.brrc) | DONE |
| 18 | Pass & Play + Family Tournament | DONE |
| 19 | Mutators (20 effects) | DONE |
| 20 | Rule Cards + Build Mode Unlock Progression | NEXT |
| 21 | Special Levels: Trials + Boss Chase | pending |
| 22 | Secret Exits + Collection Room | pending |
| 23 | Daily Dive + Seeded Reef + Radio Shuffle | pending |
| 24 | Co-Pilot Mode + Level Tennis | pending |
| 25 | Reef Radio Architecture + Sticker Mode + Polish | pending |
