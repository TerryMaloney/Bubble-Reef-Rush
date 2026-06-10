extends Node2D

class_name CurrentJet

enum State { IDLE, TELEGRAPHING, FIRING, COOLDOWN }

const TELEGRAPH_DUR: float = 0.5
const FIRE_DUR: float = 0.4
const COOLDOWN_DUR: float = 0.3
const CANVAS_W: float = 1080.0

var _state: State = State.IDLE
var _time_in_state: float = 0.0
var _cycle_beats: int = 2
var _entry_beat: float = 0.0
var _origin_wall: String = "left"

@onready var _stream_area: Area2D = $StreamArea
@onready var _stream_col: CollisionShape2D = $StreamArea/CollisionShape2D
@onready var _visual: Polygon2D = $Visual


func _ready() -> void:
	add_to_group("scrolling")
	_stream_col.disabled = true
	_stream_area.body_entered.connect(_on_stream_body_entered)
	BeatConductor.beat_fired.connect(_on_beat_fired)


func setup(entry: Dictionary) -> void:
	_entry_beat = float(entry.get("beat_index", 0))
	var p: Dictionary = entry.get("parameters", {}) as Dictionary
	_cycle_beats = int(p.get("cycle_beats", 2))
	_origin_wall = str(p.get("origin_wall", "left"))
	_update_visual()


func _process(delta: float) -> void:
	position.x -= ScrollService.speed_now() * delta
	if position.x < -(CANVAS_W * 0.5 + 100.0):
		queue_free()
		return

	_time_in_state += delta
	match _state:
		State.TELEGRAPHING:
			if _time_in_state >= TELEGRAPH_DUR:
				_set_state(State.FIRING)
		State.FIRING:
			if _time_in_state >= FIRE_DUR:
				_set_state(State.COOLDOWN)
		State.COOLDOWN:
			if _time_in_state >= COOLDOWN_DUR:
				_set_state(State.IDLE)


func _on_beat_fired(beat_idx: int) -> void:
	if _state != State.IDLE:
		return
	if float(beat_idx) < _entry_beat:
		return
	if (beat_idx - int(_entry_beat)) % _cycle_beats == 0:
		_set_state(State.TELEGRAPHING)


func _set_state(s: State) -> void:
	_state = s
	_time_in_state = 0.0
	_stream_col.disabled = (s != State.FIRING)
	_update_visual()


func _update_visual() -> void:
	match _state:
		State.IDLE:
			_visual.color = Color(0.3, 0.5, 0.7)
		State.TELEGRAPHING:
			_visual.color = Color(1.0, 0.8, 0.2)
		State.FIRING:
			_visual.color = Color(0.2, 0.7, 1.0)
		State.COOLDOWN:
			_visual.color = Color(0.3, 0.5, 0.7, 0.5)


func _on_stream_body_entered(body: Node2D) -> void:
	if _state != State.FIRING:
		return
	if body.has_method("on_hit"):
		body.on_hit()
