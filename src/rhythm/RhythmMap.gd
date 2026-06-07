## RhythmMap.gd
## Loads, validates, and caches a level's beat/obstacle timing data.
##
## Usage (instantiated per level by GameManager):
##   var rhythm_map := RhythmMap.new()
##   add_child(rhythm_map)
##   rhythm_map.map_loaded.connect(_on_map_loaded)
##   rhythm_map.load_level("z1-l1")   # or a full path override

class_name RhythmMap
extends Node

# ---------------------------------------------------------------------------
# Signals
# ---------------------------------------------------------------------------

## Emitted once the level JSON is fully parsed and cached.
signal map_loaded(level_id: String)

## Emitted if loading or validation fails. error contains a human-readable reason.
signal map_load_failed(error: String)

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

## Root directory for official level files (relative to res://).
const LEVELS_DIR: String = "res://assets/levels/"

## Music asset root (used for filename validation).
const MUSIC_DIR: String = "res://assets/audio/music/"

## Required top-level keys per level_schema.json.
const REQUIRED_KEYS: Array[String] = [
	"schema_version",
	"metadata",
	"music",
	"beat_map",
	"speed_zones",
	"background",
	"unlock_requirements",
	"par_score"
]

## Required keys inside metadata.
const REQUIRED_METADATA_KEYS: Array[String] = [
	"id", "name", "zone", "bpm", "bpm_variable", "difficulty", "author",
	"created_at", "is_official"
]

## Required keys inside music.
const REQUIRED_MUSIC_KEYS: Array[String] = [
	"filename", "loop", "loop_start_beat", "preview_start_beat",
	"preview_duration_beats"
]

# ---------------------------------------------------------------------------
# Cached parsed data
# ---------------------------------------------------------------------------

## Raw parsed JSON dictionary for the loaded level.
var _raw_data: Dictionary = {}

## level_id string from metadata.
var _level_id: String = ""

## Whether variable BPM mode is active (Zone 5).
var _bpm_variable: bool = false

## Base BPM from metadata.
var _base_bpm: float = 110.0

## BPM change events for variable-BPM levels: Array of { beat_index, new_bpm, transition_beats }.
var _bpm_changes: Array[Dictionary] = []

## Sorted array of all unique beat_index float values in the beat_map.
var _all_beats: Array[float] = []

## Map from beat_index (float, as String key for Dictionary) to Array[Dictionary].
## Each inner array holds all obstacle entries at that beat position.
var _beats_by_index: Dictionary = {}

## Sorted array of speed_zone Dictionaries (start_beat, end_beat, speed_multiplier).
var _speed_zones: Array[Dictionary] = []

## True once _cache_data() has run successfully.
var _cached: bool = false

# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

## Load a level by its ID (e.g. "z1-l1") from the default levels directory.
## The file is looked up as LEVELS_DIR + id + ".brl".
## Player-created levels can pass a full "user://…" path instead.
func load_level(level_id_or_path: String) -> void:
	_cached = false
	_raw_data = {}
	_level_id = ""

	var path: String
	if level_id_or_path.begins_with("res://") or level_id_or_path.begins_with("user://"):
		path = level_id_or_path
	else:
		path = LEVELS_DIR + level_id_or_path + ".brl"

	if not FileAccess.file_exists(path):
		var err: String = "Level file not found: %s" % path
		push_warning("RhythmMap: " + err)
		map_load_failed.emit(err)
		return

	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		var err: String = "Cannot open level file: %s (error %d)" % [path, FileAccess.get_open_error()]
		push_warning("RhythmMap: " + err)
		map_load_failed.emit(err)
		return

	var json_text: String = file.get_as_text()
	file.close()

	var json_parser: JSON = JSON.new()
	var parse_error: Error = json_parser.parse(json_text)
	if parse_error != OK:
		var err: String = "JSON parse error in %s at line %d: %s" % [
			path, json_parser.get_error_line(), json_parser.get_error_message()
		]
		push_warning("RhythmMap: " + err)
		map_load_failed.emit(err)
		return

	var data: Variant = json_parser.get_data()
	if not data is Dictionary:
		var err: String = "Level JSON root must be an object: %s" % path
		push_warning("RhythmMap: " + err)
		map_load_failed.emit(err)
		return

	_raw_data = data as Dictionary
	var validation_error: String = _validate(_raw_data)
	if not validation_error.is_empty():
		push_warning("RhythmMap: Validation failed for %s — %s" % [path, validation_error])
		map_load_failed.emit(validation_error)
		return

	_cache_data()
	map_loaded.emit(_level_id)


## Returns all obstacle entries at a given beat_index.
## beat_index may be a whole or fractional float (e.g. 4.0 or 4.5).
## Returns an empty array if no obstacles exist at that beat.
## O(1) after load.
func get_obstacles_at_beat(beat_index: float) -> Array[Dictionary]:
	if not _cached:
		return []
	var key: String = _beat_key(beat_index)
	if _beats_by_index.has(key):
		return _beats_by_index[key] as Array[Dictionary]
	return []


## Returns a sorted array of every beat_index value that has at least one
## obstacle entry. Includes fractional values (eighth/sixteenth beats).
## O(1) after load.
func get_all_beats() -> Array[float]:
	if not _cached:
		return []
	return _all_beats


## Returns the scroll speed multiplier active at the given beat_index.
## Falls back to 1.0 if no speed zone covers that beat.
## O(n) where n is speed_zones length — typically very small (<20 entries).
func get_speed_multiplier_at_beat(beat_index: float) -> float:
	for zone: Dictionary in _speed_zones:
		if beat_index >= float(zone["start_beat"]) and beat_index < float(zone["end_beat"]):
			return float(zone["speed_multiplier"])
	return 1.0


## Returns the effective BPM at the given beat index.
## For fixed-BPM levels this always returns the base BPM.
## For variable-BPM levels (bpm_variable == true) this interpolates through
## the bpm_changes array to give the instantaneous tempo at that beat.
func get_bpm_at_beat(beat_index: float) -> float:
	if not _bpm_variable or _bpm_changes.is_empty():
		return _base_bpm

	# Walk through bpm_changes in reverse to find the most recent change
	# at or before beat_index.
	var current_bpm: float = _base_bpm
	var current_change_beat: float = 0.0

	for change in _bpm_changes:
		var change_beat: float = float(change["beat_index"])
		if change_beat > beat_index:
			break
		# Interpolate if we are within the transition window.
		var transition: float = float(change["transition_beats"])
		var new_bpm: float = float(change["new_bpm"])
		if transition > 0.0 and beat_index < change_beat + transition:
			var t: float = (beat_index - change_beat) / transition
			current_bpm = lerpf(current_bpm, new_bpm, clampf(t, 0.0, 1.0))
		else:
			current_bpm = new_bpm
		current_change_beat = change_beat

	return current_bpm


## Returns the raw parsed JSON dictionary for this level.
## Useful for GameManager to extract metadata, music path, par_score etc.
func get_raw_data() -> Dictionary:
	return _raw_data


## True if a level has been successfully loaded and cached.
func is_loaded() -> bool:
	return _cached


## Returns the level ID string (e.g. "z1-l1").
func get_level_id() -> String:
	return _level_id

# ---------------------------------------------------------------------------
# Private — validation
# ---------------------------------------------------------------------------

func _validate(data: Dictionary) -> String:
	# Check top-level required keys.
	for key: String in REQUIRED_KEYS:
		if not data.has(key):
			return "Missing required top-level key: '%s'" % key

	# Validate metadata sub-object.
	var meta: Variant = data["metadata"]
	if not meta is Dictionary:
		return "metadata must be an object"
	for key: String in REQUIRED_METADATA_KEYS:
		if not (meta as Dictionary).has(key):
			return "metadata missing required key: '%s'" % key

	# Validate music sub-object.
	var music: Variant = data["music"]
	if not music is Dictionary:
		return "music must be an object"
	for key: String in REQUIRED_MUSIC_KEYS:
		if not (music as Dictionary).has(key):
			return "music missing required key: '%s'" % key

	# Warn (not fail) if the music filename does not match any known asset.
	var music_filename: String = str((music as Dictionary).get("filename", ""))
	if not music_filename.is_empty():
		var full_music_path: String = MUSIC_DIR + music_filename
		if not FileAccess.file_exists(full_music_path):
			push_warning(
				"RhythmMap: Music file reference '%s' not found at expected path '%s'. "
				% [music_filename, full_music_path] +
				"Level will load but audio will be silent."
			)

	# Validate beat_map is an array.
	if not data["beat_map"] is Array:
		return "beat_map must be an array"

	# Validate each beat_map entry has required keys.
	var beat_map: Array = data["beat_map"] as Array
	for i: int in range(beat_map.size()):
		var entry: Variant = beat_map[i]
		if not entry is Dictionary:
			return "beat_map[%d] must be an object" % i
		var e: Dictionary = entry as Dictionary
		if not e.has("beat_index"):
			return "beat_map[%d] missing 'beat_index'" % i
		if not e.has("obstacle_type"):
			return "beat_map[%d] missing 'obstacle_type'" % i
		if not e.has("lane_position"):
			return "beat_map[%d] missing 'lane_position'" % i

	# Validate speed_zones is an array.
	if not data["speed_zones"] is Array:
		return "speed_zones must be an array"

	return ""  # No error.

# ---------------------------------------------------------------------------
# Private — caching
# ---------------------------------------------------------------------------

func _cache_data() -> void:
	var meta: Dictionary = _raw_data["metadata"] as Dictionary
	_level_id = str(meta.get("id", "unknown"))
	_base_bpm = float(meta.get("bpm", 110.0))
	_bpm_variable = bool(meta.get("bpm_variable", false))

	# Cache BPM changes for variable-BPM levels.
	_bpm_changes.clear()
	if _bpm_variable and meta.has("bpm_changes") and meta["bpm_changes"] is Array:
		var raw_changes: Array = meta["bpm_changes"] as Array
		# Sort by beat_index ascending.
		var sorted_changes: Array = raw_changes.duplicate()
		sorted_changes.sort_custom(
			func(a: Variant, b: Variant) -> bool:
				return float((a as Dictionary).get("beat_index", 0)) < float((b as Dictionary).get("beat_index", 0))
		)
		for change: Variant in sorted_changes:
			_bpm_changes.append(change as Dictionary)

	# Build beat index lookup from beat_map.
	_beats_by_index.clear()
	var beat_set: Dictionary = {}  # used as a set of float keys
	var beat_map: Array = _raw_data["beat_map"] as Array

	for entry: Variant in beat_map:
		var e: Dictionary = entry as Dictionary
		var idx: float = float(e.get("beat_index", 0.0))
		var key: String = _beat_key(idx)
		if not _beats_by_index.has(key):
			_beats_by_index[key] = [] as Array[Dictionary]
			beat_set[key] = idx
		(_beats_by_index[key] as Array[Dictionary]).append(e)

	# Build sorted all_beats array.
	_all_beats.clear()
	var unsorted: Array[float] = []
	for key: String in beat_set.keys():
		unsorted.append(float(beat_set[key]))
	unsorted.sort()
	_all_beats = unsorted

	# Cache speed zones sorted by start_beat.
	_speed_zones.clear()
	var raw_zones: Array = _raw_data["speed_zones"] as Array
	var sorted_zones: Array = raw_zones.duplicate()
	sorted_zones.sort_custom(
		func(a: Variant, b: Variant) -> bool:
			return float((a as Dictionary).get("start_beat", 0)) < float((b as Dictionary).get("start_beat", 0))
	)
	for zone: Variant in sorted_zones:
		_speed_zones.append(zone as Dictionary)

	_cached = true


## Converts a float beat_index to a stable Dictionary key string.
## Uses 4 decimal places to handle sixteenth-beat positions (0.25, 0.5, 0.75, …).
func _beat_key(beat_index: float) -> String:
	return "%.4f" % beat_index
