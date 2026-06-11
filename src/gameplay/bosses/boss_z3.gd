extends RefCounted

func get_phases() -> Array:
	return [
		{"beat_threshold": 8.0, "name": "approach", "pattern": "anchor_chain_wall"},
		{"beat_threshold": 16.0, "name": "frenzy", "pattern": "eel_snap_barrage"},
		{"beat_threshold": 24.0, "name": "final", "pattern": "anchor_eel_combo"},
	]
