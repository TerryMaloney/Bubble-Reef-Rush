# Scene-local CharacterBody2D implementing one-touch buoyancy physics for the player fish.
extends CharacterBody2D

class_name PlayerController

@export var float_force: float = 1250.0
@export var dive_force: float = 1940.0
@export var max_float_speed: float = 700.0
@export var max_dive_speed: float = 1100.0
@export var drag: float = 0.983

## On tap, velocity is SET (not added) — guarantees identical feel every time.
## Tuned for a shallow ~40–55px dip with fast (~0.2s) buoyant recovery; holding
## then accelerates into a fast sustained dive (terminal 1100 px/s).
@export var dive_impulse: float = 220.0

# Fixed logical canvas height — matches project.godot viewport_height. Gameplay
# coordinates are always in the 1080×1920 space; never query the viewport for
# bounds (its size varies with window/DPI and breaks the clamp).
const CANVAS_H: float = 1920.0

var diving: bool = false
var alive: bool = true

@onready var beat_visualizer: BeatVisualizer = $BeatVisualizer
@onready var timing_judge: TimingJudge = $TimingJudge

var _ghost_recorder: GhostRecorder = null
## Set by LevelRoot so the death path can report the live HUD score.
var score_provider: Callable

const _ART_PATH: String = "res://assets/characters/player.png"
const _SWIM_PATH: String = "res://assets/characters/player_swim.png"
const _DIVE_PATH: String = "res://assets/characters/player_dive.png"
const _DEATH_PATH: String = "res://assets/characters/player_death.png"
## Target on-screen height (px) for drop-in character art.
const _ART_TARGET_HEIGHT: float = 110.0

var _anim_sprite: AnimatedSprite2D = null


func _ready() -> void:
	add_to_group("player")
	timing_judge.input_judged.connect(_on_input_judged)
	_try_load_art()


func _try_load_art() -> void:
	# Try animated sprite system first (swim/dive/death sheets).
	if ResourceLoader.exists(_SWIM_PATH):
		var swim_tex: Texture2D = load(_SWIM_PATH) as Texture2D
		if swim_tex != null:
			$Visual.hide()
			_build_animated_sprite(swim_tex)
			return
	# Fallback: static player.png.
	if not ResourceLoader.exists(_ART_PATH):
		return
	var tex: Texture2D = load(_ART_PATH) as Texture2D
	if tex == null:
		return
	$Visual.hide()
	var sp := Sprite2D.new()
	sp.texture = tex
	var tex_h: float = float(tex.get_height())
	if tex_h > 0.0:
		sp.scale = Vector2(_ART_TARGET_HEIGHT / tex_h, _ART_TARGET_HEIGHT / tex_h)
	add_child(sp)


func _build_animated_sprite(swim_tex: Texture2D) -> void:
	var frames := SpriteFrames.new()

	# swim — 2×2 grid → 4 frames.
	frames.add_animation("swim")
	frames.set_animation_loop("swim", true)
	frames.set_animation_speed("swim", 7.0)
	var sw: int = swim_tex.get_width() / 2
	var sh: int = swim_tex.get_height() / 2
	for row: int in range(2):
		for col: int in range(2):
			var a := AtlasTexture.new()
			a.atlas = swim_tex
			a.region = Rect2(col * sw, row * sh, sw, sh)
			frames.add_frame("swim", a)

	# dive — 2 frames side by side.
	if ResourceLoader.exists(_DIVE_PATH):
		var dive_tex: Texture2D = load(_DIVE_PATH) as Texture2D
		if dive_tex != null:
			frames.add_animation("dive")
			frames.set_animation_loop("dive", false)
			frames.set_animation_speed("dive", 8.0)
			var dw: int = dive_tex.get_width() / 2
			var dh: int = dive_tex.get_height()
			for col: int in range(2):
				var a := AtlasTexture.new()
				a.atlas = dive_tex
				a.region = Rect2(col * dw, 0, dw, dh)
				frames.add_frame("dive", a)

	# death — bottom row of 3×2 grid (3 clean frames without panel borders).
	if ResourceLoader.exists(_DEATH_PATH):
		var death_tex: Texture2D = load(_DEATH_PATH) as Texture2D
		if death_tex != null:
			frames.add_animation("death")
			frames.set_animation_loop("death", false)
			frames.set_animation_speed("death", 5.0)
			var ew: int = death_tex.get_width() / 3
			var eh: int = death_tex.get_height() / 2
			for col: int in range(3):
				var a := AtlasTexture.new()
				a.atlas = death_tex
				a.region = Rect2(col * ew, eh, ew, eh)
				frames.add_frame("death", a)

	var sp := AnimatedSprite2D.new()
	sp.sprite_frames = frames
	var s: float = _ART_TARGET_HEIGHT / float(sh) if sh > 0 else 1.0
	sp.scale = Vector2(s, s)
	sp.play("swim")
	add_child(sp)
	_anim_sprite = sp


func _update_anim() -> void:
	if _anim_sprite == null or not alive:
		return
	var target: StringName = &"dive" if diving else &"swim"
	if _anim_sprite.sprite_frames.has_animation(target) and _anim_sprite.animation != target:
		_anim_sprite.play(target)


func set_ghost_recorder(recorder: GhostRecorder) -> void:
	_ghost_recorder = recorder


func _input(event: InputEvent) -> void:
	if not alive:
		return
	# `not diving` guard: one physical tap arrives as TWO events (the raw
	# mouse/touch event plus its emulated counterpart, both bound to swim_dive),
	# which would double-judge every input and double-apply the impulse.
	if event.is_action_pressed("swim_dive") and not diving:
		diving = true
		var ov: Dictionary = GameManager.physics_overrides
		velocity.y = float(ov.get("dive_impulse", dive_impulse))
		timing_judge.judge_input(BeatConductor.get_current_beat_time_ms())
		if _ghost_recorder != null:
			_ghost_recorder.record_event(BeatConductor.get_current_beat_position(), "dive_start")
		_update_anim()
	elif event.is_action_released("swim_dive"):
		diving = false
		if _ghost_recorder != null:
			_ghost_recorder.record_event(BeatConductor.get_current_beat_position(), "dive_end")
		_update_anim()


func _physics_process(delta: float) -> void:
	if not alive:
		return

	# Allow live physics tuner to override values (debug builds only).
	var ov: Dictionary = GameManager.physics_overrides
	var _float_force: float = float(ov.get("float_force", float_force))
	var _dive_force: float = float(ov.get("dive_force", dive_force))
	var _max_float: float = float(ov.get("max_float_speed", max_float_speed))
	var _max_dive: float = float(ov.get("max_dive_speed", max_dive_speed))
	var _impulse: float = float(ov.get("dive_impulse", dive_impulse))

	# Buoyancy — always float upward.
	velocity.y -= _float_force * delta

	# Dive — pull downward while input is held.
	if diving:
		velocity.y += _dive_force * delta

	# Clamp to terminal velocities (upward speed is negative Y in Godot).
	velocity.y = clamp(velocity.y, -_max_float, _max_dive)

	# Light water drag applied every frame.
	velocity *= drag

	move_and_slide()

	# Clamp player within screen bounds with a small margin.
	global_position.y = clamp(global_position.y, 60.0, CANVAS_H - 60.0)


func on_hit() -> void:
	if not alive:
		return
	# Check EchoShield before dying.
	var rc: Node = get_tree().get_first_node_in_group("resonance_controller")
	if rc != null and rc.has_method("consume_shield"):
		if rc.consume_shield():
			return
	alive = false
	if _anim_sprite != null and _anim_sprite.sprite_frames.has_animation(&"death"):
		_anim_sprite.play("death")
	else:
		modulate = Color(1.0, 0.3, 0.3)
	EventBus.player_hit.emit()
	_die_after_delay()


func _die_after_delay() -> void:
	await get_tree().create_timer(0.8).timeout
	var s: int = score_provider.call() if score_provider.is_valid() else 0
	EventBus.run_failed.emit(GameManager.current_level_id, s)


func _on_input_judged(result: TimingJudge.TimingResult, _offset_ms: float, _beat_index: int) -> void:
	beat_visualizer.set_timing_quality(result)
