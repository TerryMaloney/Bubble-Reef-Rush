## ProfileManagerScreen — create and select family profiles.
## Opened as an overlay from MainMenu via the Players button.
extends Control

class_name ProfileManagerScreen

@onready var _profile_list: VBoxContainer = $Panel/VBox/ProfileList
@onready var _name_input: LineEdit = $Panel/VBox/AddRow/NameInput
@onready var _add_btn: Button = $Panel/VBox/AddRow/AddButton
@onready var _close_btn: Button = $Panel/VBox/CloseButton
@onready var _error_label: Label = $Panel/VBox/ErrorLabel

## Profile awaiting a second "really delete?" tap; cleared by any other press.
var _pending_delete: String = ""


func _ready() -> void:
	_add_btn.pressed.connect(_on_add_pressed)
	_close_btn.pressed.connect(func() -> void: queue_free())
	_name_input.text_submitted.connect(func(_t: String) -> void: _on_add_pressed())
	_populate_list()


func _populate_list() -> void:
	for child: Node in _profile_list.get_children():
		child.queue_free()
	var profiles: Array[String] = SaveSystem.list_profiles()
	var active: String = SaveSystem.get_active_profile_id()
	for pid: String in profiles:
		var row: HBoxContainer = HBoxContainer.new()
		var lbl: Label = Label.new()
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if pid == active:
			lbl.text = "→  " + pid
			lbl.modulate = Color(0.3, 1.0, 0.5)
		else:
			lbl.text = "    " + pid
		row.add_child(lbl)
		var sel_btn: Button = Button.new()
		sel_btn.text = "Play as"
		sel_btn.custom_minimum_size = Vector2(0, 88)
		sel_btn.disabled = (pid == active)
		sel_btn.pressed.connect(_on_select.bind(pid))
		row.add_child(sel_btn)
		var del_btn: Button = Button.new()
		del_btn.custom_minimum_size = Vector2(88, 88)
		if pid == _pending_delete:
			del_btn.text = "Really delete?"
			del_btn.modulate = Color(1.0, 0.35, 0.35)
		else:
			del_btn.text = "X"
		del_btn.disabled = profiles.size() <= 1
		del_btn.pressed.connect(_on_delete_pressed.bind(pid))
		row.add_child(del_btn)
		_profile_list.add_child(row)


func _on_add_pressed() -> void:
	var name: String = _name_input.text.strip_edges()
	_pending_delete = ""
	_error_label.visible = false
	if name.is_empty():
		return
	var existing: Array[String] = SaveSystem.list_profiles()
	if name in existing:
		_error_label.text = "Name already taken."
		_error_label.visible = true
		return
	if name.length() > 20:
		_error_label.text = "Name too long (max 20 characters)."
		_error_label.visible = true
		return
	SaveSystem.ensure_profile(name)
	SaveSystem.set_active_profile(name)
	_name_input.text = ""
	_populate_list()


func _on_select(profile_id: String) -> void:
	_pending_delete = ""
	SaveSystem.set_active_profile(profile_id)
	_populate_list()


func _on_delete_pressed(profile_id: String) -> void:
	_error_label.visible = false
	if _pending_delete != profile_id:
		_pending_delete = profile_id
		_populate_list()
		# Auto-cancel the pending confirmation after 5 seconds.
		get_tree().create_timer(5.0).timeout.connect(func() -> void:
			if is_instance_valid(self) and _pending_delete == profile_id:
				_pending_delete = ""
				_populate_list()
		)
		return
	_pending_delete = ""
	if not SaveSystem.delete_profile(profile_id):
		_error_label.text = "Can't delete the last player."
		_error_label.visible = true
	_populate_list()
