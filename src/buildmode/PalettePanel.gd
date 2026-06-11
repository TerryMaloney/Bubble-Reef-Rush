## PalettePanel.gd
## Scrollable list of obstacle buttons filtered by player's cleared zone.
## Emits obstacle_selected when the user taps an obstacle type.
extends Panel

class_name PalettePanel

signal obstacle_type_selected(obstacle_type: String)

## Highest zone the current profile has cleared (set by BuildModeRoot on load).
var highest_cleared_zone: int = 1

## Currently selected type (highlighted).
var selected_type: String = ""

var _buttons: Array[Button] = []
var _available_types: Array[String] = []


func _ready() -> void:
	refresh_palette(highest_cleared_zone)


## Rebuild palette buttons for the given cleared-zone level.
## Only shows obstacle types that the active profile has unlocked in Build Mode.
func refresh_palette(max_zone: int) -> void:
	highest_cleared_zone = max_zone
	for b: Button in _buttons:
		b.queue_free()
	_buttons.clear()
	_available_types.clear()

	var all_types: Array[String] = ObstacleParamSchema.types_for_zone(max_zone)
	var profile_id: String = SaveSystem.get_active_profile_id()
	for otype: String in all_types:
		if SaveSystem.has_build_unlock(profile_id, "obstacles", otype):
			_available_types.append(otype)

	var y: float = 10.0
	for otype: String in _available_types:
		var btn: Button = Button.new()
		btn.text = _label(otype)
		btn.custom_minimum_size = Vector2(220.0, 60.0)
		btn.position = Vector2(10.0, y)
		btn.pressed.connect(_on_btn_pressed.bind(otype))
		btn.add_theme_font_size_override("font_size", 20)
		if otype == selected_type:
			btn.modulate = Color(1.0, 0.85, 0.2)
		add_child(btn)
		_buttons.append(btn)
		y += 70.0

	custom_minimum_size = Vector2(240.0, y + 10.0)


func _on_btn_pressed(otype: String) -> void:
	selected_type = otype
	for btn: Button in _buttons:
		btn.modulate = Color(1, 1, 1)
	var idx: int = _available_types.find(otype)
	if idx >= 0 and idx < _buttons.size():
		_buttons[idx].modulate = Color(1.0, 0.85, 0.2)
	obstacle_type_selected.emit(otype)


static func _label(otype: String) -> String:
	return otype.replace("_", " ").capitalize()
