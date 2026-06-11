## WorldStation — data class for one Reef Radio station entry.
## Load from a dict entry in assets/data/worlds.json via from_dict().
extends RefCounted

class_name WorldStation

var id: String = ""
var name: String = ""
var description: String = ""
var zones: Array[int] = []
var build_pack_id: String = ""
var signature_mechanic: String = ""
var unlock_condition: Dictionary = {}


func from_dict(d: Dictionary) -> void:
	id = str(d.get("id", ""))
	name = str(d.get("name", ""))
	description = str(d.get("description", ""))
	var z: Array = d.get("zones", []) as Array
	zones.clear()
	for zv: Variant in z:
		zones.append(int(zv))
	build_pack_id = str(d.get("build_pack_id", ""))
	signature_mechanic = str(d.get("signature_mechanic", ""))
	unlock_condition = d.get("unlock_condition", {}) as Dictionary


## Returns true if this station is available to the given profile.
func is_unlocked_for(profile_id: String) -> bool:
	var condition_type: String = str(unlock_condition.get("type", "default"))
	match condition_type:
		"default":
			return true
		"radio_key":
			var key_id: String = str(unlock_condition.get("key_id", ""))
			return SaveSystem.has_radio_key(profile_id, key_id)
	return false
