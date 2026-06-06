# Scene-local node that reads the collectibles array from RhythmMap and spawns Pearl scenes on cue.
extends Node

class_name CollectibleSpawner

const PEARL_SCENE: String = "res://scenes/collectibles/Pearl.tscn"
const SPAWN_LOOKAHEAD_BEATS: float = 4.0

var _pending: Array[Dictionary] = []
var _rhythm_map: RhythmMap


func setup(rhythm_map: RhythmMap) -> void:
	_rhythm_map = rhythm_map
	_pending.clear()

	# Copy all collectibles entries and sort ascending by beat_index.
	var raw: Dictionary = _rhythm_map.get_raw_data()
	var collectibles: Array = raw.get("collectibles", []) as Array
	for entry: Variant in collectibles:
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
	if not ResourceLoader.exists(PEARL_SCENE):
		push_warning("CollectibleSpawner: Pearl scene not found at '%s' — skipping." % PEARL_SCENE)
		return

	var packed: PackedScene = load(PEARL_SCENE) as PackedScene
	var collectible: Node2D = packed.instantiate() as Node2D

	var viewport_size: Vector2 = get_viewport_rect().size
	collectible.position.x = viewport_size.x + 100.0
	collectible.position.y = float(entry.get("lane_position", 0.5)) * viewport_size.y

	get_parent().add_child(collectible)

	if collectible.has_method("setup"):
		collectible.setup(entry)


## Called by Pearl scene instances when the player collects them.
func on_collectible_collected(value: int) -> void:
	EventBus.collectible_taken.emit(value)
