extends Node2D

class_name AnchorChain

signal on_apex

const CHAIN_SEGS: int = 6
const SEG_RADIUS: float = 16.0
const SEG_HEIGHT: float = 60.0
const APEX_THRESHOLD: float = 0.05   # rad/s below which the apex fires

var _max_angle: float = deg_to_rad(35.0)
var _freq: float = 0.5
var _chain_length: float = 500.0
var _time: float = 0.0
var _rotation_prev: float = 0.0
var _angular_velocity: float = 0.0
var _at_apex: bool = false
var _segments: Array = []


func _ready() -> void:
	add_to_group("scrolling")


func setup(entry: Dictionary) -> void:
	var p: Dictionary = entry.get("parameters", {}) as Dictionary
	_max_angle = deg_to_rad(float(p.get("max_angle_degrees", 35)))
	_freq = float(p.get("pendulum_frequency", 0.5))
	_chain_length = float(p.get("chain_length", 500))
	_clear_segments()
	_build_chain()


func _clear_segments() -> void:
	for seg: Variant in _segments:
		if is_instance_valid(seg as Node):
			(seg as Node).queue_free()
	_segments.clear()


func _build_chain() -> void:
	var spacing: float = _chain_length / float(CHAIN_SEGS)
	for i: int in range(CHAIN_SEGS):
		var local_y: float = (float(i) + 0.5) * spacing
		_add_segment(Vector2(0.0, local_y), SEG_RADIUS, SEG_HEIGHT)

	# Anchor rectangle at chain bottom.
	var anchor: Area2D = Area2D.new()
	anchor.position = Vector2(0.0, _chain_length)
	var col: CollisionShape2D = CollisionShape2D.new()
	var rect: RectangleShape2D = RectangleShape2D.new()
	rect.size = Vector2(80.0, 60.0)
	col.shape = rect
	anchor.add_child(col)
	anchor.body_entered.connect(func(body: Node2D) -> void:
		if body.has_method("on_hit"):
			body.on_hit()
	)
	add_child(anchor)
	_segments.append(anchor)


func _add_segment(local_pos: Vector2, radius: float, height: float) -> void:
	var area: Area2D = Area2D.new()
	area.position = local_pos
	var col: CollisionShape2D = CollisionShape2D.new()
	var cap: CapsuleShape2D = CapsuleShape2D.new()
	cap.radius = radius
	cap.height = height
	col.shape = cap
	area.add_child(col)
	area.body_entered.connect(func(body: Node2D) -> void:
		if body.has_method("on_hit"):
			body.on_hit()
	)
	add_child(area)
	_segments.append(area)


func _process(delta: float) -> void:
	position.x -= ScrollService.speed_now() * delta
	if position.x < -400.0:
		queue_free()
		return

	_time += delta
	_rotation_prev = rotation
	rotation = _max_angle * sin(_time * _freq * TAU)
	_angular_velocity = (rotation - _rotation_prev) / delta

	var now_apex: bool = absf(_angular_velocity) < APEX_THRESHOLD
	if now_apex and not _at_apex:
		on_apex.emit()
	_at_apex = now_apex
