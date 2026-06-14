extends Area2D

class_name CoralSpike

const SPIKE_WIDTH: float = 60.0
## Collision is intentionally narrower than the visual and stops short of the
## tip so brushing the edge of a spike doesn't read as a hit (forgiving feel).
const COLLISION_WIDTH: float = 46.0
const TIP_FORGIVE: float = 16.0
const _BASE_PATH: String = "res://assets/obstacles/coral_spike_base.png"
const _BODY_PATH: String = "res://assets/obstacles/coral_spike_body.png"

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
	# Collision length runs base->tip; inset the tip end so the very point is
	# forgiving. The base stays anchored at the wall (origin side).
	var col_len: float = maxf(8.0, height - TIP_FORGIVE)
	var half: float = col_len * 0.5

	match attachment:
		"top":
			shape.size = Vector2(COLLISION_WIDTH, col_len)
			_collision.shape = shape
			_collision.position = Vector2(0.0, half)
		"bottom":
			shape.size = Vector2(COLLISION_WIDTH, col_len)
			_collision.shape = shape
			_collision.position = Vector2(0.0, -half)
		"left":
			shape.size = Vector2(col_len, COLLISION_WIDTH)
			_collision.shape = shape
			_collision.position = Vector2(half, 0.0)
		"right":
			shape.size = Vector2(col_len, COLLISION_WIDTH)
			_collision.shape = shape
			_collision.position = Vector2(-half, 0.0)
		_:
			shape.size = Vector2(COLLISION_WIDTH, col_len)
			_collision.shape = shape
			_collision.position = Vector2(0.0, -half)

	_build_visual(attachment, height)
	_try_load_sprites(attachment, height)


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


func _try_load_sprites(attachment: String, height: float) -> void:
	var base_tex: Texture2D = null
	var body_tex: Texture2D = null
	if ResourceLoader.exists(_BASE_PATH):
		base_tex = load(_BASE_PATH) as Texture2D
	if ResourceLoader.exists(_BODY_PATH):
		body_tex = load(_BODY_PATH) as Texture2D
	if base_tex == null and body_tex == null:
		return
	_visual.hide()
	var base_h: float = SPIKE_WIDTH * 1.2  # base piece display height
	# Body sprite: stretches from base top to spike tip.
	if body_tex != null:
		var body_sp := Sprite2D.new()
		body_sp.texture = body_tex
		var body_display_h: float = height - base_h
		if body_display_h > 2.0:
			var tw: float = float(body_tex.get_width())
			var th: float = float(body_tex.get_height())
			body_sp.scale = Vector2(SPIKE_WIDTH / tw, body_display_h / th) if tw > 0.0 and th > 0.0 else Vector2(1.0, 1.0)
			body_sp.centered = true
			match attachment:
				"bottom": body_sp.position = Vector2(0.0, -(base_h + body_display_h * 0.5))
				"top":    body_sp.position = Vector2(0.0, base_h + body_display_h * 0.5)
				"left":   body_sp.position = Vector2(base_h + body_display_h * 0.5, 0.0); body_sp.rotation = -PI * 0.5
				"right":  body_sp.position = Vector2(-(base_h + body_display_h * 0.5), 0.0); body_sp.rotation = PI * 0.5
			add_child(body_sp)
	# Base sprite: anchored at the wall.
	if base_tex != null:
		var base_sp := Sprite2D.new()
		base_sp.texture = base_tex
		var tw: float = float(base_tex.get_width())
		var th: float = float(base_tex.get_height())
		base_sp.scale = Vector2(SPIKE_WIDTH / tw, base_h / th) if tw > 0.0 and th > 0.0 else Vector2(1.0, 1.0)
		base_sp.centered = true
		match attachment:
			"bottom": base_sp.position = Vector2(0.0, -(base_h * 0.5))
			"top":    base_sp.position = Vector2(0.0, base_h * 0.5); base_sp.flip_v = true
			"left":   base_sp.position = Vector2(base_h * 0.5, 0.0); base_sp.rotation = -PI * 0.5
			"right":  base_sp.position = Vector2(-(base_h * 0.5), 0.0); base_sp.rotation = PI * 0.5
		add_child(base_sp)


func _on_body_entered(body: Node2D) -> void:
	if body.has_method("on_hit"):
		body.on_hit()
	queue_free()
