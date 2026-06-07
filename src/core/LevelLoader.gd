# Scene-local node that reads the current level's .brl file and distributes data to gameplay systems.
extends Node

class_name LevelLoader

## Emitted when the last beat of the level has fired and no run_failed has occurred.
signal level_ended(level_id: String)

var rhythm_map: RhythmMap

## Obstacle and collectible spawner refs — set by LevelRoot after adding this node.
var obstacle_spawner: Node = null
var collectible_spawner: Node = null

var _total_beats: int = 0
var _level_id_meta: String = ""
var _result_emitted: bool = false


func load_level(level_id_or_path: String) -> void:
	rhythm_map = RhythmMap.new()
	add_child(rhythm_map)
	rhythm_map.map_loaded.connect(_on_map_loaded)
	rhythm_map.map_load_failed.connect(_on_map_load_failed)
	rhythm_map.load_level(level_id_or_path)


func _on_map_loaded(level_id: String) -> void:
	var raw: Dictionary = rhythm_map.get_raw_data()
	var meta: Dictionary = raw.get("metadata", {}) as Dictionary
	var music_data: Dictionary = raw.get("music", {}) as Dictionary

	var bpm: float = float(meta.get("bpm", 110.0))
	var is_variable: bool = bool(meta.get("bpm_variable", false))
	var music_filename: String = str(music_data.get("filename", ""))
	var music_path: String = "res://assets/audio/music/" + music_filename

	var music_stream: AudioStream = null
	if ResourceLoader.exists(music_path):
		music_stream = load(music_path) as AudioStream
	else:
		push_warning("LevelLoader: Music file not found at '%s'. Audio will be silent." % music_path)

	if is_variable:
		var total_beats: int = int(meta.get("total_beats", 32))
		var timestamps: Array[float] = _build_beat_timestamps(rhythm_map, total_beats)
		BeatConductor.start_level_variable_bpm(music_stream, timestamps)
	else:
		BeatConductor.start_level(bpm, music_stream)

	# Cache level-end data and arm the completion detector.
	_total_beats = int(meta.get("total_beats", 32))
	_level_id_meta = level_id
	_result_emitted = false
	BeatConductor.beat_fired.connect(_check_level_end)
	EventBus.run_failed.connect(_on_run_aborted)

	EventBus.run_started.emit(level_id)

	if obstacle_spawner != null and obstacle_spawner.has_method("setup"):
		obstacle_spawner.setup(rhythm_map)

	if collectible_spawner != null and collectible_spawner.has_method("setup"):
		collectible_spawner.setup(rhythm_map)


func _check_level_end(beat_index: int) -> void:
	if _result_emitted:
		return
	if beat_index >= _total_beats - 1:
		_result_emitted = true
		level_ended.emit(_level_id_meta)


func _on_run_aborted(_level_id: String, _score: int) -> void:
	# run_failed fired first — suppress level_ended so we don't double-transition.
	_result_emitted = true


func _on_map_load_failed(error: String) -> void:
	push_error("LevelLoader: Map load failed — " + error)
	EventBus.run_failed.emit(GameManager.current_level_id, 0)


func _build_beat_timestamps(map: RhythmMap, total_beats: int) -> Array[float]:
	var timestamps: Array[float] = []
	var t: float = 0.0
	for i: int in range(total_beats):
		timestamps.append(t)
		var beat_bpm: float = map.get_bpm_at_beat(float(i))
		t += 60.0 / beat_bpm
	return timestamps
