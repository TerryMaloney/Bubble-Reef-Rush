## ChallengeExportScreen — lets the player share a Challenge Capsule.
##
## Usage: call setup(capsule_data) after adding to tree.
## The screen generates a base64 code the player can copy or share as a .brrc file.
extends Control

class_name ChallengeExportScreen

var _raw_code: String = ""
var _level_ref: String = ""
var _serializer: CapsuleSerializer

@onready var _code_label: Label = $Panel/VBox/CodeLabel
@onready var _copy_btn: Button = $Panel/VBox/CopyButton
@onready var _share_btn: Button = $Panel/VBox/ShareButton
@onready var _close_btn: Button = $Panel/VBox/CloseButton
@onready var _status_label: Label = $Panel/VBox/StatusLabel


func _ready() -> void:
	_serializer = CapsuleSerializer.new()
	_copy_btn.pressed.connect(_on_copy_pressed)
	_share_btn.pressed.connect(_on_share_pressed)
	_close_btn.pressed.connect(_on_close_pressed)


## Call after adding to scene tree.
func setup(capsule_data: Dictionary) -> void:
	_raw_code = _serializer.pack(capsule_data)
	_level_ref = str(capsule_data.get("level_ref", "capsule_%d" % Time.get_ticks_msec()))
	# Display truncated code with total length hint.
	var display: String = _raw_code.substr(0, 48) + "…" if _raw_code.length() > 48 else _raw_code
	_code_label.text = display + "\n(%d chars)" % _raw_code.length()
	_status_label.text = ""
	EventBus.capsule_exported.emit("")


func _on_copy_pressed() -> void:
	DisplayServer.clipboard_set(_raw_code)
	_status_label.text = "Copied to clipboard!"


func _on_share_pressed() -> void:
	# Save to a .brrc file then open via OS share intent (Android).
	var profile: String = SaveSystem.get_active_profile_id()
	var dir: String = "user://profiles/%s/capsules" % profile
	DirAccess.make_dir_recursive_absolute(dir)
	var path: String = "%s/%s.brrc" % [dir, _level_ref]
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		_status_label.text = "Could not save capsule file."
		return
	file.store_string(_raw_code)
	file.close()
	_status_label.text = "Capsule saved."
	EventBus.capsule_exported.emit(path)
	# On Android: OS.shell_open("content://" + path) — no-op on desktop.
	if OS.get_name() == "Android":
		OS.shell_open(path)


func _on_close_pressed() -> void:
	queue_free()
