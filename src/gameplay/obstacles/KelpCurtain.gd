extends Node2D

class_name KelpCurtain

const SCROLL_SPEED: float = 408.0
const BLADE_W: float = 24.0
const BLADE_H: float = 180.0
const GAP_HALF: float = 60.0   ## Half the 120 px navigable gap
const MAX_SWAY: float = 0.2    ## Radians (~11.5 deg); gives 84 px effective gap at extremes
const CANVAS_H: float = 1920.0

var _sway_speed: float = 2.0
var _blades: Array[Node2D] = []
var _blade_visuals: Array[Polygon2D] = []
var _time: float = 0.0
var _beat_flash: float = 0.0   ## Decays 5/s after each beat_fired; drives teal blade flash


func _ready() -> void:
	BeatConductor.beat_fired.connect(_on_beat_fired)


func setup(entry: Dictionary) -> void:
	var params: Dictionary = entry.get("parameters", {}) as Dictionary
	var gap_y_norm: float = float(params.get("gap_y_normalized", entry.get("lane_position", 0.5)))
	_sway_speed = float(params.get("sway_speed", 2.0))

	# Root at top of screen; blade positions are in local screen-coordinate space.
	position.y = 0.0
	_build_blades(gap_y_norm * CANVAS_H, CANVAS_H)


func _build_blades(gap_center_y: float, screen_h: float) -> void:
	var gap_top: float = gap_center_y - GAP_HALF
	var gap_bottom: float = gap_center_y + GAP_HALF

	# Blades above the gap — step upward from the gap edge.
	# Include a blade as long as its center is above -BLADE_H/2 (partial off-screen top OK).
	var cy: float = gap_top - BLADE_H * 0.5
	while cy > -BLADE_H * 0.5:
		_create_blade(cy)
		cy -= BLADE_H

	# Blades below the gap — step downward from the gap edge.
	cy = gap_bottom + BLADE_H * 0.5
	while cy < screen_h + BLADE_H * 0.5:
		_create_blade(cy)
		cy += BLADE_H


func _create_blade(local_y: float) -> void:
	var blade: Area2D = Area2D.new()
	blade.position = Vector2(0.0, local_y)

	var col: CollisionShape2D = CollisionShape2D.new()
	var rect: RectangleShape2D = RectangleShape2D.new()
	rect.size = Vector2(BLADE_W, BLADE_H)
	col.shape = rect
	blade.add_child(col)

	var vis: Polygon2D = _build_blade_placeholder()
	blade.add_child(vis)

	blade.body_entered.connect(func(body: Node2D) -> void:
		if body.has_method("on_hit"):
			body.on_hit()
	)

	add_child(blade)
	_blades.append(blade)
	_blade_visuals.append(vis)


## Placeholder visual for a single kelp blade.
## When "sprite/obstacle/kelp_blade" is added to the manifest, replace this
## with VisualFactory.build_visual("sprite/obstacle/kelp_blade", _build_blade_placeholder).
func _build_blade_placeholder() -> Polygon2D:
	var vis: Polygon2D = Polygon2D.new()
	var hw: float = BLADE_W * 0.5
	var hh: float = BLADE_H * 0.5
	vis.polygon = PackedVector2Array([
		Vector2(-hw, -hh),
		Vector2(hw,  -hh),
		Vector2(hw,   hh),
		Vector2(-hw,  hh),
	])
	vis.color = Color(0.1, 0.5, 0.2)
	return vis


func _process(delta: float) -> void:
	_time += delta
	position.x -= SCROLL_SPEED * delta
	if position.x < -200.0:
		queue_free()
		return

	_beat_flash = maxf(0.0, _beat_flash - delta * 5.0)

	var base_green: Color = Color(0.1, 0.5, 0.2)
	var flash_teal: Color = Color(0.2, 0.9, 0.6)

	for i: int in range(_blades.size()):
		if not is_instance_valid(_blades[i]):
			continue
		# Stagger blade phases by π/2 per blade — creates a lateral wave effect.
		var phase: float = float(i) * PI * 0.5
		_blades[i].rotation = MAX_SWAY * sin(_time * _sway_speed + phase)
		_blade_visuals[i].color = base_green.lerp(flash_teal, _beat_flash)


func _on_beat_fired(_beat_index: int) -> void:
	_beat_flash = 1.0
