## MyLevelsScreen — lists player-created levels for play or editing.
## Built entirely in GDScript so no .tscn is needed.
extends Control

class_name MyLevelsScreen

const BTN_H: int = 96
const ZONE_NAMES: Array[String] = ["", "World 1", "World 2", "World 3", "World 4", "World 5", "World 6"]


func _ready() -> void:
	_build_ui()


func _build_ui() -> void:
	# Full-screen dim background.
	var bg: ColorRect = ColorRect.new()
	bg.color = Color(0.0, 0.0, 0.0, 0.75)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# Centered panel.
	var panel: PanelContainer = PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(640, 720)
	add_child(panel)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	panel.add_child(vbox)

	# Title.
	var title: Label = Label.new()
	title.text = "My Levels"
	title.add_theme_font_size_override("font_size", 40)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	# "Make a New Level!" button.
	var new_btn: Button = Button.new()
	new_btn.text = "Make a New Level!"
	new_btn.custom_minimum_size = Vector2(0, BTN_H)
	new_btn.add_theme_font_size_override("font_size", 30)
	new_btn.pressed.connect(_on_new_level)
	vbox.add_child(new_btn)

	var sep: HSeparator = HSeparator.new()
	vbox.add_child(sep)

	# Scrollable level list.
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 480)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)

	var list: VBoxContainer = VBoxContainer.new()
	list.add_theme_constant_override("separation", 8)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)

	_populate_list(list)

	# Close / Back button.
	var close_btn: Button = Button.new()
	close_btn.text = "Back"
	close_btn.custom_minimum_size = Vector2(0, BTN_H)
	close_btn.add_theme_font_size_override("font_size", 28)
	close_btn.pressed.connect(func() -> void: queue_free())
	vbox.add_child(close_btn)


func _populate_list(list: VBoxContainer) -> void:
	var profile_id: String = SaveSystem.get_active_profile_id()
	var level_ids: Array[String] = BrlSerializer.list_levels(profile_id)
	# Filter out test files.
	level_ids = level_ids.filter(func(id: String) -> bool: return not id.ends_with("_test"))

	if level_ids.is_empty():
		var empty: Label = Label.new()
		empty.text = "No levels yet!\nPress the button above to make your first level."
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty.add_theme_font_size_override("font_size", 26)
		empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		list.add_child(empty)
		return

	for level_id: String in level_ids:
		var session: BuildSession = BrlSerializer.load_from_disk(level_id, profile_id)
		if session == null:
			continue
		var data: Dictionary = session.get_data()
		var meta: Dictionary = data.get("metadata", {}) as Dictionary
		var level_name: String = meta.get("name", level_id) as String
		var zone: int = int(meta.get("zone", 1))
		var zone_label: String = ZONE_NAMES[clamp(zone, 0, ZONE_NAMES.size() - 1)]

		var row: HBoxContainer = HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		list.add_child(row)

		# Level name + world badge.
		var info: VBoxContainer = VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(info)

		var name_lbl: Label = Label.new()
		name_lbl.text = level_name
		name_lbl.add_theme_font_size_override("font_size", 28)
		name_lbl.clip_text = true
		info.add_child(name_lbl)

		var zone_lbl: Label = Label.new()
		zone_lbl.text = zone_label
		zone_lbl.add_theme_font_size_override("font_size", 22)
		zone_lbl.modulate = Color(0.7, 0.9, 1.0)
		info.add_child(zone_lbl)

		# Play button.
		var play_btn: Button = Button.new()
		play_btn.text = "Play"
		play_btn.custom_minimum_size = Vector2(100, BTN_H)
		play_btn.add_theme_font_size_override("font_size", 26)
		var path: String = "user://profiles/%s/levels/%s.brl" % [profile_id, level_id]
		play_btn.pressed.connect(_on_play_level.bind(path))
		row.add_child(play_btn)

		# Edit button.
		var edit_btn: Button = Button.new()
		edit_btn.text = "Edit"
		edit_btn.custom_minimum_size = Vector2(100, BTN_H)
		edit_btn.add_theme_font_size_override("font_size", 26)
		edit_btn.pressed.connect(_on_edit_level.bind(level_id, profile_id))
		row.add_child(edit_btn)


func _on_new_level() -> void:
	GameManager.open_build_mode()
	queue_free()


func _on_play_level(path: String) -> void:
	GameManager.is_practice_mode = false
	GameManager.start_level(path)
	queue_free()


func _on_edit_level(level_id: String, profile_id: String) -> void:
	var session: BuildSession = BrlSerializer.load_from_disk(level_id, profile_id)
	if session == null:
		push_error("MyLevelsScreen: could not load level %s" % level_id)
		return
	GameManager.pending_build_session = session
	GameManager.open_build_mode()
	queue_free()
