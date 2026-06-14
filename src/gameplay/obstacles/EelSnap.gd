extends Node2D

class_name EelSnap

enum State { DORMANT, TELEGRAPH, STRIKE, RETRACT }

const TELEGRAPH_DUR: float = 0.5
const STRIKE_DUR: float = 0.15
const RETRACT_DUR: float = 0.3

var _state: State = State.DORMANT
var _time_in_state: float = 0.0
var _dormant_beats: int = 4
var _entry_beat: float = 0.0
var _strike_length: float = 300.0
var _origin_wall: String = "left"
var _tween: Tween = null

@onready var _eel_body: Node2D = $EelBody
@onready var _strike_area: Area2D = $StrikeArea
@onready var _strike_col: CollisionShape2D = $StrikeArea/CollisionShape2D
@onready var _visual: Polygon2D = $Visual

## Visible strike bar that exactly overlays the kill collision (built in setup()).
## Without this the eel struck an invisible 300px kill zone — an unfair death.
var _strike_visual: Polygon2D = null


func _ready() -> void:
	add_to_group("scrolling")
	_strike_col.disabled = true
	_strike_area.body_entered.connect(_on_strike_body_entered)
	BeatConductor.beat_fired.connect(_on_beat_fired)


func setup(entry: Dictionary) -> void:
	_entry_beat = float(entry.get("beat_index", 0))
	var p: Dictionary = entry.get("parameters", {}) as Dictionary
	_dormant_beats = int(p.get("dormant_beats", 4))
	_strike_length = float(p.get("strike_length", 300))
	_origin_wall = str(p.get("origin_wall", "left"))

	var rect: RectangleShape2D = RectangleShape2D.new()
	rect.size = Vector2(_strike_length, 60.0)
	_strike_col.shape = rect
	if _origin_wall == "left":
		_strike_area.position = Vector2(_strike_length * 0.5, 0.0)
	else:
		_strike_area.position = Vector2(-_strike_length * 0.5, 0.0)

	# Build a visible bar overlaying the exact kill zone so the strike is never
	# invisible. Hidden until the eel telegraphs/strikes.
	var hw: float = _strike_length * 0.5
	var hh: float = 30.0
	_strike_visual = Polygon2D.new()
	_strike_visual.polygon = PackedVector2Array([
		Vector2(-hw, -hh), Vector2(hw, -hh), Vector2(hw, hh), Vector2(-hw, hh)])
	_strike_visual.color = Color(1.0, 1.0, 1.0, 0.0)
	_strike_area.add_child(_strike_visual)


func _process(delta: float) -> void:
	position.x -= ScrollService.speed_now() * delta
	if position.x < -500.0:
		queue_free()
		return

	_time_in_state += delta
	match _state:
		State.TELEGRAPH:
			if _time_in_state >= TELEGRAPH_DUR:
				_do_strike()
		State.STRIKE:
			if _time_in_state >= STRIKE_DUR:
				_do_retract()
		State.RETRACT:
			if _time_in_state >= RETRACT_DUR:
				_set_state(State.DORMANT)


func _on_beat_fired(beat_idx: int) -> void:
	if _state != State.DORMANT:
		return
	if float(beat_idx) < _entry_beat:
		return
	if (beat_idx - int(_entry_beat)) % _dormant_beats == 0:
		_set_state(State.TELEGRAPH)


func _set_state(s: State) -> void:
	_state = s
	_time_in_state = 0.0
	if _strike_visual != null:
		match s:
			State.TELEGRAPH:
				# Warning preview of where the eel will strike.
				_strike_visual.color = Color(1.0, 0.85, 0.2, 0.4)
			State.STRIKE:
				# Solid danger bar — matches the live kill collision exactly.
				_strike_visual.color = Color(0.9, 0.25, 0.25, 0.95)
			_:
				_strike_visual.color = Color(1.0, 1.0, 1.0, 0.0)


func _do_strike() -> void:
	_set_state(State.STRIKE)
	_strike_col.disabled = false
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	var target_x: float = _strike_length if _origin_wall == "left" else -_strike_length
	_tween.tween_property(_eel_body, "position:x", target_x, STRIKE_DUR).set_ease(Tween.EASE_IN)


func _do_retract() -> void:
	_strike_col.disabled = true
	_set_state(State.RETRACT)
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(_eel_body, "position:x", 0.0, RETRACT_DUR)


func _on_strike_body_entered(body: Node2D) -> void:
	if _state != State.STRIKE:
		return
	if body.has_method("on_hit"):
		body.on_hit()
