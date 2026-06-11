## ChallengeExportScreen — lets the player share a Challenge Capsule.
##
## Usage: call setup(capsule_data) after adding to tree.
## The screen generates a base64 code the player can copy or share as a .brrc file.
extends Control

class_name ChallengeExportScreen

var _raw_code: String = ""

@onready var _code_label: Label = $Panel/VBox/CodeLabel
@onready var _copy_btn: Button = $Panel/VBox/CopyButton
@onready var _share_btn: Button = $Panel/VBox/ShareButton
@onready var _close_btn: Button = $Panel/VBox/CloseButton
@onready var _status_label: Label = $Panel/VBox/StatusLabel


func _ready() -> void:
	_copy_btn.pressed.connect(_on_copy_pressed)
	_share_btn.pressed.connect(_on_share_pressed)
	_close_btn.pressed.connect(_on_close_pressed)


## Call after adding to scene tree.
func setup(capsule_data: Dictionary) -> void:
	_raw_code = CapsuleSerializer.pack(capsule_data)
	# Display truncated code with total length hint.
	var display: String = _raw_code.substr(0, 48) + "…" if _raw_code.length() > 48 else _raw_code
	_code_label.text = display + "\n(%d chars)" % _raw_code.length()
	_status_label.text = ""
	EventBus.capsule_exported.emit("")


func _on_copy_pressed() -> void:
	DisplayServer.clipboard_set(_raw_code)
	_status_label.text = "Copied to clipboard!"


func _on_share_pressed() -> void:
	# Save to a temp .brrc file then open via OS share intent (Android).
	var path: String = CapsuleSerializer.save_capsule(_raw_code)
	if path.is_empty():
		_status_label.text = "Could not save capsule file."
		return
	_status_label.text = "Capsule saved."
	EventBus.capsule_exported.emit(path)
	# On Android: OS.shell_open("content://" + path) — no-op on desktop.
	if OS.get_name() == "Android":
		OS.shell_open(path)


func _on_close_pressed() -> void:
	queue_free()
