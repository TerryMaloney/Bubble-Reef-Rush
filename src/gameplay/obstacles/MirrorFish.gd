extends Area2D

class_name MirrorFish

const MAX_HISTORY: int = 60
const SPEED_TUNING: float = 0.8

var _delay_frames: int = 30
var _approach_speed_bonus: float = 100.0
var _y_history: Array[float] = []
var _player_ref: Node2D = null


func _ready() -> void:
	add_to_group("scrolling")
	add_to_group("bubble_destructible")
	body_entered.connect(_on_body_entered)
	var players: Array[Node] = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		_player_ref = players[0] as Node2D
	for _i: int in range(MAX_HISTORY):
		_y_history.append(960.0)
	EventBus.hazard_warning.emit("SHADOW APPROACHING")


func setup(entry: Dictionary) -> void:
	var p: Dictionary = entry.get("parameters", {}) as Dictionary
	_delay_frames = int(p.get("delay_frames", 30))
	_approach_speed_bonus = float(p.get("approach_speed_bonus", 100)) * SPEED_TUNING


func _process(delta: float) -> void:
	if _player_ref != null and is_instance_valid(_player_ref):
		_y_history.push_back(_player_ref.position.y)
		if _y_history.size() > MAX_HISTORY:
			_y_history.pop_front()

	var history_size: int = _y_history.size()
	if history_size > 0:
		var delay_idx: int = maxi(0, history_size - _delay_frames - 1)
		position.y = _y_history[mini(delay_idx, history_size - 1)]

	position.x -= (ScrollService.speed_now() + _approach_speed_bonus) * delta

	if position.x < -400.0:
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	if body.has_method("on_hit"):
		body.on_hit()
