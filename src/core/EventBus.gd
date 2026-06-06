# Cross-scene signal bus — only signals that cross scene boundaries are declared here.
extends Node

class_name EventBus

signal player_hit
signal collectible_taken(value: int)
signal run_started(level_id: String)
signal run_failed(level_id: String, score: int)
signal run_completed(level_id: String, score: int, stars: int)
signal buildmode_level_saved(path: String)
signal active_profile_changed(profile_id: String)
signal level_load_requested(level_id_or_path: String)
signal retry_requested
