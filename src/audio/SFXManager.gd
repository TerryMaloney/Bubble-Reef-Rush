# Autoload singleton. Plays all in-game sound effects by listening to EventBus.
# Audio files resolve through AssetRegistry (manifest key → fallback path chain).
# Missing files are silently skipped — the game is fully playable without them.
extends Node

# PERFECT / GOOD / MISS enum values from TimingJudge — using int to avoid
# circular autoload dependency (TimingJudge is not an autoload).
const RESULT_PERFECT: int = 0
const RESULT_GOOD: int = 1
const RESULT_MISS: int = 2

var _players: Dictionary = {}


func _ready() -> void:
	_load_sounds()
	EventBus.collectible_taken.connect(_on_collectible_taken)
	EventBus.player_hit.connect(_on_player_hit)
	EventBus.beat_judged.connect(_on_beat_judged)


func _load_sounds() -> void:
	var keys: Array[String] = [
		"sfx/timing_perfect",
		"sfx/timing_good",
		"sfx/timing_miss",
		"sfx/collectible_pearl",
		"sfx/player_hit",
		"sfx/fever_start",
		"sfx/fever_end",
		"sfx/near_miss",
		"sfx/checkpoint_set",
		"sfx/checkpoint_respawn",
		"sfx/coin_collect",
		"sfx/achievement",
		"sfx/ui_select",
		"sfx/ui_back",
	]
	for key: String in keys:
		var stream: AudioStream = AssetRegistry.get_stream(key)
		if stream == null:
			continue
		var player: AudioStreamPlayer = AudioStreamPlayer.new()
		player.bus = "SFX"
		player.stream = stream
		add_child(player)
		_players[key] = player


func _on_collectible_taken(_value: int) -> void:
	_play("sfx/collectible_pearl")


func _on_player_hit() -> void:
	_play("sfx/player_hit")


func _on_beat_judged(result: int) -> void:
	match result:
		RESULT_PERFECT: _play("sfx/timing_perfect")
		RESULT_GOOD:    _play("sfx/timing_good")
		RESULT_MISS:    _play("sfx/timing_miss")


func play_sfx(key: String) -> void:
	_play(key)


func _play(key: String) -> void:
	if _players.has(key):
		(_players[key] as AudioStreamPlayer).play()
