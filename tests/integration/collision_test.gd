## Deterministic collision-contract test.
## Places the player directly on a Pearl and on a CoralSpike to confirm the
## Area2D detection, layer masks, and signal wiring actually fire — independent
## of where the wandering playtest happens to move the fish.
##
## Run with:
##   godot --headless --path . --script tests/integration/collision_test.gd
extends SceneTree

var _collectible_taken: bool = false
var _player_hit: bool = false


func _init() -> void:
	await process_frame
	var event_bus: Node = root.get_node("EventBus")
	event_bus.collectible_taken.connect(func(_v: int) -> void: _collectible_taken = true)
	event_bus.player_hit.connect(func() -> void: _player_hit = true)

	# ---- Pearl collection ----
	var pearl_ok: bool = await _test_pearl_collection()

	# ---- Spike hit ----
	var spike_ok: bool = await _test_spike_hit()

	print("==== COLLISION TEST ====")
	print("Pearl collected on overlap: %s" % _collectible_taken)
	print("Player hit on spike overlap: %s" % _player_hit)
	print("========================")

	if pearl_ok and spike_ok:
		print("COLLISION_OK")
		quit(0)
	else:
		print("COLLISION_FAIL")
		quit(1)


func _test_pearl_collection() -> bool:
	var holder: Node2D = Node2D.new()
	root.add_child(holder)

	var player: Node2D = load("res://scenes/player/Player.tscn").instantiate()
	holder.add_child(player)
	player.global_position = Vector2(400, 500)
	# Freeze the fish so its buoyancy doesn't drift it off the pearl mid-test.
	player.set_physics_process(false)

	var pearl: Node2D = load("res://scenes/collectibles/Pearl.tscn").instantiate()
	holder.add_child(pearl)
	pearl.set_process(false)  # stop it scrolling away
	pearl.global_position = Vector2(400, 500)

	# Give the physics server a few steps to register the overlap.
	for i: int in range(5):
		await physics_frame

	holder.queue_free()
	await process_frame
	return _collectible_taken


func _test_spike_hit() -> bool:
	var holder: Node2D = Node2D.new()
	root.add_child(holder)

	var player: Node2D = load("res://scenes/player/Player.tscn").instantiate()
	holder.add_child(player)
	player.global_position = Vector2(400, 500)
	player.set_physics_process(false)

	var spike: Node2D = load("res://scenes/obstacles/CoralSpike.tscn").instantiate()
	holder.add_child(spike)
	spike.set_process(false)
	spike.global_position = Vector2(400, 500)
	if spike.has_method("setup"):
		spike.setup({"parameters": {"wall_attachment": "bottom", "height": 120}})

	for i: int in range(5):
		await physics_frame

	holder.queue_free()
	await process_frame
	return _player_hit
