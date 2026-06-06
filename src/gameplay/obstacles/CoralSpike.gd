extends Area2D

class_name CoralSpike

const SCROLL_SPEED: float = 408.0


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	position.x -= SCROLL_SPEED * delta
	if position.x < -200.0:
		queue_free()


func setup(_entry: Dictionary) -> void:
	pass


func _on_body_entered(body: Node2D) -> void:
	if body.has_method("on_hit"):
		body.on_hit()
	queue_free()
