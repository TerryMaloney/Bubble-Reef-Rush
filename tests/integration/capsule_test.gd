## capsule_test.gd — Phase 17 contracts for CapsuleSerializer.
##
## Tests:
##   1. roundtrip_deep_equal        — pack then unpack preserves level_ref and creator_nick.
##   2. tampered_checksum_rejected  — tampered base64 yields empty dict from unpack().
##   3. validate_errors_empty_on_valid — validate() on a good capsule returns no errors.
##   4. validate_catches_missing_field — validate() on dict without level_ref returns errors.
##
## Run with:
##   godot --headless --path . --script tests/integration/capsule_test.gd
extends SceneTree

var _pass_count := 0
var _fail_count := 0


func _initialize() -> void:
	_test_roundtrip_deep_equal()
	_test_tampered_checksum_rejected()
	_test_validate_errors_empty_on_valid()
	_test_validate_catches_missing_field()

	print("Capsule tests: %d passed, %d failed" % [_pass_count, _fail_count])
	if _fail_count == 0:
		print("CAPSULE_OK")
	quit()


func _ok(label: String) -> void:
	print("  PASS: " + label)
	_pass_count += 1


func _fail(label: String, detail: String = "") -> void:
	print("  FAIL: " + label + ("  -- " + detail if detail != "" else ""))
	_fail_count += 1


## 1. roundtrip_deep_equal
func _test_roundtrip_deep_equal() -> void:
	var ser = load("res://src/core/CapsuleSerializer.gd").new()
	var data: Dictionary = {
		"level_ref": "z1-l1",
		"creator_nick": "Terry",
		"target": "family",
		"ghost_inputs": [],
		"rules": [],
		"mutators": [],
	}
	var encoded: String = ser.pack(data)
	var result: Dictionary = ser.unpack(encoded)
	if result.is_empty():
		_fail("roundtrip_deep_equal", "unpack returned empty dict")
		return
	if str(result.get("level_ref", "")) != "z1-l1":
		_fail("roundtrip_deep_equal", "level_ref mismatch: got '%s'" % str(result.get("level_ref", "")))
		return
	if str(result.get("creator_nick", "")) != "Terry":
		_fail("roundtrip_deep_equal", "creator_nick mismatch: got '%s'" % str(result.get("creator_nick", "")))
		return
	_ok("roundtrip_deep_equal")


## 2. tampered_checksum_rejected
func _test_tampered_checksum_rejected() -> void:
	var ser = load("res://src/core/CapsuleSerializer.gd").new()
	var data: Dictionary = {
		"level_ref": "z1-l1",
		"creator_nick": "Terry",
		"target": "family",
		"ghost_inputs": [],
		"rules": [],
		"mutators": [],
	}
	var encoded: String = ser.pack(data)

	# Decode, tamper the checksum, re-encode.
	var json_str: String = Marshalls.base64_to_utf8(encoded)
	var json: JSON = JSON.new()
	if json.parse(json_str) != OK:
		_fail("tampered_checksum_rejected", "could not parse original JSON for tampering")
		return
	var parsed: Dictionary = json.data as Dictionary
	parsed["checksum"] = "invalid"
	var tampered_json: String = JSON.stringify(parsed)
	var tampered_encoded: String = Marshalls.utf8_to_base64(tampered_json)

	var result: Dictionary = ser.unpack(tampered_encoded)
	if not result.is_empty():
		_fail("tampered_checksum_rejected", "unpack should return empty dict for tampered capsule")
		return
	_ok("tampered_checksum_rejected")


## 3. validate_errors_empty_on_valid
func _test_validate_errors_empty_on_valid() -> void:
	var ser = load("res://src/core/CapsuleSerializer.gd").new()
	var data: Dictionary = {
		"level_ref": "z1-l1",
		"creator_nick": "Terry",
		"target": "family",
		"ghost_inputs": [],
		"rules": [],
		"mutators": [],
	}
	var encoded: String = ser.pack(data)
	var unpacked: Dictionary = ser.unpack(encoded)
	if unpacked.is_empty():
		_fail("validate_errors_empty_on_valid", "unpack failed unexpectedly")
		return
	var errors: Array[String] = ser.validate(unpacked)
	if not errors.is_empty():
		_fail("validate_errors_empty_on_valid", "expected no errors, got: %s" % str(errors))
		return
	_ok("validate_errors_empty_on_valid")


## 4. validate_catches_missing_field
func _test_validate_catches_missing_field() -> void:
	var ser = load("res://src/core/CapsuleSerializer.gd").new()
	# Deliberately omit level_ref.
	var data: Dictionary = {
		"schema_ver": "1.0",
		"app_ver": "0.14.0",
		"creator_nick": "Terry",
		"target": "family",
		"ghost_inputs": [],
		"rules": [],
		"mutators": [],
		"checksum": "somechecksum",
	}
	var errors: Array[String] = ser.validate(data)
	if errors.is_empty():
		_fail("validate_catches_missing_field", "expected errors for missing level_ref, got none")
		return
	_ok("validate_catches_missing_field")
