## TimelineView.gd
## Custom-draw scrollable timeline grid for the Build Mode editor.
## Horizontal axis = beats (time), vertical axis = lane Y (0..CANVAS_H).
## Supports drag-pan, discrete zoom 1×/2×/4×, beat-grid snap, and a beat ruler.
extends Control

class_name TimelineView

signal obstacle_placed(beat_index: float, lane_y_normalized: float)
signal obstacle_selected(beat_map_index: int)
signal obstacle_deselected
signal delete_requested(beat_map_index: int)

const CANVAS_H: float = 1920.0
const BEATS_VISIBLE_DEFAULT: int = 16
const RULER_H: float = 44.0  # pixels reserved for beat-number ruler

var px_per_beat: float = 60.0
var px_per_lane: float = 1.0
var pan_beat: float = 0.0
var zoom: int = 1
var selected_index: int = -1
var session: BuildSession = null
var active_type: String = ""
var snap_beats: float = 0.25
var playhead_beat: float = 0.0

var _dragging: bool = false
var _drag_start_x: float = 0.0
var _drag_start_beat: float = 0.0

const COL_BG: Color = Color(0.04, 0.05, 0.14)
const COL_RULER: Color = Color(0.10, 0.12, 0.22)
const COL_BEAT: Color = Color(0.30, 0.30, 0.46)
const COL_BEAT_4: Color = Color(0.50, 0.52, 0.72)
const COL_BEAT_8: Color = Color(0.18, 0.18, 0.30)
const COL_PLAYHEAD: Color = Color(1.0, 0.6, 0.1)
const COL_SELECTED: Color = Color(1.0, 1.0, 0.3, 1.0)
const COL_DELETE_BTN: Color = Color(0.9, 0.15, 0.15)

const OBSTACLE_COLORS: Dictionary = {
	"pressure_wall":  Color(0.25, 0.65, 1.0),
	"jellyfish_drift": Color(0.85, 0.35, 0.95),
	"boss_projectile": Color(1.0, 0.35, 0.25),
	"speed_ring":      Color(0.25, 0.95, 0.55),
	"gravity_flip":    Color(0.95, 0.75, 0.15),
	"secret_exit":     Color(0.95, 0.85, 0.2),
}
const COL_OBSTACLE_DEFAULT: Color = Color(0.3, 0.8, 1.0, 0.9)


func _ready() -> void:
	_recalc_scale()
	set_process_input(true)


func _recalc_scale() -> void:
	var beats_visible: int = BEATS_VISIBLE_DEFAULT / zoom
	var usable_h: float = size.y - RULER_H
	px_per_beat = size.x / float(beats_visible)
	px_per_lane = usable_h / CANVAS_H


func _draw() -> void:
	if size.x <= 0 or size.y <= 0:
		return

	draw_rect(Rect2(Vector2.ZERO, size), COL_BG)

	var beats_visible: float = size.x / px_per_beat
	var start_beat: int = int(pan_beat)
	var end_beat: int = int(pan_beat + beats_visible) + 2
	var font: Font = ThemeDB.fallback_font

	# ── Ruler background ─────────────────────────────────────────────────────
	draw_rect(Rect2(0.0, 0.0, size.x, RULER_H), COL_RULER)

	# ── Beat lines + ruler numbers ────────────────────────────────────────────
	for b: int in range(start_beat, end_beat):
		var x: float = (float(b) - pan_beat) * px_per_beat
		if x < -2.0 or x > size.x + 2.0:
			continue

		var is_bar: bool = (b % 4 == 0)
		var line_col: Color = COL_BEAT_4 if is_bar else COL_BEAT
		draw_line(Vector2(x, RULER_H), Vector2(x, size.y), line_col, 1.0)

		# Ruler tick + beat number (every beat; bold on bar lines)
		draw_line(Vector2(x, RULER_H - 8.0), Vector2(x, RULER_H), line_col, 1.5)
		var label: String = str(b)
		var font_size: int = 20 if is_bar else 16
		var txt_col: Color = Color.WHITE if is_bar else Color(0.7, 0.7, 0.8)
		draw_string(font, Vector2(x + 3.0, RULER_H - 10.0), label,
				HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, txt_col)

		if zoom >= 2:
			var hx: float = x + px_per_beat * 0.5
			draw_line(Vector2(hx, RULER_H), Vector2(hx, size.y), COL_BEAT_8, 1.0)
		if zoom >= 4:
			for q: int in [1, 3]:
				var qx: float = x + px_per_beat * (float(q) * 0.25)
				draw_line(Vector2(qx, RULER_H), Vector2(qx, size.y),
						COL_BEAT_8 * Color(1, 1, 1, 0.5), 1.0)

	# ── Obstacles ─────────────────────────────────────────────────────────────
	if session != null:
		var beat_map: Array = (session.get_data().get("beat_map", []) as Array)
		for i: int in range(beat_map.size()):
			var entry: Dictionary = beat_map[i] as Dictionary
			var beat_idx: float = float(entry.get("beat_index", 0))
			var lane_y: float = float(entry.get("lane_position", 0.5))
			var otype: String = str(entry.get("obstacle_type", "?"))
			_draw_obstacle(beat_idx, lane_y, otype, i == selected_index)

	# ── Playhead ──────────────────────────────────────────────────────────────
	var ph_x: float = (playhead_beat - pan_beat) * px_per_beat
	if ph_x >= 0.0 and ph_x <= size.x:
		draw_line(Vector2(ph_x, 0.0), Vector2(ph_x, size.y), COL_PLAYHEAD, 2.5)
		draw_string(font, Vector2(ph_x + 3.0, RULER_H - 12.0), "▶",
				HORIZONTAL_ALIGNMENT_LEFT, -1, 16, COL_PLAYHEAD)

	# ── Ruler divider line ────────────────────────────────────────────────────
	draw_line(Vector2(0.0, RULER_H), Vector2(size.x, RULER_H),
			Color(0.5, 0.5, 0.7, 0.6), 1.0)


func _draw_obstacle(beat_idx: float, lane_y_norm: float, otype: String, is_sel: bool) -> void:
	var x: float = (beat_idx - pan_beat) * px_per_beat
	var y: float = RULER_H + lane_y_norm * (size.y - RULER_H)
	if x < -40.0 or x > size.x + 40.0:
		return

	var base_col: Color = OBSTACLE_COLORS.get(otype, COL_OBSTACLE_DEFAULT) as Color
	if is_sel:
		base_col = COL_SELECTED

	var rw: float = maxf(10.0, px_per_beat * 0.45)
	var rh: float = 32.0
	# Shadow
	draw_rect(Rect2(x - rw * 0.5 + 2.0, y - rh * 0.5 + 2.0, rw, rh),
			Color(0.0, 0.0, 0.0, 0.4))
	# Filled chip
	draw_rect(Rect2(x - rw * 0.5, y - rh * 0.5, rw, rh), base_col.darkened(0.35))
	draw_rect(Rect2(x - rw * 0.5 + 1.0, y - rh * 0.5 + 1.0, rw - 2.0, rh - 2.0), base_col)

	# Short label (first 3 chars of type)
	var short: String = otype.substr(0, 3).to_upper()
	draw_string(ThemeDB.fallback_font,
			Vector2(x - rw * 0.5 + 2.0, y + 6.0),
			short, HORIZONTAL_ALIGNMENT_LEFT, -1, 11,
			Color(0.05, 0.05, 0.1, 0.9))

	# Delete button on selected obstacle
	if is_sel:
		var dx: float = x + rw * 0.5 + 2.0
		var dy: float = y - rh * 0.5 - 2.0
		draw_circle(Vector2(dx, dy), 11.0, COL_DELETE_BTN)
		draw_string(ThemeDB.fallback_font,
				Vector2(dx - 5.0, dy + 6.0), "×",
				HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color.WHITE)


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
			# Check if tapping on the delete button of the selected obstacle.
			if selected_index >= 0 and _hit_delete_btn(pos):
				delete_requested.emit(selected_index)
				selected_index = -1
				obstacle_deselected.emit()
				queue_redraw()
				get_viewport().set_input_as_handled()
				return

			_dragging = true
			_drag_start_x = pos.x
			_drag_start_beat = pan_beat

			var beat_map: Array = []
			if session != null:
				beat_map = (session.get_data().get("beat_map", []) as Array)

			# Ignore ruler area for placement — ruler is for display only.
			if pos.y < RULER_H:
				return

			var hit_idx: int = _hit_test(pos, beat_map)
			if hit_idx >= 0:
				selected_index = hit_idx
				obstacle_selected.emit(hit_idx)
				queue_redraw()
			elif not active_type.is_empty() and not is_right_click:
				var beat_idx: float = _snap_beat(pan_beat + pos.x / px_per_beat)
				var lane_y: float = (pos.y - RULER_H) / (size.y - RULER_H)
				obstacle_placed.emit(beat_idx, clampf(lane_y, 0.0, 1.0))
				selected_index = -1
				obstacle_deselected.emit()
				queue_redraw()
			else:
				selected_index = -1
				obstacle_deselected.emit()
				queue_redraw()
		else:
			_dragging = false


func _hit_delete_btn(pos: Vector2) -> bool:
	if session == null or selected_index < 0:
		return false
	var beat_map: Array = (session.get_data().get("beat_map", []) as Array)
	if selected_index >= beat_map.size():
		return false
	var entry: Dictionary = beat_map[selected_index] as Dictionary
	var beat_idx: float = float(entry.get("beat_index", 0))
	var lane_y: float = float(entry.get("lane_position", 0.5))
	var ox: float = (beat_idx - pan_beat) * px_per_beat
	var oy: float = RULER_H + lane_y * (size.y - RULER_H)
	var rw: float = maxf(10.0, px_per_beat * 0.45)
	var rh: float = 32.0
	var dx: float = ox + rw * 0.5 + 2.0
	var dy: float = oy - rh * 0.5 - 2.0
	return pos.distance_to(Vector2(dx, dy)) <= 14.0


func _hit_test(pos: Vector2, beat_map: Array) -> int:
	for i: int in range(beat_map.size()):
		var entry: Dictionary = beat_map[i] as Dictionary
		var beat_idx: float = float(entry.get("beat_index", 0))
		var lane_y: float = float(entry.get("lane_position", 0.5))
		var ox: float = (beat_idx - pan_beat) * px_per_beat
		var oy: float = RULER_H + lane_y * (size.y - RULER_H)
		if pos.distance_to(Vector2(ox, oy)) <= 20.0:
			return i
	return -1


func _snap_beat(raw_beat: float) -> float:
	return roundf(raw_beat / snap_beats) * snap_beats


func cycle_zoom() -> void:
	match zoom:
		1: zoom = 2
		2: zoom = 4
		_: zoom = 1
	_recalc_scale()
	queue_redraw()


func refresh() -> void:
	_recalc_scale()
	queue_redraw()
