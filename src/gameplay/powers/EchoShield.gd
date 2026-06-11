## EchoShield — visual indicator for the echo_shield power state.
##
## Attached as a child of the Player node. Listens to EventBus.power_activated for
## "echo_shield" to show itself, and to power_cooldown_started to play the break animation.
## Pulses gently while the shield is active. Hidden at rest.
extends Node2D

class_name EchoShield

var _pulse_tween: Tween = null

@onready var _ring: Polygon2D = $Ring


func _ready() -> void:
	EventBus.power_activated.connect(_on_power_activated)
	EventBus.power_cooldown_started.connect(_on_shield_broken)
	EventBus.run_started.connect(_on_run_reset)
	EventBus.practice_respawned.connect(_on_run_reset.bind(""))
	visible = false


func _on_run_reset(_level_id: String = "") -> void:
	if _pulse_tween != null:
		_pulse_tween.kill()
		_pulse_tween = null
	visible = false
	scale = Vector2.ONE
	modulate.a = 1.0
	if _ring != null:
		_ring.color = Color(0.3, 0.8, 1.0, 0.7)


func _on_power_activated(power_type: String, _is_perfect: bool) -> void:
	if power_type != "echo_shield":
		return
	visible = true
	_pulse()


func _on_shield_broken() -> void:
	if _pulse_tween != null:
		_pulse_tween.kill()
		_pulse_tween = null
	if _ring != null:
		_ring.color = Color(1.0, 0.3, 0.3, 0.9)
	var tween: Tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	tween.tween_callback(func() -> void:
		visible = false
		modulate.a = 1.0
		if _ring != null:
			_ring.color = Color(0.3, 0.8, 1.0, 0.7)
	)


func _pulse() -> void:
	if _pulse_tween != null:
		_pulse_tween.kill()
	_pulse_tween = create_tween()
	_pulse_tween.set_loops()
	_pulse_tween.tween_property(self, "scale", Vector2(1.12, 1.12), 0.35)
	_pulse_tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.35)
