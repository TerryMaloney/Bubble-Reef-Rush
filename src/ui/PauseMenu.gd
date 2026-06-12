## PauseMenu.gd
## In-game pause overlay (CanvasLayer, PROCESS_MODE_ALWAYS so it receives input
## while the tree is paused). Pausing is purely logical — BeatConductor.set_paused()
## and process_mode freeze on LevelRoot; never Engine.time_scale.
extends CanvasLayer

var _visible: bool = false


func _ready() -> void:
	EventBus.pause_requested.connect(_show)
	EventBus.resume_requested.connect(_hide)
	$Panel/VBox/ResumeButton.pressed.connect(_on_resume)
	$Panel/VBox/RestartButton.pressed.connect(_on_restart)
	$Panel/VBox/QuitButton.pressed.connect(_on_quit)
	$Panel/VBox/MainMenuButton.pressed.connect(_on_main_menu)
	$Panel/VBox/ReturnToEditorButton.pressed.connect(_on_return_to_editor)
	hide()


func _input(event: InputEvent) -> void:
	# Keyboard Escape / P, and Android Back (ui_cancel).
	if event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel"):
		if _visible:
			_on_resume()
		else:
			_show()
		get_viewport().set_input_as_handled()


func _show() -> void:
	if _visible:
		return
	_visible = true
	# Show "Return to Editor" only during build test-play.
	$Panel/VBox/ReturnToEditorButton.visible = GameManager.pending_build_session != null
	BeatConductor.set_paused(true)
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


func _on_main_menu() -> void:
	_visible = false
	BeatConductor.set_paused(false)
	hide()
	GameManager.go_to_menu()


func _on_return_to_editor() -> void:
	_visible = false
	BeatConductor.set_paused(false)
	hide()
	if not GameManager.pending_build_test_path.is_empty():
		DirAccess.remove_absolute(GameManager.pending_build_test_path)
		GameManager.pending_build_test_path = ""
	GameManager.open_build_mode()


func _find_level_root() -> Node:
	return get_parent()
