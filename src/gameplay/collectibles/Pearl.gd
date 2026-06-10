extends Area2D

class_name Pearl

var _value: int = 10


func _ready() -> void:
	add_to_group("scrolling")
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	position.x -= ScrollService.speed_now() * delta
	if position.x < -200.0:
		queue_free()


func setup(entry: Dictionary) -> void:
	_value = int(entry.get("value", 10))


func _on_body_entered(body: Node2D) -> void:
	if body is PlayerController:
		EventBus.collectible_taken.emit(_value)
		queue_free()
