# Scene-local node that reads the beat_map from RhythmMap and spawns obstacle scenes on cue.
extends Node

class_name ObstacleSpawner

const SPAWN_LOOKAHEAD_BEATS: float = 4.0
const OBSTACLE_SCENE_MAP: Dictionary = {
	"coral_spike": "res://scenes/obstacles/CoralSpike.tscn",
	"jellyfish_drift": "res://scenes/obstacles/JellyfishDrift.tscn",
	"kelp_curtain": "res://scenes/obstacles/KelpCurtain.tscn",
	"bubble_mine": "res://scenes/obstacles/BubbleMine.tscn",
}
const CORAL_SPIKE_SCENE: String = "res://scenes/obstacles/CoralSpike.tscn"

# Gate geometry: gap width in pixels at the easiest vs hardest intensity.
# Research-derived: Easy = 5× player height (5×56=280), Normal = 3.6× (200px).
# Player capsule = 56px tall. Both widths leave physically passable clearance;
# difficulty comes from having to be *at* the gap on the beat.
const GAP_MAX_PX: float = 280.0
const GAP_MIN_PX: float = 200.0
# If effective intensity falls at/below this, the gate is skipped entirely
# (open water) — this is how rests and heavy assist produce breathing room.
const SKIP_INTENSITY: float = 0.08
const SPIKE_WIDTH: float = 60.0

var _pending: Array[Dictionary] = []
var _rhythm_map: RhythmMap

## Set by LevelRoot. When present, gates consult it for effective intensity.
var director: DifficultyDirector = null


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
	var params: Dictionary = entry.get("parameters", {}) as Dictionary

	# A "pressure_wall" entry becomes a difficulty-driven gate.
	# NOTE: kelp_curtain also has gap_y_normalized in params — do NOT use params.has()
	# as the gate condition or kelp curtains will be silently routed here instead.
	if obstacle_type == "pressure_wall":
		_spawn_gate(entry, params)
		return

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
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	obstacle.position.x = viewport_size.x + 100.0
	obstacle.position.y = float(entry.get("lane_position", 0.5)) * viewport_size.y

	# Parent to the gameplay root (two levels up from this node).
	get_parent().add_child(obstacle)

	if obstacle.has_method("setup"):
		obstacle.setup(entry)


## Build a gate: a top and bottom CoralSpike with a navigable gap between them.
## The gap *size* is driven by the (possibly DDA-adjusted) effective intensity;
## the gap *center* comes from the authored chart.
func _spawn_gate(entry: Dictionary, params: Dictionary) -> void:
	var beat_index: int = int(entry.get("beat_index", 0))
	var authored: float = float(params.get("intensity", 0.5))

	var effective: float = authored
	if director != null:
		effective = director.effective_intensity(authored, beat_index)

	# Rest / heavy-assist beats open into clear water.
	if effective <= SKIP_INTENSITY:
		return

	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	var screen_h: float = viewport_size.y
	var spawn_x: float = viewport_size.x + 100.0

	var gap_px: float = lerpf(GAP_MAX_PX, GAP_MIN_PX, clampf(effective, 0.0, 1.0))
	var gap_center_norm: float = float(params.get("gap_y_normalized", entry.get("lane_position", 0.5)))
	var gap_center_y: float = clampf(gap_center_norm * screen_h, gap_px * 0.5 + 40.0, screen_h - gap_px * 0.5 - 40.0)

	var gap_top: float = gap_center_y - gap_px * 0.5
	var gap_bottom: float = gap_center_y + gap_px * 0.5

	# Top piece spans from the top wall down to the gap.
	if gap_top > 20.0:
		_spawn_spike("top", gap_top, spawn_x, 0.0)
	# Bottom piece spans from the gap down to the bottom wall.
	var bottom_height: float = screen_h - gap_bottom
	if bottom_height > 20.0:
		_spawn_spike("bottom", bottom_height, spawn_x, screen_h)


func _spawn_spike(attachment: String, height: float, x: float, wall_y: float) -> void:
	if not ResourceLoader.exists(CORAL_SPIKE_SCENE):
		push_warning("ObstacleSpawner: CoralSpike scene missing — cannot build gate.")
		return
	var packed: PackedScene = load(CORAL_SPIKE_SCENE) as PackedScene
	var spike: Node2D = packed.instantiate() as Node2D
	spike.position = Vector2(x, wall_y)
	get_parent().add_child(spike)
	if spike.has_method("configure"):
		spike.configure(attachment, height)
