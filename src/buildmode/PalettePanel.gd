## PalettePanel.gd
## Scrollable grid of obstacle cards (150×150 each, 2-column layout).
## Each card shows a thumbnail image (from res://assets/ui/palette/<type>.png
## if it exists, otherwise a solid-colour placeholder) above the obstacle name.
## Drop a PNG into that folder and it appears automatically on next launch.
## Emits obstacle_type_selected when the player picks an obstacle type.
extends ScrollContainer

class_name PalettePanel

signal obstacle_type_selected(obstacle_type: String)

var highest_cleared_zone: int = 1
var selected_type: String = ""

var _buttons: Array[Button] = []
var _available_types: Array[String] = []

const CARD_SIZE: Vector2 = Vector2(150.0, 150.0)
const LABEL_FONT_SIZE: int = 20
const THUMBNAIL_DIR: String = "res://assets/ui/palette/"

const TYPE_COLORS: Dictionary = {
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
}
const TYPE_COLOR_DEFAULT: Color = Color(0.25, 0.55, 0.70)

## Per-session thumbnail cache — avoids regenerating Image objects for the same type.
static var _thumbnail_cache: Dictionary = {}

@onready var _grid: GridContainer = $VBox/Grid
@onready var _section_label: Label = $VBox/SectionLabel


func _ready() -> void:
	# Horizontal bottom-strip palette: scroll sideways, never vertically.
	horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	refresh_palette(highest_cleared_zone)


func refresh_palette(max_zone: int) -> void:
	highest_cleared_zone = max_zone
	for b: Button in _buttons:
		b.queue_free()
	_buttons.clear()
	_available_types.clear()

	# Build Mode is a creator tool — show the full obstacle roster always.
	_available_types = ObstacleParamSchema.all_types()

	# Single horizontal row — all cards on one line, scrolled sideways.
	_grid.columns = maxi(1, _available_types.size())

	for otype: String in _available_types:
		var btn: Button = _make_card(otype)
		_grid.add_child(btn)
		_buttons.append(btn)


func _make_card(otype: String) -> Button:
	var btn: Button = Button.new()
	btn.custom_minimum_size = CARD_SIZE
	btn.clip_contents = true
	btn.text = ""  # visuals live in child nodes, not Button text

	var base_col: Color = TYPE_COLORS.get(otype, TYPE_COLOR_DEFAULT) as Color
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = base_col.darkened(0.30)
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

	# Inner layout: thumbnail image on top, name label on bottom.
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 0)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(vbox)

	# Thumbnail — fills the upper portion of the card.
	var tex_rect: TextureRect = TextureRect.new()
	tex_rect.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tex_rect.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tex_rect.texture = _load_thumbnail(otype)
	tex_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(tex_rect)

	# Name label — sits in the bottom strip.
	var lbl: Label = Label.new()
	lbl.text = ObstacleParamSchema.display_name(otype)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", LABEL_FONT_SIZE)
	lbl.add_theme_color_override("font_color", Color.WHITE)
	lbl.custom_minimum_size = Vector2(0, 40)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(lbl)

	btn.pressed.connect(_on_btn_pressed.bind(otype))
	return btn


## Try loading res://assets/ui/palette/<type>.png; fall back to a solid-colour swatch.
static func _load_thumbnail(otype: String) -> Texture2D:
	if _thumbnail_cache.has(otype):
		return _thumbnail_cache[otype] as Texture2D
	var path: String = THUMBNAIL_DIR + otype + ".png"
	var tex: Texture2D
	if ResourceLoader.exists(path):
		tex = load(path) as Texture2D
	else:
		tex = _generate_placeholder(otype)
	_thumbnail_cache[otype] = tex
	return tex


## Generates a solid-colour placeholder from the obstacle's type colour.
## Replace it at any time by dropping a PNG into res://assets/ui/palette/.
static func _generate_placeholder(otype: String) -> ImageTexture:
	var base: Color = TYPE_COLORS.get(otype, TYPE_COLOR_DEFAULT) as Color
	var img: Image = Image.create(100, 80, false, Image.FORMAT_RGBA8)
	img.fill(base.lightened(0.15))
	return ImageTexture.create_from_image(img)


func _on_btn_pressed(otype: String) -> void:
	# Tapping the already-selected card toggles OFF (exits place mode).
	if otype == selected_type:
		selected_type = ""
		_reset_card_styles()
		obstacle_type_selected.emit("")
		return
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
			s.bg_color = base.darkened(0.30)
	obstacle_type_selected.emit(otype)


## Reset every card to its unselected style (used when deselecting).
func _reset_card_styles() -> void:
	for i: int in range(_buttons.size()):
		var base: Color = TYPE_COLORS.get(_available_types[i], TYPE_COLOR_DEFAULT) as Color
		var s: StyleBoxFlat = _buttons[i].get_theme_stylebox("normal") as StyleBoxFlat
		s.border_color = base
		s.border_width_left = 3
		s.border_width_right = 3
		s.border_width_top = 3
		s.border_width_bottom = 3
		s.bg_color = base.darkened(0.30)
