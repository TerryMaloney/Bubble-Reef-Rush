## CapsuleSerializer — pack/unpack/validate for Challenge Capsule (.brrc) files.
##
## Capsule data schema:
##   {schema_ver: int, app_ver: String, creator_nick: String,
##    level_id: String, level_hash: String,
##    ghost_inputs: Array, rules: Array, mutators: Array,
##    target: Dictionary, checksum: String}
##
## Packing: canonical JSON (no checksum) → HMAC-SHA256 → inject checksum → JSON → base64.
## Unpacking: base64 → JSON parse → Dictionary (or {} on parse failure).
## Validating: check schema, version, checksum; return Array[String] of issues.
##   Issues prefixed "WARN:" are non-fatal.
##   Issues without prefix are hard errors that should reject the capsule.
extends RefCounted

class_name CapsuleSerializer

const SCHEMA_VER: int = 1
const APP_VER: String = "1.0"
const CAPSULE_DIR: String = "user://capsules"
const MAX_CAPSULES: int = 100

# Embedded integrity key — tamper detection only, not cryptographic secrecy.
const _HMAC_KEY: String = "brr_capsule_integrity_v1"


## Pack capsule_data into a base64-encoded string suitable for clipboard or .brrc file.
## Automatically injects schema_ver, app_ver, and checksum — caller must not set them.
static func pack(capsule_data: Dictionary) -> String:
	var payload: Dictionary = capsule_data.duplicate(true)
	payload.erase("checksum")
	payload["schema_ver"] = SCHEMA_VER
	payload["app_ver"] = APP_VER
	# Round-trip through JSON parse so numeric types match what unpack() will produce.
	# Without this, int values like schema_ver=1 differ from float 1.0 after parse.
	payload = JSON.parse_string(JSON.stringify(payload)) as Dictionary
	var canonical: String = JSON.stringify(payload, "", true)
	payload["checksum"] = _hmac(canonical)
	return Marshalls.utf8_to_base64(JSON.stringify(payload, "", true))


## Decode a packed capsule string. Returns empty dict on any decode/parse error.
## Does NOT validate the checksum — call validate() separately.
static func unpack(raw: String) -> Dictionary:
	var json_str: String = Marshalls.base64_to_utf8(raw.strip_edges())
	if json_str.is_empty():
		return {}
	var parsed: Variant = JSON.parse_string(json_str)
	if parsed is Dictionary:
		return parsed as Dictionary
	return {}


## Validate a capsule dict (from unpack()). Returns Array[String] of issues.
## Empty array = fully valid.  "WARN:" prefix = non-fatal flag.  No prefix = hard error.
static func validate(data: Dictionary) -> Array[String]:
	var issues: Array[String] = []

	# Required fields.
	for field: String in ["schema_ver", "app_ver", "checksum"]:
		if not data.has(field):
			issues.append("missing field: " + field)
	if not issues.is_empty():
		return issues

	# Schema version — only SCHEMA_VER 1 is currently supported.
	var schema_ver: int = int(data.get("schema_ver", 0))
	if schema_ver != SCHEMA_VER:
		issues.append("unsupported schema_ver: %d" % schema_ver)
		return issues

	# App version compatibility.
	var app_ver: String = str(data.get("app_ver", "0.0"))
	var ver_issue: String = _check_app_ver(app_ver)
	if ver_issue != "":
		issues.append(ver_issue)

	# Checksum — computed over all fields except "checksum" itself.
	var stored_checksum: String = str(data.get("checksum", ""))
	var payload: Dictionary = data.duplicate(true)
	payload.erase("checksum")
	var canonical: String = JSON.stringify(payload, "", true)
	var expected: String = _hmac(canonical)
	if stored_checksum != expected:
		issues.append("checksum_mismatch")
		return issues  # Tampered — further checks unreliable.

	# Level hash (non-fatal: the capsule is still playable, just unverified).
	if data.has("level_hash") and data.has("level_id"):
		var level_id: String = str(data.get("level_id", ""))
		var stored_hash: String = str(data.get("level_hash", ""))
		var actual_hash: String = _compute_level_hash(level_id)
		if not actual_hash.is_empty() and actual_hash != stored_hash:
			issues.append("WARN:level_hash_mismatch")

	return issues


## Save a packed capsule code to user://capsules/. Returns path or "" on failure.
## Prunes oldest capsules if over MAX_CAPSULES.
static func save_capsule(raw_code: String) -> String:
	DirAccess.make_dir_recursive_absolute(CAPSULE_DIR)
	var ts: int = Time.get_ticks_msec()
	var path: String = "%s/%d.brrc" % [CAPSULE_DIR, ts]
	var f: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		push_warning("CapsuleSerializer: cannot write '%s'" % path)
		return ""
	f.store_string(raw_code)
	f.close()
	_prune_old_capsules()
	return path


## Load a .brrc file from disk. Returns raw base64 string or "".
static func load_capsule_file(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	var f: FileAccess = FileAccess.open(path, FileAccess.READ)
	if f == null:
		return ""
	var raw: String = f.get_as_text()
	f.close()
	return raw


# ── Private helpers ────────────────────────────────────────────────────────────

static func _hmac(data: String) -> String:
	var crypto := Crypto.new()
	var key_bytes: PackedByteArray = _HMAC_KEY.to_utf8_buffer()
	var data_bytes: PackedByteArray = data.to_utf8_buffer()
	var result: PackedByteArray = crypto.hmac_digest(HashingContext.HASH_SHA256, key_bytes, data_bytes)
	return result.hex_encode()


static func _check_app_ver(app_ver: String) -> String:
	var parts: PackedStringArray = app_ver.split(".")
	if parts.size() < 2:
		return "WARN:old_app_ver"
	var major: int = int(parts[0])
	var minor: int = int(parts[1])
	# Current minimum: 1.0. Older capsules may be missing newer fields.
	if major == 0:
		return "WARN:old_app_ver"
	if major > 1:
		return "WARN:newer_app_ver"
	return ""


static func _compute_level_hash(level_id: String) -> String:
	# Hash the .brl file for integrity; returns "" if level not found locally.
	var safe_id: String = level_id.replace("/", "-").replace(":", "_")
	var path: String = "res://assets/levels/%s.brl" % safe_id
	if not FileAccess.file_exists(path):
		return ""
	var f: FileAccess = FileAccess.open(path, FileAccess.READ)
	if f == null:
		return ""
	var content: String = f.get_as_text()
	f.close()
	return content.md5_text()


static func _prune_old_capsules() -> void:
	var dir: DirAccess = DirAccess.open(CAPSULE_DIR)
	if dir == null:
		return
	var files: Array[String] = []
	dir.list_dir_begin()
	var fname: String = dir.get_next()
	while fname != "":
		if not dir.current_is_dir() and fname.ends_with(".brrc"):
			files.append(fname)
		fname = dir.get_next()
	dir.list_dir_end()
	files.sort()
	while files.size() > MAX_CAPSULES:
		DirAccess.remove_absolute(CAPSULE_DIR + "/" + files[0])
		files.remove_at(0)
