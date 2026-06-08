# Autoload singleton. Plays all in-game sound effects by listening to EventBus.
# Audio files live in assets/audio/sfx/. Missing files are silently skipped —
# the game remains fully playable without them (see Milestone 4).
extends Node

const SFX_DIR: String = "res://assets/audio/sfx/"

# Maps event key → filename inside SFX_DIR.
const SFX_FILES: Dictionary = {
	"timing_perfect":    "timing_perfect.wav",
	"timing_good":       "timing_good.wav",
	"timing_miss":       "timing_miss.wav",
	"collectible_pearl": "collectible_pearl.wav",
	"player_hit":        "player_hit.wav",
}

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
	for key: String in SFX_FILES:
		var path: String = SFX_DIR + SFX_FILES[key]
		if not ResourceLoader.exists(path):
			continue
		var stream: AudioStream = load(path) as AudioStream
		if stream == null:
			continue
		var player: AudioStreamPlayer = AudioStreamPlayer.new()
		player.bus = "SFX"
		player.stream = stream
		add_child(player)
		_players[key] = player


func _on_collectible_taken(_value: int) -> void:
	_play("collectible_pearl")


func _on_player_hit() -> void:
	_play("player_hit")


func _on_beat_judged(result: int) -> void:
	match result:
		RESULT_PERFECT: _play("timing_perfect")
		RESULT_GOOD:    _play("timing_good")
		RESULT_MISS:    _play("timing_miss")


func _play(key: String) -> void:
	if _players.has(key):
		(_players[key] as AudioStreamPlayer).play()
