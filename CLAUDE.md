# Bubble Reef Rush

Underwater rhythm runner for kids (ages 6–12), inspired by Geometry Dash.
Built in Godot 4 (GDScript). Android-first, also targets iOS.

## Project Structure

- `docs/design/` — Game Design Document, level schema, obstacle catalog
- `docs/art/` — Art bible, asset manifest, placeholder specs
- `docs/audio/` — Audio bible, AI music prompts, asset manifest
- `docs/narrative/` — World bible, zone lore, all UI copy strings
- `docs/compliance/` — COPPA, Google Play Families, Apple Kids checklists
- `docs/business/` — Monetization spec, IAP catalog
- `docs/store/` — Google Play and App Store listing copy
- `docs/human/` — Step-by-step guide for everything a human must do
- `docs/pm/` — Project state, agent team reference
- `src/core/` — GameManager, PlayerController, ObstacleSpawner, ScoreSystem, SaveSystem
- `src/rhythm/` — BeatConductor, TimingJudge, RhythmMap
- `src/ui/` — All Godot UI scenes
- `src/tools/level_editor/` — In-editor level builder plugin
- `levels/` — Level JSON files (must conform to docs/design/level_schema.json)
- `assets/art/` — Sprites, animations (populated by human/artist)
- `assets/audio/music/` — Zone music tracks as OGG files
- `assets/audio/sfx/` — Sound effects as OGG files
- `export/` — Godot export presets
- `ci/` — GitHub Actions workflows

## Agent Team

See `docs/pm/project_state.json` for current agent status.
See `docs/pm/agent_team.md` for full role descriptions and handoff contracts.

## Key Docs

- GDD: `docs/design/GDD.md`
- Level Schema: `docs/design/level_schema.json`
- Art Bible: `docs/art/art_bible.md`
- Audio Bible + AI Music Prompts: `docs/audio/audio_bible.md`
- Human Setup Guide: `docs/human/setup_guide.md`

## Tech Stack

- Engine: Godot 4.3 (GDScript, typed)
- Platform: Android API 33+ (primary), iOS 16+ (secondary)
- Audio sync: `AudioServer.get_time_since_last_mix()` + latency compensation
- Level format: JSON (schema at `docs/design/level_schema.json`)
- Architecture: Signal-based via EventBus autoload

## Music Integration (Quick Reference)

Drop OGG files into `assets/audio/music/` with these exact names:
- `zone_1_sunlit_shallows.ogg`
- `zone_2_kelp_forest.ogg`
- `zone_3_shipwreck_alley.ogg`
- `zone_4_volcanic_vents.ogg`
- `zone_5_twilight_trench.ogg`
- `zone_6_crystal_caves.ogg`

See `docs/audio/audio_bible.md` for full spec and AI music generator prompts.
