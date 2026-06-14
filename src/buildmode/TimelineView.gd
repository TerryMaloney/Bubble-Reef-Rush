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
const DRAG_THRESHOLD: float = 14.0  # pixels of movement before drag activates

# Trash target: a compact pill in the top-right corner, shown only while
# dragging an obstacle — keeps the whole editing area clear (no bottom strip).
const TRASH_W: float = 220.0
const TRASH_H: float = 56.0
const TRASH_MARGIN: float = 12.0

# Gate geometry — mirrors ObstacleSpawner.gd so the editor is WYSIWYG.
const GAP_MAX_PX: float = 280.0
const GAP_MIN_PX: float = 200.0

# Real in-game body sizes (canvas px) for point hazards, so chips match play.
const HAZARD_RADIUS: Dictionary = {
	"jellyfish_drift": 40.0,
	"bubble_mine": 56.0,
	"crystal_shard": 40.0,
}

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

# True only between a press and its release — gates motion so a bare mouse
# move (no button held) never pans the timeline ("grab to slide").
var _pressed: bool = false

# Reachability autoshadow — set by BuildModeRoot on every edit.
var _band_trace: Array[Dictionary] = []

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
	"coral_spike":     Color(0.85, 0.30, 0.20),
	"jellyfish_drift": Color(0.72, 0.25, 0.82),
	"kelp_curtain":    Color(0.20, 0.65, 0.35),
	"bubble_mine":     Color(0.88, 0.60, 0.10),
	"current_jet":     Color(0.18, 0.62, 0.88),
	"anchor_chain":    Color(0.50, 0.42, 0.28),
	"eel_snap":        Color(0.30, 0.75, 0.55),
	"lava_burst":      Color(0.95, 0.35, 0.05),
	"pressure_wall":   Color(0.18, 0.52, 0.88),
	"dark_void":       Color(0.30, 0.15, 0.55),
	"crystal_shard":   Color(0.40, 0.80, 0.95),
	"mirror_fish":     Color(0.60, 0.60, 0.75),
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

	# ── Reachability autoshadow ────────────────────────────────────────────────
	if not _band_trace.is_empty():
		var vs: float = _vscale()
		for i: int in range(_band_trace.size()):
			var te: Dictionary = _band_trace[i] as Dictionary
			var beat: float = float(te.get("beat", 0))
			var next_beat: float = beat + 2.0
			if i + 1 < _band_trace.size():
				next_beat = float((_band_trace[i + 1] as Dictionary).get("beat", beat + 2.0))
			var lo: float = float(te.get("lo", 60.0))
			var hi: float = float(te.get("hi", 1860.0))
			var x1: float = (beat - pan_beat) * px_per_beat - px_per_beat * 0.5
			var x2: float = (next_beat - pan_beat) * px_per_beat - px_per_beat * 0.5
			var rx: float = maxf(0.0, x1)
			var rx2: float = minf(size.x, x2)
			if rx2 <= rx:
				continue
			draw_rect(Rect2(rx, RULER_H + lo * vs, rx2 - rx, (hi - lo) * vs),
					Color(0.2, 1.0, 0.3, 0.18))

	# ── Obstacles (drawn at their true in-game footprint) ──────────────────────
	if session != null:
		var beat_map: Array = (session.get_data().get("beat_map", []) as Array)
		for i: int in range(beat_map.size()):
			if _obs_dragging and i == _obs_drag_index:
				continue  # drawn separately below at drag position
			var entry: Dictionary = beat_map[i] as Dictionary
			_draw_obstacle_entry(
					float(entry.get("beat_index", 0)),
					float(entry.get("lane_position", 0.5)),
					str(entry.get("obstacle_type", "?")),
					entry.get("parameters", {}) as Dictionary,
					i == selected_index, false)

	# ── Dragged obstacle ghost ─────────────────────────────────────────────────
	if _obs_dragging and session != null:
		var beat_map: Array = (session.get_data().get("beat_map", []) as Array)
		if _obs_drag_index < beat_map.size():
			var drag_entry: Dictionary = beat_map[_obs_drag_index] as Dictionary
			_draw_obstacle_entry(_obs_drag_beat, _obs_drag_lane,
					str(drag_entry.get("obstacle_type", "?")),
					drag_entry.get("parameters", {}) as Dictionary,
					true, _obs_drag_over_trash)

	# ── Placement preview (dragging out a new obstacle in place mode) ──────────
	if _placing and not active_type.is_empty():
		_draw_obstacle_entry(_place_beat, _place_lane, active_type,
				_default_params(active_type), true, false)

	# ── Place-mode hint banner ─────────────────────────────────────────────────
	if not active_type.is_empty() and not _placing and not _obs_dragging:
		var hint: String = "Placing: %s  —  tap or drag to drop" % ObstacleParamSchema.display_name(active_type)
		var hint_w: float = 540.0
		draw_rect(Rect2(8.0, RULER_H + 8.0, hint_w, 36.0), Color(0.1, 0.5, 0.2, 0.85))
		draw_string(font, Vector2(18.0, RULER_H + 33.0), hint,
				HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color.WHITE)

	# ── Trash pill (top-right corner, only while dragging an obstacle) ─────────
	if _obs_dragging:
		var tr: Rect2 = _trash_rect()
		var trash_col: Color = COL_TRASH_HOT if _obs_drag_over_trash else COL_TRASH_IDLE
		draw_rect(tr, trash_col)
		draw_string(font, Vector2(tr.position.x + 14.0, tr.position.y + 37.0),
				"🗑  Drop to delete", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color.WHITE)

	# ── Playhead ───────────────────────────────────────────────────────────────
	var ph_x: float = (playhead_beat - pan_beat) * px_per_beat
	if ph_x >= 0.0 and ph_x <= size.x:
		draw_line(Vector2(ph_x, 0.0), Vector2(ph_x, size.y), COL_PLAYHEAD, 2.5)
		draw_string(font, Vector2(ph_x + 3.0, RULER_H - 12.0), "▶",
				HORIZONTAL_ALIGNMENT_LEFT, -1, 16, COL_PLAYHEAD)

	# ── Ruler divider line ─────────────────────────────────────────────────────
	draw_line(Vector2(0.0, RULER_H), Vector2(size.x, RULER_H),
			Color(0.5, 0.5, 0.7, 0.6), 1.0)


## Canvas-Y (0..1920) → screen-Y scale for the play area below the ruler.
func _vscale() -> float:
	return (size.y - RULER_H) / CANVAS_H


func _trash_rect() -> Rect2:
	return Rect2(size.x - TRASH_W - TRASH_MARGIN, RULER_H + TRASH_MARGIN, TRASH_W, TRASH_H)


## Default parameters for a freshly-placed obstacle (for the placement preview).
func _default_params(otype: String) -> Dictionary:
	var result: Dictionary = {}
	for pdef: Dictionary in ObstacleParamSchema.params_for(otype):
		result[str(pdef.get("key", ""))] = pdef.get("default")
	return result


## Draw an obstacle at its real in-game footprint: walls span the full height
## with the true gap, spikes are triangles of their height, point hazards are
## circles of their real radius. This makes the editor WYSIWYG.
func _draw_obstacle_entry(beat_idx: float, lane_y_norm: float, otype: String,
		params: Dictionary, is_sel: bool, is_trashing: bool) -> void:
	var x: float = (beat_idx - pan_beat) * px_per_beat
	if x < -160.0 or x > size.x + 160.0:
		return

	var col: Color = OBSTACLE_COLORS.get(otype, COL_OBSTACLE_DEFAULT) as Color
	if is_trashing:
		col = Color(1.0, 0.3, 0.3)
	elif is_sel:
		col = COL_SELECTED

	var w: float = maxf(40.0, px_per_beat * 0.45)
	var vs: float = _vscale()
	var label_y: float = RULER_H + lane_y_norm * (size.y - RULER_H)

	match otype:
		"pressure_wall", "kelp_curtain":
			label_y = _draw_gate(x, w, otype, params, col, vs)
		"coral_spike":
			label_y = _draw_spike(x, params, col, vs)
		"jellyfish_drift", "bubble_mine", "crystal_shard":
			var r: float = float(HAZARD_RADIUS.get(otype, 40.0)) * vs
			var range_px: float = 0.0
			if otype == "jellyfish_drift":
				range_px = float(params.get("oscillation_amplitude", 80.0)) * vs
			_draw_blob(x, lane_y_norm, r, col, range_px)
		_:
			_draw_generic(x, lane_y_norm, w, col)

	# Selection ring around the whole footprint for clarity.
	if is_sel:
		var rr: Rect2 = _obstacle_rect_local(beat_idx, lane_y_norm, otype, params)
		draw_rect(rr, COL_SELECTED, false, 2.0)

	# Short friendly label.
	var short: String = ObstacleParamSchema.display_name(otype)
	draw_string(ThemeDB.fallback_font, Vector2(x - w * 0.5 - 2.0, label_y),
			short, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.95, 0.97, 1.0))


## Draw a top+bottom wall with the real navigable gap. Returns a y for the label.
func _draw_gate(x: float, w: float, otype: String, params: Dictionary,
		col: Color, vs: float) -> float:
	var gap_px: float
	var center_norm: float = float(params.get("gap_y_normalized", 0.5))
	if otype == "pressure_wall":
		var intensity: float = float(params.get("intensity", 0.5))
		gap_px = lerpf(GAP_MAX_PX, GAP_MIN_PX, clampf(intensity, 0.0, 1.0))
	else:
		gap_px = float(params.get("gap_height", 240.0))
	var center: float = center_norm * CANVAS_H
	var gap_top: float = center - gap_px * 0.5
	var gap_bot: float = center + gap_px * 0.5
	var lx: float = x - w * 0.5

	if gap_top > 0.0:
		var top_h: float = gap_top * vs
		draw_rect(Rect2(lx, RULER_H, w, top_h), col.darkened(0.35))
		draw_rect(Rect2(lx + 2.0, RULER_H, w - 4.0, maxf(0.0, top_h - 2.0)), col)
	if gap_bot < CANVAS_H:
		var bot_y: float = RULER_H + gap_bot * vs
		draw_rect(Rect2(lx, bot_y, w, size.y - bot_y), col.darkened(0.35))
		draw_rect(Rect2(lx + 2.0, bot_y + 2.0, w - 4.0, size.y - bot_y - 2.0), col)
	return RULER_H + center * vs


## Draw a spike triangle of its configured height from the chosen wall.
func _draw_spike(x: float, params: Dictionary, col: Color, vs: float) -> float:
	var h: float = float(params.get("height", 120)) * vs
	var attach: String = str(params.get("wall_attachment", "bottom"))
	var bw: float = maxf(56.0, 60.0 * vs)
	var pts: PackedVector2Array = PackedVector2Array()
	var label_y: float
	if attach == "top":
		pts.append(Vector2(x - bw * 0.5, RULER_H))
		pts.append(Vector2(x + bw * 0.5, RULER_H))
		pts.append(Vector2(x, RULER_H + h))
		label_y = RULER_H + h + 14.0
	else:
		pts.append(Vector2(x - bw * 0.5, size.y))
		pts.append(Vector2(x + bw * 0.5, size.y))
		pts.append(Vector2(x, size.y - h))
		label_y = size.y - h - 6.0
	draw_colored_polygon(pts, col)
	return label_y


## Draw a point hazard as a circle of its real radius, with optional drift range.
func _draw_blob(x: float, lane_y_norm: float, r: float, col: Color, range_px: float) -> void:
	var cy: float = RULER_H + lane_y_norm * (size.y - RULER_H)
	r = maxf(r, 9.0)
	if range_px > 2.0:
		draw_rect(Rect2(x - 3.0, cy - range_px, 6.0, range_px * 2.0),
				Color(col.r, col.g, col.b, 0.22))
	draw_circle(Vector2(x, cy), r + 2.0, col.darkened(0.35))
	draw_circle(Vector2(x, cy), r, col)


## Fallback chip for hazards without a simple geometric footprint.
func _draw_generic(x: float, lane_y_norm: float, w: float, col: Color) -> void:
	var cy: float = RULER_H + lane_y_norm * (size.y - RULER_H)
	var rh: float = 52.0
	draw_rect(Rect2(x - w * 0.5, cy - rh * 0.5, w, rh), col.darkened(0.35))
	draw_rect(Rect2(x - w * 0.5 + 2.0, cy - rh * 0.5 + 2.0, w - 4.0, rh - 4.0), col)


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
	_pressed = true
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
	# Grab to slide: ignore bare mouse movement when nothing is held down.
	if not _pressed:
		return

	if _obs_dragging:
		# Update obstacle ghost position.
		_obs_drag_beat = _snap_beat(pan_beat + pos.x / px_per_beat)
		_obs_drag_lane = clampf((pos.y - RULER_H) / (size.y - RULER_H), 0.0, 1.0)
		_obs_drag_over_trash = _trash_rect().has_point(pos)
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
	_pressed = false
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
	# Iterate back-to-front so the visually top-most obstacle wins.
	for i: int in range(beat_map.size() - 1, -1, -1):
		var entry: Dictionary = beat_map[i] as Dictionary
		var rect: Rect2 = _obstacle_rect_local(
				float(entry.get("beat_index", 0)),
				float(entry.get("lane_position", 0.5)),
				str(entry.get("obstacle_type", "?")),
				entry.get("parameters", {}) as Dictionary)
		if rect.has_point(pos):
			return i
	return -1


## Selectable on-screen bounds for an obstacle, matching how it is drawn.
func _obstacle_rect_local(beat_idx: float, lane_y_norm: float, otype: String,
		params: Dictionary) -> Rect2:
	var x: float = (beat_idx - pan_beat) * px_per_beat
	var w: float = maxf(40.0, px_per_beat * 0.45)
	var vs: float = _vscale()
	match otype:
		"pressure_wall", "kelp_curtain":
			# Whole vertical column is tappable.
			return Rect2(x - w * 0.5, RULER_H, w, size.y - RULER_H)
		"coral_spike":
			var h: float = float(params.get("height", 120)) * vs
			var bw: float = maxf(56.0, 60.0 * vs)
			if str(params.get("wall_attachment", "bottom")) == "top":
				return Rect2(x - bw * 0.5, RULER_H, bw, h)
			return Rect2(x - bw * 0.5, size.y - h, bw, h)
		"jellyfish_drift", "bubble_mine", "crystal_shard":
			var r: float = maxf(12.0, float(HAZARD_RADIUS.get(otype, 40.0)) * vs)
			var cy: float = RULER_H + lane_y_norm * (size.y - RULER_H)
			return Rect2(x - r, cy - r, r * 2.0, r * 2.0)
		_:
			var cy2: float = RULER_H + lane_y_norm * (size.y - RULER_H)
			return Rect2(x - w * 0.5, cy2 - 28.0, w, 56.0)


func _snap_beat(raw_beat: float) -> float:
	return roundf(raw_beat / snap_beats) * snap_beats


func set_band_trace(trace: Array[Dictionary]) -> void:
	_band_trace = trace
	queue_redraw()


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
