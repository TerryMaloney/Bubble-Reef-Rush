extends Area2D

class_name JellyfishDrift

const DRIFT_AMPLITUDE: float = 60.0
const DRIFT_SPEED: float = 2.0
const _ART_PATH: String = "res://assets/obstacles/jellyfish_drift.png"
const _ART_TARGET_H: float = 160.0

var _start_y: float = 0.0
var _time: float = 0.0

@onready var _visual: Polygon2D = $Visual


func _ready() -> void:
	add_to_group("scrolling")
	add_to_group("bubble_destructible")
	body_entered.connect(_on_body_entered)
	_start_y = position.y
	_try_load_sprite()


func _try_load_sprite() -> void:
	if not ResourceLoader.exists(_ART_PATH):
		return
	var tex: Texture2D = load(_ART_PATH) as Texture2D
	if tex == null:
		return
	_visual.hide()
	var sp := Sprite2D.new()
	sp.texture = tex
	var th: float = float(tex.get_height())
	if th > 0.0:
		var s: float = _ART_TARGET_H / th
		sp.scale = Vector2(s, s)
	add_child(sp)


func _process(delta: float) -> void:
	_time += delta
	position.x -= ScrollService.speed_now() * delta
	position.y = _start_y + sin(_time * DRIFT_SPEED) * DRIFT_AMPLITUDE
	if position.x < -200.0:
		queue_free()


func setup(_entry: Dictionary) -> void:
	pass


func _on_body_entered(body: Node2D) -> void:
	if body.has_method("on_hit"):
		body.on_hit()
	queue_free()
