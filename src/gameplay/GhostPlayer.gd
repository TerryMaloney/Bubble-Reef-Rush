## GhostPlayer — replays recorded ghost inputs using the same buoyancy physics.
## Non-colliding (no physics body collision). Rendered as a translucent fish silhouette.
## Place as a child of LevelRoot. Call setup(ghost_data) then play() on run_started.
extends Node2D

class_name GhostPlayer

const CANVAS_H: float = 1920.0
# These MUST mirror PlayerController / GameConstants exactly, or the ghost
# replays the same dive inputs under different physics and desyncs — drifting
# to the floor or ceiling instead of tracking the recorded run.
const FLOAT_FORCE: float = 1250.0
const DIVE_FORCE: float = 1940.0
const MAX_FLOAT_SPEED: float = 700.0
const MAX_DIVE_SPEED: float = 1100.0
const DIVE_IMPULSE: float = 220.0
const DRAG: float = 0.983

var _inputs: Array = []
var _input_idx: int = 0
var _velocity_y: float = 0.0
var _diving: bool = false
var _playing: bool = false
var _last_beat: float = 0.0

@onready var _visual: Polygon2D = $Visual


func setup(ghost_data: Dictionary) -> void:
	_inputs = ghost_data.get("inputs", []) as Array
	_input_idx = 0
	_velocity_y = 0.0
	_diving = false
	_playing = false
	global_position = Vector2(200.0, CANVAS_H * 0.5)
	if _visual != null:
		_visual.color = Color(0.4, 0.7, 1.0, 0.4)


func play() -> void:
	_input_idx = 0
	_playing = true


func _process(delta: float) -> void:
	if not _playing or _inputs.is_empty():
		return

	var current_beat: float = BeatConductor.get_current_beat_position()

	while _input_idx < _inputs.size():
		var inp: Dictionary = _inputs[_input_idx] as Dictionary
		if float(inp.get("beat", 0.0)) <= current_beat:
			var ev: String = str(inp.get("event", ""))
			if ev == "dive_start":
				_diving = true
				_velocity_y = DIVE_IMPULSE
			elif ev == "dive_end":
				_diving = false
			_input_idx += 1
		else:
			break

	_velocity_y -= FLOAT_FORCE * delta
	if _diving:
		_velocity_y += DIVE_FORCE * delta
	_velocity_y = clamp(_velocity_y, -MAX_FLOAT_SPEED, MAX_DIVE_SPEED)
	_velocity_y *= DRAG
	global_position.y += _velocity_y * delta
	global_position.y = clamp(global_position.y, 60.0, CANVAS_H - 60.0)

	_last_beat = current_beat
