# Scene-local CharacterBody2D implementing one-touch buoyancy physics for the player fish.
extends CharacterBody2D

class_name PlayerController

@export var float_force: float = 480.0
@export var dive_force: float = 1220.0
@export var max_float_speed: float = 480.0
@export var max_dive_speed: float = 720.0
# drag = 1 - (float_force/fps) / terminal_float_speed = 1 - (480/60)/480 = 0.983
@export var drag: float = 0.983

## On tap, velocity is SET (not added) to this value — guarantees immediate
## direction reversal with identical feel every time (Flappy Bird-style).
@export var dive_impulse: float = 480.0

var diving: bool = false
var alive: bool = true

@onready var beat_visualizer: BeatVisualizer = $BeatVisualizer
@onready var timing_judge: TimingJudge = $TimingJudge


func _ready() -> void:
	timing_judge.input_judged.connect(_on_input_judged)


func _input(event: InputEvent) -> void:
	if not alive:
		return
	if event.is_action_pressed("swim_dive"):
		diving = true
		velocity.y = dive_impulse
		timing_judge.judge_input(BeatConductor.get_current_beat_time_ms())
	elif event.is_action_released("swim_dive"):
		diving = false


func _physics_process(delta: float) -> void:
	if not alive:
		return

	# Buoyancy — always float upward.
	velocity.y -= float_force * delta

	# Dive — pull downward while input is held.
	if diving:
		velocity.y += dive_force * delta

	# Clamp to terminal velocities (upward speed is negative Y in Godot).
	velocity.y = clamp(velocity.y, -max_float_speed, max_dive_speed)

	# Light water drag applied every frame.
	velocity *= drag

	move_and_slide()

	# Clamp player within screen bounds with a small margin.
	var screen_height: float = get_viewport_rect().size.y
	global_position.y = clamp(global_position.y, 60.0, screen_height - 60.0)


func on_hit() -> void:
	if not alive:
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
