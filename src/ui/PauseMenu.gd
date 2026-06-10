## PauseMenu.gd
## In-game pause overlay (CanvasLayer, PROCESS_MODE_ALWAYS so it receives input
## while the tree is paused).  Pausing is purely logical — we call
## BeatConductor.set_paused() and freeze _physics_process / _process on the
## LevelRoot subtree via process_mode, never Engine.time_scale.
extends CanvasLayer

var _visible: bool = false


func _ready() -> void:
	EventBus.pause_requested.connect(_show)
	EventBus.resume_requested.connect(_hide)
	$Panel/VBox/ResumeButton.pressed.connect(_on_resume)
	$Panel/VBox/RestartButton.pressed.connect(_on_restart)
	$Panel/VBox/QuitButton.pressed.connect(_on_quit)
	hide()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if _visible:
			_on_resume()
		else:
			_show()
		get_viewport().set_input_as_handled()


func _show() -> void:
	if _visible:
		return
	_visible = true
	BeatConductor.set_paused(true)
	# Freeze gameplay nodes but keep CanvasLayer (process_mode = ALWAYS) running.
	var level_root: Node = _find_level_root()
	if level_root != null:
		level_root.process_mode = Node.PROCESS_MODE_DISABLED
	show()


func _hide() -> void:
	if not _visible:
		return
	_visible = false
	var level_root: Node = _find_level_root()
	if level_root != null:
		level_root.process_mode = Node.PROCESS_MODE_INHERIT
	BeatConductor.set_paused(false)
	hide()


func _on_resume() -> void:
	EventBus.resume_requested.emit()


func _on_restart() -> void:
	_visible = false
	var level_root: Node = _find_level_root()
	if level_root != null:
		level_root.process_mode = Node.PROCESS_MODE_INHERIT
	BeatConductor.set_paused(false)
	hide()
	EventBus.retry_requested.emit()


func _on_quit() -> void:
	_visible = false
	BeatConductor.set_paused(false)
	hide()
	GameManager.go_to_zone_select()


func _find_level_root() -> Node:
	# PauseMenu is a child of LevelRoot; its parent is the LevelRoot Node2D.
	return get_parent()
