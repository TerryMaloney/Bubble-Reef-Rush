## TimelineView.gd
## Custom-draw scrollable timeline grid for the Build Mode editor.
## Horizontal axis = beats (time), vertical axis = lane Y (0..CANVAS_H).
##
## Interaction model (mobile-first), redesigned to remove the place-vs-pan clash:
##   • Drag the RULER strip (top) → always pans the timeline (dedicated pan zone)
##   • With an obstacle chosen in the palette ("place mode"):
##       – Tap empty space        → place it there
##       – Drag empty space        → live-preview placement, drops on release
##         (placement never pans, so dropping no longer drags the map)
##   • With NO obstacle chosen:
##       – Drag empty space        → pan the timeline
##       – Tap empty space         → deselect
##   • Tap an existing obstacle    → select it (shows properties)
##   • Drag an existing obstacle   → reposition it; drop on the trash strip to delete
##   • Zoom cycles 1×/2×/4× via PlaybackBar button
extends Control

class_name TimelineView

signal obstacle_placed(beat_index: float, lane_y_normalized: float)
signal obstacle_selected(beat_map_index: int)
signal obstacle_deselected
signal delete_requested(beat_map_index: int)
signal obstacle_moved(beat_map_index: int, new_beat: float, new_lane: float)

const CANVAS_H: float = 1920.0
const BEATS_VISIBLE_DEFAULT: int = 16
const RULER_H: float = 44.0
const TRASH_ZONE_H: float = 80.0
const DRAG_THRESHOLD: float = 14.0  # pixels of movement before drag activates

var px_per_beat: float = 60.0
var px_per_lane: float = 1.0
var pan_beat: float = 0.0
var zoom: int = 1
var selected_index: int = -1
var session: BuildSession = null
var active_type: String = ""
var snap_beats: float = 0.25
var playhead_beat: float = 0.0

# ── Touch/click tracking ───────────────────────────────────────────────────────
var _press_pos: Vector2 = Vector2.ZERO       # position of the initial press
var _press_obs_index: int = -1               # obstacle hit at press time (-1 = none)
var _moved_enough: bool = false              # has motion exceeded DRAG_THRESHOLD?

# Pan state
var _pan_active: bool = false

# Obstacle drag state
var _obs_dragging: bool = false
var _obs_drag_index: int = -1
var _obs_drag_beat: float = 0.0
var _obs_drag_lane: float = 0.0
var _obs_drag_over_trash: bool = false

# Placement state (dragging out a new obstacle in place mode)
var _placing: bool = false
var _place_beat: float = 0.0
var _place_lane: float = 0.0
var _press_on_ruler: bool = false

const COL_BG: Color = Color(0.04, 0.05, 0.14)
const COL_RULER: Color = Color(0.10, 0.12, 0.22)
const COL_BEAT: Color = Color(0.30, 0.30, 0.46)
const COL_BEAT_4: Color = Color(0.50, 0.52, 0.72)
const COL_BEAT_8: Color = Color(0.18, 0.18, 0.30)
const COL_PLAYHEAD: Color = Color(1.0, 0.6, 0.1)
const COL_SELECTED: Color = Color(1.0, 1.0, 0.3, 1.0)
const COL_TRASH_IDLE: Color = Color(0.55, 0.10, 0.10, 0.80)
const COL_TRASH_HOT: Color = Color(0.95, 0.15, 0.15, 0.95)

const OBSTACLE_COLORS: Dictionary = {
	"pressure_wall":   Color(0.25, 0.65, 1.0),
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

	# ── Ruler ──────────────────────────────────────────────────────────────────
	draw_rect(Rect2(0.0, 0.0, size.x, RULER_H), COL_RULER)

	for b: int in range(start_beat, end_beat):
		var x: float = (float(b) - pan_beat) * px_per_beat
		if x < -2.0 or x > size.x + 2.0:
			continue
		var is_bar: bool = (b % 4 == 0)
		var line_col: Color = COL_BEAT_4 if is_bar else COL_BEAT
		draw_line(Vector2(x, RULER_H), Vector2(x, size.y), line_col, 1.0)
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

	# ── Obstacles ──────────────────────────────────────────────────────────────
	if session != null:
		var beat_map: Array = (session.get_data().get("beat_map", []) as Array)
		for i: int in range(beat_map.size()):
			if _obs_dragging and i == _obs_drag_index:
				continue  # drawn separately below at drag position
			var entry: Dictionary = beat_map[i] as Dictionary
			var beat_idx: float = float(entry.get("beat_index", 0))
			var lane_y: float = float(entry.get("lane_position", 0.5))
			var otype: String = str(entry.get("obstacle_type", "?"))
			_draw_obstacle(beat_idx, lane_y, otype, i == selected_index, false)

	# ── Dragged obstacle ghost ─────────────────────────────────────────────────
	if _obs_dragging and session != null:
		var beat_map: Array = (session.get_data().get("beat_map", []) as Array)
		if _obs_drag_index < beat_map.size():
			var drag_entry: Dictionary = beat_map[_obs_drag_index] as Dictionary
			var drag_otype: String = str(drag_entry.get("obstacle_type", "?"))
			_draw_obstacle(_obs_drag_beat, _obs_drag_lane, drag_otype, true, _obs_drag_over_trash)

	# ── Placement preview (dragging out a new obstacle in place mode) ──────────
	if _placing and not active_type.is_empty():
		_draw_obstacle(_place_beat, _place_lane, active_type, true, false)

	# ── Place-mode hint banner ─────────────────────────────────────────────────
	if not active_type.is_empty() and not _placing and not _obs_dragging:
		var hint: String = "Placing: %s  —  tap or drag to drop" % ObstacleParamSchema.display_name(active_type)
		var hint_w: float = 540.0
		draw_rect(Rect2(8.0, RULER_H + 8.0, hint_w, 36.0), Color(0.1, 0.5, 0.2, 0.85))
		draw_string(font, Vector2(18.0, RULER_H + 33.0), hint,
				HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color.WHITE)

	# ── Trash zone (visible only while dragging an obstacle) ───────────────────
	if _obs_dragging:
		var trash_col: Color = COL_TRASH_HOT if _obs_drag_over_trash else COL_TRASH_IDLE
		draw_rect(Rect2(0.0, size.y - TRASH_ZONE_H, size.x, TRASH_ZONE_H), trash_col)
		draw_string(font,
				Vector2(size.x * 0.5 - 100.0, size.y - TRASH_ZONE_H + 52.0),
				"Drag here to remove",
				HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color.WHITE)

	# ── Playhead ───────────────────────────────────────────────────────────────
	var ph_x: float = (playhead_beat - pan_beat) * px_per_beat
	if ph_x >= 0.0 and ph_x <= size.x:
		draw_line(Vector2(ph_x, 0.0), Vector2(ph_x, size.y), COL_PLAYHEAD, 2.5)
		draw_string(font, Vector2(ph_x + 3.0, RULER_H - 12.0), "▶",
				HORIZONTAL_ALIGNMENT_LEFT, -1, 16, COL_PLAYHEAD)

	# ── Ruler divider line ─────────────────────────────────────────────────────
	draw_line(Vector2(0.0, RULER_H), Vector2(size.x, RULER_H),
			Color(0.5, 0.5, 0.7, 0.6), 1.0)


func _draw_obstacle(beat_idx: float, lane_y_norm: float, otype: String,
		is_sel: bool, is_trashing: bool) -> void:
	var x: float = (beat_idx - pan_beat) * px_per_beat
	var y: float = RULER_H + lane_y_norm * (size.y - RULER_H)
	if x < -60.0 or x > size.x + 60.0:
		return

	var base_col: Color = OBSTACLE_COLORS.get(otype, COL_OBSTACLE_DEFAULT) as Color
	if is_trashing:
		base_col = Color(1.0, 0.2, 0.2)
	elif is_sel:
		base_col = COL_SELECTED

	var rw: float = maxf(48.0, px_per_beat * 0.55)
	var rh: float = 48.0
	# Shadow
	draw_rect(Rect2(x - rw * 0.5 + 3.0, y - rh * 0.5 + 3.0, rw, rh),
			Color(0.0, 0.0, 0.0, 0.35))
	# Chip body
	draw_rect(Rect2(x - rw * 0.5, y - rh * 0.5, rw, rh), base_col.darkened(0.35))
	draw_rect(Rect2(x - rw * 0.5 + 2.0, y - rh * 0.5 + 2.0, rw - 4.0, rh - 4.0), base_col)

	# Friendly short label using display_name
	var short: String = ObstacleParamSchema.display_name(otype)
	if short.length() > 6:
		short = short.substr(0, 6)
	draw_string(ThemeDB.fallback_font,
			Vector2(x - rw * 0.5 + 4.0, y + 6.0),
			short, HORIZONTAL_ALIGNMENT_LEFT, -1, 13,
			Color(0.05, 0.05, 0.1, 0.95))


func _gui_input(event: InputEvent) -> void:
	# ── Motion ────────────────────────────────────────────────────────────────
	if event is InputEventScreenDrag or event is InputEventMouseMotion:
		var pos: Vector2 = Vector2.ZERO
		var rel: Vector2 = Vector2.ZERO
		if event is InputEventScreenDrag:
			var e: InputEventScreenDrag = event as InputEventScreenDrag
			pos = e.position
			rel = e.relative
		else:
			var e: InputEventMouseMotion = event as InputEventMouseMotion
			pos = e.position
			rel = e.relative
		_handle_motion(pos, rel)
		return

	# ── Press / Release ────────────────────────────────────────────────────────
	if event is InputEventScreenTouch or event is InputEventMouseButton:
		var pressed: bool = false
		var pos: Vector2 = Vector2.ZERO
		var is_right: bool = false
		if event is InputEventScreenTouch:
			var e: InputEventScreenTouch = event as InputEventScreenTouch
			pressed = e.pressed
			pos = e.position
		else:
			var e: InputEventMouseButton = event as InputEventMouseButton
			pressed = e.pressed
			pos = e.position
			is_right = (e.button_index == MOUSE_BUTTON_RIGHT)
		if pressed:
			_handle_press(pos, is_right)
		else:
			_handle_release(pos)


func _handle_press(pos: Vector2, is_right: bool) -> void:
	_press_pos = pos
	_moved_enough = false
	_pan_active = false
	_obs_dragging = false
	_placing = false
	_obs_drag_index = -1
	_press_on_ruler = pos.y < RULER_H

	# The ruler is the dedicated pan strip — never hit-tests obstacles.
	if _press_on_ruler:
		_press_obs_index = -1
		return

	var beat_map: Array = []
	if session != null:
		beat_map = (session.get_data().get("beat_map", []) as Array)

	_press_obs_index = _hit_test(pos, beat_map)


func _handle_motion(pos: Vector2, rel: Vector2) -> void:
	if _obs_dragging:
		# Update obstacle ghost position.
		_obs_drag_beat = _snap_beat(pan_beat + pos.x / px_per_beat)
		_obs_drag_lane = clampf((pos.y - RULER_H) / (size.y - RULER_H), 0.0, 1.0)
		_obs_drag_over_trash = (pos.y > size.y - TRASH_ZONE_H)
		queue_redraw()
		return

	if _placing:
		# Live-preview the new obstacle; placement never pans.
		_place_beat = _snap_beat(pan_beat + pos.x / px_per_beat)
		_place_lane = clampf((pos.y - RULER_H) / (size.y - RULER_H), 0.0, 1.0)
		queue_redraw()
		return

	if _pan_active:
		# Accumulate pan correctly using per-frame delta.
		pan_beat = maxf(0.0, pan_beat - rel.x / px_per_beat)
		queue_redraw()
		return

	# Not yet committed to a mode — check if we've moved enough to disambiguate.
	if not _moved_enough and _press_pos.distance_to(pos) >= DRAG_THRESHOLD:
		_moved_enough = true
		if _press_on_ruler:
			# Ruler drag → pan.
			_pan_active = true
			pan_beat = maxf(0.0, pan_beat - rel.x / px_per_beat)
			queue_redraw()
		elif _press_obs_index >= 0:
			# Start obstacle drag.
			_obs_dragging = true
			_obs_drag_index = _press_obs_index
			var beat_map: Array = []
			if session != null:
				beat_map = (session.get_data().get("beat_map", []) as Array)
			if _press_obs_index < beat_map.size():
				var entry: Dictionary = beat_map[_press_obs_index] as Dictionary
				_obs_drag_beat = float(entry.get("beat_index", 0))
				_obs_drag_lane = float(entry.get("lane_position", 0.5))
			selected_index = _press_obs_index
			obstacle_selected.emit(_press_obs_index)
			queue_redraw()
		elif not active_type.is_empty():
			# Place mode: drag out a live placement preview (does NOT pan).
			_placing = true
			_place_beat = _snap_beat(pan_beat + pos.x / px_per_beat)
			_place_lane = clampf((pos.y - RULER_H) / (size.y - RULER_H), 0.0, 1.0)
			queue_redraw()
		else:
			# No obstacle chosen → body drag pans.
			_pan_active = true
			pan_beat = maxf(0.0, pan_beat - rel.x / px_per_beat)
			queue_redraw()


func _handle_release(pos: Vector2) -> void:
	if _placing:
		obstacle_placed.emit(_place_beat, _place_lane)
		selected_index = -1
		obstacle_deselected.emit()
		_placing = false
		queue_redraw()
		return

	if _obs_dragging:
		if _obs_drag_over_trash:
			delete_requested.emit(_obs_drag_index)
			selected_index = -1
			obstacle_deselected.emit()
		else:
			var new_beat: float = _snap_beat(pan_beat + pos.x / px_per_beat)
			var new_lane: float = clampf((pos.y - RULER_H) / (size.y - RULER_H), 0.0, 1.0)
			obstacle_moved.emit(_obs_drag_index, new_beat, new_lane)
		_obs_dragging = false
		_obs_drag_index = -1
		_obs_drag_over_trash = false
		queue_redraw()
		return

	_pan_active = false

	if not _moved_enough:
		# This was a tap — process as tap action.
		if pos.y < RULER_H:
			return
		var beat_map: Array = []
		if session != null:
			beat_map = (session.get_data().get("beat_map", []) as Array)

		if _press_obs_index >= 0:
			selected_index = _press_obs_index
			obstacle_selected.emit(_press_obs_index)
			queue_redraw()
		elif not active_type.is_empty():
			var beat_idx: float = _snap_beat(pan_beat + pos.x / px_per_beat)
			var lane_y: float = clampf((pos.y - RULER_H) / (size.y - RULER_H), 0.0, 1.0)
			obstacle_placed.emit(beat_idx, lane_y)
			selected_index = -1
			obstacle_deselected.emit()
			queue_redraw()
		else:
			selected_index = -1
			obstacle_deselected.emit()
			queue_redraw()


func _hit_test(pos: Vector2, beat_map: Array) -> int:
	var rh: float = 48.0
	for i: int in range(beat_map.size()):
		var entry: Dictionary = beat_map[i] as Dictionary
		var beat_idx: float = float(entry.get("beat_index", 0))
		var lane_y: float = float(entry.get("lane_position", 0.5))
		var ox: float = (beat_idx - pan_beat) * px_per_beat
		var oy: float = RULER_H + lane_y * (size.y - RULER_H)
		var rw: float = maxf(48.0, px_per_beat * 0.55)
		var rect: Rect2 = Rect2(ox - rw * 0.5, oy - rh * 0.5, rw, rh)
		if rect.has_point(pos):
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
