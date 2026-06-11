## PropertiesPanel.gd
## Schema-driven panel that shows editable parameters for the currently
## selected beat_map entry.  Driven by ObstacleParamSchema.
extends Panel

class_name PropertiesPanel

signal property_changed(beat_map_index: int, key: String, value: Variant)

var _current_index: int = -1
var _current_entry: Dictionary = {}
var _widgets: Array[Control] = []

@onready var _title_label: Label = $TitleLabel
@onready var _container: VBoxContainer = $ScrollContainer/VBoxContainer


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
		_title_label.text = "Select an obstacle"
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
		_title_label.text = otype.replace("_", " ").capitalize()

	var param_defs: Array[Dictionary] = ObstacleParamSchema.params_for(otype)
	var params: Dictionary = _current_entry.get("parameters", {}) as Dictionary

	for pdef: Dictionary in param_defs:
		var key: String = str(pdef.get("key", ""))
		var label_text: String = str(pdef.get("label", key))
		var ptype: String = str(pdef.get("type", "float"))
		var default_val: Variant = pdef.get("default")
		var current_val: Variant = params.get(key, default_val)

		var row: HBoxContainer = HBoxContainer.new()
		row.custom_minimum_size = Vector2(0, 50)
		_container.add_child(row)
		_widgets.append(row)

		var lbl: Label = Label.new()
		lbl.text = label_text
		lbl.custom_minimum_size = Vector2(130, 0)
		lbl.add_theme_font_size_override("font_size", 18)
		row.add_child(lbl)

		match ptype:
			"enum":
				var opt: OptionButton = OptionButton.new()
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
				chk.button_pressed = bool(current_val)
				chk.toggled.connect(func(on: bool) -> void:
					_emit_change(key, on)
				)
				row.add_child(chk)
				_widgets.append(chk)

			"int":
				var spin: SpinBox = SpinBox.new()
				spin.min_value = float(pdef.get("min", 0))
				spin.max_value = float(pdef.get("max", 100))
				spin.step = 1.0
				spin.value = float(current_val)
				spin.value_changed.connect(func(v: float) -> void:
					_emit_change(key, int(v))
				)
				row.add_child(spin)
				_widgets.append(spin)

			_: # float
				var spin: SpinBox = SpinBox.new()
				spin.min_value = float(pdef.get("min", 0.0))
				spin.max_value = float(pdef.get("max", 1.0))
				spin.step = 0.01
				spin.value = float(current_val)
				spin.value_changed.connect(func(v: float) -> void:
					_emit_change(key, v)
				)
				row.add_child(spin)
				_widgets.append(spin)


func _emit_change(key: String, value: Variant) -> void:
	property_changed.emit(_current_index, key, value)
