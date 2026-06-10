## TreasureCoin — hidden collectible (3 per level, coin_id 0–2).
## Dimmed when already collected. Triggers save + EventBus on first collect.
extends Area2D

class_name TreasureCoin

var _coin_id: int = 0
var _level_id: String = ""
var _collected: bool = false


func _ready() -> void:
	add_to_group("scrolling")
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	position.x -= ScrollService.speed_now() * delta
	if position.x < -200.0:
		queue_free()


func setup(entry: Dictionary) -> void:
	_coin_id = int(entry.get("coin_id", 0))
	_level_id = GameManager.current_level_id
	# Dim if already collected in this save.
	var profile: String = SaveSystem.get_active_profile_id()
	if SaveSystem.get_treasure_coin(profile, _level_id, _coin_id):
		_collected = true
		modulate.a = 0.35


func _on_body_entered(body: Node2D) -> void:
	if _collected or not body.has_method("on_hit"):
		return
	# Don't collect if body is the player and they've already been hit (dead).
	if body.has_method("on_hit") and not body.alive:
		return
	_collected = true
	var profile: String = SaveSystem.get_active_profile_id()
	SaveSystem.set_treasure_coin(profile, _level_id, _coin_id)
	SFXManager.play_sfx("sfx/treasure_coin")
	queue_free()
