## PassPlaySetupScreen — configure and launch a Pass & Play session.
extends Control

class_name PassPlaySetupScreen

@onready var _profile_container: VBoxContainer = $Panel/VBox/ProfileList
@onready var _level_label: Label = $Panel/VBox/LevelRow/LevelLabel
@onready var _random_btn: Button = $Panel/VBox/LevelRow/RandomButton
@onready var _one_attempt_btn: Button = $Panel/VBox/ModeRow/OneAttemptButton
@onready var _three_attempt_btn: Button = $Panel/VBox/ModeRow/ThreeAttemptsButton
@onready var _start_btn: Button = $Panel/VBox/StartButton
@onready var _close_btn: Button = $Panel/VBox/CloseButton

var _selected_level: String = "z1-l1"
var _mode: PassPlaySession.Mode = PassPlaySession.Mode.ONE_ATTEMPT
var _profile_checks: Dictionary = {}  # profile_id → CheckBox


func _ready() -> void:
	_random_btn.pressed.connect(_pick_random_level)
	_one_attempt_btn.pressed.connect(func() -> void: _mode = PassPlaySession.Mode.ONE_ATTEMPT)
	_three_attempt_btn.pressed.connect(func() -> void: _mode = PassPlaySession.Mode.THREE_ATTEMPTS)
	_start_btn.pressed.connect(_on_start_pressed)
	_close_btn.pressed.connect(func() -> void: queue_free())
	_level_label.text = _selected_level
	_populate_profiles()


func _populate_profiles() -> void:
	for child: Node in _profile_container.get_children():
		child.queue_free()
	_profile_checks.clear()
	var profiles: Array[String] = SaveSystem.list_profiles()
	for pid: String in profiles:
		var row: HBoxContainer = HBoxContainer.new()
		var cb: CheckBox = CheckBox.new()
		cb.button_pressed = true
		cb.text = pid
		row.add_child(cb)
		_profile_container.add_child(row)
		_profile_checks[pid] = cb


func _pick_random_level() -> void:
	var easy_levels: Array[String] = ["z1-l1", "z1-l2", "z1-l3", "z2-l1", "z2-l2", "z2-l3"]
	_selected_level = easy_levels[randi() % easy_levels.size()]
	_level_label.text = _selected_level


func _on_start_pressed() -> void:
	var selected: Array[String] = []
	for pid: String in _profile_checks:
		if (_profile_checks[pid] as CheckBox).button_pressed:
			selected.append(pid)
	if selected.size() < 2:
		return  # Need at least 2 players.
	var session: PassPlaySession = PassPlaySession.new()
	session.setup(selected, _selected_level, _mode)
	GameManager.start_pass_play(session)
	queue_free()
