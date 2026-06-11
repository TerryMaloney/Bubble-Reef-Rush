## DeterministicSeed — LCG-based seeded level picker for Daily Dive and Seeded Reef.
## All callers must go through pick_levels() to guarantee reproducible sequences.
## LCG parameters from Numerical Recipes (same values as Java's java.util.Random).
extends Node

const LCG_A: int = 1664525
const LCG_C: int = 1013904223
const APP_VERSION: String = "0.14.0"


func _lcg_next(state: int) -> int:
	return (LCG_A * state + LCG_C) & 0xFFFFFFFF


## Hash an arbitrary string to a non-zero 32-bit seed.
func seed_from_string(s: String) -> int:
	var h: int = 0
	for i in range(s.length()):
		h = (h * 31 + s.unicode_at(i)) & 0xFFFFFFFF
	return h if h != 0 else 1


## Seed for today's Daily Dive. Stable for the full calendar day.
func date_seed(date_string: String) -> int:
	return seed_from_string(date_string + ":" + APP_VERSION)


## Decode a 5-char base-36 seed code entered by the player.
func base36_to_int(code: String) -> int:
	const CHARS: String = "0123456789abcdefghijklmnopqrstuvwxyz"
	var result: int = 0
	for ch: String in code.to_lower():
		var idx: int = CHARS.find(ch)
		if idx < 0:
			continue
		result = result * 36 + idx
	return result if result != 0 else 1


## Encode a seed int to a 5-char base-36 string for sharing.
func int_to_base36(value: int) -> String:
	const CHARS: String = "0123456789abcdefghijklmnopqrstuvwxyz"
	var n: int = abs(value) % (36 * 36 * 36 * 36 * 36)
	if n == 0:
		n = 1
	var result: String = ""
	for _i in range(5):
		result = CHARS[n % 36] + result
		n /= 36
	return result


## Pick `count` level IDs from the official pool, filtered by [min_zone, max_zone].
## Same initial_seed + same arguments always returns the same sequence.
## Sampling is without-replacement within each pool pass; pool resets when exhausted.
func pick_levels(initial_seed: int, count: int, zone_range: Array) -> Array[String]:
	var pool: Array[String] = _build_pool(zone_range)
	if pool.is_empty():
		return []

	var state: int = initial_seed
	var result: Array[String] = []
	var available: Array[String] = pool.duplicate()

	for _i in range(count):
		if available.is_empty():
			available = pool.duplicate()
		state = _lcg_next(state)
		var idx: int = state % available.size()
		result.append(available[idx])
		available.remove_at(idx)

	return result


## Build the candidate pool: all z{z}-l{l} IDs in the zone range.
func _build_pool(zone_range: Array) -> Array[String]:
	var min_zone: int = int(zone_range[0]) if zone_range.size() >= 1 else 1
	var max_zone: int = int(zone_range[1]) if zone_range.size() >= 2 else 6
	var pool: Array[String] = []
	for z in range(min_zone, max_zone + 1):
		for l in range(1, 9):
			pool.append("z%d-l%d" % [z, l])
	return pool
