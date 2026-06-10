## PracticeController — scene-local node for practice-mode checkpoint management.
## Practice mode never writes SaveSystem best-score or star data.
## Enabled by setting GameManager.is_practice_mode = true before the level starts.
extends Node

class_name PracticeController

## A frozen snapshot of game state taken at a checkpoint beat.
class Checkpoint:
	var beat: float
	var player_y: float
	var velocity_y: float
	var score: int

	func _init(b: float, py: float, vy: float, s: int) -> void:
		beat = b
		player_y = py
		velocity_y = vy
		score = s


var _checkpoints: Array = []  # Array[Checkpoint]

## References wired by LevelRoot.setup_practice().
var _player: Node = null          # PlayerController (duck-typed)
var _hud: Node = null             # HUDController (duck-typed)
var _level_loader: LevelLoader = null


## Wire up references. Only registers run_failed handler when in practice mode.
func setup(player: Node, hud: Node, level_loader: LevelLoader) -> void:
	_player = player
	_hud = hud
	_level_loader = level_loader
	if GameManager.is_practice_mode:
		EventBus.run_failed.connect(_on_run_failed)


## Save a checkpoint at the current game state.
func drop_checkpoint() -> void:
	if not GameManager.is_practice_mode:
		return
	var cp := Checkpoint.new(
		BeatConductor.get_current_beat_position(),
		_player.global_position.y,
		_player.velocity.y,
		_hud.score
	)
	_checkpoints.append(cp)
	EventBus.practice_checkpoint_saved.emit()
	SFXManager.play_sfx("sfx/checkpoint_saved")


## Respawn from the most recent checkpoint (or beat 0 if none saved).
func respawn() -> void:
	var from_beat: float = 0.0
	var restore_y: float = 960.0
	var restore_vy: float = 0.0
	var restore_score: int = 0

	if not _checkpoints.is_empty():
		var cp: Checkpoint = _checkpoints.back() as Checkpoint
		from_beat = cp.beat
		restore_y = cp.player_y
		restore_vy = cp.velocity_y
		restore_score = cp.score

	# Restart conductor + spawners from checkpoint beat.
	_level_loader.restart_from_beat(from_beat)

	# Restore player state. PlayerController.alive flag reset here so physics
	# resumes without a full scene reload.
	_player.global_position.y = restore_y
	_player.velocity = Vector2(0.0, restore_vy)
	_player.alive = true
	_player.modulate = Color.WHITE

	# Restore HUD score.
	if _hud.has_method("set_score"):
		_hud.set_score(restore_score)

	# Reset timing judge state.
	_player.timing_judge.reset()


func _on_run_failed(_level_id: String, _score: int) -> void:
	if not GameManager.is_practice_mode:
		return
	respawn()
