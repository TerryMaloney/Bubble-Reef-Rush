# Feature Status

Last updated: 2026-06-11 (Production Readiness A/B/C complete)

## Phases 1–13 (Foundation) — ALL COMPLETE

| System | Status |
|--------|--------|
| Save schema v2 + migration | ✅ |
| Free unlock chain (no IAP) | ✅ |
| Settings + Accessibility | ✅ |
| Asset Registry + drop-in pipeline | ✅ |
| ScrollService + speed zones | ✅ |
| Juice + fever + near-miss | ✅ |
| Practice mode + checkpoints | ✅ |
| Economy + achievements | ✅ |
| Characters + cosmetics + shop | ✅ |
| Zone 1–6 obstacles (12 types) | ✅ |
| 48 official .brl levels | ✅ |
| Build Mode (full data layer + UI) | ✅ |
| Performance sweep + CLAUDE.md | ✅ |

## Phases 14–25 (Expansion) — IN PROGRESS

| Phase | Feature | Status | Notes |
|-------|---------|--------|-------|
| 14 | Save v3 + MutatorSystem stub | ✅ DONE | 20-stage suite green |
| 15 | Resonance: Bubble Burst + Echo Shield | ✅ DONE | |
| 16 | Ghost Recording + Playback | ✅ DONE | |
| 17 | Challenge Capsules (.brrc) | ✅ DONE | |
| 18 | Pass & Play + Family Tournament | ✅ DONE | |
| 19 | Mutators (20 effects) | ✅ DONE | |
| 20 | Rule Cards + Build Mode Unlock Progression | ✅ DONE | |
| 21 | Special Levels: Character/Creator Trials + Boss Chase | ✅ DONE | 29-stage suite green |
| 22 | Secret Exits + Collection Room | ✅ DONE | 31-stage suite green; 65/65 BRL pass |
| 23 | Daily Dive + Seeded Reef + Radio Shuffle | ✅ DONE | 33-stage suite green |
| 24 | Co-Pilot Mode + Level Tennis | ✅ DONE | 35-stage suite green |
| 25 | Reef Radio Architecture + Sticker Mode + Final Polish | ✅ DONE | 36-stage suite green; 73/73 BRL pass |

## Production Readiness (Post Phase 25)

| Phase | Work | Status | Notes |
|-------|------|--------|-------|
| A | Critical wiring (MainMenu hub, LevelRoot nodes, PowerButton, export config) | ✅ DONE | |
| B | Stub UI scene layouts (CollectionRoom, DailyDive, RadioShuffle, CoPilot) | ✅ DONE | |
| C | Results polish (ghost delta, Rule Card results, LevelSelect ghost ★, MainMenu animation) | ✅ DONE | |
| D | Art & Audio integration | ⏳ Terry's task | Specs in STUB_ASSETS.md |
| E | Android export + beta test | ⏳ Terry's task | Protocol in next_session_handoff.md |

## New Autoloads (Phase 14+)

| Name | File | Status |
|------|------|--------|
| MutatorSystem | src/core/MutatorSystem.gd | ✅ all 20 effects |
| GhostLibrary | src/core/GhostLibrary.gd | ✅ Phase 16 |
| RuleCardSystem | src/core/RuleCardSystem.gd | ✅ Phase 20 |
| BuildUnlockRegistry | src/buildmode/BuildUnlockRegistry.gd | ✅ Phase 20 |
| DeterministicSeed | src/core/DeterministicSeed.gd | ⏳ Phase 23 |

## New EventBus Signals (declared in Phase 14)

All 28 expansion signals are declared in EventBus.gd and ready to use:
- Resonance: power_charged, power_activated, power_cooldown_started
- Ghost: ghost_saved, ghost_beat_delta
- Capsules: capsule_exported, capsule_imported
- Pass & Play: pass_play_next_player, pass_play_session_ended
- Mutators: mutators_changed
- Rule Cards: rule_card_result, build_unlock_earned
- Special Levels: boss_phase_changed, trial_completed
- Secrets: secret_exit_found
- Deterministic: daily_dive_completed
