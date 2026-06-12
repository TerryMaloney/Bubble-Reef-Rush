## PropertiesPanel.gd
## Schema-driven panel that shows editable parameters for the currently
## selected beat_map entry.  Driven by ObstacleParamSchema.
##
## Design goals: large touch targets, simple labels, sliders for numeric params.
extends Panel

class_name PropertiesPanel

signal property_changed(beat_map_index: int, key: String, value: Variant)

var _current_index: int = -1
var _current_entry: Dictionary = {}
var _widgets: Array[Control] = []

@onready var _title_label: Label = $TitleLabel
@onready var _container: VBoxContainer = $ScrollContainer/VBoxContainer

const ROW_HEIGHT: int = 80
const LABEL_FONT_SIZE: int = 26
const VALUE_FONT_SIZE: int = 22
const LABEL_MIN_WIDTH: int = 160


func _ready() -> void:
	clear()


## Show properties for the beat_map entry at the given index.
func show_entry(index: int, entry: Dictionary) -> void:
	_current_index = index
	_current_entry = entry.duplicate(true)
	_rebuild_widgets()


## Clear the panel (nothing selected).
func clear() -> void:
	_current_index = -1
	_current_entry = {}
	if _title_label != null:
		_title_label.text = "Tap an obstacle\nto change it"
	_clear_widgets()


func _clear_widgets() -> void:
	if _container == null:
		return
	for w: Control in _widgets:
		w.queue_free()
	_widgets.clear()


func _rebuild_widgets() -> void:
	_clear_widgets()
	if _container == null:
		return

	var otype: String = str(_current_entry.get("obstacle_type", ""))
	if _title_label != null:
		_title_label.text = ObstacleParamSchema.display_name(otype)

	var param_defs: Array[Dictionary] = ObstacleParamSchema.params_for(otype)
	var params: Dictionary = _current_entry.get("parameters", {}) as Dictionary

	for pdef: Dictionary in param_defs:
		var key: String = str(pdef.get("key", ""))
		var label_text: String = str(pdef.get("label", key))
		var ptype: String = str(pdef.get("type", "float"))
		var default_val: Variant = pdef.get("default")
		var current_val: Variant = params.get(key, default_val)

		var row: HBoxContainer = HBoxContainer.new()
		row.custom_minimum_size = Vector2(0, ROW_HEIGHT)
		_container.add_child(row)
		_widgets.append(row)

		var lbl: Label = Label.new()
		lbl.text = label_text
		lbl.custom_minimum_size = Vector2(LABEL_MIN_WIDTH, 0)
		lbl.add_theme_font_size_override("font_size", LABEL_FONT_SIZE)
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		row.add_child(lbl)

		match ptype:
			"enum":
				var opt: OptionButton = OptionButton.new()
				opt.custom_minimum_size = Vector2(0, ROW_HEIGHT - 8)
				opt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				opt.add_theme_font_size_override("font_size", LABEL_FONT_SIZE)
				var options: Array = pdef.get("options", []) as Array
				for o: Variant in options:
					opt.add_item(str(o))
				var sel_idx: int = options.find(current_val)
				if sel_idx >= 0:
					opt.select(sel_idx)
				opt.item_selected.connect(func(idx: int) -> void:
					var new_val: Variant = options[idx]
					_emit_change(key, new_val)
				)
				row.add_child(opt)
				_widgets.append(opt)

			"bool":
				var chk: CheckBox = CheckBox.new()
				chk.custom_minimum_size = Vector2(ROW_HEIGHT, ROW_HEIGHT - 8)
				chk.add_theme_font_size_override("font_size", LABEL_FONT_SIZE)
				chk.button_pressed = bool(current_val)
				chk.toggled.connect(func(on: bool) -> void:
					_emit_change(key, on)
				)
				row.add_child(chk)
				_widgets.append(chk)

			"int":
				var slider: HSlider = _make_slider(
					float(pdef.get("min", 0)), float(pdef.get("max", 100)),
					1.0, float(current_val))
				var val_lbl: Label = _make_val_label(str(int(current_val)))
				slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				slider.value_changed.connect(func(v: float) -> void:
					val_lbl.text = str(int(v))
					_emit_change(key, int(v))
				)
				row.add_child(slider)
				row.add_child(val_lbl)
				_widgets.append(slider)
				_widgets.append(val_lbl)

			_: # float
				var slider: HSlider = _make_slider(
					float(pdef.get("min", 0.0)), float(pdef.get("max", 1.0)),
					0.01, float(current_val))
				var val_lbl: Label = _make_val_label("%.2f" % current_val)
				slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				slider.value_changed.connect(func(v: float) -> void:
					val_lbl.text = "%.2f" % v
					_emit_change(key, v)
				)
				row.add_child(slider)
				row.add_child(val_lbl)
				_widgets.append(slider)
				_widgets.append(val_lbl)


func _make_slider(min_v: float, max_v: float, step: float, value: float) -> HSlider:
	var s: HSlider = HSlider.new()
	s.min_value = min_v
	s.max_value = max_v
	s.step = step
	s.value = value
	s.custom_minimum_size = Vector2(0, 56)
	return s


func _make_val_label(text: String) -> Label:
	var l: Label = Label.new()
	l.text = text
	l.custom_minimum_size = Vector2(72, 0)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", VALUE_FONT_SIZE)
	return l


func _emit_change(key: String, value: Variant) -> void:
	property_changed.emit(_current_index, key, value)
