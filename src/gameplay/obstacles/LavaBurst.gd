extends Node2D

class_name LavaBurst

enum State { DORMANT, TELEGRAPHING, ERUPTING, COOLDOWN }

const TELEGRAPH_DUR: float = 0.6
const ERUPT_DUR: float = 0.3
const COOLDOWN_DUR: float = 0.2
const ERUPTION_WIDTH: float = 96.0
const ERUPTION_HEIGHT: float = 1080.0  # column extends 1080 px from wall
const CANVAS_H: float = 1920.0

var _state: State = State.DORMANT
var _time_in_state: float = 0.0
var _dormant_beats: int = 4
var _entry_beat: float = 0.0
var _wall_origin: String = "bottom"

@onready var _erupt_area: Area2D = $EruptArea
@onready var _erupt_col: CollisionShape2D = $EruptArea/CollisionShape2D
@onready var _visual: Polygon2D = $Visual


func _ready() -> void:
	add_to_group("scrolling")
	_erupt_col.disabled = true
	_erupt_area.body_entered.connect(_on_erupt_body_entered)
	BeatConductor.beat_fired.connect(_on_beat_fired)


func setup(entry: Dictionary) -> void:
	_entry_beat = float(entry.get("beat_index", 0))
	var p: Dictionary = entry.get("parameters", {}) as Dictionary
	_dormant_beats = int(p.get("dormant_beats", 4))
	_wall_origin = str(p.get("wall_origin", "bottom"))

	var rect: RectangleShape2D = RectangleShape2D.new()
	rect.size = Vector2(ERUPTION_WIDTH, ERUPTION_HEIGHT)
	_erupt_col.shape = rect

	# Override y to sit at the appropriate wall; eruption area extends inward.
	if _wall_origin == "bottom":
		position.y = CANVAS_H
		_erupt_area.position = Vector2(0.0, -ERUPTION_HEIGHT * 0.5)
	else:
		position.y = 0.0
		_erupt_area.position = Vector2(0.0, ERUPTION_HEIGHT * 0.5)

	_update_visual()


func _process(delta: float) -> void:
	position.x -= ScrollService.speed_now() * delta
	if position.x < -400.0:
		queue_free()
		return

	_time_in_state += delta
	match _state:
		State.TELEGRAPHING:
			if _time_in_state >= TELEGRAPH_DUR:
				_do_erupt()
		State.ERUPTING:
			if _time_in_state >= ERUPT_DUR:
				_set_state(State.COOLDOWN)
		State.COOLDOWN:
			if _time_in_state >= COOLDOWN_DUR:
				_set_state(State.DORMANT)


func _on_beat_fired(beat_idx: int) -> void:
	if _state != State.DORMANT:
		return
	if float(beat_idx) < _entry_beat:
		return
	if (beat_idx - int(_entry_beat)) % _dormant_beats == 0:
		_set_state(State.TELEGRAPHING)


func _set_state(s: State) -> void:
	_state = s
	_time_in_state = 0.0
	_erupt_col.disabled = (s != State.ERUPTING)
	_update_visual()


func _do_erupt() -> void:
	_set_state(State.ERUPTING)


func _do_cooldown() -> void:
	_set_state(State.COOLDOWN)


func _on_erupt_body_entered(body: Node2D) -> void:
	if _state != State.ERUPTING:
		return
	if body.has_method("on_hit"):
		body.on_hit()


func _update_visual() -> void:
	match _state:
		State.DORMANT:
			_visual.color = Color(0.4, 0.15, 0.05, 0.8)
		State.TELEGRAPHING:
			_visual.color = Color(1.0, 0.5, 0.0, 1.0)
		State.ERUPTING:
			_visual.color = Color(1.0, 0.9, 0.2, 1.0)
		State.COOLDOWN:
			_visual.color = Color(0.6, 0.2, 0.05, 0.9)
