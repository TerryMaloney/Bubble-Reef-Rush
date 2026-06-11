## GhostRecorder — scene-local node that captures player input timing for ghost replay.
##
## Records {beat: float, event: String} pairs on every dive_start / dive_end event.
## LevelRoot calls start() on run_started, stop(score) on run_completed, and
## reads get_ghost_data() before passing it to GhostLibrary.save_ghost().
## Does NOT save anything itself — that is LevelRoot's responsibility.
extends Node

class_name GhostRecorder

var _recording: Array[Dictionary] = []
var _recording_active: bool = false
var _final_score: int = 0


func start() -> void:
	_recording.clear()
	_recording_active = true
	_final_score = 0


func stop(score: int) -> void:
	_recording_active = false
	_final_score = score


func record_event(event_type: String) -> void:
	if not _recording_active:
		return
	_recording.append({
		"beat": BeatConductor.get_current_beat_position(),
		"event": event_type,
	})


func get_ghost_data(level_id: String, game_version: String) -> Dictionary:
	return {
		"schema_ver": 1,
		"level_id": level_id,
		"game_version": game_version,
		"final_score": _final_score,
		"inputs": _recording.duplicate(true),
	}


func is_empty() -> bool:
	return _recording.is_empty()


func get_input_count() -> int:
	return _recording.size()
