## PassPlaySession — manages a local multiplayer Pass & Play session.
##
## Supports 2-4 profiles, one-attempt or three-attempt mode, optional tournament bracket.
## Call setup() → next_player() to start. After each play, call record_turn_result().
## When all players have taken their turns, call is_round_complete() and advance_round().
## Session ends when is_session_complete() returns true.
extends RefCounted

class_name PassPlaySession

enum Mode { ONE_ATTEMPT, THREE_ATTEMPTS }
enum Phase { SETUP, PLAYING, BETWEEN_TURNS, RESULTS }

var profiles: Array[String] = []
var level_id: String = ""
var mode: Mode = Mode.ONE_ATTEMPT
var current_phase: Phase = Phase.SETUP

var _turn_index: int = 0
var _round: int = 0
var _max_rounds: int = 1  # 1 = one turn each; 3 = three attempts each

## Per-profile score totals: {profile_id: int}.
var scores: Dictionary = {}
## Per-profile best scores: {profile_id: int}.
var best_scores: Dictionary = {}
## Full history: Array of {profile_id, round, score, stars}.
var history: Array[Dictionary] = []


func setup(profile_ids: Array, level: String, play_mode: int) -> void:
	profiles.clear()
	for pid: Variant in profile_ids:
		profiles.append(str(pid))
	level_id = level
	mode = play_mode as Mode
	_max_rounds = 3 if play_mode == Mode.THREE_ATTEMPTS else 1
	_turn_index = 0
	_round = 0
	scores = {}
	best_scores = {}
	history = []
	for pid: String in profiles:
		scores[pid] = 0
		best_scores[pid] = 0
	current_phase = Phase.PLAYING


## Returns the profile_id whose turn it currently is.
func current_profile() -> String:
	if profiles.is_empty():
		return ""
	return profiles[_turn_index % profiles.size()]


## Returns true if all players have taken their turn for the current round.
func is_round_complete() -> bool:
	return _turn_index > 0 and _turn_index % profiles.size() == 0


## Returns true if the session is fully complete.
func is_session_complete() -> bool:
	return _round >= _max_rounds and is_round_complete()


## Record a play result for the current player. Call after each level run.
func record_turn_result(score: int, stars: int) -> void:
	var pid: String = current_profile()
	scores[pid] = scores.get(pid, 0) + score
	if score > int(best_scores.get(pid, 0)):
		best_scores[pid] = score
	history.append({
		"profile_id": pid,
		"round": _round,
		"score": score,
		"stars": stars
	})
	current_phase = Phase.BETWEEN_TURNS
	_turn_index += 1
	if is_round_complete():
		_round += 1


## Advance to the next player. Call after showing PassPlayNextPlayerScreen.
func advance_to_next_player() -> void:
	current_phase = Phase.PLAYING


## Returns sorted results Array of {profile_id, total_score, best_score, funny_title}.
## Sorted descending by total_score; ties broken by best_score.
func get_results() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for pid: String in profiles:
		result.append({
			"profile_id": pid,
			"total_score": int(scores.get(pid, 0)),
			"best_score": int(best_scores.get(pid, 0)),
			"funny_title": funny_title(pid)
		})
	result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if int(a["total_score"]) != int(b["total_score"]):
			return int(a["total_score"]) > int(b["total_score"])
		return int(a["best_score"]) > int(b["best_score"])
	)
	return result


## Returns a fun title for a profile based on their session stats.
func funny_title(profile_id: String) -> String:
	var total: int = int(scores.get(profile_id, 0))
	var best: int = int(best_scores.get(profile_id, 0))

	# Compute rank without calling get_results() (avoids circular call).
	var beats_count: int = 0  # how many profiles this one beats
	var beaten_by_count: int = 0  # how many profiles beat this one
	for pid: String in profiles:
		if pid == profile_id:
			continue
		if int(scores.get(pid, 0)) < total:
			beats_count += 1
		elif int(scores.get(pid, 0)) > total:
			beaten_by_count += 1

	var is_first: bool = beaten_by_count == 0 and profiles.size() > 1
	var is_last: bool = beats_count == 0 and profiles.size() > 1

	if is_first:
		return "Reef Champion"
	if best >= 600:
		return "Pearl Hoarder"
	if total == 0:
		return "Mystery Diver"
	if total < 100:
		return "Bubble Newbie"
	if is_last:
		return "Brave Explorer"
	if _all_stars_equal():
		return "Tide Turner"
	return "Current Rider"


func _all_stars_equal() -> bool:
	if history.is_empty():
		return false
	var first_score: int = int(history[0].get("score", -1))
	for entry: Dictionary in history:
		if int(entry.get("score", -1)) != first_score:
			return false
	return true
