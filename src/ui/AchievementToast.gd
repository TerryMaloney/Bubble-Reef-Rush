## AchievementToast — autoload CanvasLayer that shows queued achievement notifications.
## Toast messages are kid-safe: 2.5s display, fade out, max 3 queued.
extends CanvasLayer

const DISPLAY_DURATION: float = 2.5
const FADE_DURATION: float = 0.4

var _queue: Array[Dictionary] = []
var _showing: bool = false

var _panel: Panel = null
var _name_label: Label = null
var _desc_label: Label = null


func _ready() -> void:
	layer = 128  # above everything
	_build_ui()


func _build_ui() -> void:
	_panel = Panel.new()
	_panel.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_panel.offset_top = 40.0
	_panel.offset_bottom = 140.0
	_panel.offset_left = 40.0
	_panel.offset_right = -40.0
	_panel.modulate.a = 0.0
	# This overlay sits on layer 128 above every screen and is a purely passive
	# notification — it must NEVER intercept input, or its (invisible) panel eats
	# every tap in the top ~140px, breaking back/save/top-bar buttons everywhere.
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_panel)

	_name_label = Label.new()
	_name_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_name_label.offset_top = 8.0
	_name_label.offset_bottom = 56.0
	_name_label.offset_left = 16.0
	_name_label.offset_right = -16.0
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(_name_label)

	_desc_label = Label.new()
	_desc_label.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_desc_label.offset_top = -56.0
	_desc_label.offset_bottom = -8.0
	_desc_label.offset_left = 16.0
	_desc_label.offset_right = -16.0
	_desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_desc_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(_desc_label)


## Queue an achievement toast. Silently drops if queue is already at max.
func show_achievement(name: String, desc: String) -> void:
	if _queue.size() >= 3:
		return
	_queue.append({"name": name, "desc": desc})
	if not _showing:
		_show_next()


func _show_next() -> void:
	if _queue.is_empty():
		_showing = false
		return
	_showing = true
	var item: Dictionary = _queue.pop_front() as Dictionary
	_name_label.text = str(item.get("name", ""))
	_desc_label.text = str(item.get("desc", ""))
	var tw: Tween = create_tween()
	tw.tween_property(_panel, "modulate:a", 1.0, FADE_DURATION)
	tw.tween_interval(DISPLAY_DURATION)
	tw.tween_property(_panel, "modulate:a", 0.0, FADE_DURATION)
	tw.tween_callback(_show_next)
