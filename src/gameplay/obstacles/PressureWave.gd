extends Node2D

class_name PressureWave

const CANVAS_H: float = 1920.0
const CANVAS_W: float = 1080.0
const WALL_THICKNESS: float = 120.0

var _travel_speed: float = 300.0

@onready var _upper_area: Area2D = $UpperBlock
@onready var _upper_col: CollisionShape2D = $UpperBlock/CollisionShape2D
@onready var _lower_area: Area2D = $LowerBlock
@onready var _lower_col: CollisionShape2D = $LowerBlock/CollisionShape2D
@onready var _visual: Polygon2D = $Visual


func _ready() -> void:
	add_to_group("scrolling")
	_upper_area.body_entered.connect(_on_body_entered)
	_lower_area.body_entered.connect(_on_body_entered)


func setup(entry: Dictionary) -> void:
	var p: Dictionary = entry.get("parameters", {}) as Dictionary
	_travel_speed = float(p.get("travel_speed", 300))
	var gap_center_y: float = float(p.get("gap_y_normalized", 0.5)) * CANVAS_H
	var gap_height: float = float(p.get("gap_height", 160))

	var gap_top: float = gap_center_y - gap_height * 0.5
	var gap_bottom: float = gap_center_y + gap_height * 0.5

	var upper_h: float = maxf(gap_top, 0.0)
	if upper_h > 0.0:
		var rect: RectangleShape2D = RectangleShape2D.new()
		rect.size = Vector2(WALL_THICKNESS, upper_h)
		_upper_col.shape = rect
		_upper_area.position = Vector2(0.0, upper_h * 0.5)
	else:
		_upper_col.disabled = true

	var lower_h: float = maxf(CANVAS_H - gap_bottom, 0.0)
	if lower_h > 0.0:
		var rect: RectangleShape2D = RectangleShape2D.new()
		rect.size = Vector2(WALL_THICKNESS, lower_h)
		_lower_col.shape = rect
		_lower_area.position = Vector2(0.0, gap_bottom + lower_h * 0.5)
	else:
		_lower_col.disabled = true

	_build_visual(gap_top, gap_bottom)


func _process(delta: float) -> void:
	position.x -= _travel_speed * delta
	if position.x < -(CANVAS_W + 200.0):
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	if body.has_method("on_hit"):
		body.on_hit()


func _build_visual(gap_top: float, gap_bottom: float) -> void:
	# Placeholder: a simple rectangle excluding the gap.
	_visual.color = Color(0.1, 0.4, 0.9, 0.7)
	var half_w: float = WALL_THICKNESS * 0.5
	# Draw upper bar using polygon (gap_top height at top of screen).
	_visual.polygon = PackedVector2Array([
		Vector2(-half_w, 0.0),
		Vector2(half_w, 0.0),
		Vector2(half_w, gap_top),
		Vector2(-half_w, gap_top),
	])
