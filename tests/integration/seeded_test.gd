## seeded_test.gd — Phase 23 contracts for DeterministicSeed.
##
## Tests:
##   1. determinism           — same seed + same args returns identical list on 5 calls.
##   2. different_seed        — different seed produces different level sequence.
##   3. date_seed_stable      — date_seed() for same date string returns same seed.
##   4. zone_filter           — zone_range [1,2] returns only z1/z2 level IDs.
##   5. base36_roundtrip      — int_to_base36 then base36_to_int recovers original value.
##
## Run with:
##   godot --headless --path . --script tests/integration/seeded_test.gd
extends SceneTree

var _pass_count := 0
var _fail_count := 0


func _initialize() -> void:
	var root := get_root()

	_test_determinism(root)
	_test_different_seed(root)
	_test_date_seed_stable(root)
	_test_zone_filter(root)
	_test_base36_roundtrip(root)

	print("Seeded tests: %d passed, %d failed" % [_pass_count, _fail_count])
	if _fail_count == 0:
		print("SEEDED_OK")
	quit()


func _ok(label: String) -> void:
	print("  PASS: " + label)
	_pass_count += 1


func _fail(label: String, detail: String = "") -> void:
	print("  FAIL: " + label + ("  -- " + detail if detail != "" else ""))
	_fail_count += 1


## 1. determinism
func _test_determinism(root: Node) -> void:
	var ds: Node = root.get_node("DeterministicSeed")
	var seed_val: int = ds.seed_from_string("test_seed_42")
	var ref_list: Array[String] = ds.pick_levels(seed_val, 5, [1, 6])

	for i in range(4):
		var result: Array[String] = ds.pick_levels(seed_val, 5, [1, 6])
		if result != ref_list:
			_fail("determinism", "call %d differed from reference" % (i + 2))
			return

	_ok("determinism")


## 2. different_seed
func _test_different_seed(root: Node) -> void:
	var ds: Node = root.get_node("DeterministicSeed")
	var seed_a: int = ds.seed_from_string("seed_alpha")
	var seed_b: int = ds.seed_from_string("seed_beta")
	var list_a: Array[String] = ds.pick_levels(seed_a, 5, [1, 6])
	var list_b: Array[String] = ds.pick_levels(seed_b, 5, [1, 6])

	if list_a != list_b:
		_ok("different_seed")
	else:
		_fail("different_seed", "different seeds produced identical sequences")


## 3. date_seed_stable
func _test_date_seed_stable(root: Node) -> void:
	var ds: Node = root.get_node("DeterministicSeed")
	var date: String = "2026-06-11"
	var s1: int = ds.date_seed(date)
	var s2: int = ds.date_seed(date)
	if s1 == s2 and s1 != 0:
		_ok("date_seed_stable")
	else:
		_fail("date_seed_stable", "date_seed not stable: %d vs %d" % [s1, s2])


## 4. zone_filter
func _test_zone_filter(root: Node) -> void:
	var ds: Node = root.get_node("DeterministicSeed")
	var seed_val: int = ds.seed_from_string("zone_test")
	var levels: Array[String] = ds.pick_levels(seed_val, 8, [1, 2])

	for lid: String in levels:
		var zone: int = int(lid.substr(1, 1))
		if zone < 1 or zone > 2:
			_fail("zone_filter", "level '%s' outside z1-z2" % lid)
			return

	if levels.size() == 8:
		_ok("zone_filter")
	else:
		_fail("zone_filter", "expected 8 levels, got %d" % levels.size())


## 5. base36_roundtrip
func _test_base36_roundtrip(root: Node) -> void:
	var ds: Node = root.get_node("DeterministicSeed")
	var original: int = 12345
	var code: String = ds.int_to_base36(original)
	var recovered: int = ds.base36_to_int(code)

	# base36 code is 5 chars; value is modded to 36^5 = 60466176.
	var expected: int = original % (36 * 36 * 36 * 36 * 36)
	if recovered == expected:
		_ok("base36_roundtrip")
	else:
		_fail("base36_roundtrip", "expected %d got %d (code='%s')" % [expected, recovered, code])
