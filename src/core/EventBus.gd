# Cross-scene signal bus — only signals that cross scene boundaries are declared here.
extends Node


signal player_hit
signal collectible_taken(value: int)
signal run_started(level_id: String)
signal run_failed(level_id: String, score: int)
signal run_completed(level_id: String, score: int, stars: int)
## Emitted periodically by LevelLoader as the level plays, pct in 0.0–100.0.
signal run_progress(level_id: String, pct: float)
signal buildmode_level_saved(path: String)
signal active_profile_changed(profile_id: String)
signal level_load_requested(level_id_or_path: String)
signal retry_requested
signal pause_requested
signal resume_requested
## Emitted by HUDController after every timing judgement so SFXManager can
## play the appropriate sound without coupling to TimingJudge directly.
signal beat_judged(result: int)
## Emitted by FeverController when combo reaches 30. Cleared on MISS.
signal fever_started
signal fever_ended
## Emitted by NearMissDetector when an obstacle passes the player without a hit.
signal near_miss
## Additional score to add, emitted by FeverController for fever bonuses.
signal score_bonus(amount: int)
## Practice mode: checkpoint saved by PracticeController.
signal practice_checkpoint_saved
## Practice mode: emitted by LevelLoader.restart_from_beat() so fever/NMD reset.
signal practice_respawned
## Economy and meta-progression signals.
signal coins_changed(profile_id: String, new_total: int)
signal achievement_unlocked(achievement_id: String, name: String)
signal character_unlocked(char_id: String)
signal treasure_coin_collected(level_id: String, coin_idx: int)

## Resonance Powers (Phase 15)
signal power_charged(pct: float)
signal power_activated(power_type: String, is_perfect: bool)
signal power_cooldown_started()

## Ghost system (Phase 16)
signal ghost_saved(level_id: String, ghost_type: String)
signal ghost_beat_delta(seconds: float)

## Challenge Capsules (Phase 17)
signal capsule_exported(path: String)
signal capsule_imported(level_id: String)

## Pass & Play (Phase 18)
signal pass_play_next_player(profile_id: String)
signal pass_play_session_ended(results: Array)

## Mutators (Phase 19)
signal mutators_changed(active: Array)

## Rule Cards + Build Mode unlocks (Phase 20)
signal rule_card_result(card_id: String, passed: bool)
signal build_unlock_earned(category: String, item_id: String)

## Special Levels — boss + trials (Phase 21)
signal boss_phase_changed(boss_id: String, phase: int)
signal trial_completed(trial_id: String, unlock_id: String)

## Secrets (Phase 22)
signal secret_exit_found(level_id: String, exit_id: String)

## Deterministic replay (Phase 23)
signal daily_dive_completed(date: String, score: int)

## Hazard warnings (Batch C) — emitted by obstacles and mutators before they activate.
signal hazard_warning(text: String)
