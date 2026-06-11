## CapsuleSerializer — pack/unpack .brrc challenge capsule JSON bundles.
## Uses HMAC-SHA256 checksum via Godot's built-in Crypto class.
## Capsule schema: {schema_ver, app_ver, level_ref, creator_nick, target,
##                  ghost_inputs, rules, mutators, checksum}
extends RefCounted

class_name CapsuleSerializer

const SCHEMA_VER: String = "1.0"
const APP_VER: String = "0.14.0"
const HMAC_KEY: PackedByteArray = [66, 82, 82, 99, 97, 112, 115, 117, 108, 101, 75, 101, 121]  # "BRRcapsuleKey"


## Pack a capsule dictionary into a base64-encoded string.
## Input dict should have: level_ref, creator_nick, target, ghost_inputs, rules, mutators
func pack(data: Dictionary) -> String:
	var payload: Dictionary = {
		"schema_ver": SCHEMA_VER,
		"app_ver": APP_VER,
		"level_ref": str(data.get("level_ref", "")),
		"creator_nick": str(data.get("creator_nick", "Anonymous")),
		"target": str(data.get("target", "")),
		"ghost_inputs": data.get("ghost_inputs", []),
		"rules": data.get("rules", []),
		"mutators": data.get("mutators", []),
	}
	payload["checksum"] = _compute_checksum(payload)
	var json_str: String = JSON.stringify(payload)
	return Marshalls.utf8_to_base64(json_str)


## Unpack a base64-encoded capsule string. Returns null if invalid.
func unpack(encoded: String) -> Dictionary:
	var json_str: String = Marshalls.base64_to_utf8(encoded)
	if json_str.is_empty():
		return {}
	var json: JSON = JSON.new()
	if json.parse(json_str) != OK:
		return {}
	var data: Variant = json.data
	if not (data is Dictionary):
		return {}
	var dict: Dictionary = data as Dictionary
	var errors: Array[String] = validate(dict)
	if not errors.is_empty():
		return {}
	return dict


## Validate a capsule dict. Returns array of error strings (empty = valid).
func validate(data: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	if not data.has("schema_ver"):
		errors.append("missing schema_ver")
	if not data.has("app_ver"):
		errors.append("missing app_ver")
	if not data.has("level_ref"):
		errors.append("missing level_ref")
	if not data.has("checksum"):
		errors.append("missing checksum")
		return errors
	var stored_checksum: String = str(data.get("checksum", ""))
	var payload: Dictionary = data.duplicate()
	payload.erase("checksum")
	var expected: String = _compute_checksum(payload)
	if stored_checksum != expected:
		errors.append("checksum mismatch")
	return errors


func _compute_checksum(payload: Dictionary) -> String:
	var crypto: Crypto = Crypto.new()
	# sort_keys=true ensures key order is deterministic across pack/unpack cycles.
	var content: PackedByteArray = JSON.stringify(payload, "", true).to_utf8_buffer()
	var result: PackedByteArray = crypto.hmac_digest(HashingContext.HASH_SHA256, HMAC_KEY, content)
	return result.hex_encode()
