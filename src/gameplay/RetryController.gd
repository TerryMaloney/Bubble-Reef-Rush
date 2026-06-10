# Scene-local node that listens for run_failed and triggers a retry after a short delay.
extends Node

class_name RetryController

@export var auto_retry: bool = true


func _ready() -> void:
	EventBus.run_failed.connect(_on_run_failed)


func _on_run_failed(_level_id: String, _score: int) -> void:
	if GameManager.is_practice_mode:
		return  # PracticeController respawns instead
	if auto_retry:
		_auto_retry_after_delay()


func _auto_retry_after_delay() -> void:
	await get_tree().create_timer(1.5).timeout
	EventBus.retry_requested.emit()
