## CoPilotSetupScreen — lets two players choose profiles and launch Co-Pilot mode.
## Player A controls movement; Player B activates powers from the right screen half.
extends Control

class_name CoPilotSetupScreen

var _profile_b: String = ""
var _selected_level: String = "z1-l1"

@onready var _player_a_value: Label = $Panel/VBox/PlayerARow/PlayerAValue
@onready var _player_b_value: Label = $Panel/VBox/PlayerBRow/PlayerBValue
@onready var _profile_container: VBoxContainer = $Panel/VBox/ProfileList
@onready var _level_label: Label = $Panel/VBox/LevelRow/LevelLabel
@onready var _start_btn: Button = $Panel/VBox/StartButton


func _ready() -> void:
	$Panel/VBox/LevelRow/RandomButton.pressed.connect(_pick_random_level)
	_start_btn.pressed.connect(_on_start_pressed)
	$Panel/VBox/CloseButton.pressed.connect(func() -> void: queue_free())

	var profile_a: String = SaveSystem.get_active_profile_id()
	_player_a_value.text = profile_a

	_populate_profile_buttons(profile_a)


func _populate_profile_buttons(profile_a: String) -> void:
	for pid: String in SaveSystem.list_profiles():
		if pid == profile_a:
			continue
		var btn: Button = Button.new()
		btn.text = pid
		btn.custom_minimum_size = Vector2(0, 88)
		btn.pressed.connect(func() -> void: _select_profile_b(pid))
		_profile_container.add_child(btn)


func _select_profile_b(pid: String) -> void:
	_profile_b = pid
	_player_b_value.text = pid
	_start_btn.disabled = false


func _pick_random_level() -> void:
	var seed: int = DeterministicSeed.seed_from_string("%d" % Time.get_ticks_msec())
	var levels: Array[String] = DeterministicSeed.pick_levels(seed, 1, [1, 3])
	if not levels.is_empty():
		_selected_level = levels[0]
		_level_label.text = "Level: " + _selected_level


func _on_start_pressed() -> void:
	if _profile_b.is_empty():
		return
	start_copilot(SaveSystem.get_active_profile_id(), _profile_b, _selected_level)
	queue_free()


func start_copilot(profile_a: String, profile_b: String, level_id: String) -> void:
	GameManager.copilot_profile_b = profile_b
	GameManager.start_level(level_id)
	_ = profile_a  # profile_a is already set as the active profile
