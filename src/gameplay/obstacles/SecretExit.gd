## SecretExit — invisible gate activated by power use, fever state, or timing window.
## setup() reads exit_id from beat_map entry parameters.
## activate() can be called directly (e.g. by BubbleBurst collision or FeverController).
extends Node2D

class_name SecretExit

var _exit_id: String = "exit_0"
var _activated: bool = false


func setup(entry: Dictionary) -> void:
	var params: Dictionary = entry.get("parameters", {}) as Dictionary
	_exit_id = str(params.get("exit_id", "exit_0"))


## Call when player triggers the exit. Safe to call multiple times (deduped).
func activate(profile_id: String, level_id: String) -> void:
	if _activated:
		return
	_activated = true
	SaveSystem.set_secret_exit_found(profile_id, level_id, _exit_id)


func get_exit_id() -> String:
	return _exit_id


func is_activated() -> bool:
	return _activated
