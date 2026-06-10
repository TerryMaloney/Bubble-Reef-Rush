## NearMissDetector — Area2D child of Player that detects close shaves.
## When an obstacle Area2D enters the ring and then exits without triggering
## player_hit, emits EventBus.near_miss and awards +25 score.
extends Area2D

class_name NearMissDetector

const NEAR_MISS_BONUS: int = 25

## Areas currently inside the ring. Cleared on player_hit to prevent
## a dying player from also earning near-miss credit.
var _nearby: Dictionary = {}
var _player_hit: bool = false


func _ready() -> void:
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)
	EventBus.player_hit.connect(_on_player_hit)
	EventBus.run_started.connect(_reset)
	EventBus.practice_respawned.connect(_reset.bind(""))


func _on_area_entered(area: Area2D) -> void:
	if _player_hit:
		return
	_nearby[area] = true


func _on_area_exited(area: Area2D) -> void:
	if not _nearby.has(area):
		return
	_nearby.erase(area)
	if _player_hit:
		return
	# Obstacle passed by the player without a collision — close shave!
	EventBus.near_miss.emit()
	EventBus.score_bonus.emit(NEAR_MISS_BONUS)
	SFXManager.play_sfx("sfx/near_miss")


func _on_player_hit() -> void:
	_player_hit = true
	_nearby.clear()


func _reset(_level_id: String = "") -> void:
	_player_hit = false
	_nearby.clear()
