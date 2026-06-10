## AssetRegistry.gd
## Autoload singleton. Loads asset_manifest.json at startup and provides
## type-safe accessors for every logical asset key.
##
## Drop-in workflow: add or update an entry in assets/asset_manifest.json,
## place the file at the given path, and re-export the project. Zero code changes.
##
## If the real asset is missing, get_stream()/get_texture() fall back to the
## manifest's "fallback" path (a stub always present in the repo). If the
## fallback is also missing, the function returns null and the caller degrades
## gracefully (visuals disappear; audio is silent).
extends Node

const MANIFEST_PATH: String = "res://assets/asset_manifest.json"

## Parsed manifest dictionary: key → {path, fallback, spec}.
var _manifest: Dictionary = {}

## In-memory caches so each asset is loaded at most once.
var _stream_cache: Dictionary = {}
var _texture_cache: Dictionary = {}


func _ready() -> void:
	_load_manifest()


func _load_manifest() -> void:
	if not FileAccess.file_exists(MANIFEST_PATH):
		push_warning("AssetRegistry: manifest not found at '%s'" % MANIFEST_PATH)
		return
	var file: FileAccess = FileAccess.open(MANIFEST_PATH, FileAccess.READ)
	if file == null:
		push_warning("AssetRegistry: cannot open manifest")
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if parsed == null or not (parsed is Dictionary):
		push_warning("AssetRegistry: manifest JSON parse failed")
		return
	_manifest = parsed as Dictionary


## Returns the AudioStream for the given logical key, or null if unavailable.
func get_stream(key: String) -> AudioStream:
	if _stream_cache.has(key):
		return _stream_cache[key] as AudioStream

	var path: String = _resolve_path(key)
	if path.is_empty():
		return null

	var stream: AudioStream = load(path) as AudioStream
	_stream_cache[key] = stream
	return stream


## Returns the Texture2D for the given logical key, or null if unavailable.
func get_texture(key: String) -> Texture2D:
	if _texture_cache.has(key):
		return _texture_cache[key] as Texture2D

	var path: String = _resolve_path(key)
	if path.is_empty():
		return null

	var texture: Texture2D = load(path) as Texture2D
	_texture_cache[key] = texture
	return texture


## Returns the spec string for the given key (for STUB_ASSETS.md generation).
func get_spec(key: String) -> String:
	if not _manifest.has(key):
		return ""
	return str((_manifest[key] as Dictionary).get("spec", ""))


## Returns all keys whose primary path file doesn't exist (used to regenerate
## STUB_ASSETS.md and to verify the drop-in pipeline in tests).
func list_missing() -> Array[String]:
	var missing: Array[String] = []
	for key: String in _manifest.keys():
		if key.begins_with("_"):
			continue
		var entry: Dictionary = _manifest[key] as Dictionary
		var path: String = str(entry.get("path", ""))
		if path.is_empty():
			continue
		if not ResourceLoader.exists(path):
			missing.append(key)
	return missing


## Returns all keys that have a non-empty primary path (ignores comment keys).
func list_all_keys() -> Array[String]:
	var keys: Array[String] = []
	for key: String in _manifest.keys():
		if key.begins_with("_"):
			continue
		var entry: Dictionary = _manifest[key] as Dictionary
		if (entry as Dictionary).has("path"):
			keys.append(key)
	return keys


func _resolve_path(key: String) -> String:
	if not _manifest.has(key):
		push_warning("AssetRegistry: unknown key '%s'" % key)
		return ""
	var entry: Dictionary = _manifest[key] as Dictionary
	var primary: String = str(entry.get("path", ""))
	if not primary.is_empty() and ResourceLoader.exists(primary):
		return primary
	var fallback: String = str(entry.get("fallback", ""))
	if not fallback.is_empty() and ResourceLoader.exists(fallback):
		return fallback
	return ""
