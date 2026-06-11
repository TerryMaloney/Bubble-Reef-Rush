## level_tennis_test.gd — Phase 24 contracts for BuildSession Level Tennis extensions.
##
## Tests:
##   1. section_ownership     — get_section_owner returns correct owner per beat range.
##   2. lock_enforcement      — is_beat_locked_for returns true for other owner's beats.
##   3. own_section_unlocked  — is_beat_locked_for returns false for own section.
##   4. contributors          — get_contributors() lists both owners in order.
##   5. dirty_on_add          — adding a section marks session dirty.
##
## Run with:
##   godot --headless --path . --script tests/integration/level_tennis_test.gd
extends SceneTree

var _pass_count := 0
var _fail_count := 0


func _initialize() -> void:
	_test_section_ownership()
	_test_lock_enforcement()
	_test_own_section_unlocked()
	_test_contributors()
	_test_dirty_on_add()

	print("Level Tennis tests: %d passed, %d failed" % [_pass_count, _fail_count])
	if _fail_count == 0:
		print("LEVEL_TENNIS_OK")
	quit()


func _ok(label: String) -> void:
	print("  PASS: " + label)
	_pass_count += 1


func _fail(label: String, detail: String = "") -> void:
	print("  FAIL: " + label + ("  -- " + detail if detail != "" else ""))
	_fail_count += 1


func _make_session() -> BuildSession:
	var bs: BuildSession = BuildSession.new()
	bs.create_new("test_author")
	return bs


## 1. section_ownership
func _test_section_ownership() -> void:
	var bs: BuildSession = _make_session()
	bs.add_tennis_section("alice", 0, 8)
	bs.add_tennis_section("bob", 8, 8)

	var owner_at_4: String = bs.get_section_owner(4.0)
	var owner_at_12: String = bs.get_section_owner(12.0)

	if owner_at_4 == "alice" and owner_at_12 == "bob":
		_ok("section_ownership")
	else:
		_fail("section_ownership",
			"beat4='%s' (want alice) beat12='%s' (want bob)" % [owner_at_4, owner_at_12])


## 2. lock_enforcement
func _test_lock_enforcement() -> void:
	var bs: BuildSession = _make_session()
	bs.add_tennis_section("alice", 0, 8)
	bs.add_tennis_section("bob", 8, 8)
	bs.lock_previous_sections = true

	# Beat 4 belongs to alice; bob should be locked out.
	var locked: bool = bs.is_beat_locked_for("bob", 4.0)
	if locked:
		_ok("lock_enforcement")
	else:
		_fail("lock_enforcement", "bob should be locked out of alice's beats")


## 3. own_section_unlocked
func _test_own_section_unlocked() -> void:
	var bs: BuildSession = _make_session()
	bs.add_tennis_section("alice", 0, 8)
	bs.lock_previous_sections = true

	var locked: bool = bs.is_beat_locked_for("alice", 4.0)
	if not locked:
		_ok("own_section_unlocked")
	else:
		_fail("own_section_unlocked", "alice should NOT be locked out of her own beats")


## 4. contributors
func _test_contributors() -> void:
	var bs: BuildSession = _make_session()
	bs.add_tennis_section("alice", 0, 8)
	bs.add_tennis_section("bob", 8, 8)

	var contributors: Array[String] = bs.get_contributors()
	if contributors.size() == 2 and contributors[0] == "alice" and contributors[1] == "bob":
		_ok("contributors")
	else:
		_fail("contributors", "expected [alice, bob], got %s" % str(contributors))


## 5. dirty_on_add
func _test_dirty_on_add() -> void:
	var bs: BuildSession = _make_session()
	bs.mark_saved()  # Reset dirty to false.
	bs.add_tennis_section("alice", 0, 8)
	if bs.dirty:
		_ok("dirty_on_add")
	else:
		_fail("dirty_on_add", "dirty should be true after add_tennis_section")
