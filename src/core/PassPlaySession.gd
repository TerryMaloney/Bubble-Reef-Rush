## PassPlaySession — manages a local pass-and-play turn sequence for 2-4 players.
## Tracks per-player scores, rotates profiles, assigns funny titles at end.
extends RefCounted

class_name PassPlaySession

enum Mode { ONE_ATTEMPT = 1, THREE_ATTEMPTS = 3 }

signal turn_started(profile_id: String)
signal session_ended(results: Array)

## Public read-only view — set by setup(), consumed by scoreboard / play-again.
var level_id: String = ""
var profiles: Array[String] = []
var mode: int = Mode.ONE_ATTEMPT

var _profiles: Array[String] = []
var _scores: Dictionary = {}   # profile_id -> int
var _attempts: Dictionary = {}  # profile_id -> int
var _current_idx: int = 0
var _max_attempts: int = 1
var _level_id: String = ""
var _active: bool = false


func setup(profiles_in: Array[String], level_id_in: String, attempts_per_player: int = 1) -> void:
	_profiles = profiles_in.duplicate()
	_level_id = level_id_in
	_max_attempts = maxi(1, attempts_per_player)
	_current_idx = 0
	_scores.clear()
	_attempts.clear()
	_active = true
	for pid: String in _profiles:
		_scores[pid] = 0
		_attempts[pid] = 0
	# Expose public view.
	level_id = _level_id
	profiles = _profiles.duplicate()
	mode = _max_attempts


func get_current_profile() -> String:
	if _profiles.is_empty():
		return ""
	return _profiles[_current_idx % _profiles.size()]


func submit_score(profile_id: String, score: int) -> void:
	if not _active:
		return
	if profile_id in _scores:
		_scores[profile_id] = maxi(int(_scores[profile_id]), score)
	if profile_id in _attempts:
		_attempts[profile_id] = int(_attempts[profile_id]) + 1


func advance_turn() -> bool:
	_current_idx += 1
	var pid: String = get_current_profile()
	if _all_done():
		_active = false
		EventBus.pass_play_session_ended.emit(_build_results())
		return false
	EventBus.pass_play_next_player.emit(pid)
	return true


func _all_done() -> bool:
	for pid: String in _profiles:
		if int(_attempts.get(pid, 0)) < _max_attempts:
			return false
	return true


func get_results() -> Array[Dictionary]:
	return _build_results()


func _build_results() -> Array[Dictionary]:
	var results: Array[Dictionary] = []
	for pid: String in _profiles:
		results.append({
			"profile_id": pid,
			"total_score": int(_scores.get(pid, 0)),
			"funny_title": funny_title(pid),
		})
	results.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.get("total_score", 0)) > int(b.get("total_score", 0))
	)
	return results


func funny_title(profile_id: String) -> String:
	var score: int = int(_scores.get(profile_id, 0))
	if score >= 900:
		return "Reef Champion"
	elif score >= 600:
		return "Pearl Hoarder"
	elif score >= 300:
		return "Deep Diver"
	else:
		return "Bubble Rookie"


func get_scores() -> Dictionary:
	return _scores.duplicate()


func is_active() -> bool:
	return _active


func get_profile_count() -> int:
	return _profiles.size()
