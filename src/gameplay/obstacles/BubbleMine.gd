extends Area2D

class_name BubbleMine

const COLLISION_RADIUS: float = 56.0
const EXPLODE_DURATION: float = 0.2

enum State { IDLE, WARNING, EXPLODE }

## Distance at which the mine begins pulsing to warn the player.
## Overridden by BRL parameters.arm_radius.
@export var arm_radius: float = 160.0

var _state: State = State.IDLE
var _player: Node2D = null

@onready var _visual: Polygon2D = $Visual
@onready var _collision: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	add_to_group("scrolling")
	body_entered.connect(_on_body_entered)
	_player = get_tree().get_first_node_in_group("player") as Node2D


func setup(entry: Dictionary) -> void:
	var params: Dictionary = entry.get("parameters", {}) as Dictionary
	arm_radius = float(params.get("arm_radius", 160.0))


func _process(delta: float) -> void:
	position.x -= ScrollService.speed_now() * delta
	if position.x < -200.0:
		queue_free()
		return

	if _state == State.EXPLODE:
		return

	# Re-try player lookup each frame if not yet found (safe after _ready races).
	if _player == null:
		_player = get_tree().get_first_node_in_group("player") as Node2D
		return

	var dist: float = position.distance_to(_player.global_position)
	if dist <= arm_radius:
		_state = State.WARNING
		var pulse: float = abs(sin(Time.get_ticks_msec() * 0.005))
		_visual.color = Color(1.0, 0.4 + pulse * 0.4, 0.1 + pulse * 0.1)
	else:
		_state = State.IDLE
		_visual.color = Color(0.2, 0.5, 0.9)


func _on_body_entered(body: Node2D) -> void:
	if _state == State.EXPLODE:
		return
	if not body.has_method("on_hit"):
		return
	_state = State.EXPLODE
	_collision.disabled = true
	_visual.color = Color(1.0, 0.3, 0.0)
	body.on_hit()
	get_tree().create_timer(EXPLODE_DURATION).timeout.connect(queue_free)
