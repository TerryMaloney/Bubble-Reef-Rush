# Scene-local node that reads the beat_map from RhythmMap and spawns obstacle scenes on cue.
extends Node

class_name ObstacleSpawner

const SPAWN_LOOKAHEAD_BEATS: float = 4.0
const OBSTACLE_SCENE_MAP: Dictionary = {
	"coral_spike": "res://scenes/obstacles/CoralSpike.tscn",
	"jellyfish_drift": "res://scenes/obstacles/JellyfishDrift.tscn",
}

var _pending: Array[Dictionary] = []
var _rhythm_map: RhythmMap


func setup(rhythm_map: RhythmMap) -> void:
	_rhythm_map = rhythm_map
	_pending.clear()

	# Copy all beat_map entries and sort ascending by beat_index.
	var raw: Dictionary = _rhythm_map.get_raw_data()
	var beat_map: Array = raw.get("beat_map", []) as Array
	for entry: Variant in beat_map:
		_pending.append(entry as Dictionary)

	_pending.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a.get("beat_index", 0)) < float(b.get("beat_index", 0))
	)


func _process(_delta: float) -> void:
	if _rhythm_map == null or not _rhythm_map.is_loaded():
		return

	var current_beat: float = BeatConductor.get_current_beat_position()

	while _pending.size() > 0 and float(_pending[0].get("beat_index", 0)) <= current_beat + SPAWN_LOOKAHEAD_BEATS:
		var entry: Dictionary = _pending.pop_front()
		_spawn_obstacle(entry, current_beat)


func _spawn_obstacle(entry: Dictionary, _current_beat: float) -> void:
	var obstacle_type: String = str(entry.get("obstacle_type", ""))
	if not OBSTACLE_SCENE_MAP.has(obstacle_type):
		push_warning("ObstacleSpawner: Unknown obstacle type '%s' — skipping." % obstacle_type)
		return

	var scene_path: String = OBSTACLE_SCENE_MAP[obstacle_type] as String
	if not ResourceLoader.exists(scene_path):
		push_warning("ObstacleSpawner: Scene '%s' not found — skipping." % scene_path)
		return

	var packed: PackedScene = load(scene_path) as PackedScene
	var obstacle: Node2D = packed.instantiate() as Node2D

	# Spawn off the right edge; Y is the normalized lane position × screen height.
	var viewport_size: Vector2 = get_viewport_rect().size
	obstacle.position.x = viewport_size.x + 100.0
	obstacle.position.y = float(entry.get("lane_position", 0.5)) * viewport_size.y

	# Parent to the gameplay root (two levels up from this node).
	get_parent().add_child(obstacle)

	if obstacle.has_method("setup"):
		obstacle.setup(entry)
