## PalettePanel.gd
## Scrollable grid of colored obstacle cards (130×130 each, 2-column layout).
## Emits obstacle_type_selected when the player picks an obstacle type.
extends ScrollContainer

class_name PalettePanel

signal obstacle_type_selected(obstacle_type: String)

var highest_cleared_zone: int = 1
var selected_type: String = ""

var _buttons: Array[Button] = []
var _available_types: Array[String] = []

const CARD_SIZE: Vector2 = Vector2(130.0, 130.0)
const CARD_FONT_SIZE: int = 20

const TYPE_COLORS: Dictionary = {
	"pressure_wall":   Color(0.18, 0.52, 0.88),
	"jellyfish_drift": Color(0.72, 0.25, 0.82),
	"boss_projectile": Color(0.88, 0.25, 0.18),
	"speed_ring":      Color(0.18, 0.80, 0.45),
	"gravity_flip":    Color(0.82, 0.65, 0.10),
	"secret_exit":     Color(0.75, 0.70, 0.12),
}
const TYPE_COLOR_DEFAULT: Color = Color(0.25, 0.55, 0.70)

@onready var _grid: GridContainer = $VBox/Grid
@onready var _section_label: Label = $VBox/SectionLabel


func _ready() -> void:
	refresh_palette(highest_cleared_zone)


func refresh_palette(max_zone: int) -> void:
	highest_cleared_zone = max_zone
	for b: Button in _buttons:
		b.queue_free()
	_buttons.clear()
	_available_types.clear()

	var profile_id: String = SaveSystem.get_active_profile_id()
	var all_types: Array[String] = ObstacleParamSchema.types_for_zone(max_zone)

	for otype: String in all_types:
		if SaveSystem.has_build_unlock(profile_id, "obstacles", otype):
			_available_types.append(otype)

	for otype: String in _available_types:
		var btn: Button = _make_card(otype)
		_grid.add_child(btn)
		_buttons.append(btn)


func _make_card(otype: String) -> Button:
	var btn: Button = Button.new()
	btn.custom_minimum_size = CARD_SIZE
	btn.clip_contents = true

	# Background color from type map.
	var base_col: Color = TYPE_COLORS.get(otype, TYPE_COLOR_DEFAULT) as Color
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = base_col.darkened(0.25)
	style.border_width_left = 3
	style.border_width_right = 3
	style.border_width_top = 3
	style.border_width_bottom = 3
	style.border_color = base_col
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	btn.add_theme_stylebox_override("normal", style)

	var hover_style: StyleBoxFlat = style.duplicate() as StyleBoxFlat
	hover_style.bg_color = base_col.darkened(0.05)
	hover_style.border_color = Color.WHITE
	btn.add_theme_stylebox_override("hover", hover_style)

	var label: String = _label(otype)
	btn.text = label
	btn.add_theme_font_size_override("font_size", CARD_FONT_SIZE)
	btn.add_theme_color_override("font_color", Color.WHITE)
	btn.add_theme_color_override("font_hover_color", Color.WHITE)
	btn.pressed.connect(_on_btn_pressed.bind(otype))
	return btn


func _on_btn_pressed(otype: String) -> void:
	selected_type = otype
	for i: int in range(_buttons.size()):
		var t: String = _available_types[i]
		var base: Color = TYPE_COLORS.get(t, TYPE_COLOR_DEFAULT) as Color
		var s: StyleBoxFlat = _buttons[i].get_theme_stylebox("normal") as StyleBoxFlat
		if t == otype:
			s.border_color = Color.WHITE
			s.border_width_left = 5
			s.border_width_right = 5
			s.border_width_top = 5
			s.border_width_bottom = 5
			s.bg_color = base.lightened(0.1)
		else:
			s.border_color = base
			s.border_width_left = 3
			s.border_width_right = 3
			s.border_width_top = 3
			s.border_width_bottom = 3
			s.bg_color = base.darkened(0.25)
	obstacle_type_selected.emit(otype)


static func _label(otype: String) -> String:
	return otype.replace("_", "\n").capitalize()
