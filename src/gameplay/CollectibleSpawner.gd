# Scene-local node that reads the collectibles array from RhythmMap and spawns Pearl scenes on cue.
extends Node

class_name CollectibleSpawner

const PEARL_SCENE: String = "res://scenes/collectibles/Pearl.tscn"
const TREASURE_COIN_SCENE: String = "res://scenes/collectibles/TreasureCoin.tscn"
const SPAWN_LOOKAHEAD_BEATS: float = 4.0
const CANVAS_W: float = 1080.0
const CANVAS_H: float = 1920.0

var _pending: Array[Dictionary] = []
var _rhythm_map: RhythmMap


func setup(rhythm_map: RhythmMap, start_beat: float = 0.0) -> void:
	_rhythm_map = rhythm_map
	_pending.clear()

	# Copy collectible entries at or after start_beat and sort ascending.
	var raw: Dictionary = _rhythm_map.get_raw_data()
	var collectibles: Array = raw.get("collectibles", []) as Array
	for entry: Variant in collectibles:
		if float((entry as Dictionary).get("beat_index", 0)) < start_beat:
			continue
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
		_spawn_collectible(entry)


func _spawn_collectible(entry: Dictionary) -> void:
	var ctype: String = str(entry.get("type", "pearl"))
	var scene_path: String = PEARL_SCENE
	if ctype == "treasure_coin":
		scene_path = TREASURE_COIN_SCENE

	if not ResourceLoader.exists(scene_path):
		push_warning("CollectibleSpawner: Scene not found at '%s' — skipping." % scene_path)
		return

	var packed: PackedScene = load(scene_path) as PackedScene
	var collectible: Node2D = packed.instantiate() as Node2D

	var beat_idx: float = float(entry.get("beat_index", 0))
	collectible.position.x = ScrollService.JUDGMENT_X + ScrollService.distance_until_beat(beat_idx)
	collectible.position.y = float(entry.get("lane_position", 0.5)) * CANVAS_H

	get_parent().add_child(collectible)

	if collectible.has_method("setup"):
		collectible.setup(entry)


## Called by Pearl scene instances when the player collects them.
func on_collectible_collected(value: int) -> void:
	EventBus.collectible_taken.emit(value)
