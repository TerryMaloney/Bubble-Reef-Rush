## PlayerSkin — autoload that tracks the equipped character and cosmetics.
## VisualFactory reads these keys when building the player sprite.
extends Node


func get_character_id() -> String:
	return SaveSystem.get_equipped_character(SaveSystem.get_active_profile_id())


func get_trail_key() -> String:
	return SaveSystem.get_equipped_cosmetic(SaveSystem.get_active_profile_id(), "trail")


func get_ring_key() -> String:
	return SaveSystem.get_equipped_cosmetic(SaveSystem.get_active_profile_id(), "ring")


func equip_character(char_id: String) -> void:
	SaveSystem.set_equipped_character(SaveSystem.get_active_profile_id(), char_id)


func equip_trail(trail_id: String) -> void:
	SaveSystem.set_equipped_cosmetic(SaveSystem.get_active_profile_id(), "trail", trail_id)


func equip_ring(ring_id: String) -> void:
	SaveSystem.set_equipped_cosmetic(SaveSystem.get_active_profile_id(), "ring", ring_id)
