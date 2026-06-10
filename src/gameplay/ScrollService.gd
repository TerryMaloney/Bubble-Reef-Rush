## ScrollService autoload.
## Central source for scroll speed and beat-aligned spawn placement.
## Replaces the SCROLL_SPEED = 408.0 constant duplicated across 5 entity scripts.
##
## Activate once per level after the RhythmMap is loaded:
##   ScrollService.activate(rhythm_map)
## Entities read speed_now() each frame; spawners call distance_until_beat() at spawn time.
extends Node

const BASE_SPEED: float = 408.0
## Player's fixed x in canvas space — the "judgment line" obstacles travel toward.
const JUDGMENT_X: float = 200.0
## Fallback distance when inactive: keeps spawn_x = CANVAS_W + 100 (= 1180 px).
const _INACTIVE_DISTANCE: float = 980.0

var _active: bool = false

## Per-beat entries; entry i covers beat [i, i+1).
## Keys: "speed" (px/s), "duration" (s/beat), "cum_px" (px from beat 0 to beat i start).
var _table: Array[Dictionary] = []


## Build the speed table from a loaded RhythmMap and activate the service.
## Called by LevelLoader after the map is parsed and BeatConductor is started.
func activate(rhythm_map: RhythmMap) -> void:
	_table.clear()
	var total: int = _total_beats(rhythm_map)
	var cum: float = 0.0
	for i: int in range(total + 1):
		var bpm: float = rhythm_map.get_bpm_at_beat(float(i))
		var mult: float = rhythm_map.get_speed_multiplier_at_beat(float(i))
		var duration: float = 60.0 / bpm
		var speed: float = BASE_SPEED * mult
		_table.append({"speed": speed, "duration": duration, "cum_px": cum})
		cum += duration * speed
	_active = true


## Clear the table. Called when the level ends or run_failed fires.
func deactivate() -> void:
	_active = false
	_table.clear()


## Current scroll speed in px/s.
## Returns BASE_SPEED when no level is active so existing tests keep passing.
func speed_now() -> float:
	if not _active or _table.is_empty():
		return BASE_SPEED
	var beat: float = BeatConductor.get_current_beat_position()
	return _speed_at(beat)


## Pixels an entity spawned right now must travel before reaching JUDGMENT_X at target_beat.
## Spawners use:  obstacle.position.x = ScrollService.JUDGMENT_X + ScrollService.distance_until_beat(beat)
## When inactive, returns _INACTIVE_DISTANCE so spawn_x = JUDGMENT_X + 980 = CANVAS_W + 100.
func distance_until_beat(target_beat: float) -> float:
	if not _active or _table.is_empty():
		return _INACTIVE_DISTANCE
	var now: float = BeatConductor.get_current_beat_position()
	return maxf(0.0, _cum_px_at(target_beat) - _cum_px_at(now))


## Speed (px/s) at a fractional beat index.
func _speed_at(beat: float) -> float:
	var idx: int = clampi(int(beat), 0, _table.size() - 1)
	return float(_table[idx]["speed"])


## Cumulative pixels scrolled from beat 0 up to a fractional beat position.
func _cum_px_at(beat: float) -> float:
	if _table.is_empty():
		return 0.0
	var idx: int = clampi(int(beat), 0, _table.size() - 1)
	var frac: float = clampf(beat - float(idx), 0.0, 1.0)
	var entry: Dictionary = _table[idx]
	return float(entry["cum_px"]) + frac * float(entry["duration"]) * float(entry["speed"])


func _total_beats(rhythm_map: RhythmMap) -> int:
	var raw: Dictionary = rhythm_map.get_raw_data()
	var meta: Dictionary = raw.get("metadata", {}) as Dictionary
	var declared: int = int(meta.get("total_beats", 0))
	if declared > 0:
		return declared
	var max_beat: int = 0
	for entry: Variant in (raw.get("beat_map", []) as Array):
		var b: int = int(float((entry as Dictionary).get("beat_index", 0)))
		if b > max_beat:
			max_beat = b
	return max_beat + 8
