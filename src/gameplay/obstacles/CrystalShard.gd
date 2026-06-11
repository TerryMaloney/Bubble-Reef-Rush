extends Area2D

class_name CrystalShard

const CANVAS_H: float = 1920.0
const CANVAS_W: float = 1080.0

var _vel: Vector2 = Vector2.ZERO
var _rotation_dir: float = 1.0

@onready var _visual: Polygon2D = $Visual


func _ready() -> void:
	add_to_group("scrolling")
	body_entered.connect(_on_body_entered)


func setup(entry: Dictionary) -> void:
	var p: Dictionary = entry.get("parameters", {}) as Dictionary
	var lateral: float = float(p.get("lateral_speed", 400))
	var entry_side: String = str(p.get("entry_side", "right"))
	var diag_init: String = str(p.get("diagonal_speed_initial", "down"))
	var rot: String = str(p.get("rotation_direction", "clockwise"))
	_rotation_dir = 1.0 if rot == "clockwise" else -1.0
	var horiz: float = -lateral if entry_side == "right" else lateral
	var vert: float = lateral * 0.5 if diag_init == "down" else -lateral * 0.5
	_vel = Vector2(horiz, vert)
	_update_color(str(p.get("color_variant", "blue")))


func _process(delta: float) -> void:
	position += _vel * delta

	# Bounce off canvas top/bottom boundaries.
	if position.y <= 0.0:
		_vel.y = absf(_vel.y)
		position.y = 0.0
	elif position.y >= CANVAS_H:
		_vel.y = -absf(_vel.y)
		position.y = CANVAS_H

	_visual.rotation += _rotation_dir * 3.0 * delta

	if position.x < -400.0 or position.x > CANVAS_W + 400.0:
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	if body.has_method("on_hit"):
		body.on_hit()


func _update_color(variant: String) -> void:
	match variant:
		"purple":
			_visual.color = Color(0.7, 0.1, 0.9, 0.9)
		"pink":
			_visual.color = Color(1.0, 0.4, 0.8, 0.9)
		"teal":
			_visual.color = Color(0.0, 0.8, 0.7, 0.9)
		_:
			_visual.color = Color(0.2, 0.5, 1.0, 0.9)
