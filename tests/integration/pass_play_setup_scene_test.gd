## pass_play_setup_scene_test.gd — verifies the Pass & Play setup UX overhaul:
## hub hides (not frees) when opening the setup screen so Back returns to it,
## large toggle-button player cards, and the Add Player shortcut.
##
## Run with:
##   godot --headless --path . --script tests/integration/pass_play_setup_scene_test.gd
extends SceneTree

var _pass_count := 0
var _fail_count := 0


func _init() -> void:
	await process_frame
	await _test_hub_hides_and_returns()
	await _test_setup_screen_layout()
	print("Pass & Play setup scene tests: %d passed, %d failed" % [_pass_count, _fail_count])
	if _fail_count == 0:
		print("PASS_PLAY_SETUP_SCENE_OK")
	quit()


func _ok(label: String) -> void:
	print("  PASS: " + label)
	_pass_count += 1


func _fail(label: String, detail: String = "") -> void:
	print("  FAIL: " + label + ("  -- " + detail if detail != "" else ""))
	_fail_count += 1


## 1. Opening Pass & Play hides the hub; closing the setup screen re-shows it.
func _test_hub_hides_and_returns() -> void:
	var holder: Control = Control.new()
	root.add_child(holder)
	var rivals: Control = (load("res://scenes/ui/ReefRivalsScreen.tscn") as PackedScene).instantiate() as Control
	holder.add_child(rivals)
	await process_frame

	rivals.call("_on_pass_play")
	await process_frame
	if not is_instance_valid(rivals):
		_fail("hub_hides_and_returns", "hub was freed instead of hidden")
		holder.queue_free()
		return
	if rivals.visible:
		_fail("hub_hides_and_returns", "hub still visible behind setup screen")
		holder.queue_free()
		return
	var setup: Control = null
	for child: Node in holder.get_children():
		if child != rivals and child is Control:
			setup = child as Control
	if setup == null:
		_fail("hub_hides_and_returns", "setup screen was not added")
		holder.queue_free()
		return

	setup.queue_free()
	await process_frame
	await process_frame
	if not rivals.visible:
		_fail("hub_hides_and_returns", "hub not re-shown after setup screen closed")
		holder.queue_free()
		return
	_ok("hub_hides_and_returns")
	holder.queue_free()


## 2. Setup screen has Add Player shortcut and ≥88px toggle-card profile rows.
func _test_setup_screen_layout() -> void:
	root.get_node("SaveSystem").ensure_profile("player1")
	var setup: Control = (load("res://scenes/ui/PassPlaySetupScreen.tscn") as PackedScene).instantiate() as Control
	root.add_child(setup)
	await process_frame

	var add_btn: Button = setup.get_node_or_null("Panel/VBox/AddPlayerButton") as Button
	if add_btn == null:
		_fail("setup_screen_layout", "AddPlayerButton missing")
		setup.queue_free()
		return
	if add_btn.custom_minimum_size.y < 88:
		_fail("setup_screen_layout", "AddPlayerButton height %.0f < 88" % add_btn.custom_minimum_size.y)
		setup.queue_free()
		return
	var profile_list: Node = setup.get_node("Panel/VBox/ProfileList")
	if profile_list.get_child_count() == 0:
		_fail("setup_screen_layout", "no profile cards rendered")
		setup.queue_free()
		return
	var card: Button = profile_list.get_child(0) as Button
	if card == null or not card.toggle_mode:
		_fail("setup_screen_layout", "profile row is not a toggle Button card")
		setup.queue_free()
		return
	if card.custom_minimum_size.y < 88:
		_fail("setup_screen_layout", "profile card height %.0f < 88" % card.custom_minimum_size.y)
		setup.queue_free()
		return
	if not card.button_pressed:
		_fail("setup_screen_layout", "profile card should start selected")
		setup.queue_free()
		return
	_ok("setup_screen_layout")
	setup.queue_free()
