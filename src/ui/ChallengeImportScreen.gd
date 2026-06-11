## ChallengeImportScreen — lets the player receive a Challenge Capsule.
##
## Player pastes a base64 code from clipboard or from a shared .brrc file.
## On import: validate → show preview → save to user://capsules/ → emit capsule_imported.
extends Control

class_name ChallengeImportScreen

@onready var _paste_edit: TextEdit = $Panel/VBox/PasteEdit
@onready var _paste_btn: Button = $Panel/VBox/PasteFromClipboardButton
@onready var _import_btn: Button = $Panel/VBox/ImportButton
@onready var _status_label: Label = $Panel/VBox/StatusLabel
@onready var _preview_label: Label = $Panel/VBox/PreviewLabel
@onready var _close_btn: Button = $Panel/VBox/CloseButton

var _pending_data: Dictionary = {}


func _ready() -> void:
	_paste_btn.pressed.connect(_on_paste_pressed)
	_import_btn.pressed.connect(_on_import_pressed)
	_close_btn.pressed.connect(_on_close_pressed)
	_import_btn.disabled = true


func _on_paste_pressed() -> void:
	_paste_edit.text = DisplayServer.clipboard_get()
	_validate_pasted()


func _on_import_pressed() -> void:
	if _pending_data.is_empty():
		return
	var raw: String = _paste_edit.text.strip_edges()
	var path: String = CapsuleSerializer.save_capsule(raw)
	if path.is_empty():
		_status_label.text = "Failed to save capsule."
		return
	var level_id: String = str(_pending_data.get("level_id", ""))
	_status_label.text = "Capsule imported!"
	EventBus.capsule_imported.emit(level_id)
	await get_tree().create_timer(1.0).timeout
	queue_free()


func _on_close_pressed() -> void:
	queue_free()


func _validate_pasted() -> void:
	var raw: String = _paste_edit.text.strip_edges()
	if raw.is_empty():
		_status_label.text = "Paste a capsule code above."
		_import_btn.disabled = true
		_pending_data = {}
		return
	var data: Dictionary = CapsuleSerializer.unpack(raw)
	if data.is_empty():
		_status_label.text = "Invalid capsule: could not decode."
		_import_btn.disabled = true
		_pending_data = {}
		return
	var issues: Array[String] = CapsuleSerializer.validate(data)
	var hard_errors: Array[String] = issues.filter(func(s: String) -> bool: return not s.begins_with("WARN:"))
	if not hard_errors.is_empty():
		_status_label.text = "Invalid capsule: " + hard_errors[0]
		_import_btn.disabled = true
		_pending_data = {}
		return
	# Soft warnings shown but not blocking.
	var warnings: Array[String] = issues.filter(func(s: String) -> bool: return s.begins_with("WARN:"))
	var creator: String = str(data.get("creator_nick", "Unknown"))
	var level_id: String = str(data.get("level_id", "?"))
	var score: int = int(data.get("target", {}).get("score", 0))
	_preview_label.text = "From: %s   Level: %s   Target: %d pts" % [creator, level_id, score]
	if warnings.is_empty():
		_status_label.text = "Capsule looks good!"
	else:
		_status_label.text = "OK with warnings: " + ", ".join(warnings)
	_pending_data = data
	_import_btn.disabled = false
