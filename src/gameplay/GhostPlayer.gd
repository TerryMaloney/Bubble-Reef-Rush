## GhostPlayer — translucent non-colliding replay of a recorded ghost run.
##
## Reads the inputs array from a ghost_data Dictionary (produced by GhostRecorder)
## and simulates the same PlayerController physics, applying recorded inputs at the
## beat positions they were originally recorded at.
##
## Positioned at x=200 (matching Player spawn). Node2D only — no CollisionShape2D,
## so it never triggers obstacle or collectible detection.
## Call setup() then play() (which fires on run_started from LevelRoot).
extends Node2D

class_name GhostPlayer

# Mirror PlayerController constants exactly so physics replay is faithful.
const FLOAT_FORCE: float = 480.0
const DIVE_FORCE: float = 1220.0
const MAX_FLOAT_SPEED: float = 480.0
const MAX_DIVE_SPEED: float = 720.0
const DRAG: float = 0.983
const DIVE_IMPULSE: float = 480.0
const CANVAS_H: float = 1920.0
const START_X: float = 200.0
const START_Y: float = 960.0

var _inputs: Array[Dictionary] = []
var _input_idx: int = 0
var _velocity_y: float = 0.0
var _diving: bool = false
var _playing: bool = false

@onready var _visual: Polygon2D = get_node_or_null("Visual") as Polygon2D


func setup(ghost_data: Dictionary) -> void:
	var raw: Array = ghost_data.get("inputs", []) as Array
	_inputs.clear()
	for item: Variant in raw:
		if item is Dictionary:
			_inputs.append(item as Dictionary)
	position = Vector2(START_X, START_Y)
	_velocity_y = 0.0
	_diving = false
	_input_idx = 0
	_playing = false


func play() -> void:
	_playing = true


func _physics_process(delta: float) -> void:
	if not _playing:
		return

	var current_beat: float = BeatConductor.get_current_beat_position()

	# Apply all inputs whose recorded beat has been passed.
	while _input_idx < _inputs.size():
		var entry: Dictionary = _inputs[_input_idx]
		if current_beat < float(entry.get("beat", 0.0)):
			break
		match str(entry.get("event", "")):
			"dive_start":
				_diving = true
				_velocity_y = DIVE_IMPULSE
			"dive_end":
				_diving = false
		_input_idx += 1

	# Same integration as PlayerController._physics_process().
	_velocity_y -= FLOAT_FORCE * delta
	if _diving:
		_velocity_y += DIVE_FORCE * delta
	_velocity_y = clampf(_velocity_y, -MAX_FLOAT_SPEED, MAX_DIVE_SPEED)
	_velocity_y *= DRAG
	position.y += _velocity_y * delta
	position.y = clampf(position.y, 60.0, CANVAS_H - 60.0)
