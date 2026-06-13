# Scene-local CharacterBody2D implementing one-touch buoyancy physics for the player fish.
extends CharacterBody2D

class_name PlayerController

@export var float_force: float = 1250.0
@export var dive_force: float = 1550.0
@export var max_float_speed: float = 700.0
@export var max_dive_speed: float = 880.0
@export var drag: float = 0.983

## On tap, velocity is SET (not added) — guarantees identical feel every time.
## Tuned for a shallow ~40–55px dip with fast (~0.2s) buoyant recovery; holding
## then accelerates into a fast sustained dive (terminal 880 px/s).
@export var dive_impulse: float = 220.0

# Fixed logical canvas height — matches project.godot viewport_height. Gameplay
# coordinates are always in the 1080×1920 space; never query the viewport for
# bounds (its size varies with window/DPI and breaks the clamp).
const CANVAS_H: float = 1920.0

var diving: bool = false
var alive: bool = true

@onready var beat_visualizer: BeatVisualizer = $BeatVisualizer
@onready var timing_judge: TimingJudge = $TimingJudge

var _ghost_recorder: GhostRecorder = null


func _ready() -> void:
	add_to_group("player")
	timing_judge.input_judged.connect(_on_input_judged)


func set_ghost_recorder(recorder: GhostRecorder) -> void:
	_ghost_recorder = recorder


func _input(event: InputEvent) -> void:
	if not alive:
		return
	# `not diving` guard: one physical tap arrives as TWO events (the raw
	# mouse/touch event plus its emulated counterpart, both bound to swim_dive),
	# which would double-judge every input and double-apply the impulse.
	if event.is_action_pressed("swim_dive") and not diving:
		diving = true
		var ov: Dictionary = GameManager.physics_overrides
		velocity.y = float(ov.get("dive_impulse", dive_impulse))
		timing_judge.judge_input(BeatConductor.get_current_beat_time_ms())
		if _ghost_recorder != null:
			_ghost_recorder.record_event(BeatConductor.get_current_beat_position(), "dive_start")
	elif event.is_action_released("swim_dive"):
		diving = false
		if _ghost_recorder != null:
			_ghost_recorder.record_event(BeatConductor.get_current_beat_position(), "dive_end")


func _physics_process(delta: float) -> void:
	if not alive:
		return

	# Allow live physics tuner to override values (debug builds only).
	var ov: Dictionary = GameManager.physics_overrides
	var _float_force: float = float(ov.get("float_force", float_force))
	var _dive_force: float = float(ov.get("dive_force", dive_force))
	var _max_float: float = float(ov.get("max_float_speed", max_float_speed))
	var _max_dive: float = float(ov.get("max_dive_speed", max_dive_speed))
	var _impulse: float = float(ov.get("dive_impulse", dive_impulse))

	# Buoyancy — always float upward.
	velocity.y -= _float_force * delta

	# Dive — pull downward while input is held.
	if diving:
		velocity.y += _dive_force * delta

	# Clamp to terminal velocities (upward speed is negative Y in Godot).
	velocity.y = clamp(velocity.y, -_max_float, _max_dive)

	# Light water drag applied every frame.
	velocity *= drag

	move_and_slide()

	# Clamp player within screen bounds with a small margin.
	global_position.y = clamp(global_position.y, 60.0, CANVAS_H - 60.0)


func on_hit() -> void:
	if not alive:
		return
	# Check EchoShield before dying.
	var rc: Node = get_tree().get_first_node_in_group("resonance_controller")
	if rc != null and rc.has_method("consume_shield"):
		if rc.consume_shield():
			return
	alive = false
	modulate = Color(1.0, 0.3, 0.3)
	EventBus.player_hit.emit()
	_die_after_delay()


func _die_after_delay() -> void:
	await get_tree().create_timer(0.8).timeout
	EventBus.run_failed.emit(GameManager.current_level_id, 0)


func _on_input_judged(result: TimingJudge.TimingResult, _offset_ms: float, _beat_index: int) -> void:
	beat_visualizer.set_timing_quality(result)
