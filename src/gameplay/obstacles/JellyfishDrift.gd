extends Area2D

class_name JellyfishDrift

const DRIFT_AMPLITUDE: float = 60.0
const DRIFT_SPEED: float = 2.0

var _start_y: float = 0.0
var _time: float = 0.0


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_start_y = position.y


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
