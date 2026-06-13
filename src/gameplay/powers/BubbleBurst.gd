## BubbleBurst — projectile spawned by ResonanceController when bubble_burst power fires.
##
## Moves right at 1200 px/s (1600 on a PERFECT-timed fire).
## Each frame checks distance against all nodes in the "bubble_destructible" group.
## On collision, the destructible obstacle is freed, FX burst plays, and the projectile despawns.
## Exits scene automatically when it leaves the canvas or exceeds MAX_LIFETIME.
extends Node2D

class_name BubbleBurst

const SPEED: float = 1200.0
const PERFECT_SPEED_BONUS: float = 400.0
const HIT_RADIUS: float = 48.0
const MAX_LIFETIME: float = 1.5

var _velocity_x: float = SPEED
var _lifetime: float = 0.0

@onready var _visual: Polygon2D = $Visual


func setup(start_pos: Vector2, is_perfect: bool) -> void:
	global_position = start_pos
	if is_perfect:
		_velocity_x = SPEED + PERFECT_SPEED_BONUS
		if _visual != null:
			_visual.color = Color(0.5, 0.95, 1.0)


func _process(delta: float) -> void:
	position.x += _velocity_x * delta
	_lifetime += delta

	for node: Node in get_tree().get_nodes_in_group("bubble_destructible"):
		if node is Node2D:
			var dist: float = global_position.distance_to((node as Node2D).global_position)
			if dist < HIT_RADIUS + 40.0:
				node.queue_free()
				EventBus.score_bonus.emit(150)
				_pop()
				return

	if global_position.x > 1280.0 or _lifetime > MAX_LIFETIME:
		queue_free()


func _pop() -> void:
	FXFactory.burst(global_position, Color(0.3, 0.8, 1.0))
	queue_free()
