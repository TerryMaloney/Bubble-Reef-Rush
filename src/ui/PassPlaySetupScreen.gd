## PassPlaySetupScreen — configure and launch a Pass & Play session.
extends Control

class_name PassPlaySetupScreen

const PROFILE_MANAGER_SCENE: String = "res://scenes/ui/ProfileManagerScreen.tscn"

@onready var _profile_container: VBoxContainer = $Panel/VBox/ProfileList
@onready var _add_player_btn: Button = $Panel/VBox/AddPlayerButton
@onready var _level_label: Label = $Panel/VBox/LevelRow/LevelLabel
@onready var _random_btn: Button = $Panel/VBox/LevelRow/RandomButton
@onready var _one_attempt_btn: Button = $Panel/VBox/ModeRow/OneAttemptButton
@onready var _three_attempt_btn: Button = $Panel/VBox/ModeRow/ThreeAttemptsButton
@onready var _start_btn: Button = $Panel/VBox/StartButton
@onready var _close_btn: Button = $Panel/VBox/CloseButton

var _selected_level: String = "z1-l1"
var _mode: PassPlaySession.Mode = PassPlaySession.Mode.ONE_ATTEMPT
var _profile_checks: Dictionary = {}  # profile_id → BaseButton (toggle card)


func _ready() -> void:
	_random_btn.pressed.connect(_pick_random_level)
	_one_attempt_btn.pressed.connect(_on_mode_pressed.bind(PassPlaySession.Mode.ONE_ATTEMPT))
	_three_attempt_btn.pressed.connect(_on_mode_pressed.bind(PassPlaySession.Mode.THREE_ATTEMPTS))
	_add_player_btn.pressed.connect(_on_add_player)
	_start_btn.pressed.connect(_on_start_pressed)
	_close_btn.pressed.connect(func() -> void: queue_free())
	_level_label.text = _selected_level
	_populate_profiles()


func _populate_profiles() -> void:
	if not is_inside_tree():
		return  # tree_exited from a child can fire while this screen tears down
	for child: Node in _profile_container.get_children():
		child.queue_free()
	_profile_checks.clear()
	var profiles: Array[String] = SaveSystem.list_profiles()
	for pid: String in profiles:
		var card: Button = Button.new()
		card.toggle_mode = true
		card.button_pressed = true
		card.text = pid
		card.custom_minimum_size = Vector2(0, 96)
		_profile_container.add_child(card)
		_profile_checks[pid] = card


func _on_mode_pressed(mode: PassPlaySession.Mode) -> void:
	_mode = mode
	# Keep the two mode buttons mutually exclusive.
	_one_attempt_btn.button_pressed = (mode == PassPlaySession.Mode.ONE_ATTEMPT)
	_three_attempt_btn.button_pressed = (mode == PassPlaySession.Mode.THREE_ATTEMPTS)


func _on_add_player() -> void:
	var pm: Control = (load(PROFILE_MANAGER_SCENE) as PackedScene).instantiate() as Control
	add_child(pm)
	pm.tree_exited.connect(_populate_profiles)


func _pick_random_level() -> void:
	var easy_levels: Array[String] = ["z1-l1", "z1-l2", "z1-l3", "z2-l1", "z2-l2", "z2-l3"]
	_selected_level = easy_levels[randi() % easy_levels.size()]
	_level_label.text = _selected_level


func _on_start_pressed() -> void:
	var selected: Array[String] = []
	for pid: String in _profile_checks:
		if (_profile_checks[pid] as BaseButton).button_pressed:
			selected.append(pid)
	if selected.size() < 2:
		$Panel/VBox/ErrorLabel.text = "Select at least 2 players to start."
		$Panel/VBox/ErrorLabel.visible = true
		return
	$Panel/VBox/ErrorLabel.visible = false
	var session: PassPlaySession = PassPlaySession.new()
	session.setup(selected, _selected_level, _mode)
	GameManager.start_pass_play(session)
	queue_free()
