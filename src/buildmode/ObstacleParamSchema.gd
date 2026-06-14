## ObstacleParamSchema.gd
## Maps each obstacle_type slug to its build-mode editable parameter definitions.
## Used by PropertiesPanel to generate schema-driven input widgets.
##
## Each param definition dictionary:
##   { "key": String, "label": String, "type": "int"|"float"|"enum"|"bool",
##     "default": Variant, "options": Array (for enum), "min": float, "max": float }
class_name ObstacleParamSchema
extends RefCounted


## Display names for each obstacle type shown in the Build Mode palette.
static func display_name(obstacle_type: String) -> String:
	match obstacle_type:
		"coral_spike":     return "Spike"
		"jellyfish_drift": return "Jellyfish"
		"kelp_curtain":    return "Seaweed Wall"
		"bubble_mine":     return "Mine"
		"current_jet":     return "Water Jet"
		"anchor_chain":    return "Anchor"
		"eel_snap":        return "Eel"
		"lava_burst":      return "Lava"
		"pressure_wall":   return "Wall"
		"dark_void":       return "Darkness"
		"crystal_shard":   return "Crystal"
		"mirror_fish":     return "Shadow Fish"
	return obstacle_type.replace("_", " ").capitalize()


## Returns the list of editable parameter definitions for the given obstacle type.
## Returns an empty array for unknown types.
static func params_for(obstacle_type: String) -> Array[Dictionary]:
	match obstacle_type:
		"coral_spike":       return _coral_spike()
		"jellyfish_drift":   return _jellyfish_drift()
		"kelp_curtain":      return _kelp_curtain()
		"bubble_mine":       return _bubble_mine()
		"current_jet":       return _current_jet()
		"anchor_chain":      return _anchor_chain()
		"eel_snap":          return _eel_snap()
		"lava_burst":        return _lava_burst()
		"pressure_wall":     return _pressure_wall()
		"dark_void":         return _dark_void()
		"crystal_shard":     return _crystal_shard()
		"mirror_fish":       return _mirror_fish()
	return []


## Returns the zone(s) in which an obstacle type is available.
static func zones_for(obstacle_type: String) -> Array[int]:
	match obstacle_type:
		"coral_spike":       return [1, 2]
		"jellyfish_drift":   return [1, 2, 3]
		"kelp_curtain":      return [2, 3]
		"bubble_mine":       return [2, 3, 4]
		"current_jet":       return [2, 3, 4, 5]
		"anchor_chain":      return [3]
		"eel_snap":          return [3, 4, 5]
		"lava_burst":        return [4, 6]
		"pressure_wall":     return [4, 5]
		"dark_void":         return [5]
		"crystal_shard":     return [6]
		"mirror_fish":       return [5, 6]
	return []


## Full roster of obstacle types — used by Build Mode so creators always see every type.
static func all_types() -> Array[String]:
	return [
		"coral_spike", "jellyfish_drift", "kelp_curtain", "bubble_mine",
		"current_jet", "anchor_chain", "eel_snap", "lava_burst",
		"pressure_wall", "dark_void", "crystal_shard", "mirror_fish"
	]


## All obstacle types available for a given zone (unlocked by having cleared that zone).
## Zone 1 is always available; higher zones unlock when the player clears up to that zone.
static func types_for_zone(highest_cleared_zone: int) -> Array[String]:
	var all_types: Array[String] = [
		"coral_spike", "jellyfish_drift", "kelp_curtain", "bubble_mine",
		"current_jet", "anchor_chain", "eel_snap", "lava_burst",
		"pressure_wall", "dark_void", "crystal_shard", "mirror_fish"
	]
	var result: Array[String] = []
	for otype: String in all_types:
		var zones: Array[int] = zones_for(otype)
		for z: int in zones:
			if z <= maxi(1, highest_cleared_zone + 1):
				result.append(otype)
				break
	return result


# ── Per-type param definitions ────────────────────────────────────────────────

static func _coral_spike() -> Array[Dictionary]:
	return [
		{"key": "wall_attachment", "label": "Attach To", "type": "enum",
			"options": ["bottom", "top", "left", "right"], "default": "bottom"},
		{"key": "height", "label": "Length", "type": "int",
			"min": 60, "max": 400, "default": 120},
	]


static func _jellyfish_drift() -> Array[Dictionary]:
	return [
		{"key": "drift_speed", "label": "Speed", "type": "float",
			"min": 50.0, "max": 300.0, "default": 120.0},
		{"key": "oscillation_amplitude", "label": "Wiggle Range", "type": "float",
			"min": 20.0, "max": 200.0, "default": 80.0},
		{"key": "oscillation_period", "label": "Wiggle Speed", "type": "float",
			"min": 1.0, "max": 8.0, "default": 2.0},
	]


static func _kelp_curtain() -> Array[Dictionary]:
	return [
		{"key": "gap_y_normalized", "label": "Gap Position", "type": "float",
			"min": 0.1, "max": 0.9, "default": 0.5},
		{"key": "gap_height", "label": "Gap Size", "type": "float",
			"min": 120.0, "max": 400.0, "default": 240.0},
		{"key": "sway_enabled", "label": "Sways?", "type": "bool", "default": true},
	]


static func _bubble_mine() -> Array[Dictionary]:
	return [
		{"key": "drift_speed", "label": "Speed", "type": "float",
			"min": 20.0, "max": 200.0, "default": 60.0},
		{"key": "explosion_radius", "label": "Blast Size", "type": "float",
			"min": 40.0, "max": 120.0, "default": 80.0},
	]


static func _current_jet() -> Array[Dictionary]:
	return [
		{"key": "origin_wall", "label": "Origin Side", "type": "enum",
			"options": ["left", "right", "top", "bottom"], "default": "left"},
		{"key": "cycle_beats", "label": "Repeat Every", "type": "int",
			"min": 1, "max": 8, "default": 2},
	]


static func _anchor_chain() -> Array[Dictionary]:
	return [
		{"key": "max_angle_degrees", "label": "Swing Angle", "type": "float",
			"min": 10.0, "max": 60.0, "default": 35.0},
		{"key": "pendulum_frequency", "label": "Swing Speed", "type": "float",
			"min": 0.2, "max": 1.0, "default": 0.5},
		{"key": "chain_length", "label": "Chain Length", "type": "float",
			"min": 200.0, "max": 800.0, "default": 500.0},
	]


static func _eel_snap() -> Array[Dictionary]:
	return [
		{"key": "origin_wall", "label": "Origin Side", "type": "enum",
			"options": ["left", "right"], "default": "left"},
		{"key": "strike_length", "label": "Strike Length", "type": "float",
			"min": 100.0, "max": 500.0, "default": 300.0},
		{"key": "dormant_beats", "label": "Wait Time", "type": "int",
			"min": 1, "max": 16, "default": 4},
	]


static func _lava_burst() -> Array[Dictionary]:
	return [
		{"key": "cycle_beats", "label": "Repeat Every", "type": "int",
			"min": 2, "max": 8, "default": 4},
	]


static func _pressure_wall() -> Array[Dictionary]:
	return [
		{"key": "intensity", "label": "Gap Size", "type": "float",
			"min": 0.0, "max": 1.0, "default": 0.5},
		{"key": "gap_y_normalized", "label": "Gap Position", "type": "float",
			"min": 0.1, "max": 0.9, "default": 0.5},
		{"key": "travel_speed", "label": "Moving Speed", "type": "float",
			"min": 0.0, "max": 600.0, "default": 0.0},
	]


static func _dark_void() -> Array[Dictionary]:
	return [
		{"key": "duration_beats", "label": "Duration", "type": "int",
			"min": 1, "max": 16, "default": 4},
		{"key": "pulse_with_beat", "label": "Pulse with Beat", "type": "bool",
			"default": true},
	]


static func _crystal_shard() -> Array[Dictionary]:
	return [
		{"key": "lateral_speed", "label": "Speed", "type": "float",
			"min": 200.0, "max": 900.0, "default": 400.0},
		{"key": "entry_side", "label": "Entry Side", "type": "enum",
			"options": ["left", "right"], "default": "right"},
		{"key": "diagonal_speed_initial", "label": "First Direction", "type": "enum",
			"options": ["up", "down"], "default": "down"},
		{"key": "rotation_direction", "label": "Spins", "type": "enum",
			"options": ["clockwise", "counter_clockwise"], "default": "clockwise"},
		{"key": "color_variant", "label": "Color", "type": "enum",
			"options": ["blue", "purple", "pink", "teal"], "default": "blue"},
	]


static func _mirror_fish() -> Array[Dictionary]:
	return [
		{"key": "delay_frames", "label": "Mirror Delay", "type": "int",
			"min": 10, "max": 60, "default": 30},
		{"key": "approach_speed_bonus", "label": "Chase Speed", "type": "float",
			"min": 0.0, "max": 300.0, "default": 100.0},
	]
