## PhysicsTuner — in-game overlay for live physics tuning. Debug builds only.
## Spawned by LevelRoot when OS.is_debug_build(). Writes to GameManager.physics_overrides
## so PlayerController reads the values without needing a scene reload.
extends CanvasLayer


const PARAMS: Array = [
	{"key": "dive_impulse",    "label": "Tap impulse",   "min": 100.0, "max": 600.0, "default": 220.0},
	{"key": "float_force",     "label": "Rise force",    "min": 400.0, "max": 1600.0, "default": 1250.0},
	{"key": "max_float_speed", "label": "Max rise spd",  "min": 200.0, "max": 900.0, "default": 700.0},
	{"key": "dive_force",      "label": "Hold force",    "min": 400.0, "max": 2200.0, "default": 1940.0},
	{"key": "max_dive_speed",  "label": "Max dive spd",  "min": 200.0, "max": 1400.0, "default": 1100.0},
]

var _rows: Dictionary = {}
var _vel_label: Label


func _ready() -> void:
	layer = 20
	var panel := PanelContainer.new()
	panel.position = Vector2(12, 200)
	panel.custom_minimum_size = Vector2(340, 0)
	add_child(panel)

	var vbox := VBoxContainer.new()
	panel.add_child(vbox)

	var title := Label.new()
	title.text = "PHYSICS TUNER"
	title.add_theme_font_size_override("font_size", 20)
	vbox.add_child(title)

	for p: Dictionary in PARAMS:
		var row := HBoxContainer.new()
		var lbl := Label.new()
		lbl.text = str(p["label"])
		lbl.custom_minimum_size = Vector2(110, 0)
		lbl.add_theme_font_size_override("font_size", 18)
		row.add_child(lbl)

		var slider := HSlider.new()
		slider.min_value = float(p["min"])
		slider.max_value = float(p["max"])
		slider.value = float(p["default"])
		slider.step = 1.0
		slider.custom_minimum_size = Vector2(160, 36)
		slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(slider)

		var val_lbl := Label.new()
		val_lbl.text = str(int(slider.value))
		val_lbl.custom_minimum_size = Vector2(50, 0)
		val_lbl.add_theme_font_size_override("font_size", 18)
		row.add_child(val_lbl)

		var key: String = str(p["key"])
		_rows[key] = {"slider": slider, "label": val_lbl}
		GameManager.physics_overrides[key] = slider.value

		slider.value_changed.connect(func(v: float) -> void:
			GameManager.physics_overrides[key] = v
			val_lbl.text = str(int(v))
		)
		vbox.add_child(row)

	_vel_label = Label.new()
	_vel_label.add_theme_font_size_override("font_size", 18)
	_vel_label.text = "vel.y: 0"
	vbox.add_child(_vel_label)


func _process(_delta: float) -> void:
	var player: Node = get_tree().get_first_node_in_group("player")
	if player != null and player.has_method("get") and "velocity" in player:
		_vel_label.text = "vel.y: %d" % int((player as CharacterBody2D).velocity.y)
