## JuiceDirector — scene-local node managing camera shake, hit-stop, and death slow-mo.
## Setup: call setup(camera) once from LevelRoot._ready().
## All effects are suppressed when Accessibility.reduced_motion() is true.
extends Node

class_name JuiceDirector

const MAX_SHAKE: float = 12.0
const SHAKE_DECAY: float = 4.0
const HIT_STOP_SCALE: float = 0.05
const HIT_STOP_DURATION: float = 0.08
const DEATH_SLOW_SCALE: float = 0.3
const DEATH_SLOW_DURATION: float = 0.4

var _camera: Camera2D = null
var _trauma: float = 0.0
var _time: float = 0.0
var _effect_running: bool = false


func setup(camera: Camera2D) -> void:
	_camera = camera
	EventBus.player_hit.connect(_on_player_hit)


func _process(delta: float) -> void:
	_time += delta
	_trauma = maxf(0.0, _trauma - SHAKE_DECAY * delta)
	if _camera == null:
		return
	if not Accessibility.reduced_motion() and _trauma > 0.0:
		var mag: float = _trauma * _trauma
		_camera.offset = Vector2(
			MAX_SHAKE * mag * sin(_time * 37.0),
			MAX_SHAKE * mag * cos(_time * 53.0)
		)
	else:
		_camera.offset = Vector2.ZERO


func _on_player_hit() -> void:
	_trauma = 1.0
	if not Accessibility.reduced_motion() and not _effect_running:
		_run_time_effects()


func _run_time_effects() -> void:
	_effect_running = true
	# Hit-stop: freeze the game very briefly to punctuate the hit.
	Engine.time_scale = HIT_STOP_SCALE
	await get_tree().create_timer(HIT_STOP_DURATION, false, false, true).timeout
	if not is_inside_tree():
		return
	# Death slow-mo: ease the player into the fail state.
	Engine.time_scale = DEATH_SLOW_SCALE
	await get_tree().create_timer(DEATH_SLOW_DURATION, false, false, true).timeout
	if not is_inside_tree():
		return
	Engine.time_scale = 1.0
	_effect_running = false


func _notification(what: int) -> void:
	if what == NOTIFICATION_EXIT_TREE:
		Engine.time_scale = 1.0
