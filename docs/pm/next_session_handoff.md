# Next Session Handoff

## Branch & Commit

- **Repository**: `TerryMaloney/Bubble-Reef-Rush`
- **Branch**: `claude/geometry-dash-game-brainstorm-m5Thu`
- **Last pushed commit**: Phase 17 (see git log)
- **Last-green tag**: `green-build-mode-v1` = commit `2407e15`
- **Remote**: `https://github.com/TerryMaloney/Bubble-Reef-Rush.git`

## Current Phase: 17 COMPLETE → Starting Phase 18

### Phase 17 deliverables (done):

- `src/core/CapsuleSerializer.gd` (RefCounted) — `pack()/unpack()/validate()/save_capsule()/load_capsule_file()`
  - HMAC-SHA256 checksum via `Crypto.hmac_digest()` (embedded key, tamper detection only)
  - JSON type normalization fix: pack() round-trips through JSON.parse_string before computing canonical (avoids int/float mismatch after Godot 4.6 JSON parse)
  - `sort_keys=true` for deterministic canonical ordering
  - validate() returns `Array[String]`; "WARN:" prefix = non-fatal, no prefix = hard error
  - Prunes user://capsules/ to MAX_CAPSULES=100 FIFO
- `src/ui/ChallengeExportScreen.gd` + `scenes/ui/ChallengeExportScreen.tscn` — clipboard copy + Android share intent stub
- `src/ui/ChallengeImportScreen.gd` + `scenes/ui/ChallengeImportScreen.tscn` — paste code, validate, preview, import
- `tests/integration/capsule_test.gd` — 9 contracts, all PASS
- `tools/run_tests.sh` — stage 23 added (CAPSULE_OK)
- 25-stage suite: all green

### Capsule data schema:
```json
{
  "schema_ver": 1,
  "app_ver": "1.0",
  "creator_nick": "...",
  "level_id": "...",
  "level_hash": "...",
  "ghost_inputs": [{beat, event}, ...],
  "rules": [],
  "mutators": [],
  "target": {"score": 0},
  "checksum": "<HMAC-SHA256-hex>"
}
```

### Validate() issue categories:
- `""` (empty array) — fully valid
- `"checksum_mismatch"` — tampered; reject
- `"missing field: X"` — bad schema; reject
- `"unsupported schema_ver: N"` — reject
- `"incompatible_app_ver: X"` — reject
- `"WARN:old_app_ver"` — readable but old; show UI warning
- `"WARN:newer_app_ver"` — may have unknown fields; show warning
- `"WARN:level_hash_mismatch"` — level may differ; still playable

### Next Phase: 18 — Pass & Play + Family Tournament

Files to create:
- `src/core/PassPlaySession.gd` (RefCounted) — profile queue management, per-turn score, funny titles
- `scenes/ui/PassPlaySetupScreen.tscn` + `src/ui/PassPlaySetupScreen.gd`
- `scenes/ui/PassPlayNextPlayerScreen.tscn` + `src/ui/PassPlayNextPlayerScreen.gd`
- `scenes/ui/PassPlayScoreboardScreen.tscn` + `src/ui/PassPlayScoreboardScreen.gd`
- `scenes/ui/ReefRivalsScreen.tscn` + `src/ui/ReefRivalsScreen.gd` — hub for ghost challenge, pass & play, tournament, import

Files to modify:
- `src/core/SaveSystem.gd` — family_tournament.history[] (already in v3 schema)
- `src/core/EventBus.gd` — pass_play_next_player, pass_play_session_ended (already declared)
- `scenes/gameplay/MainMenu.tscn` — add Reef Rivals button

Tests: `tests/integration/pass_play_test.gd` — profile rotation, score aggregation, funny titles, tournament bracket seeding

## Test Suite Status

| Stage | Test | Status |
|-------|------|--------|
| 0 | BRL schema + movement validation | PASS |
| 1-20 | All original + save_v3 stages | PASS |
| 21 | resonance_test.gd | PASS |
| 22 | ghost_test.gd | PASS |
| 23 | capsule_test.gd | PASS |

25 stages, all green.

## Expansion Plan Summary

| Phase | Feature | Status |
|-------|---------|--------|
| 14 | Save v3 + MutatorSystem stub | DONE |
| 15 | Resonance: Bubble Burst + Echo Shield | DONE |
| 16 | Ghost Recording + Playback | DONE |
| 17 | Challenge Capsules (.brrc) | DONE |
| 18 | Pass & Play + Family Tournament | NEXT |
| 19 | Mutators (20 effects) | pending |
| 20 | Rule Cards + Build Mode Unlock Progression | pending |
| 21 | Special Levels: Trials + Boss Chase | pending |
| 22 | Secret Exits + Collection Room | pending |
| 23 | Daily Dive + Seeded Reef + Radio Shuffle | pending |
| 24 | Co-Pilot Mode + Level Tennis | pending |
| 25 | Reef Radio Architecture + Sticker Mode + Polish | pending |
