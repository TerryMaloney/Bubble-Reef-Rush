## TimelineView.gd
## Custom-draw scrollable timeline grid for the Build Mode editor.
## Horizontal axis = beats (time), vertical axis = lane Y (0..CANVAS_H).
## Supports drag-pan, discrete zoom 1×/2×/4×, and beat-grid snap.
extends Control

class_name TimelineView

signal obstacle_placed(beat_index: float, lane_y_normalized: float)
signal obstacle_selected(beat_map_index: int)
signal obstacle_deselected

# Timeline dimensions.
const CANVAS_H: float = 1920.0
const BEATS_VISIBLE_DEFAULT: int = 16  # at 1× zoom

## Pixels per beat at current zoom. Set by _recalc_scale().
var px_per_beat: float = 60.0
## Vertical scale: timeline height / CANVAS_H.
var px_per_lane: float = 1.0

## Beat offset of the left edge (pan).
var pan_beat: float = 0.0

## Zoom level: 1, 2, or 4.
var zoom: int = 1

## Currently selected obstacle index in beat_map (-1 = none).
var selected_index: int = -1

## Reference to the active BuildSession (set by BuildModeRoot).
var session: BuildSession = null

## Active obstacle type to place (set by PalettePanel selection).
var active_type: String = ""

## Snap resolution in beats: 0.25 always, 0.125 at Z3+, 0.0625 at Z5+.
var snap_beats: float = 0.25

# Drag pan state.
var _dragging: bool = false
var _drag_start_x: float = 0.0
var _drag_start_beat: float = 0.0

# Colors.
const COL_BG: Color = Color(0.05, 0.05, 0.12)
const COL_BEAT: Color = Color(0.35, 0.35, 0.5)
const COL_BEAT_4: Color = Color(0.55, 0.55, 0.7)
const COL_BEAT_8: Color = Color(0.22, 0.22, 0.35)
const COL_PLAYHEAD: Color = Color(1.0, 0.6, 0.1)
const COL_OBSTACLE: Color = Color(0.3, 0.8, 1.0, 0.9)
const COL_SELECTED: Color = Color(1.0, 1.0, 0.3, 1.0)
const COL_OVERLAP_ERR: Color = Color(1.0, 0.1, 0.1, 0.8)

## Current playhead beat position (set by PlaybackBar).
var playhead_beat: float = 0.0


func _ready() -> void:
	_recalc_scale()
	set_process_input(true)


func _recalc_scale() -> void:
	var beats_visible: int = BEATS_VISIBLE_DEFAULT / zoom
	px_per_beat = size.x / float(beats_visible)
	px_per_lane = size.y / CANVAS_H


func _draw() -> void:
	if size.x <= 0 or size.y <= 0:
		return

	draw_rect(Rect2(Vector2.ZERO, size), COL_BG)

	var beats_visible: float = size.x / px_per_beat

	# Beat lines.
	var start_beat: int = int(pan_beat)
	var end_beat: int = int(pan_beat + beats_visible) + 2

	for b: int in range(start_beat, end_beat):
		var x: float = (float(b) - pan_beat) * px_per_beat
		if x < -2.0 or x > size.x + 2.0:
			continue
		var col: Color
		if b % 4 == 0:
			col = COL_BEAT_4
		else:
			col = COL_BEAT

		draw_line(Vector2(x, 0), Vector2(x, size.y), col, 1.0)

		# Eighth/sixteenth sub-beat lines at zoom ≥ 2×/4×.
		if zoom >= 2:
			var hx: float = x + px_per_beat * 0.5
			draw_line(Vector2(hx, 0), Vector2(hx, size.y), COL_BEAT_8, 1.0)
		if zoom >= 4:
			for q: int in [1, 3]:
				var qx: float = x + px_per_beat * (float(q) * 0.25)
				draw_line(Vector2(qx, 0), Vector2(qx, size.y), COL_BEAT_8 * Color(1, 1, 1, 0.5), 1.0)

	# Obstacles from session.
	if session != null:
		var beat_map: Array = (session.get_data().get("beat_map", []) as Array)
		for i: int in range(beat_map.size()):
			var entry: Dictionary = beat_map[i] as Dictionary
			var beat_idx: float = float(entry.get("beat_index", 0))
			var lane_y: float = float(entry.get("lane_position", 0.5))
			var col: Color = COL_SELECTED if i == selected_index else COL_OBSTACLE
			_draw_obstacle(beat_idx, lane_y, str(entry.get("obstacle_type", "?")), col)

	# Playhead.
	var ph_x: float = (playhead_beat - pan_beat) * px_per_beat
	if ph_x >= 0.0 and ph_x <= size.x:
		draw_line(Vector2(ph_x, 0), Vector2(ph_x, size.y), COL_PLAYHEAD, 2.0)


func _draw_obstacle(beat_idx: float, lane_y_norm: float, type_hint: String, col: Color) -> void:
	var x: float = (beat_idx - pan_beat) * px_per_beat
	var y: float = lane_y_norm * size.y
	if x < -20.0 or x > size.x + 20.0:
		return
	draw_circle(Vector2(x, y), 12.0, col)
	# Type initial for orientation.
	if not type_hint.is_empty():
		draw_string(
			ThemeDB.fallback_font,
			Vector2(x - 5.0, y + 5.0),
			type_hint.substr(0, 1).to_upper(),
			HORIZONTAL_ALIGNMENT_LEFT, -1, 14,
			Color.BLACK
		)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenDrag or event is InputEventMouseMotion:
		if _dragging:
			var motion: float = 0.0
			if event is InputEventScreenDrag:
				motion = (event as InputEventScreenDrag).relative.x
			else:
				motion = (event as InputEventMouseMotion).relative.x
			pan_beat = _drag_start_beat - (motion / px_per_beat)
			pan_beat = maxf(0.0, pan_beat)
			queue_redraw()
		return

	if event is InputEventScreenTouch or event is InputEventMouseButton:
		var pressed: bool = false
		var pos: Vector2 = Vector2.ZERO
		var is_right_click: bool = false

		if event is InputEventScreenTouch:
			var te: InputEventScreenTouch = event as InputEventScreenTouch
			pressed = te.pressed
			pos = te.position
		else:
			var mb: InputEventMouseButton = event as InputEventMouseButton
			pressed = mb.pressed
			pos = mb.position
			is_right_click = (mb.button_index == MOUSE_BUTTON_RIGHT)

		if pressed:
			_dragging = true
			_drag_start_x = pos.x
			_drag_start_beat = pan_beat

			# Check if tapping on an existing obstacle.
			var beat_map: Array = []
			if session != null:
				beat_map = (session.get_data().get("beat_map", []) as Array)

			var hit_idx: int = _hit_test(pos, beat_map)
			if hit_idx >= 0:
				selected_index = hit_idx
				obstacle_selected.emit(hit_idx)
				queue_redraw()
			elif not active_type.is_empty() and not is_right_click:
				# Place new obstacle.
				var beat_idx: float = _snap_beat(pan_beat + pos.x / px_per_beat)
				var lane_y: float = pos.y / size.y
				obstacle_placed.emit(beat_idx, lane_y)
				selected_index = -1
				obstacle_deselected.emit()
				queue_redraw()
			else:
				selected_index = -1
				obstacle_deselected.emit()
				queue_redraw()
		else:
			_dragging = false


func _hit_test(pos: Vector2, beat_map: Array) -> int:
	for i: int in range(beat_map.size()):
		var entry: Dictionary = beat_map[i] as Dictionary
		var beat_idx: float = float(entry.get("beat_index", 0))
		var lane_y: float = float(entry.get("lane_position", 0.5))
		var ox: float = (beat_idx - pan_beat) * px_per_beat
		var oy: float = lane_y * size.y
		if pos.distance_to(Vector2(ox, oy)) <= 18.0:
			return i
	return -1


func _snap_beat(raw_beat: float) -> float:
	return roundf(raw_beat / snap_beats) * snap_beats


## Cycle zoom: 1× → 2× → 4× → 1×.
func cycle_zoom() -> void:
	match zoom:
		1: zoom = 2
		2: zoom = 4
		_: zoom = 1
	_recalc_scale()
	queue_redraw()


## Called when session or window size changes.
func refresh() -> void:
	_recalc_scale()
	queue_redraw()
