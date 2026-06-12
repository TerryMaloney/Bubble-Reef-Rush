## hazard_warning_test.gd — Batch C contracts for the hazard warning system.
##
## Tests:
##   1. mirror_fish_speed       — approach_speed_bonus=80 after setup({bonus:100})
##   2. mirror_fish_warning     — MirrorFish emits "SHADOW APPROACHING" on _ready()
##   3. dark_void_warning       — DarkVoid emits "DARKNESS FALLS" from setup()
##   4. dark_void_fade          — overlay alpha < 1.0 right after activation (fade, not instant)
##   5. sudden_darkness_darkens — sudden_darkness mutator darkens BackgroundController base color
##
## Run with:
##   godot --headless --path . --script tests/integration/hazard_warning_test.gd
extends SceneTree

var _pass_count := 0
var _fail_count := 0


func _init() -> void:
	await process_frame
	var root := get_root()
	var eb: Node = root.get_node("EventBus")
	var ms: Node = root.get_node("MutatorSystem")

	_test_mirror_fish_speed(root)
	_test_mirror_fish_warning(root, eb)
	_test_dark_void_warning(root, eb)
	_test_dark_void_fade(root)
	_test_sudden_darkness_darkens(root, ms, eb)

	print("Hazard warning tests: %d passed, %d failed" % [_pass_count, _fail_count])
	if _fail_count == 0:
		print("HAZARD_WARNING_OK")
	quit()


func _ok(label: String) -> void:
	print("  PASS: " + label)
	_pass_count += 1


func _fail(label: String, detail: String = "") -> void:
	print("  FAIL: " + label + ("  -- " + detail if detail != "" else ""))
	_fail_count += 1


## 1. MirrorFish approach_speed_bonus is reduced by SPEED_TUNING (0.8)
func _test_mirror_fish_speed(root: Node) -> void:
	var fish: Node = load("res://src/gameplay/obstacles/MirrorFish.gd").new()
	root.add_child(fish)
	fish.setup({"parameters": {"approach_speed_bonus": 100}})
	var bonus: float = fish._approach_speed_bonus
	fish.queue_free()

	if absf(bonus - 80.0) < 0.01:
		_ok("mirror_fish_speed")
	else:
		_fail("mirror_fish_speed", "expected 80.0, got %f" % bonus)


## 2. MirrorFish emits hazard_warning("SHADOW APPROACHING") during _ready()
func _test_mirror_fish_warning(root: Node, eb: Node) -> void:
	var received: Array = []
	var cb: Callable = func(text: String) -> void: received.append(text)
	eb.hazard_warning.connect(cb)

	var fish: Node = load("res://src/gameplay/obstacles/MirrorFish.gd").new()
	root.add_child(fish)

	eb.hazard_warning.disconnect(cb)
	fish.queue_free()

	if "SHADOW APPROACHING" in received:
		_ok("mirror_fish_warning")
	else:
		_fail("mirror_fish_warning", "expected SHADOW APPROACHING, got: %s" % str(received))


## 3. DarkVoid emits hazard_warning("DARKNESS FALLS") from setup()
func _test_dark_void_warning(root: Node, eb: Node) -> void:
	var received: Array = []
	var cb: Callable = func(text: String) -> void: received.append(text)
	eb.hazard_warning.connect(cb)

	var canvas: CanvasLayer = CanvasLayer.new()
	canvas.name = "DarkCanvas"
	var rect: ColorRect = ColorRect.new()
	rect.name = "Overlay"
	canvas.add_child(rect)

	var void_node: Node2D = load("res://src/gameplay/obstacles/DarkVoid.gd").new()
	void_node.add_child(canvas)
	root.add_child(void_node)

	void_node.setup({"beat_index": 99, "parameters": {"duration_beats": 4}})

	eb.hazard_warning.disconnect(cb)
	void_node.queue_free()

	if "DARKNESS FALLS" in received:
		_ok("dark_void_warning")
	else:
		_fail("dark_void_warning", "DARKNESS FALLS not emitted from setup(), got: %s" % str(received))


## 4. DarkVoid overlay fades in (alpha < 1.0 immediately after activation)
func _test_dark_void_fade(root: Node) -> void:
	var canvas: CanvasLayer = CanvasLayer.new()
	canvas.name = "DarkCanvas"
	var rect: ColorRect = ColorRect.new()
	rect.name = "Overlay"
	rect.modulate.a = 1.0
	canvas.add_child(rect)

	var void_node: Node2D = load("res://src/gameplay/obstacles/DarkVoid.gd").new()
	void_node.add_child(canvas)
	root.add_child(void_node)

	void_node.setup({"beat_index": 0, "parameters": {"duration_beats": 4}})
	void_node._on_beat_fired(0)

	var alpha: float = rect.modulate.a
	void_node.queue_free()

	if alpha < 1.0:
		_ok("dark_void_fade")
	else:
		_fail("dark_void_fade", "expected alpha < 1.0 right after activation, got %f" % alpha)


## 5. sudden_darkness mutator darkens BackgroundController base color
func _test_sudden_darkness_darkens(root: Node, ms: Node, _eb: Node) -> void:
	ms._test_set_active(["sudden_darkness"])

	var bg: ColorRect = ColorRect.new()
	var bc: Node = load("res://src/gameplay/BackgroundController.gd").new()
	root.add_child(bg)
	root.add_child(bc)
	bc.setup(bg)

	var base_before: Color = Color(0.04, 0.24, 0.52)  # ZONE_COLORS[1]
	bc._on_run_started("z1-l1")
	var base_after: Color = bg.color

	ms._test_set_active([])
	bc.queue_free()
	bg.queue_free()

	if base_after.g < base_before.g - 0.01:
		_ok("sudden_darkness_darkens")
	else:
		_fail("sudden_darkness_darkens",
			"color not darkened: before_g=%f after_g=%f" % [base_before.g, base_after.g])
