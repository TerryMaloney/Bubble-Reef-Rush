# Feature Status

Last updated: 2026-06-11

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
| 14 | Save v3 + MutatorSystem stub | ✅ DONE | 22-stage suite green |
| 15 | Resonance: Bubble Burst + Echo Shield | ✅ DONE | |
| 16 | Ghost Recording + Playback | ⏳ NEXT | |
| 17 | Challenge Capsules (.brrc) | ⏳ | |
| 18 | Pass & Play + Family Tournament | ⏳ | |
| 19 | Mutators (20 effects) | ⏳ | |
| 20 | Rule Cards + Build Mode Unlock Progression | ⏳ | |
| 21 | Special Levels: Character/Creator Trials + Boss Chase | ⏳ | |
| 22 | Secret Exits + Collection Room | ⏳ | |
| 23 | Daily Dive + Seeded Reef + Radio Shuffle | ⏳ | |
| 24 | Co-Pilot Mode + Level Tennis | ⏳ | |
| 25 | Reef Radio Architecture + Sticker Mode + Final Polish | ⏳ | |

## New Autoloads (Phase 14+)

| Name | File | Status |
|------|------|--------|
| MutatorSystem | src/core/MutatorSystem.gd | ✅ stub, effects in Phase 19 |
| GhostLibrary | src/core/GhostLibrary.gd | ⏳ Phase 16 |
| RuleCardSystem | src/core/RuleCardSystem.gd | ⏳ Phase 20 |
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
