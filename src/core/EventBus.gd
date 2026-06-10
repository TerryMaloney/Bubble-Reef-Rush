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
