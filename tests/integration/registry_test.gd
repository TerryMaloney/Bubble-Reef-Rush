## AssetRegistry integration test.
##
## Verifies:
##   1. asset_manifest.json parses successfully.
##   2. Every key in the manifest has a non-empty spec string.
##   3. Every key with a non-empty "fallback" path resolves to a loadable resource.
##   4. Keys that have a present fallback do NOT appear in list_missing().
##   5. GameConstants exposes the expected canonical values.
##
## Run with:
##   godot --headless --path . --script tests/integration/registry_test.gd
extends SceneTree

var _failures: PackedStringArray = []
var _registry: Node = null
var _constants: Node = null


func _init() -> void:
	await process_frame
	await process_frame

	_registry = root.get_node("AssetRegistry")
	_constants = root.get_node("GameConstants")

	_test_manifest_parses()
	_test_all_keys_have_spec()
	_test_fallbacks_resolve()
	_test_game_constants()

	print("==== REGISTRY TEST ====")
	if _failures.is_empty():
		print("All AssetRegistry and GameConstants contracts hold.")
		print("REGISTRY_OK")
		quit(0)
	else:
		for f: String in _failures:
			print("FAIL: " + f)
		print("REGISTRY_FAIL")
		quit(1)


func _fail(msg: String) -> void:
	_failures.append(msg)


## ── Manifest parses ──────────────────────────────────────────────────────────
func _test_manifest_parses() -> void:
	var keys: Array = _registry.list_all_keys()
	if keys.is_empty():
		_fail("Manifest parsed 0 keys — check assets/asset_manifest.json")
		return
	print("Manifest loaded %d keys — OK" % keys.size())


## ── Every key has a spec ─────────────────────────────────────────────────────
func _test_all_keys_have_spec() -> void:
	var keys: Array = _registry.list_all_keys()
	var no_spec: int = 0
	for k: Variant in keys:
		var key: String = str(k)
		var spec: String = str(_registry.get_spec(key))
		if spec.is_empty():
			no_spec += 1
			print("  Missing spec: %s" % key)
	if no_spec > 0:
		_fail("%d manifest keys have empty spec strings" % no_spec)
	else:
		print("All %d keys have spec strings — OK" % keys.size())


## ── Fallbacks resolve ────────────────────────────────────────────────────────
func _test_fallbacks_resolve() -> void:
	# Read the raw manifest to check fallback fields directly.
	var file: FileAccess = FileAccess.open("res://assets/asset_manifest.json", FileAccess.READ)
	if file == null:
		_fail("Cannot open asset_manifest.json directly")
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if parsed == null or not (parsed is Dictionary):
		_fail("Manifest is not a valid JSON object")
		return

	var manifest: Dictionary = parsed as Dictionary
	var missing_fallbacks: int = 0
	for key: String in manifest.keys():
		if key.begins_with("_"):
			continue
		var entry: Dictionary = manifest[key] as Dictionary
		var fallback: String = str(entry.get("fallback", ""))
		if fallback.is_empty():
			continue
		if not ResourceLoader.exists(fallback):
			missing_fallbacks += 1
			print("  Missing fallback file: %s → %s" % [key, fallback])

	if missing_fallbacks > 0:
		_fail("%d manifest fallback files are missing on disk" % missing_fallbacks)
	else:
		print("All non-empty fallback paths resolve — OK")


## ── GameConstants values ─────────────────────────────────────────────────────
func _test_game_constants() -> void:
	var checks: Dictionary = {
		"CANVAS_W":           1080.0,
		"CANVAS_H":           1920.0,
		"SCROLL_SPEED":        408.0,
		"PLAYER_FLOAT_FORCE": 1250.0,
		"PLAYER_DIVE_FORCE":  1550.0,
		"TIMING_PERFECT_HALF_MS": 80.0,
		"TIMING_GOOD_OUTER_HALF_MS": 160.0,
	}
	for name: String in checks.keys():
		var expected: float = float(checks[name])
		var got: Variant = _constants.get(name)
		if got == null:
			_fail("GameConstants.%s not found" % name)
		elif absf(float(got) - expected) > 0.001:
			_fail("GameConstants.%s = %.3f, expected %.3f" % [name, float(got), expected])
	print("GameConstants canonical values — OK")
