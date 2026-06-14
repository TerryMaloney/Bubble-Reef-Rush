extends Area2D

class_name CoralSpike

const SPIKE_WIDTH: float = 60.0

@onready var _collision: CollisionShape2D = $CollisionShape2D
@onready var _visual: Polygon2D = $Visual


func _ready() -> void:
	add_to_group("scrolling")
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	position.x -= ScrollService.speed_now() * delta
	if position.x < -200.0:
		queue_free()


## Configure from beat_map entry.
func setup(entry: Dictionary) -> void:
	var params: Dictionary = entry.get("parameters", {}) as Dictionary
	var attachment: String = str(params.get("wall_attachment", "bottom"))
	var height: float = float(params.get("height", 120))
	_configure(attachment, height)


## Directly configure — used by ObstacleSpawner when composing gate pieces.
func configure(attachment: String, height: float) -> void:
	_configure(attachment, height)


func _configure(attachment: String, height: float) -> void:
	var shape: RectangleShape2D = RectangleShape2D.new()

	match attachment:
		"top":
			shape.size = Vector2(SPIKE_WIDTH, height)
			_collision.shape = shape
			_collision.position = Vector2(0.0, height * 0.5)
		"bottom":
			shape.size = Vector2(SPIKE_WIDTH, height)
			_collision.shape = shape
			_collision.position = Vector2(0.0, -height * 0.5)
		"left":
			shape.size = Vector2(height, SPIKE_WIDTH)
			_collision.shape = shape
			_collision.position = Vector2(height * 0.5, 0.0)
		"right":
			shape.size = Vector2(height, SPIKE_WIDTH)
			_collision.shape = shape
			_collision.position = Vector2(-height * 0.5, 0.0)
		_:
			shape.size = Vector2(SPIKE_WIDTH, height)
			_collision.shape = shape
			_collision.position = Vector2(0.0, -height * 0.5)

	_build_visual(attachment, height)


func _build_visual(attachment: String, height: float) -> void:
	var hw: float = SPIKE_WIDTH * 0.5
	var tip: float = 28.0  # how far the tip narrows before the point

	match attachment:
		"bottom":
			_visual.polygon = PackedVector2Array([
				Vector2(-hw, 0.0), Vector2(hw, 0.0),
				Vector2(hw, -height + tip), Vector2(0.0, -height),
				Vector2(-hw, -height + tip),
			])
		"top":
			_visual.polygon = PackedVector2Array([
				Vector2(-hw, 0.0), Vector2(hw, 0.0),
				Vector2(hw, height - tip), Vector2(0.0, height),
				Vector2(-hw, height - tip),
			])
		"left":
			_visual.polygon = PackedVector2Array([
				Vector2(0.0, -hw), Vector2(0.0, hw),
				Vector2(height - tip, hw), Vector2(height, 0.0),
				Vector2(height - tip, -hw),
			])
		"right":
			_visual.polygon = PackedVector2Array([
				Vector2(0.0, -hw), Vector2(0.0, hw),
				Vector2(-(height - tip), hw), Vector2(-height, 0.0),
				Vector2(-(height - tip), -hw),
			])


func _on_body_entered(body: Node2D) -> void:
	if body.has_method("on_hit"):
		body.on_hit()
	queue_free()
