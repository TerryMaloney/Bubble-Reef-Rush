## GhostRecorder — captures player dive/float events at beat positions.
## Attach to LevelRoot. Call start() when a run begins, stop(score) when done.
## Provides get_ghost_data(level_id, game_version) for GhostLibrary to persist.
extends Node

class_name GhostRecorder

var _recording: bool = false
var _inputs: Array = []   # Array of {beat: float, event: String}
var _start_time_ms: int = 0


func start() -> void:
	_inputs.clear()
	_recording = true
	_start_time_ms = Time.get_ticks_msec()


func stop(_score: int) -> void:
	_recording = false


func is_empty() -> bool:
	return _inputs.is_empty()


func record_event(beat_position: float, event_name: String) -> void:
	if not _recording:
		return
	_inputs.append({"beat": beat_position, "event": event_name})


func get_ghost_data(level_id: String, game_version: String) -> Dictionary:
	return {
		"level_id": level_id,
		"game_version": game_version,
		"level_hash": "",
		"final_score": 0,
		"inputs": _inputs.duplicate(true),
		"recorded_at": Time.get_datetime_string_from_system(),
	}


func get_input_count() -> int:
	return _inputs.size()


func get_inputs() -> Array:
	return _inputs.duplicate(true)
