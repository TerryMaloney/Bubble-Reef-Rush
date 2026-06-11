## ResonanceController — scene-local node tracking power charge and firing powers.
##
## Pearl collection (collectible_taken) fills a charge meter (5 pearls = 1 charge).
## Each pearl also emits power_charged(pct) so the HUD can show sub-charge progress.
## When fire() is called, the equipped power activates:
##   bubble_burst  — emits power_activated; LevelRoot spawns a BubbleBurst projectile.
##   echo_shield   — sets _echo_shield_active; PlayerController.on_hit() calls
##                   consume_shield() first to absorb one hit.
## _is_perfect_timed() checks the current beat fraction against a ±0.12 window.
## LevelRoot calls setup() from its run_started handler (after level metadata is loaded).
extends Node

class_name ResonanceController

const PEARLS_PER_CHARGE: int = 5
const PERFECT_BEAT_WINDOW: float = 0.12

var _mode: String = "allowed"        # "allowed" | "disabled" | "required"
var _max_charges: int = 1
var _charges: int = 0
var _pearl_accumulator: int = 0
var _echo_shield_active: bool = false
var _equipped_power: String = "bubble_burst"
var _connected: bool = false


func setup(mode: String, max_charges: int, equipped_power: String) -> void:
	_mode = mode
	_max_charges = maxi(1, max_charges)
	_equipped_power = equipped_power
	_reset()
	if not _connected:
		_connected = true
		EventBus.collectible_taken.connect(_on_collectible_taken)


func reset() -> void:
	_reset()


func _reset() -> void:
	_charges = 0
	_pearl_accumulator = 0
	_echo_shield_active = false
	EventBus.power_charged.emit(0.0)


func _on_collectible_taken(_value: int) -> void:
	if _mode == "disabled":
		return
	_pearl_accumulator += 1
	var gained: bool = false
	if _pearl_accumulator >= PEARLS_PER_CHARGE and _charges < _max_charges:
		_pearl_accumulator -= PEARLS_PER_CHARGE
		_charges += 1
		gained = true
	_emit_charge_pct()
	if gained:
		SFXManager.play_sfx("sfx/power_charge")


func _emit_charge_pct() -> void:
	var partial: float = float(_pearl_accumulator) / float(PEARLS_PER_CHARGE)
	var pct: float = (float(_charges) + partial) / float(_max_charges)
	EventBus.power_charged.emit(clampf(pct, 0.0, 1.0))


func can_fire() -> bool:
	return _mode != "disabled" and _charges > 0


## Returns true if a power was successfully fired.
func fire() -> bool:
	if not can_fire():
		return false
	_charges -= 1
	var is_perfect: bool = _is_perfect_timed()
	if _equipped_power == "echo_shield":
		_echo_shield_active = true
	SFXManager.play_sfx("sfx/power_fire")
	EventBus.power_activated.emit(_equipped_power, is_perfect)
	_emit_charge_pct()
	return true


## Called by PlayerController.on_hit(). Returns true if the hit was absorbed.
func consume_shield() -> bool:
	if _echo_shield_active:
		_echo_shield_active = false
		SFXManager.play_sfx("sfx/shield_break")
		EventBus.power_cooldown_started.emit()
		return true
	return false


func has_echo_shield() -> bool:
	return _echo_shield_active


func get_charges() -> int:
	return _charges


func get_pearl_accumulator() -> int:
	return _pearl_accumulator


func _is_perfect_timed() -> bool:
	var frac: float = fmod(BeatConductor.get_current_beat_position(), 1.0)
	return frac < PERFECT_BEAT_WINDOW or frac > (1.0 - PERFECT_BEAT_WINDOW)
