extends Area2D

class_name CoralSpike

const SCROLL_SPEED: float = 408.0
const SPIKE_WIDTH: float = 60.0

@onready var _collision: CollisionShape2D = $CollisionShape2D
@onready var _visual: Polygon2D = $Visual


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	position.x -= SCROLL_SPEED * delta
	if position.x < -200.0:
		queue_free()


## Configure the spike from its beat_map entry. The spawner positions this node
## at the wall (lane 0.0 = top edge, lane 1.0 = bottom edge); here we build the
## collision shape and visual so the spike extends `height` px into the playfield
## from that wall, making it both visible and properly collidable.
func setup(entry: Dictionary) -> void:
	var params: Dictionary = entry.get("parameters", {}) as Dictionary
	var attachment: String = str(params.get("wall_attachment", "bottom"))
	var height: float = float(params.get("height", 120))
	_configure(attachment, height)


func _configure(attachment: String, height: float) -> void:
	# Build a fresh shape per instance so we never mutate a shared sub-resource.
	var shape: RectangleShape2D = RectangleShape2D.new()
	shape.size = Vector2(SPIKE_WIDTH, height)

	var half_w: float = SPIKE_WIDTH * 0.5

	if attachment == "top":
		# Node sits at the top wall; spike points down into the field.
		_collision.shape = shape
		_collision.position = Vector2(0.0, height * 0.5)
		_visual.polygon = PackedVector2Array([
			Vector2(-half_w, 0.0),
			Vector2(half_w, 0.0),
			Vector2(half_w, height - 30.0),
			Vector2(0.0, height),
			Vector2(-half_w, height - 30.0),
		])
	else:
		# Default "bottom": node sits at the bottom wall; spike points up.
		_collision.shape = shape
		_collision.position = Vector2(0.0, -height * 0.5)
		_visual.polygon = PackedVector2Array([
			Vector2(-half_w, 0.0),
			Vector2(half_w, 0.0),
			Vector2(half_w, -height + 30.0),
			Vector2(0.0, -height),
			Vector2(-half_w, -height + 30.0),
		])


func _on_body_entered(body: Node2D) -> void:
	if body.has_method("on_hit"):
		body.on_hit()
	queue_free()
